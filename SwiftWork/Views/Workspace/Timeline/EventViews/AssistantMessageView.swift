import SwiftUI

struct AssistantMessageView: View {
    let event: AgentEvent

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 2)
                .padding(.trailing, 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.content)
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
            }
            Spacer()
        }
    }
}
