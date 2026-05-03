import SwiftUI

struct BashToolRenderer: ToolRenderable {
    static let toolName = "Bash"
    static let accentColor: Color = .green
    static let icon: String = "terminal"

    @MainActor
    func body(content: ToolContent) -> any View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "terminal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(summaryTitle(content: content))
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }
                if let subtitle = subtitle(content: content) {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
        }
        .padding(8)
        .background(.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

}
