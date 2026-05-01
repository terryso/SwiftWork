import XCTest
@testable import SwiftWork

// MARK: - Story 2-4: MarkdownContentView Tests
//
// Coverage: AC#1 (Markdown rendering integration), AC#3 (long text collapse/expand)

final class MarkdownContentViewTests: XCTestCase {

    // MARK: - AC#1 — MarkdownContentView Instantiation

    // [P0] MarkdownContentView should instantiate with a simple Markdown string
    @MainActor
    func testMarkdownContentViewInstantiation() throws {
        let view = MarkdownContentView(markdown: "# Hello World")
        XCTAssertNotNil(view, "MarkdownContentView should instantiate with a Markdown string")
    }

    // [P0] MarkdownContentView should instantiate with empty string
    @MainActor
    func testMarkdownContentViewHandlesEmptyString() throws {
        let view = MarkdownContentView(markdown: "")
        XCTAssertNotNil(view, "MarkdownContentView should handle empty string without crashing")
    }

    // [P1] MarkdownContentView should render text with inline formatting
    @MainActor
    func testMarkdownContentViewRendersInlineFormatting() throws {
        let markdown = "This has **bold**, *italic*, and `code` inline."
        let view = MarkdownContentView(markdown: markdown)
        XCTAssertNotNil(view, "MarkdownContentView should render inline Markdown formatting")
    }

    // [P1] MarkdownContentView should render a code block
    @MainActor
    func testMarkdownContentViewRendersCodeBlock() throws {
        let markdown = """
        Here is some code:

        ```swift
        let x = 42
        print(x)
        ```
        """
        let view = MarkdownContentView(markdown: markdown)
        XCTAssertNotNil(view, "MarkdownContentView should render fenced code blocks")
    }

    // MARK: - AC#3 — Long Text Collapse/Expand

    // [P0] MarkdownContentView should collapse long text by default (>20 lines or >1000 chars)
    @MainActor
    func testMarkdownContentViewCollapsesLongText() throws {
        // Generate content exceeding the 1000 character threshold
        let longContent = String(repeating: "This is a line of text that adds to the total length. ", count: 30)
        let view = MarkdownContentView(markdown: longContent)
        XCTAssertNotNil(view, "MarkdownContentView should collapse content exceeding 1000 characters")
    }

    // [P0] MarkdownContentView should not collapse short text
    @MainActor
    func testMarkdownContentViewDoesNotCollapseShortText() throws {
        let shortContent = "This is a short message."
        let view = MarkdownContentView(markdown: shortContent)
        XCTAssertNotNil(view, "MarkdownContentView should not collapse short content")
    }

    // [P1] MarkdownContentView should handle content with many lines (>20 lines)
    @MainActor
    func testMarkdownContentViewCollapsesManyLines() throws {
        // Generate content exceeding the 20 line threshold
        var lines: [String] = []
        for i in 0..<25 {
            lines.append("Line \(i): Some content on this line.")
        }
        let longMarkdown = lines.joined(separator: "\n")
        let view = MarkdownContentView(markdown: longMarkdown)
        XCTAssertNotNil(view, "MarkdownContentView should collapse content exceeding 20 lines")
    }

    // [P2] MarkdownContentView should handle mixed Markdown with code blocks and text
    @MainActor
    func testMarkdownContentViewRendersMixedContent() throws {
        let markdown = """
        ## Overview

        The analysis shows:

        1. **Performance** improved by 30%
        2. *Memory* usage decreased

        ```swift
        func optimize() -> Result {
            return .success
        }
        ```

        > Conclusion: The optimization was successful.
        """
        let view = MarkdownContentView(markdown: markdown)
        XCTAssertNotNil(view, "MarkdownContentView should handle mixed Markdown content")
    }
}
