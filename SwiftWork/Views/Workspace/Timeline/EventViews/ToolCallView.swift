import SwiftUI

struct ToolCallView: View {
    let event: AgentEvent

    private var input: String? {
        event.metadata["input"] as? String
    }

    var body: some View {
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
                if let input, !input.isEmpty {
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
}
