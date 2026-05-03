import SwiftUI

/// Right-side panel that displays full details of a selected Timeline event.
struct InspectorView: View {
    let selectedEvent: AgentEvent?
    let toolContentMap: [String: ToolContent]

    @State private var isRawDataExpanded = false

    var body: some View {
        Group {
            if let event = selectedEvent {
                eventDetail(for: event)
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: selectedEvent?.id) { _, _ in
            isRawDataExpanded = false
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("选择一个事件以查看详情")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Event Detail

    @ViewBuilder
    private func eventDetail(for event: AgentEvent) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Basic info
                eventTypeHeader(event: event)
                timestampRow(event: event)

                if !event.content.isEmpty {
                    contentRow(event: event)
                }

                Divider()

                // Type-specific sections (see EventDetailSections.swift)
                switch event.type {
                case .toolUse, .toolResult, .toolProgress:
                    toolEventSection(event: event)
                case .result:
                    resultEventSection(event: event)
                case .assistant:
                    assistantEventSection(event: event)
                case .system:
                    systemEventSection(event: event)
                default:
                    genericMetadataSection(event: event)
                }

                Divider()

                // Raw JSON data
                rawDataSection(event: event)
            }
            .padding()
        }
    }

    // MARK: - Header

    private func eventTypeHeader(event: AgentEvent) -> some View {
        HStack {
            Text(event.type.rawValue)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(colorForEventType(event.type).opacity(0.15))
                .foregroundStyle(colorForEventType(event.type))
                .clipShape(Capsule())
            Spacer()
        }
    }

    private func colorForEventType(_ type: AgentEventType) -> Color {
        switch type {
        case .toolUse, .toolResult, .toolProgress: return .blue
        case .result: return .green
        case .assistant: return .purple
        case .userMessage: return .orange
        case .system: return .gray
        default: return .secondary
        }
    }

    private func timestampRow(event: AgentEvent) -> some View {
        HStack {
            Text("时间")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(event.timestamp.formatted(date: .omitted, time: .standard))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func contentRow(event: AgentEvent) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("内容")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(event.content)
                .font(.caption)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
    }

    // MARK: - Raw Data Section

    @ViewBuilder
    private func rawDataSection(event: AgentEvent) -> some View {
        let jsonString = rawJSONString(for: event)
        VStack(alignment: .leading, spacing: 4) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isRawDataExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: isRawDataExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10))
                    Text("原始数据")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    CopyButton(text: jsonString)
                }
            }
            .buttonStyle(.plain)

            if isRawDataExpanded {
                Text(jsonString)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
    }

    // MARK: - Helpers

    func labeledRow(_ label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
    }

    func statusText(_ status: ToolExecutionStatus) -> String {
        switch status {
        case .pending: return "pending"
        case .running: return "running"
        case .completed: return "completed"
        case .failed: return "failed"
        }
    }

    func rawJSONString(for event: AgentEvent) -> String {
        let payload: [String: Any] = [
            "id": event.id.uuidString,
            "type": event.type.rawValue,
            "content": event.content,
            "metadata": event.metadata,
            "timestamp": event.timestamp.ISO8601Format()
        ]
        guard let data = try? JSONSerialization.data(
            withJSONObject: payload,
            options: [.prettyPrinted, .sortedKeys]
        ) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
