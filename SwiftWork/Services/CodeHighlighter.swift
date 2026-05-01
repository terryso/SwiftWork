import SwiftUI
import Splash

/// Syntax highlighting service using Splash for Swift code.
/// Non-Swift languages fall back to monospace plain text rendering.
enum CodeHighlighter {

    // MARK: - Public API

    /// Render code with optional syntax highlighting based on language.
    /// - Parameters:
    ///   - code: The source code string to highlight.
    ///   - language: The language identifier (e.g., "swift", "python"). Nil means unknown.
    /// - Returns: A SwiftUI view representing the highlighted or plain text code.
    static func highlight(code: String, language: String?) -> AnyView {
        let trimmedLanguage = language?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if trimmedLanguage == "swift" {
            return highlightedSwiftView(code: code)
        } else {
            return plainCodeView(code: code)
        }
    }

    // MARK: - Swift Highlighting

    private static func highlightedSwiftView(code: String) -> AnyView {
        let font = Splash.Font(size: 13)
        let theme = Theme.sundellsColors(withFont: font)
        let format = AttributedStringOutputFormat(theme: theme)
        let highlighter = SyntaxHighlighter(format: format)

        let nsAttributedString = highlighter.highlight(code)

        guard let attributed = try? AttributedString(nsAttributedString, including: \.appKit) else {
            return AnyView(
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            )
        }

        return AnyView(
            Text(attributed)
                .textSelection(.enabled)
        )
    }

    // MARK: - Plain Text Fallback

    private static func plainCodeView(code: String) -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 0) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
            }
        )
    }
}
