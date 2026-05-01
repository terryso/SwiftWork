import SwiftUI

struct UnknownEventView: View {
    let event: AgentEvent

    var body: some View {
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
