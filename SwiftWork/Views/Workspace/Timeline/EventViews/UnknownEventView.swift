import SwiftUI

struct UnknownEventView: View {
    let event: AgentEvent

    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "questionmark.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("未知事件")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !event.content.isEmpty {
                    Text(event.content)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                }
            }
            .padding(12)
            Spacer()
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        )
    }
}
