import SwiftUI

struct ToolResultView: View {
    let event: AgentEvent

    private var isError: Bool {
        event.metadata["isError"] as? Bool ?? false
    }

    var body: some View {
        HStack {
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
}
