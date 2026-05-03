import SwiftUI

/// Token statistics tab for Debug Panel -- aggregated token usage and per-call breakdown.
struct TokenStatsView: View {
    let debugViewModel: DebugViewModel

    var body: some View {
        let summary = debugViewModel.tokenSummary

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Summary cards grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    statCard(title: "总 Token", value: "\(summary.totalTokens)")
                    statCard(title: "费用", value: String(format: "$%.4f", summary.totalCostUsd))
                    statCard(title: "Input", value: "\(summary.totalInputTokens)")
                    statCard(title: "Output", value: "\(summary.totalOutputTokens)")
                }

                Divider()

                // Per-call breakdown
                let resultEvents = debugViewModel.perCallTokenBreakdown
                if resultEvents.isEmpty {
                    Text("无 LLM 调用记录")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("调用历史")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    ForEach(Array(resultEvents.enumerated()), id: \.offset) { index, event in
                        resultCallRow(index: index + 1, event: event)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func resultCallRow(index: Int, event: AgentEvent) -> some View {
        HStack(spacing: 4) {
            Text("#\(index)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .leading)

            if let usage = event.metadata["usage"] as? [String: Any] {
                let input = (usage["inputTokens"] as? Int) ?? 0
                let output = (usage["outputTokens"] as? Int) ?? 0
                Text("\(input) / \(output)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let cost = event.metadata["totalCostUsd"] as? Double {
                Text(String(format: "$%.4f", cost))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let durationMs = event.metadata["durationMs"] as? Int {
                Text(String(format: "%.1fs", Double(durationMs) / 1000.0))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
