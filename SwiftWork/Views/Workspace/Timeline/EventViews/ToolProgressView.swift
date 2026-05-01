import SwiftUI

struct ToolProgressView: View {
    let event: AgentEvent

    private var elapsedTimeSeconds: Int? {
        event.metadata["elapsedTimeSeconds"] as? Int
    }

    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.content)
                    .font(.caption)
                    .fontWeight(.medium)
                if let elapsed = elapsedTimeSeconds {
                    Text("已用时 \(elapsed)s")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(8)
        .background(.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
