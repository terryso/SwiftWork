import SwiftUI
import Markdown

/// Renders Markdown text into a SwiftUI View hierarchy using swift-markdown's MarkupVisitor.
enum MarkdownRenderer {

    // MARK: - Public API

    /// Parse and render a Markdown string into an array of SwiftUI views.
    @MainActor
    static func render(_ markdown: String) -> [AnyView] {
        guard !markdown.isEmpty else { return [] }
        let document = Document(parsing: markdown)
        var visitor = MarkdownToViewsVisitor()
        visitor.visit(document)
        return visitor.views
    }
}

// MARK: - Visitor Implementation

/// Converts swift-markdown AST nodes into SwiftUI AnyView elements.
private struct MarkdownToViewsVisitor: MarkupVisitor {
    typealias Result = Void

    /// Accumulated top-level views from the visit.
    private(set) var views: [AnyView] = []

    // Typealiases to disambiguate Markdown types from SwiftUI types
    private typealias MarkdownText = Markdown.Text
    private typealias MarkdownLink = Markdown.Link

    mutating func defaultVisit(_ markup: Markup) -> Result {
        for child in markup.children {
            visit(child)
        }
    }

    // MARK: - Document

    mutating func visitDocument(_ document: Document) -> Result {
        for child in document.children {
            visit(child)
        }
    }

    // MARK: - Headings

    mutating func visitHeading(_ heading: Heading) -> Result {
        let text = collectInlineText(from: heading)
        let view: AnyView
        switch heading.level {
        case 1:
            view = AnyView(
                SwiftUI.Text(text)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            )
        case 2:
            view = AnyView(
                SwiftUI.Text(text)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            )
        case 3:
            view = AnyView(
                SwiftUI.Text(text)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            )
        default:
            view = AnyView(
                SwiftUI.Text(text)
                    .font(.headline)
                    .foregroundStyle(.primary)
            )
        }
        views.append(view)
    }

    // MARK: - Paragraph

    mutating func visitParagraph(_ paragraph: Paragraph) -> Result {
        let attributed = collectAttributedString(from: paragraph)
        views.append(AnyView(
            SwiftUI.Text(attributed)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        ))
    }

    // MARK: - Code Block

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> Result {
        let code = codeBlock.code
        let language = codeBlock.language
        let codeView = buildCodeView(code: code, language: language)
        views.append(codeView)
    }

