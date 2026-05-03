import SwiftUI

/// Tool execution log tab for Debug Panel -- shows each tool call with status and results.
struct ToolLogListView: View {
    let debugViewModel: DebugViewModel

    var body: some View {
        let logs = debugViewModel.toolLogs

        if logs.isEmpty {
            DebugEmptyStateView(message: "无工具执行记录")
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(logs) { log in
                        toolLogRow(log: log)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
    }

    private func toolLogRow(log: ToolLogEntry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(log.toolName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Spacer()

                Text(log.status.rawValue)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(statusColor(log.status).opacity(0.15))
                    .foregroundStyle(statusColor(log.status))
                    .clipShape(Capsule())
            }

            Text(log.summaryTitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack(spacing: 8) {
                if let elapsed = log.elapsedTimeSeconds {
                    Text("耗时: \(elapsed)s")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if !log.resultPreview.isEmpty {
                    Text("结果: \(log.resultPreview)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 3)
    }

    private func statusColor(_ status: ToolExecutionStatus) -> Color {
        switch status {
        case .completed: return .green
        case .failed: return .red
        case .running: return .blue
        case .pending: return .gray
        }
    }
}
