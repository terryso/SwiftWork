import SwiftUI

/// UI-layer transport mode concept, mapping to SDK transport types.
/// Simplifies the SDK's sse/http/stdio to just Remote/Local for the user.
enum MCPTransportMode: String, CaseIterable, Sendable {
    case remote
    case local
}

struct MCPTransportTypePicker: View {
    @Binding var selectedMode: MCPTransportMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MCPTransportMode.allCases, id: \.self) { mode in
                Button {
                    selectedMode = mode
                } label: {
                    Text(label(for: mode))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(selectedMode == mode ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            selectedMode == mode
                                ? Color.accentColor
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func label(for mode: MCPTransportMode) -> String {
        switch mode {
        case .remote: "Remote"
        case .local: "Local"
        }
    }
}
