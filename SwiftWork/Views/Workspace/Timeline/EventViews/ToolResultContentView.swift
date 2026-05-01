import SwiftUI

/// Displays tool result content with success/error styling, diff detection, and copy support.
struct ToolResultContentView: View {
    let output: String
    let isError: Bool

    @State private var isExpanded = false

    private static let maxPreviewLines = 5
    private static let maxPreviewChars = 200

    private var isDiffContent: Bool {
        guard !output.isEmpty else { return false }
        let lines = output.components(separatedBy: "\n")
        let diffLines = lines.filter { $0.hasPrefix("+") || $0.hasPrefix("-") || $0.hasPrefix("@@") }
        return diffLines.count >= 2
    }

    private var truncatedPreview: String {
        if output.isEmpty { return output }
        let lines = output.components(separatedBy: "\n")
        if lines.count <= Self.maxPreviewLines {
            if output.count <= Self.maxPreviewChars { return output }
            return String(output.prefix(Self.maxPreviewChars)) + "..."
        }
        return Array(lines.prefix(Self.maxPreviewLines)).joined(separator: "\n") + "\n..."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(isError ? .red : .green)

                Text("OUTPUT")
                    .font(.system(size: 9))
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                CopyButton(text: output)

                if !isExpanded && output.count > Self.maxPreviewChars {
                    Button("Expand") {
                        withAnimation { isExpanded = true }
                    }
                    .font(.system(size: 9))
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                }
            }

            if isDiffContent && !isError {
                diffView
            } else {
                plainTextView
            }
        }
        .padding(6)
        .background(isError ? Color.red.opacity(0.08) : Color.green.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // MARK: - Plain Text View

    private var plainTextView: some View {
        Text(isExpanded ? output : truncatedPreview)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(isError ? .red : .primary)
            .textSelection(.enabled)
    }

    // MARK: - Diff View

    private var diffView: some View {
        VStack(alignment: .leading, spacing: 0) {
            let allLines = output.components(separatedBy: "\n")
            let displayLines: [String] = isExpanded
                ? allLines
                : allLines.count > 10 ? Array(allLines[0..<10]) : allLines

            ForEach(Array(displayLines.enumerated()), id: \.offset) { _, line in
                diffLineView(line)
            }
        }
    }

    @ViewBuilder
    private func diffLineView(_ line: String) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(line)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
            Spacer()
        }
        .padding(.vertical, 1)
        .padding(.horizontal, 4)
        .background(diffLineBackground(line))
    }

    private func diffLineBackground(_ line: String) -> Color {
        if line.hasPrefix("+") { return .green.opacity(0.15) }
        if line.hasPrefix("-") { return .red.opacity(0.15) }
        if line.hasPrefix("@@") { return .blue.opacity(0.1) }
        return .clear
    }
}
