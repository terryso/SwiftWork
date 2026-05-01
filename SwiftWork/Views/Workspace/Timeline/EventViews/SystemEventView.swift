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
                // Error: red left bar + warning icon + red background
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.red)
                    .frame(width: 3)
                    .padding(.leading, 4)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(.red)
            } else {
                Image(systemName: "info.circle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(event.content)
                .font(.caption)
                .foregroundStyle(isError ? .red : .secondary)
            Spacer()
        }
        .padding(.vertical, 2)
        .padding(.trailing, 4)
        .background(isError ? Color.red.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
