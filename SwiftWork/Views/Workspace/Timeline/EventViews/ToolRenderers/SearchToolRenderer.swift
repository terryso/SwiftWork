import SwiftUI

struct SearchToolRenderer: ToolRenderable {
    static let toolName = "Grep"
    static let accentColor: Color = .purple
    static let icon: String = "text.magnifyingglass"

    @MainActor
    func body(content: ToolContent) -> any View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "text.magnifyingglass")
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

    func summaryTitle(content: ToolContent) -> String {
        guard !content.input.isEmpty,
              let data = content.input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return content.toolName
        }
        if let pattern = json["pattern"] as? String {
            return pattern
        }
        return content.toolName
    }

    func subtitle(content: ToolContent) -> String? {
        guard !content.input.isEmpty,
              let data = content.input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let path = json["path"] as? String
        else {
            return nil
        }
        return path
    }
}
