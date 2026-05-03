import SwiftUI

struct TimelineView: View {
    let agentBridge: AgentBridge
    var toolRendererRegistry: ToolRendererRegistry = ToolRendererRegistry()

    @Binding var selectedEventId: UUID?
    @State private var virtualizationManager = TimelineVirtualizationManager()
    @State private var scrollModeManager = ScrollModeManager()
    @State private var visibleRange: Range<Int> = 0..<0

    @State private var scrollPositionId: UUID?
    @State private var hasCompletedInitialScroll = false
    @State private var scrollViewHeight: CGFloat = 0

    private let estimatedRowHeight: CGFloat = 80

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
                topPlaceholder

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
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal)
                .padding(.vertical, 4)

                bottomPlaceholder

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
        .scrollPosition(id: scrollPositionBinding)
        .coordinateSpace(name: "timelineScroll")
        .onPreferenceChange(BottomAnchorPreferenceKey.self) { bottomY in
            guard hasCompletedInitialScroll else { return }
            let distanceFromBottom = max(0, bottomY - scrollViewHeight)
            if distanceFromBottom <= 96 {
                scrollModeManager.scrollMode = .followLatest
            }
        }
        .onChange(of: scrollPositionId) { oldId, newId in
            guard hasCompletedInitialScroll else { return }
            guard let newId,
                  let newIdx = agentBridge.events.firstIndex(where: { $0.id == newId })
            else { return }
            let total = agentBridge.events.count
            let distanceFromEnd = total - 1 - newIdx
            if distanceFromEnd <= 2 {
                scrollModeManager.scrollMode = .followLatest
            } else if let oldId,
                      let oldIdx = agentBridge.events.firstIndex(where: { $0.id == oldId }),
                      newIdx < oldIdx {
                scrollModeManager.scrollMode = .manualBrowse
            }
        }
        .task(id: agentBridge.events.first?.id) {
            hasCompletedInitialScroll = false
            scrollPositionId = nil
            guard !agentBridge.events.isEmpty else { return }
            scrollModeManager.scrollMode = .followLatest
            visibleRange = 0..<0
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            let initialRange = 0..<agentBridge.events.count
            visibleRange = initialRange
            try? await Task.sleep(for: .milliseconds(50))
            guard !Task.isCancelled else { return }

            let renderedHeight = estimatedRenderableHeight(
                in: initialRange,
                allEvents: agentBridge.events
            )
            let contentExceedsViewport = scrollViewHeight == 0 || renderedHeight > scrollViewHeight
            if shouldFocusLatestUserMessage(allEvents: agentBridge.events),
               let latestUserMessage = latestUserMessage(in: 0..<agentBridge.events.count, allEvents: agentBridge.events) {
                proxy.scrollTo(latestUserMessage.id, anchor: .top)
            } else if contentExceedsViewport {
                withAnimation {
                    proxy.scrollTo("bottom-anchor", anchor: .bottom)
                }
            } else if let firstRenderableEvent = firstRenderableEvent(in: initialRange, allEvents: agentBridge.events) {
                proxy.scrollTo(firstRenderableEvent.id, anchor: .top)
            }
            hasCompletedInitialScroll = true
        }
        .onChange(of: agentBridge.events.count) { oldCount, newCount in
            if newCount > oldCount {
                let range = oldCount..<newCount
                let hasUserMessage = range.contains { idx in
                    idx < agentBridge.events.count && agentBridge.events[idx].type == .userMessage
                }
                if hasUserMessage {
                    scrollModeManager.returnToBottom()
                }
            }
            updateVisibleRangeForCount(newCount)
            if hasCompletedInitialScroll && scrollModeManager.scrollMode == .followLatest {
                scrollToLast(proxy: proxy)
            }
        }
        .onChange(of: agentBridge.streamingText) { _, _ in
            if hasCompletedInitialScroll && scrollModeManager.scrollMode == .followLatest {
                scrollToLast(proxy: proxy)
            }
        }
    }

    private var scrollPositionBinding: Binding<UUID?> {
        hasCompletedInitialScroll ? $scrollPositionId : .constant(nil)
    }

    // MARK: - Virtualization

    private var virtualizedEvents: [AgentEvent] {
        let allEvents = agentBridge.events
        if allEvents.isEmpty { return [] }

        if !hasCompletedInitialScroll {
            return allEvents
        }

        if visibleRange.isEmpty {
            let upper = allEvents.count
            let lower = max(0, upper - 50)
            return virtualizationManager.eventsToRender(
                visibleRange: lower..<upper,
                allEvents: allEvents
            )
        }

        return virtualizationManager.eventsToRender(
            visibleRange: visibleRange,
            allEvents: allEvents
        )
    }

    private var topPlaceholder: some View {
        guard hasCompletedInitialScroll else { return AnyView(EmptyView()) }
        let upper = max(0, visibleRange.lowerBound - virtualizationManager.renderBuffer)
        return AnyView(Group {
            if agentBridge.hasEarlierEvents {
                Color.clear
                    .frame(height: 1)
                    .onAppear {
                        agentBridge.loadEarlierEvents()
                    }
            }
            if upper > 0 && !visibleRange.isEmpty {
                Spacer()
                    .frame(height: estimatedRenderableHeight(in: 0..<upper, allEvents: agentBridge.events))
            }
        })
    }

    private var bottomPlaceholder: some View {
        guard hasCompletedInitialScroll else { return AnyView(EmptyView()) }
        let allEvents = agentBridge.events
        let lower = min(
            allEvents.count,
            visibleRange.upperBound + virtualizationManager.renderBuffer
        )
        let remaining = allEvents.count - lower
        return AnyView(Group {
            if remaining > 0 && !visibleRange.isEmpty {
                Spacer()
                    .frame(height: estimatedRenderableHeight(in: lower..<allEvents.count, allEvents: allEvents))
            }
        })
    }

    private func updateVisibleRangeForCount(_ count: Int) {
        guard count > 0 else {
            visibleRange = 0..<0
            return
        }
        if scrollModeManager.scrollMode == .followLatest {
            let upper = count
            let lower = max(0, upper - 50)
            visibleRange = lower..<upper
        }
    }

    private func estimatedRenderableHeight(in range: Range<Int>, allEvents: [AgentEvent]) -> CGFloat {
        let safeRange = virtualizationManager.clampedRange(range, totalCount: allEvents.count)
        let renderableCount = allEvents[safeRange].reduce(into: 0) { count, event in
            if isRenderable(event) {
                count += 1
            }
        }
        return CGFloat(renderableCount) * estimatedRowHeight
    }

    private func firstRenderableEvent(in range: Range<Int>, allEvents: [AgentEvent]) -> AgentEvent? {
        let safeRange = virtualizationManager.clampedRange(range, totalCount: allEvents.count)
        return allEvents[safeRange].first(where: isRenderable)
    }

    private func latestUserMessage(in range: Range<Int>, allEvents: [AgentEvent]) -> AgentEvent? {
        let safeRange = virtualizationManager.clampedRange(range, totalCount: allEvents.count)
        return allEvents[safeRange].last(where: { $0.type == .userMessage })
    }

    private func shouldFocusLatestUserMessage(allEvents: [AgentEvent]) -> Bool {
        guard let latestUserMessageIndex = allEvents.lastIndex(where: { $0.type == .userMessage }) else {
            return false
        }

        let trailingStart = min(allEvents.count, latestUserMessageIndex + 1)
        let trailingRenderableCount = allEvents[trailingStart..<allEvents.count].reduce(into: 0) { count, event in
            if isRenderable(event) {
                count += 1
            }
        }

        return trailingRenderableCount > 8
    }

    // MARK: - Return to Bottom Button

    private func returnToBottomButton(proxy: ScrollViewProxy) -> some View {
        ZStack(alignment: .bottomTrailing) {
            if scrollModeManager.showReturnToBottomButton {
                Button {
                    scrollModeManager.returnToBottom()
                    let total = agentBridge.events.count
                    let lower = max(0, total - 50)
                    visibleRange = lower..<total
                    withAnimation {
                        proxy.scrollTo("bottom-anchor", anchor: .bottom)
                    }
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
        withAnimation {
            if !agentBridge.streamingText.isEmpty {
                proxy.scrollTo("streaming", anchor: .bottom)
            } else if let lastEvent = agentBridge.events.last {
                proxy.scrollTo(lastEvent.id, anchor: .bottom)
            }
        }
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
}

private struct BottomAnchorPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
