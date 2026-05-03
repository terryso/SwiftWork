import SwiftUI

/// Raw event stream tab for Debug Panel -- displays unprocessed SDK events as JSON.
struct RawEventStreamView: View {
    let debugViewModel: DebugViewModel

    @State private var expandedEventIds: Set<UUID> = []

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    var body: some View {
        let events = debugViewModel.filteredEvents

        if events.isEmpty {
            DebugEmptyStateView(message: "无事件数据")
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(events) { event in
                        rawEventRow(event: event)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
    }

    private func rawEventRow(event: AgentEvent) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(formattedTimestamp(event.timestamp))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)

                Text(event.type.rawValue)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(colorForEventType(event.type).opacity(0.15))
                    .foregroundStyle(colorForEventType(event.type))
                    .clipShape(Capsule())

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if expandedEventIds.contains(event.id) {
                            expandedEventIds.remove(event.id)
                        } else {
                            expandedEventIds.insert(event.id)
                        }
                    }
                } label: {
                    Image(systemName: expandedEventIds.contains(event.id) ? "chevron.down" : "chevron.right")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if expandedEventIds.contains(event.id) {
                Text(debugViewModel.rawJSONString(for: event))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .padding(.leading, 4)
            }
        }
        .padding(.vertical, 3)
    }

    private func colorForEventType(_ type: AgentEventType) -> Color {
        .forEventType(type)
    }

    private func formattedTimestamp(_ date: Date) -> String {
        Self.timestampFormatter.string(from: date)
    }
}
