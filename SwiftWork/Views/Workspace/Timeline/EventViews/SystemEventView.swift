import SwiftUI

struct SystemEventView: View {
    let event: AgentEvent
    let isError: Bool

    init(event: AgentEvent, isError: Bool = false) {
        self.event = event
        self.isError = isError
    }

    var body: some View {
        HStack(spacing: 4) {
            if isError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
            }
            Text(event.content)
                .font(.caption)
                .foregroundStyle(isError ? .red : .secondary)
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
