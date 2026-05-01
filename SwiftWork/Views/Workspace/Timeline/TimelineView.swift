import SwiftUI

struct TimelineView: View {
    let agentBridge: AgentBridge
    var toolRendererRegistry: ToolRendererRegistry = ToolRendererRegistry()

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
            toolUseView(event: event)
        case .toolResult:
            ToolResultView(event: event)
        case .toolProgress:
            ToolProgressView(event: event)
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
    private func toolUseView(event: AgentEvent) -> some View {
        let toolName = event.content
        if let renderer = toolRendererRegistry.renderer(for: toolName) {
            let content = ToolContent.fromToolUseEvent(event)
            AnyView(renderer.body(content: content))
        } else {
            ToolCallView(event: event)
        }
    }

    @ViewBuilder
    private func systemOrThinking(event: AgentEvent) -> some View {
        let subtype = event.metadata["subtype"] as? String ?? ""
        if subtype == "init" || subtype == "status" {
            ThinkingView()
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
