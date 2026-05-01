import SwiftUI

struct TimelineView: View {
    let agentBridge: AgentBridge
    var toolRendererRegistry: ToolRendererRegistry = ToolRendererRegistry()

    @State private var selectedEventId: UUID?

    var body: some View {
        if agentBridge.events.isEmpty {
            emptyStateView
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(agentBridge.events) { event in
                            eventView(for: event)
                                .id(event.id)
                        }

                        if !agentBridge.streamingText.isEmpty {
                            StreamingTextView(text: agentBridge.streamingText)
                                .id("streaming")
                        }
                    }
                    .padding()
                }
                .onChange(of: agentBridge.events.count) { _, _ in
                    scrollToLast(proxy: proxy)
                }
                .onChange(of: agentBridge.streamingText) { _, _ in
                    scrollToLast(proxy: proxy)
                }
            }
        }
    }

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
            // Paired tool events are rendered inside ToolCardView (via toolContentMap)
            // Only render as fallback if there's no corresponding toolUse in the map
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
        // If this toolResult/toolProgress has been paired with a toolUse,
        // it's rendered inside the ToolCardView — don't render a separate card.
        if agentBridge.toolContentMap[toolUseId] != nil {
            EmptyView()
        } else {
            // Unpaired fallback: render the legacy views
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
