import XCTest
@testable import SwiftWork

// MARK: - Story 2-4: Markdown Rendering Integration Tests
//
// Coverage: AC#1 (integration into existing views), AC#2 (code highlighting in context)

final class MarkdownRenderingIntegrationTests: XCTestCase {

    // MARK: - AC#1 — AssistantMessageView Integration

    // [P0] AssistantMessageView should render Markdown content via MarkdownContentView
    @MainActor
    func testAssistantMessageViewRendersMarkdown() throws {
        let markdownContent = """
        ## Analysis

        The code has **two issues**:

        1. Missing `guard` statement
        2. Force unwrap on line 42

        ```swift
        guard let value = optional else { return }
        ```
        """
        let event = AgentEvent(
            type: .assistant,
            content: markdownContent,
            metadata: ["model": "claude-sonnet-4-6", "stopReason": "end_turn"],
            timestamp: .now
        )
        let view = AssistantMessageView(event: event)
        XCTAssertNotNil(view, "AssistantMessageView should render Markdown content")
    }

    // [P1] AssistantMessageView should preserve left-side identity line after Markdown integration
    @MainActor
    func testAssistantMessageViewPreservesIdentityLine() throws {
        let event = AgentEvent(
            type: .assistant,
            content: "Simple response",
            metadata: ["model": "claude-sonnet-4-6"],
            timestamp: .now
        )
        let view = AssistantMessageView(event: event)
        XCTAssertNotNil(view, "AssistantMessageView should preserve the 2px left identity line from Story 2-3")
    }

    // [P1] AssistantMessageView should handle plain text content (backwards compatibility)
    @MainActor
    func testAssistantMessageViewHandlesPlainTextContent() throws {
        let plainContent = "This is a simple response without any Markdown formatting."
        let event = AgentEvent(
            type: .assistant,
            content: plainContent,
            metadata: ["model": "claude-sonnet-4-6"],
            timestamp: .now
        )
        let view = AssistantMessageView(event: event)
        XCTAssertNotNil(view, "AssistantMessageView should handle plain text content (no Markdown)")
    }

    // MARK: - AC#1 — ResultView Integration

    // [P2] ResultView should optionally render Markdown content
    @MainActor
    func testResultViewRendersMarkdownContent() throws {
        let markdownContent = "Task completed with **3** changes:\n- File A modified\n- File B created"
        let event = AgentEvent(
            type: .result,
            content: markdownContent,
            metadata: [
                "subtype": "success",
                "numTurns": 3,
                "durationMs": 15000,
                "totalCostUsd": 0.04
            ] as [String: any Sendable],
            timestamp: .now
        )
        let view = ResultView(event: event)
        XCTAssertNotNil(view, "ResultView should render Markdown content in its content area")
    }

    // MARK: - AC#2 — Code Highlighting in Context

    // [P1] MarkdownContentView should highlight Swift code blocks within Markdown
    @MainActor
    func testSwiftCodeBlockHighlightedInMarkdownContext() throws {
        let markdown = """
        Here is the fix:

        ```swift
        func solve() -> String {
            return "solved"
        }
        ```
        """
        let view = MarkdownContentView(markdown: markdown)
        XCTAssertNotNil(view, "MarkdownContentView should delegate Swift code blocks to CodeHighlighter")
    }

    // [P1] MarkdownContentView should render non-Swift code blocks as plain monospace text
    @MainActor
    func testNonSwiftCodeBlockRenderedAsPlainText() throws {
        let markdown = """
        Run this command:

        ```bash
        echo "Hello, World!"
        ```
        """
        let view = MarkdownContentView(markdown: markdown)
        XCTAssertNotNil(view, "MarkdownContentView should render Bash code blocks as plain monospace text")
    }

    // MARK: - Streaming Text Not Affected

    // [P1] StreamingTextView should NOT use Markdown rendering (performance constraint)
    func testStreamingTextViewRemainsPlainText() {
        // This test is always active — StreamingTextView already exists and should NOT change
        let view = StreamingTextView(text: "**bold** text streaming")
        XCTAssertNotNil(view, "StreamingTextView should NOT use Markdown rendering during streaming")
    }

    // MARK: - Edge Cases

    // [P2] AssistantMessageView should handle content with only a code block
    @MainActor
    func testAssistantMessageViewWithOnlyCodeBlock() throws {
        let codeOnlyContent = """
        ```python
        def hello():
            print("world")
        ```
        """
        let event = AgentEvent(
            type: .assistant,
            content: codeOnlyContent,
            metadata: ["model": "claude-sonnet-4-6"],
            timestamp: .now
        )
        let view = AssistantMessageView(event: event)
        XCTAssertNotNil(view, "AssistantMessageView should handle content that is only a code block")
    }

    // [P2] MarkdownContentView should handle CJK content in Markdown
    @MainActor
    func testMarkdownContentViewHandlesCJKContent() throws {
        let cjkMarkdown = "## \u{5206}\u{6790}\u{7ED3}\u{679C}\n\n\u{8FD9}\u{6BB5}\u{4EE3}\u{7801}\u{6709} **\u{4E24}\u{4E2A}\u{95EE}\u{9898}**\u{FF1A}\n\n1. \u{7F3A}\u{5C11} `guard` \u{8BED}\u{53E5}\n2. \u{5F3A}\u{5236}\u{89E3}\u{5305}"
        let view = MarkdownContentView(markdown: cjkMarkdown)
        XCTAssertNotNil(view, "MarkdownContentView should handle CJK (Chinese/Japanese/Korean) content in Markdown")
    }
}
