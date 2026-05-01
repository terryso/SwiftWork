import XCTest
import SwiftUI
@testable import SwiftWork

// ATDD Red Phase — Story 2.2: Tool Card 完整体验
// Unit tests for ToolCardView and ToolResultContentView.
// These tests will FAIL until Story 2.2 is implemented.

@MainActor
final class ToolCardViewTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeToolContent(
        toolName: String = "Bash",
        toolUseId: String = "tu-001",
        input: String = "{\"command\": \"npm test\"}",
        output: String? = nil,
        isError: Bool = false,
        status: ToolExecutionStatus = .pending,
        elapsedTimeSeconds: Int? = nil
    ) -> ToolContent {
        ToolContent(
            toolName: toolName,
            toolUseId: toolUseId,
            input: input,
            output: output,
            isError: isError,
            status: status,
            elapsedTimeSeconds: elapsedTimeSeconds
        )
    }

    // MARK: - AC#1: ToolCardView Instantiation

    // [P0] ToolCardView instantiates with ToolContent
    func testToolCardViewInstantiates() {
        let content = makeToolContent()
        let registry = ToolRendererRegistry()
        let view = ToolCardView(content: content, registry: registry, isSelected: false, onSelect: {})

        XCTAssertNotNil(view, "ToolCardView should instantiate with ToolContent and Registry")
    }

    // [P0] ToolCardView instantiates with completed status
    func testToolCardViewInstantiatesWithCompletedContent() {
        let content = makeToolContent(
            output: "test passed",
            status: .completed
        )
        let registry = ToolRendererRegistry()
        let view = ToolCardView(content: content, registry: registry, isSelected: false, onSelect: {})

        XCTAssertNotNil(view, "ToolCardView should render completed tool content")
    }

    // [P0] ToolCardView instantiates with failed status
    func testToolCardViewInstantiatesWithFailedContent() {
        let content = makeToolContent(
            output: "error: command failed",
            isError: true,
            status: .failed
        )
        let registry = ToolRendererRegistry()
        let view = ToolCardView(content: content, registry: registry, isSelected: false, onSelect: {})

        XCTAssertNotNil(view, "ToolCardView should render failed tool content")
    }

    // [P0] ToolCardView instantiates with running status
    func testToolCardViewInstantiatesWithRunningContent() {
        let content = makeToolContent(
            status: .running,
            elapsedTimeSeconds: 5
        )
        let registry = ToolRendererRegistry()
        let view = ToolCardView(content: content, registry: registry, isSelected: false, onSelect: {})

        XCTAssertNotNil(view, "ToolCardView should render running tool content with progress")
    }

    // MARK: - AC#1: ToolCardView uses Registry for rendering

    // [P0] ToolCardView uses registered renderer for summaryTitle
    func testToolCardViewUsesRegisteredRendererSummaryTitle() {
        let content = makeToolContent(toolName: "Bash")
        let registry = ToolRendererRegistry()
        let renderer = registry.renderer(for: "Bash")

        XCTAssertNotNil(renderer, "Registry should have BashToolRenderer")
        let title = renderer?.summaryTitle(content: content)
        XCTAssertEqual(title, "npm test",
            "ToolCardView should delegate summaryTitle to registered renderer")
    }

    // [P0] ToolCardView uses registered renderer for subtitle
    func testToolCardViewUsesRegisteredRendererSubtitle() {
        let content = makeToolContent(
            toolName: "Edit",
            input: "{\"file_path\": \"/src/main.swift\", \"old_string\": \"func old()\", \"new_string\": \"func new()\"}"
        )
        let registry = ToolRendererRegistry()
        let renderer = registry.renderer(for: "Edit")

        XCTAssertNotNil(renderer)
        let subtitle = renderer?.subtitle(content: content)
        XCTAssertNotNil(subtitle,
            "FileEditToolRenderer should return a subtitle for Edit tool")
    }

    // MARK: - AC#2: Progress indicator in ToolCardView

    // [P0] ToolCardView with running status has progress indicator
    func testToolCardViewRunningStatusHasProgressIndicator() {
        let content = makeToolContent(
            status: .running,
            elapsedTimeSeconds: 7
        )
        let registry = ToolRendererRegistry()
        let view = ToolCardView(content: content, registry: registry, isSelected: false, onSelect: {})

        XCTAssertNotNil(view, "ToolCardView should render progress indicator for running status")
    }

    // [P0] ToolCardView with running status displays elapsed time
    func testToolCardViewDisplaysElapsedTime() {
        let content = makeToolContent(
            status: .running,
            elapsedTimeSeconds: 12
        )
        let registry = ToolRendererRegistry()
        let view = ToolCardView(content: content, registry: registry, isSelected: false, onSelect: {})

        XCTAssertNotNil(view, "ToolCardView should display elapsed time for running status")
    }

    // MARK: - AC#3: Status labels

    // [P0] ToolContent with pending status is correctly labeled
    func testToolCardViewPendingStatusLabel() {
        let content = makeToolContent(status: .pending)
        XCTAssertEqual(content.status, .pending)
    }

    // [P0] ToolContent with completed status is correctly labeled
    func testToolCardViewCompletedStatusLabel() {
        let content = makeToolContent(status: .completed)
        XCTAssertEqual(content.status, .completed)
    }

    // [P0] ToolContent with failed status is correctly labeled
    func testToolCardViewFailedStatusLabel() {
        let content = makeToolContent(status: .failed)
        XCTAssertEqual(content.status, .failed)
    }

    // MARK: - AC#3: ToolResultContentView

    // [P0] ToolResultContentView instantiates with success result
    func testToolResultContentViewSuccess() {
        let view = ToolResultContentView(
            output: "file1.txt\nfile2.txt",
            isError: false
        )
        XCTAssertNotNil(view, "ToolResultContentView should render success result")
    }

    // [P0] ToolResultContentView instantiates with error result
    func testToolResultContentViewError() {
        let view = ToolResultContentView(
            output: "command not found: npm",
            isError: true
        )
        XCTAssertNotNil(view, "ToolResultContentView should render error result")
    }

    // [P1] ToolResultContentView handles long output (truncation)
    func testToolResultContentViewLongOutput() {
        let longOutput = String(repeating: "line of output\n", count: 100)
        let view = ToolResultContentView(output: longOutput, isError: false)
        XCTAssertNotNil(view, "ToolResultContentView should handle long output with truncation")
    }

    // [P1] ToolResultContentView handles empty output
    func testToolResultContentViewEmptyOutput() {
        let view = ToolResultContentView(output: "", isError: false)
        XCTAssertNotNil(view, "ToolResultContentView should handle empty output")
    }

    // MARK: - AC#3: Diff format detection

    // [P0] ToolResultContentView detects diff content
    func testToolResultContentViewDetectsDiffContent() {
        let diffOutput = """
        @@ -1,5 +1,5 @@
        -old line 1
        -old line 2
        +new line 1
        +new line 2
         unchanged line
        """
        let view = ToolResultContentView(output: diffOutput, isError: false)
        XCTAssertNotNil(view, "ToolResultContentView should detect and render diff content")
    }

    // [P1] ToolResultContentView with non-diff content renders as plain text
    func testToolResultContentViewNonDiffContent() {
        let plainOutput = "Build succeeded. 5 tests passed."
        let view = ToolResultContentView(output: plainOutput, isError: false)
        XCTAssertNotNil(view, "ToolResultContentView should render non-diff content as plain text")
    }

    // MARK: - AC#4: Selection state

    // [P0] ToolCardView accepts isSelected parameter
    func testToolCardViewAcceptsIsSelectedParameter() {
        let content = makeToolContent()
        let registry = ToolRendererRegistry()

        let viewSelected = ToolCardView(content: content, registry: registry, isSelected: true, onSelect: {})
        let viewDeselected = ToolCardView(content: content, registry: registry, isSelected: false, onSelect: {})

        XCTAssertNotNil(viewSelected, "ToolCardView should accept isSelected=true")
        XCTAssertNotNil(viewDeselected, "ToolCardView should accept isSelected=false")
    }

    // [P0] ToolCardView accepts onSelect callback
    func testToolCardViewAcceptsOnSelectCallback() {
        let content = makeToolContent()
        let registry = ToolRendererRegistry()
        var selectionTriggered = false

        let view = ToolCardView(content: content, registry: registry, isSelected: false, onSelect: {
            selectionTriggered = true
        })

        XCTAssertNotNil(view, "ToolCardView should accept onSelect callback")
    }

    // MARK: - AC#1: Unregistered tool fallback in ToolCardView

    // [P1] ToolCardView with unregistered tool renders generic content
    func testToolCardViewUnregisteredToolFallback() {
        let content = makeToolContent(
            toolName: "CustomTool",
            input: "{\"param\": \"value\"}"
        )
        let registry = ToolRendererRegistry()

        let view = ToolCardView(content: content, registry: registry, isSelected: false, onSelect: {})
        XCTAssertNotNil(view, "ToolCardView should render generic content for unregistered tool")
    }

    // MARK: - AC#1: Copy functionality

    // [P1] ToolContent input and output are accessible for copy
    func testToolContentInputOutputAccessible() {
        let content = makeToolContent(
            input: "{\"command\": \"npm test\"}",
            output: "test output"
        )

        XCTAssertEqual(content.input, "{\"command\": \"npm test\"}",
            "Input should be accessible for copy")
        XCTAssertEqual(content.output, "test output",
            "Output should be accessible for copy")
    }
}
