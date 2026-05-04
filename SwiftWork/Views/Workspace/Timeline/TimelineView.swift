import AppKit
import SwiftUI

struct TimelineView: View {
    let agentBridge: AgentBridge
    let reloadToken: UUID
    var toolRendererRegistry: ToolRendererRegistry = ToolRendererRegistry()

    @Binding var selectedEventId: UUID?
    @State private var virtualizationManager = TimelineVirtualizationManager(strategy: .conservative)
    @State private var scrollModeManager = ScrollModeManager()

    @State private var hasCompletedInitialScroll = false
    @State private var scrollViewHeight: CGFloat = 0
    @State private var distanceFromBottom: CGFloat = .greatestFiniteMagnitude
    @State private var topVisibleEventId: UUID?
    @State private var topVisibleEventMinY: CGFloat = 0
    @State private var pendingPrependAnchorId: UUID?
    @State private var pendingPrependAnchorOffset: CGFloat = 0
    @State private var pendingPrependDocumentHeight: CGFloat?
    @State private var programmaticScrollGeneration = 0
    @State private var scrollViewport = TimelineScrollViewport()

    private let topPaginationThreshold: CGFloat = 120

    init(
        agentBridge: AgentBridge,
        reloadToken: UUID = UUID(),
        toolRendererRegistry: ToolRendererRegistry = ToolRendererRegistry(),
        selectedEventId: Binding<UUID?>
    ) {
        self.agentBridge = agentBridge
        self.reloadToken = reloadToken
        self.toolRendererRegistry = toolRendererRegistry
        self._selectedEventId = selectedEventId
    }

    var body: some View {
        if agentBridge.events.isEmpty {
            emptyStateView
        } else {
            ScrollViewReader { proxy in
                GeometryReader { geo in
                    ZStack(alignment: .bottomTrailing) {
                        timelineContent(proxy: proxy)
                        returnToBottomButton(proxy: proxy)
                    }
                    .onAppear { scrollViewHeight = geo.size.height }
                    .onChange(of: geo.size.height) { _, newHeight in
                        scrollViewHeight = newHeight
                    }
                }
            }
        }
    }

    // MARK: - Timeline Content

