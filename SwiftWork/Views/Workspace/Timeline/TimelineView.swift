import SwiftUI

struct TimelineView: View {
    let agentBridge: AgentBridge

    var body: some View {
        if agentBridge.events.isEmpty {
            // Empty state
            VStack(spacing: 8) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("发送消息开始与 Agent 对话")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(agentBridge.events) { event in
                            eventView(for: event)
                                .id(event.id)
                        }

                        // Streaming text — accumulated partial messages rendered as a single block
                        if !agentBridge.streamingText.isEmpty {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(agentBridge.streamingText)
                                        .foregroundStyle(.primary)
                                        .textSelection(.enabled)
                                }
                                Spacer()
                            }
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

    @ViewBuilder
    private func eventView(for event: AgentEvent) -> some View {
        switch event.type {
        case .userMessage:
            userMessageView(event)
        case .partialMessage:
            EmptyView()
        case .assistant:
            assistantView(event)
        case .toolUse:
            toolUseView(event)
        case .toolResult:
            toolResultView(event)
        case .result:
            resultView(event)
        case .system:
            systemView(event)
        case .toolProgress:
            systemView(event)
        default:
            unknownView(event)
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

    // MARK: - User Message

    private func userMessageView(_ event: AgentEvent) -> some View {
        HStack {
            Spacer()
            Text(event.content)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.blue.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Assistant / Partial Message

    private func assistantView(_ event: AgentEvent) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.content)
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
            }
            Spacer()
        }
    }

    // MARK: - Tool Use

    private func toolUseView(_ event: AgentEvent) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(event.content)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                if let input = event.metadata["input"] as? String, !input.isEmpty {
                    Text(input)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            Spacer()
        }
        .padding(8)
        .background(.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Tool Result

    private func toolResultView(_ event: AgentEvent) -> some View {
        let isError = event.metadata["isError"] as? Bool ?? false
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                if isError {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption)
                        Text("Error")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.red)
                }
                Text(event.content)
                    .font(.caption)
                    .lineLimit(5)
                    .foregroundStyle(.primary)
            }
            Spacer()
        }
        .padding(8)
        .background(isError ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Result

    private func resultView(_ event: AgentEvent) -> some View {
        let subtype = event.metadata["subtype"] as? String ?? ""
        let durationMs = event.metadata["durationMs"] as? Int
        let totalCostUsd = event.metadata["totalCostUsd"] as? Double

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: subtype == "success" ? "checkmark.circle" : "xmark.circle")
                        .foregroundStyle(subtype == "success" ? .green : .orange)
                    Text(subtype)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                HStack(spacing: 12) {
                    if let duration = durationMs {
                        Label("\(duration)ms", systemImage: "clock")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if let cost = totalCostUsd {
                        Label(String(format: "$%.4f", cost), systemImage: "dollarsign.circle")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding(8)
        .background(.bar)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - System

    private func systemView(_ event: AgentEvent) -> some View {
        Text(event.content)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.vertical, 2)
    }

    // MARK: - Unknown

    private func unknownView(_ event: AgentEvent) -> some View {
        HStack {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(.secondary)
            Text("未知事件")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(8)
        .background(.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
