import SwiftUI

struct UserMessageView: View {
    let event: AgentEvent

    var body: some View {
        HStack {
            Spacer()
            Text(event.content)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.blue.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.primary)
        }
    }
}