    private func timelineContent(proxy: ScrollViewProxy) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(virtualizedEvents) { event in
                        eventView(for: event)
                            .id(event.id)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedEventId = event.id }
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.accentColor, lineWidth: selectedEventId == event.id && !hasOwnSelectionBorder(event) ? 2 : 0)
                            )
                            .background(
                                GeometryReader { rowGeo in
                                    Color.clear.preference(
                                        key: EventFramePreferenceKey.self,
                                        value: [event.id: rowGeo.frame(in: .named("timelineScroll"))]
                                    )
                                }
                            )
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal)
                .padding(.vertical, 4)

                if !agentBridge.streamingText.isEmpty {
                    StreamingTextView(text: agentBridge.streamingText)
                        .id("streaming")
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                }

                Color.clear
                    .frame(height: 1)
                    .id("bottom-anchor")
                    .background(
                        GeometryReader { bottomGeo in
                            Color.clear.preference(
                                key: BottomAnchorPreferenceKey.self,
                                value: bottomGeo.frame(in: .named("timelineScroll")).minY
                            )
                        }
                    )
            }
        }
        .background(
            TimelineScrollViewAccessor { scrollView in
                scrollViewport.capture(scrollView)
            }
            .frame(width: 0, height: 0)
        )
        .scrollPosition(id: scrollPositionBinding)
        .coordinateSpace(name: "timelineScroll")
        .onPreferenceChange(EventFramePreferenceKey.self) { frames in
            updateTopVisibleEvent(with: frames)
        }
        .onPreferenceChange(BottomAnchorPreferenceKey.self) { bottomY in
            distanceFromBottom = max(0, bottomY - scrollViewHeight)
            guard hasCompletedInitialScroll else { return }
            scrollModeManager.handleScrollChange(
                scrollDelta: 0,
                distanceFromBottom: distanceFromBottom,
                isProgrammatic: scrollModeManager.isProgrammaticScrollInFlight
            )
        }
        .task(id: reloadToken) {
            await performInitialPositioning(proxy: proxy)
        }
        .onChange(of: agentBridge.events.count) { oldCount, newCount in
            if newCount > oldCount && TimelineViewBehavior.shouldAutoScroll(
                hasCompletedInitialScroll: hasCompletedInitialScroll,
                scrollMode: scrollModeManager.scrollMode,
                hasPendingPrepend: pendingPrependAnchorId != nil
            ) {
                scrollToLast(proxy: proxy)
            }
        }
        .onChange(of: agentBridge.timelinePaginationState.prependRevision) { _, _ in
            guard hasCompletedInitialScroll else { return }
            restoreAnchorAfterPrepend(proxy: proxy)
        }
        .onChange(of: agentBridge.streamingText) { _, _ in
            if TimelineViewBehavior.shouldAutoScroll(
                hasCompletedInitialScroll: hasCompletedInitialScroll,
                scrollMode: scrollModeManager.scrollMode,
                hasPendingPrepend: pendingPrependAnchorId != nil
            ) {
                scrollToLast(proxy: proxy)
            }
        }
    }

    // MARK: - Virtualization

    private var virtualizedEvents: [AgentEvent] {
        let allEvents = agentBridge.events
        if allEvents.isEmpty { return [] }
        return virtualizationManager.eventsToRender(
            visibleRange: 0..<allEvents.count,
            allEvents: allEvents
        )
    }

    // MARK: - Return to Bottom Button

    private func returnToBottomButton(proxy: ScrollViewProxy) -> some View {
        ZStack(alignment: .bottomTrailing) {
            if scrollModeManager.showReturnToBottomButton {
                Button {
                    scrollModeManager.returnToBottom()
                    scrollToLast(proxy: proxy)
                } label: {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .background(Circle().fill(.regularMaterial).shadow(radius: 2))
                }
                .buttonStyle(.plain)
                .padding()
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: scrollModeManager.showReturnToBottomButton)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("发送消息开始与 Agent 对话")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Event Views

    @ViewBuilder
    private func eventView(for event: AgentEvent) -> some View {
        switch event.type {
        case .userMessage:
            UserMessageView(event: event)
        case .partialMessage:
            EmptyView()
        case .assistant:
            AssistantMessageView(event: event)
        case .toolUse:
            toolCardView(for: event)
        case .toolResult, .toolProgress:
            pairedToolEventView(for: event)
        case .result:
            ResultView(event: event)
        case .system:
            systemOrThinking(event: event)
        case .plan:
            PlanView(event: event)
        case .hookStarted,
             .hookProgress,
             .hookResponse,
             .taskStarted,
             .taskProgress,
             .authStatus,
             .filesPersisted,
             .localCommandOutput,
             .promptSuggestion,
             .toolUseSummary:
            SystemEventView(event: event)
        case .unknown:
            UnknownEventView(event: event)
        }
    }

    @ViewBuilder
    private func toolCardView(for event: AgentEvent) -> some View {
        let toolUseId = event.metadata["toolUseId"] as? String ?? ""
        if let content = agentBridge.toolContentMap[toolUseId] {
            ToolCardView(
                content: content,
                registry: toolRendererRegistry,
                isSelected: selectedEventId == event.id,
                onSelect: { selectedEventId = event.id }
            )
        } else {
            ToolCallView(event: event)
        }
    }

    @ViewBuilder
    private func pairedToolEventView(for event: AgentEvent) -> some View {
        let toolUseId = event.metadata["toolUseId"] as? String ?? ""
        if agentBridge.toolContentMap[toolUseId] != nil {
            EmptyView()
        } else {
            if event.type == .toolResult {
                ToolResultView(event: event)
            } else {
                ToolProgressView(event: event)
            }
        }
    }

    @ViewBuilder
    private func systemOrThinking(event: AgentEvent) -> some View {
        let subtype = event.metadata["subtype"] as? String ?? ""
        if subtype == "init" || subtype == "status" {
            let isLatestInit = agentBridge.events.last(where: {
                let s = $0.metadata["subtype"] as? String ?? ""
                return s == "init" || s == "status"
            })?.id == event.id
            ThinkingView(isActive: isLatestInit && agentBridge.isRunning)
        } else if let isError = event.metadata["isError"] as? Bool, isError {
            SystemEventView(event: event, isError: true)
        } else {
            SystemEventView(event: event)
        }
    }

    private func scrollToLast(proxy: ScrollViewProxy) {
        performProgrammaticScroll(proxy: proxy, animated: true) {
            switch TimelineViewBehavior.latestScrollTarget(
                streamingText: agentBridge.streamingText,
                events: agentBridge.events
            ) {
            case .streaming:
                proxy.scrollTo("streaming", anchor: .bottom)
            case .event(let eventId):
                proxy.scrollTo(eventId, anchor: .bottom)
            case .bottomAnchor:
                proxy.scrollTo("bottom-anchor", anchor: .bottom)
            }
        }
    }

    private func clearPendingPrependState() {
        pendingPrependAnchorId = nil
        pendingPrependAnchorOffset = 0
        pendingPrependDocumentHeight = nil
    }

    private func preserveViewportAfterPrepend() -> Bool {
        guard let previousDocumentHeight = pendingPrependDocumentHeight,
              let currentDocumentHeight = scrollViewport.documentHeight
        else {
            return false
        }

        let heightDelta = currentDocumentHeight - previousDocumentHeight
        guard heightDelta > 0 else { return false }
        scrollViewport.adjustScrollOrigin(by: heightDelta)
        return true
    }

    private func restorePrependOffset(_ offset: CGFloat) {
        guard offset != 0 else { return }
        scrollViewport.adjustScrollOrigin(by: -offset)
    }

    /// Returns true if the event's view already renders its own selection border.
    private func hasOwnSelectionBorder(_ event: AgentEvent) -> Bool {
        if event.type == .toolUse {
            let toolUseId = event.metadata["toolUseId"] as? String ?? ""
            return agentBridge.toolContentMap[toolUseId] != nil
        }
        return false
    }

    private func isRenderable(_ event: AgentEvent) -> Bool {
        switch event.type {
        case .partialMessage:
            return false
        case .toolResult, .toolProgress:
            let toolUseId = event.metadata["toolUseId"] as? String ?? ""
            return agentBridge.toolContentMap[toolUseId] == nil
        default:
            return true
        }
    }

    private var scrollPositionBinding: Binding<UUID?> {
        .constant(nil)
    }

    private func updateTopVisibleEvent(with frames: [UUID: CGRect]) {
        guard hasCompletedInitialScroll, scrollViewHeight > 0 else { return }

        let visibleFrames = frames
            .filter { $0.value.maxY >= 0 && $0.value.minY <= scrollViewHeight }
            .sorted { lhs, rhs in
                if lhs.value.minY == rhs.value.minY {
                    return eventIndex(for: lhs.key) < eventIndex(for: rhs.key)
                }
                return lhs.value.minY < rhs.value.minY
            }

        guard let topEntry = visibleFrames.first else { return }

        let previousId = topVisibleEventId
        let previousMinY = topVisibleEventMinY
        topVisibleEventId = topEntry.key
        topVisibleEventMinY = topEntry.value.minY

        let scrollDelta = computeScrollDelta(
            previousId: previousId,
            previousMinY: previousMinY,
            newId: topEntry.key,
            newMinY: topEntry.value.minY
        )

        scrollModeManager.handleScrollChange(
            scrollDelta: scrollDelta,
            distanceFromBottom: distanceFromBottom,
            isProgrammatic: scrollModeManager.isProgrammaticScrollInFlight
        )

        maybeLoadEarlierEventsIfNeeded()
    }

    private func maybeLoadEarlierEventsIfNeeded() {
        let isFirstLoadedEventVisible = topVisibleEventId == agentBridge.events.first?.id
        guard TimelineViewBehavior.shouldLoadEarlier(
            hasCompletedInitialScroll: hasCompletedInitialScroll,
            hasEarlierEvents: agentBridge.hasEarlierEvents,
            isLoadingEarlierEvents: agentBridge.isLoadingEarlierEvents,
            hasPendingPrepend: pendingPrependAnchorId != nil,
            isFirstLoadedEventVisible: isFirstLoadedEventVisible,
            topVisibleEventMinY: topVisibleEventMinY,
            threshold: topPaginationThreshold
        ) else { return }

        let previousPrependRevision = agentBridge.timelinePaginationState.prependRevision
        pendingPrependAnchorId = topVisibleEventId ?? agentBridge.events.first?.id
        pendingPrependAnchorOffset = topVisibleEventMinY
        pendingPrependDocumentHeight = scrollViewport.documentHeight
        agentBridge.loadEarlierEvents()

        if !agentBridge.isLoadingEarlierEvents,
           agentBridge.timelinePaginationState.prependRevision == previousPrependRevision {
            clearPendingPrependState()
        }
    }

    private func restoreAnchorAfterPrepend(proxy: ScrollViewProxy) {
        guard let anchorId = pendingPrependAnchorId else { return }
        if preserveViewportAfterPrepend() {
            clearPendingPrependState()
            return
        }

        let preservedOffset = pendingPrependAnchorOffset
        performProgrammaticScroll(proxy: proxy) {
            proxy.scrollTo(anchorId, anchor: .top)
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(40))
            restorePrependOffset(preservedOffset)
        }
        clearPendingPrependState()
    }

    private func eventIndex(for eventId: UUID) -> Int {
        agentBridge.events.firstIndex(where: { $0.id == eventId }) ?? .max
    }

    private func computeScrollDelta(
        previousId: UUID?,
        previousMinY: CGFloat,
        newId: UUID,
        newMinY: CGFloat
    ) -> CGFloat {
        guard let previousId else { return 0 }
        if previousId == newId {
            return previousMinY - newMinY
        }

        let previousIndex = eventIndex(for: previousId)
        let newIndex = eventIndex(for: newId)
        if newIndex < previousIndex {
            return -scrollModeManagerThresholdStep
        }
        if newIndex > previousIndex {
            return scrollModeManagerThresholdStep
        }
        return previousMinY - newMinY
    }

    private var scrollModeManagerThresholdStep: CGFloat {
        20
    }

    private func performProgrammaticScroll(
        proxy: ScrollViewProxy,
        animated: Bool = false,
        action: () -> Void
    ) {
        programmaticScrollGeneration += 1
        let generation = programmaticScrollGeneration
        scrollModeManager.beginProgrammaticScroll()
        if animated {
            withAnimation {
                action()
            }
        } else {
            action()
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(animated ? 220 : 80))
            guard generation == programmaticScrollGeneration else { return }
            scrollModeManager.endProgrammaticScroll()
        }
    }

    private func performInitialPositioning(proxy: ScrollViewProxy) async {
        hasCompletedInitialScroll = false
        clearPendingPrependState()
        topVisibleEventId = nil
        topVisibleEventMinY = 0
        scrollModeManager.resetForReload()

        guard !agentBridge.events.isEmpty else { return }
        try? await Task.sleep(for: .milliseconds(50))
        guard !Task.isCancelled else { return }
        performProgrammaticScroll(proxy: proxy) {
            proxy.scrollTo("bottom-anchor", anchor: .bottom)
        }
        try? await Task.sleep(for: .milliseconds(100))
        guard !Task.isCancelled else { return }
        hasCompletedInitialScroll = true
    }
}

