import SwiftUI

struct WriteToolRenderer: ToolRenderable {
    static let toolName = "Write"
    static let accentColor: Color = .orange
    static let icon: String = "pencil.and.outline"

    @MainActor
    func body(content: ToolContent) -> any View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "pencil.and.outline")
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
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let filePath = json["file_path"] as? String
        else {
            return content.toolName
        }
        return filePath
    }

    func subtitle(content: ToolContent) -> String? {
        guard !content.input.isEmpty,
              let data = content.input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentStr = json["content"] as? String, !contentStr.isEmpty
        else {
            return nil
        }
        return "\(contentStr.prefix(80))..."
    }
}
