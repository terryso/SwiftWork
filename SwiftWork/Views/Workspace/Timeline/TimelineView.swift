import SwiftUI

struct TimelineView: View {
    let agentBridge: AgentBridge
    var toolRendererRegistry: ToolRendererRegistry = ToolRendererRegistry()

    @State private var selectedEventId: UUID?
    @State private var virtualizationManager = TimelineVirtualizationManager()
    @State private var scrollModeManager = ScrollModeManager()
    @State private var visibleRange: Range<Int> = 0..<0

    @State private var scrollPositionId: UUID?
    @State private var hasCompletedInitialScroll = false
    @State private var scrollViewHeight: CGFloat = 0
    @State private var previousBottomAnchorY: CGFloat?

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
        .scrollPosition(id: $scrollPositionId)
        .coordinateSpace(name: "timelineScroll")
        .onPreferenceChange(BottomAnchorPreferenceKey.self) { bottomY in
            guard hasCompletedInitialScroll else { return }
            let distanceFromBottom = max(0, bottomY - scrollViewHeight)
            let scrollDelta = previousBottomAnchorY.map { $0 - bottomY } ?? 0
            previousBottomAnchorY = bottomY
            scrollModeManager.handleScrollChange(
                scrollDelta: scrollDelta,
                distanceFromBottom: distanceFromBottom
            )
        }
        .task(id: agentBridge.events.first?.id) {
            hasCompletedInitialScroll = false
            previousBottomAnchorY = nil
            guard !agentBridge.events.isEmpty else { return }
            scrollModeManager.scrollMode = .followLatest
            visibleRange = 0..<0
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            let total = agentBridge.events.count
            let lower = max(0, total - 50)
            visibleRange = lower..<total
            withAnimation {
                proxy.scrollTo("bottom-anchor", anchor: .bottom)
            }
            hasCompletedInitialScroll = true
        }
        .onChange(of: agentBridge.events.count) { _, newCount in
            updateVisibleRangeForCount(newCount)
            if scrollModeManager.scrollMode == .followLatest {
                scrollToLast(proxy: proxy)
            }
        }
        .onChange(of: agentBridge.streamingText) { _, _ in
            if scrollModeManager.scrollMode == .followLatest {
                scrollToLast(proxy: proxy)
            }
        }
    }

    // MARK: - Virtualization

    private var virtualizedEvents: [AgentEvent] {
        let allEvents = agentBridge.events
        if allEvents.isEmpty { return [] }

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
        let upper = max(0, visibleRange.lowerBound - virtualizationManager.renderBuffer)
        return Group {
            if upper > 0 && !visibleRange.isEmpty {
                Spacer()
                    .frame(height: CGFloat(upper) * estimatedRowHeight)
            }
        }
    }

    private var bottomPlaceholder: some View {
        let allEvents = agentBridge.events
        let lower = min(
            allEvents.count,
            visibleRange.upperBound + virtualizationManager.renderBuffer
        )
        let remaining = allEvents.count - lower
        return Group {
            if remaining > 0 && !visibleRange.isEmpty {
                Spacer()
                    .frame(height: CGFloat(remaining) * estimatedRowHeight)
            }
        }
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
        let isLastEvent = agentBridge.events.last?.id == event.id
        if (subtype == "init" || subtype == "status") && isLastEvent {
            ThinkingView()
        } else if subtype == "init" || subtype == "status" {
            ThinkingView(isActive: false)
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
}

private struct BottomAnchorPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