    // MARK: - Lists

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> Result {
        var items: [AnyView] = []
        for listItem in unorderedList.children {
            if let li = listItem as? ListItem {
                let content = collectAttributedString(from: li)
                items.append(AnyView(
                    HStack(alignment: .top, spacing: 6) {
                        SwiftUI.Text("\u{2022}")
                            .foregroundStyle(.secondary)
                        SwiftUI.Text(content)
                            .textSelection(.enabled)
                    }
                ))
            }
        }
        views.append(AnyView(
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    item
                }
            }
        ))
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) -> Result {
        var items: [AnyView] = []
        for (index, child) in orderedList.children.enumerated() {
            if let li = child as? ListItem {
                let content = collectAttributedString(from: li)
                items.append(AnyView(
                    HStack(alignment: .top, spacing: 6) {
                        SwiftUI.Text("\(index + 1).")
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 20, alignment: .trailing)
                        SwiftUI.Text(content)
                            .textSelection(.enabled)
                    }
                ))
            }
        }
        views.append(AnyView(
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    item
                }
            }
        ))
    }

    // MARK: - Block Quote

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> Result {
        var innerVisitor = MarkdownToViewsVisitor()
        for child in blockQuote.children {
            innerVisitor.visit(child)
        }
        let innerViews = innerVisitor.views
        views.append(AnyView(
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 3)
                    .padding(.trailing, 8)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(innerViews.enumerated()), id: \.offset) { _, v in
                        v
                    }
                }
            }
            .padding(.vertical, 4)
        ))
    }

    // MARK: - Thematic Break

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> Result {
        views.append(AnyView(Divider()))
    }

    // MARK: - Table

    mutating func visitTable(_ table: Markdown.Table) -> Result {
        var headerCells: [String] = []
        for child in table.children {
            if let head = child as? Markdown.Table.Head {
                for cell in head.children {
                    if let tableCell = cell as? Markdown.Table.Cell {
                        headerCells.append(collectInlineText(from: tableCell))
                    }
                }
            }
        }

        var rows: [[String]] = []
        for child in table.children {
            if let body = child as? Markdown.Table.Body {
                for row in body.children {
                    if let tableRow = row as? Markdown.Table.Row {
                        var cells: [String] = []
                        for cell in tableRow.children {
                            if let tableCell = cell as? Markdown.Table.Cell {
                                cells.append(collectInlineText(from: tableCell))
                            }
                        }
                        rows.append(cells)
                    }
                }
            }
        }

        let columnCount = headerCells.count
        views.append(AnyView(
            tableView(header: headerCells, rows: rows, columnCount: columnCount)
        ))
    }

    // MARK: - HTML Block

    mutating func visitHTMLBlock(_ html: HTMLBlock) -> Result {
        let raw = html.rawHTML
        views.append(AnyView(
            SwiftUI.Text(raw)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        ))
    }

    // MARK: - Helpers

    /// Build a code block view with optional syntax highlighting.
    private func buildCodeView(code: String, language: String?) -> AnyView {
        let codeContent = CodeHighlighter.highlight(code: code, language: language)

        return AnyView(
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    if let lang = language, !lang.isEmpty {
                        SwiftUI.Text(lang.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.bottom, 2)

                codeContent
            }
            .padding(10)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .textSelection(.enabled)
        )
    }

    /// Collect plain text from inline children.
    private func collectInlineText(from markup: any Markup) -> String {
        var result = ""
        for child in markup.children {
            if let text = child as? MarkdownText {
                result += text.string
            } else if let strong = child as? Strong {
                result += collectInlineText(from: strong)
            } else if let emphasis = child as? Emphasis {
                result += collectInlineText(from: emphasis)
            } else if let inlineCode = child as? InlineCode {
                result += inlineCode.code
            } else if let link = child as? MarkdownLink {
                result += collectInlineText(from: link)
            } else if child is SoftBreak {
                result += " "
            } else if child is LineBreak {
                result += "\n"
            } else if let strikethrough = child as? Strikethrough {
                result += collectInlineText(from: strikethrough)
            } else {
                result += collectInlineText(from: child)
            }
        }
        return result
    }

    /// Build an AttributedString with inline formatting (bold, italic, code, links).
    private func collectAttributedString(from markup: any Markup) -> AttributedString {
        var result = AttributedString()
        for child in markup.children {
            if let text = child as? MarkdownText {
                result.append(AttributedString(text.string))
            } else if let strong = child as? Strong {
                var s = collectAttributedString(from: strong)
                s.font = .body.bold()
                result.append(s)
            } else if let emphasis = child as? Emphasis {
                var e = collectAttributedString(from: emphasis)
                e.font = .body.italic()
                result.append(e)
            } else if let inlineCode = child as? InlineCode {
                var codeAttr = AttributedString(inlineCode.code)
                codeAttr.backgroundColor = Color.primary.opacity(0.06)
                codeAttr.font = .system(.body, design: .monospaced)
                result.append(codeAttr)
            } else if let link = child as? MarkdownLink {
                var linkAttr = AttributedString(collectInlineText(from: link))
                linkAttr.foregroundColor = Color.accentColor
                linkAttr.underlineStyle = .single
                if let destination = link.destination {
                    linkAttr.link = URL(string: destination)
                }
                result.append(linkAttr)
            } else if child is SoftBreak {
                result.append(AttributedString(" "))
            } else if child is LineBreak {
                result.append(AttributedString("\n"))
            } else if let strikethrough = child as? Strikethrough {
                var st = collectAttributedString(from: strikethrough)
                st.strikethroughStyle = .single
                result.append(st)
            } else {
                result.append(collectAttributedString(from: child))
            }
        }
        return result
    }

    /// Build a simple table view.
    private func tableView(header: [String], rows: [[String]], columnCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                ForEach(0..<columnCount, id: \.self) { col in
                    SwiftUI.Text(col < header.count ? header[col] : "")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                }
            }
            .background(Color.primary.opacity(0.06))

            // Data rows
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 0) {
                    ForEach(0..<columnCount, id: \.self) { col in
                        SwiftUI.Text(col < row.count ? row[col] : "")
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(6)
                    }
                }
                Divider()
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
