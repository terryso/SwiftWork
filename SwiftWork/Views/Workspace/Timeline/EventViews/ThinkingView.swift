import SwiftUI

struct ThinkingView: View {
    var isActive: Bool = true

    var body: some View {
        HStack(spacing: 8) {
            if isActive {
                SwiftUI.TimelineView(.animation) { context in
                    let angle = context.date.timeIntervalSinceReferenceDate
                        .truncatingRemainder(dividingBy: 1) * 360
                    Image(systemName: "gearshape")
                        .rotationEffect(.degrees(angle))
                }
                Text("思考中...")
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(.green)
                Text("Agent 已响应")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(8)
    }
}