private struct BottomAnchorPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct EventFramePreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

enum TimelineScrollTarget: Equatable {
    case streaming
    case event(UUID)
    case bottomAnchor
}

enum TimelineViewBehavior {
    static func latestScrollTarget(
        streamingText: String,
        events: [AgentEvent]
    ) -> TimelineScrollTarget {
        if !streamingText.isEmpty {
            return .streaming
        }
        if let lastEvent = events.last {
            return .event(lastEvent.id)
        }
        return .bottomAnchor
    }

    static func shouldAutoScroll(
        hasCompletedInitialScroll: Bool,
        scrollMode: ScrollMode,
        hasPendingPrepend: Bool
    ) -> Bool {
        hasCompletedInitialScroll && scrollMode == .followLatest && !hasPendingPrepend
    }

    static func shouldLoadEarlier(
        hasCompletedInitialScroll: Bool,
        hasEarlierEvents: Bool,
        isLoadingEarlierEvents: Bool,
        hasPendingPrepend: Bool,
        isFirstLoadedEventVisible: Bool,
        topVisibleEventMinY: CGFloat,
        threshold: CGFloat
    ) -> Bool {
        hasCompletedInitialScroll &&
            hasEarlierEvents &&
            !isLoadingEarlierEvents &&
            !hasPendingPrepend &&
            isFirstLoadedEventVisible &&
            topVisibleEventMinY <= threshold
    }
}

