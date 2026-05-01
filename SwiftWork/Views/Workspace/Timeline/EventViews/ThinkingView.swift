import SwiftUI

struct ThinkingView: View {
    var isActive: Bool = true
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 8) {
            if isActive {
                Image(systemName: "gearshape")
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        .linear(duration: 1).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
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
        .onAppear { if isActive { isAnimating = true } }
    }
}
