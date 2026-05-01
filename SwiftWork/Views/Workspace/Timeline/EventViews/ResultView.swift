import SwiftUI

struct ResultView: View {
    let event: AgentEvent

    private var subtype: String {
        event.metadata["subtype"] as? String ?? ""
    }

    private var durationMs: Int? {
        event.metadata["durationMs"] as? Int
    }

    private var totalCostUsd: Double? {
        event.metadata["totalCostUsd"] as? Double
    }

    private var numTurns: Int? {
        event.metadata["numTurns"] as? Int
    }

    private var isError: Bool {
        !subtype.isEmpty && subtype != "success" && subtype != "cancelled"
    }

    private var statusColor: Color {
        switch subtype {
        case "success": .green
        case "cancelled": .orange
        default: .red
        }
    }

    private var statusIcon: String {
        switch subtype {
        case "success": "checkmark.circle"
        case "cancelled": "pause.circle"
        default: "xmark.circle"
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .foregroundStyle(statusColor)
                    Text(subtype)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(statusColor)
                }
                if !event.content.isEmpty {
                    MarkdownContentView(markdown: event.content)
                        .font(.caption)
                }
                HStack(spacing: 12) {
                    if let duration = durationMs {
                        Label("\(duration)ms", systemImage: "clock")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if let turns = numTurns {
                        Label("\(turns) 轮", systemImage: "arrow.triangle.2.circlepath")
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
        .background(isError ? AnyShapeStyle(Color.red.opacity(0.08)) : AnyShapeStyle(.bar))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isError ? Color.red.opacity(0.3) : Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}
