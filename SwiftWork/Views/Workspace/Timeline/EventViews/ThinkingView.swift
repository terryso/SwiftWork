import SwiftUI

struct ThinkingView: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "gearshape")
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: 1).repeatForever(autoreverses: false),
                    value: isAnimating
                )
            Text("思考中...")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(8)
        .onAppear { isAnimating = true }
    }
}