@MainActor
final class TimelineScrollViewport {
    weak var scrollView: NSScrollView?

    var documentHeight: CGFloat? {
        scrollView?.documentView?.bounds.height
    }

    func capture(_ scrollView: NSScrollView) {
        self.scrollView = scrollView
    }

    func adjustScrollOrigin(by delta: CGFloat) {
        guard delta != 0,
              let scrollView,
              let documentView = scrollView.documentView
        else { return }

        let clipView = scrollView.contentView
        let maxOriginY = max(0, documentView.bounds.height - clipView.bounds.height)
        var origin = clipView.bounds.origin
        origin.y = min(maxOriginY, max(0, origin.y + delta))
        clipView.scroll(to: origin)
        scrollView.reflectScrolledClipView(clipView)
    }
}

private struct TimelineScrollViewAccessor: NSViewRepresentable {
    let onResolve: (NSScrollView) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        resolve(from: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        resolve(from: nsView)
    }

    private func resolve(from view: NSView) {
        DispatchQueue.main.async {
            guard let scrollView = enclosingScrollView(from: view) else { return }
            onResolve(scrollView)
        }
    }

    private func enclosingScrollView(from view: NSView) -> NSScrollView? {
        if let scrollView = view.enclosingScrollView {
            return scrollView
        }

        var currentSuperview: NSView? = view.superview
        while let current = currentSuperview {
            if let scrollView = current as? NSScrollView {
                return scrollView
            }
            currentSuperview = current.superview
        }
        return nil
    }
}
