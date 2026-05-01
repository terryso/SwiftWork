import XCTest
@testable import SwiftWork

// MARK: - Story 2-4: MarkdownRenderer Tests
//
// Coverage: AC#1 (Markdown rendering of headings, lists, bold, italic, inline code, links, tables)

final class MarkdownRendererTests: XCTestCase {

    // MARK: - AC#1 — Markdown Element Rendering

    // [P0] MarkdownRenderer should parse a plain text string and produce a non-empty result
    @MainActor
    func testRenderPlainTextReturnsNonEmptyResult() throws {
        let markdown = "Hello world"
        let result = MarkdownRenderer.render(markdown)
        XCTAssertFalse(result.isEmpty, "MarkdownRenderer.render() should return non-empty views for plain text")
    }

    // [P0] MarkdownRenderer should parse H1-H3 headings and produce heading views
    @MainActor
    func testRenderHeadingsH1ThroughH3() throws {
        let markdown = """
        # Heading 1
        ## Heading 2
        ### Heading 3
        """
        let result = MarkdownRenderer.render(markdown)
        XCTAssertEqual(result.count, 3, "MarkdownRenderer should produce 3 views for 3 headings")
    }

    // [P0] MarkdownRenderer should parse bold and italic text
    @MainActor
    func testRenderBoldAndItalic() throws {
        let markdown = "This is **bold** and this is *italic* text."
        let result = MarkdownRenderer.render(markdown)
        XCTAssertFalse(result.isEmpty, "MarkdownRenderer should handle bold and italic inline formatting")
    }

    // [P0] MarkdownRenderer should parse inline code
    @MainActor
    func testRenderInlineCode() throws {
        let markdown = "Use `let x = 42` to declare a constant."
        let result = MarkdownRenderer.render(markdown)
        XCTAssertFalse(result.isEmpty, "MarkdownRenderer should handle inline code spans")
    }

    // [P0] MarkdownRenderer should parse links
    @MainActor
    func testRenderLinks() throws {
        let markdown = "Visit [Apple](https://apple.com) for more info."
        let result = MarkdownRenderer.render(markdown)
        XCTAssertFalse(result.isEmpty, "MarkdownRenderer should handle links with text and URL")
    }

    // [P1] MarkdownRenderer should parse unordered lists
    @MainActor
    func testRenderUnorderedList() throws {
        let markdown = """
        - First item
        - Second item
        - Third item
        """
        let result = MarkdownRenderer.render(markdown)
        XCTAssertFalse(result.isEmpty, "MarkdownRenderer should handle unordered lists")
    }

    // [P1] MarkdownRenderer should parse ordered lists
    @MainActor
    func testRenderOrderedList() throws {
        let markdown = """
        1. First step
        2. Second step
        3. Third step
        """
        let result = MarkdownRenderer.render(markdown)
        XCTAssertFalse(result.isEmpty, "MarkdownRenderer should handle ordered lists")
    }

    // [P1] MarkdownRenderer should parse tables (GFM)
    @MainActor
    func testRenderTable() throws {
        let markdown = """
        | Column A | Column B |
        |----------|----------|
        | Cell 1   | Cell 2   |
        | Cell 3   | Cell 4   |
        """
        let result = MarkdownRenderer.render(markdown)
        XCTAssertFalse(result.isEmpty, "MarkdownRenderer should handle GFM tables")
    }

    // [P1] MarkdownRenderer should parse block quotes
    @MainActor
    func testRenderBlockQuote() throws {
        let markdown = "> This is a block quote with important information."
        let result = MarkdownRenderer.render(markdown)
        XCTAssertFalse(result.isEmpty, "MarkdownRenderer should handle block quotes")
    }

    // [P2] MarkdownRenderer should parse thematic breaks (horizontal rules)
    @MainActor
    func testRenderThematicBreak() throws {
        let markdown = """
        Section above

        ---

        Section below
        """
        let result = MarkdownRenderer.render(markdown)
        XCTAssertGreaterThanOrEqual(result.count, 3, "MarkdownRenderer should handle thematic breaks")
    }

    // [P0] MarkdownRenderer should delegate code blocks to CodeHighlighter
    @MainActor
    func testRenderCodeBlockDelegatesToHighlighter() throws {
        let markdown = """
        ```swift
        let greeting = "Hello, World!"
        print(greeting)
        ```
        """
        let result = MarkdownRenderer.render(markdown)
        XCTAssertFalse(result.isEmpty, "MarkdownRenderer should handle fenced code blocks and delegate to CodeHighlighter")
    }

    // [P2] MarkdownRenderer should handle empty string input gracefully
    @MainActor
    func testRenderEmptyStringReturnsEmptyResult() throws {
        let result = MarkdownRenderer.render("")
        XCTAssertTrue(result.isEmpty, "MarkdownRenderer.render() should return empty array for empty string")
    }

    // [P2] MarkdownRenderer should handle complex nested Markdown
    @MainActor
    func testRenderComplexNestedMarkdown() throws {
        let markdown = """
        ## Analysis

        The function `processData()` does the following:

        1. **Validates** input parameters
        2. Calls the `transform()` helper
        3. Returns a [Result](https://example.com) enum

        > **Note**: This is a nested block quote with **bold** and `code`.

        - Item with `inline code`
        - Item with [link](https://example.com)
        """
        let result = MarkdownRenderer.render(markdown)
        XCTAssertFalse(result.isEmpty, "MarkdownRenderer should handle complex nested Markdown without crashing")
    }
}
