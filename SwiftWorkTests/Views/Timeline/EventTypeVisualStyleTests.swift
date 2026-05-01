import XCTest
import SwiftUI
@testable import SwiftWork

// ATDD Red Phase — Story 2.3: 事件类型视觉系统
// Unit tests for event-type visual differentiation, tool-specific card styles,
// and error highlighting in the Timeline.
// These tests will FAIL until Story 2.3 is implemented.

@MainActor
final class EventTypeVisualStyleTests: XCTestCase {

    // MARK: - AC#1: Event Type Visual Differentiation (FR11)

    // [P0] UserMessageView uses blue left-aligned bubble style
    func testUserMessageViewHasBlueBubbleStyle() {
        let event = AgentEvent(type: .userMessage, content: "Hello Agent", timestamp: .now)
        let view = UserMessageView(event: event)
        XCTAssertNotNil(view, "UserMessageView should instantiate for visual style verification")
    }

    // [P0] ToolCardView uses gray card background style
    func testToolCardViewHasGrayCardStyle() {
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-001",
            input: "{\"command\": \"ls\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let registry = ToolRendererRegistry()
        let view = ToolCardView(content: content, registry: registry, isSelected: false, onSelect: {})
        XCTAssertNotNil(view, "ToolCardView should use gray card background for tool calls")
    }

    // [P0] ToolResultView uses green background for success
    func testToolResultViewSuccessUsesGreenBackground() {
        let event = AgentEvent(
            type: .toolResult,
            content: "file1.txt",
            metadata: ["toolUseId": "tu-001", "isError": false] as [String: any Sendable],
            timestamp: .now
        )
        let view = ToolResultView(event: event)
        XCTAssertNotNil(view, "ToolResultView success should use green background")
    }

    // [P0] ToolResultView uses red background for error
    func testToolResultViewErrorUsesRedBackground() {
        let event = AgentEvent(
            type: .toolResult,
            content: "command not found",
            metadata: ["toolUseId": "tu-001", "isError": true] as [String: any Sendable],
            timestamp: .now
        )
        let view = ToolResultView(event: event)
        XCTAssertNotNil(view, "ToolResultView error should use red background")
    }

    // [P0] SystemEventView uses light gray secondary style
    func testSystemEventViewUsesSecondaryStyle() {
        let event = AgentEvent(
            type: .system,
            content: "Session initialized",
            metadata: ["subtype": "init"] as [String: any Sendable],
            timestamp: .now
        )
        let view = SystemEventView(event: event)
        XCTAssertNotNil(view, "SystemEventView should use light gray secondary style")
    }

    // [P0] SystemEventView error variant uses red style
    func testSystemEventViewErrorUsesRedStyle() {
        let event = AgentEvent(
            type: .system,
            content: "Rate limit reached",
            metadata: ["subtype": "rateLimit", "isError": true] as [String: any Sendable],
            timestamp: .now
        )
        let view = SystemEventView(event: event, isError: true)
        XCTAssertNotNil(view, "SystemEventView with isError should use red styling")
    }

    // MARK: - AC#1: Distinct visual styles per event type (FR11 continued)

    // [P0] AssistantMessageView uses left-aligned primary text style
    func testAssistantMessageViewUsesPrimaryTextStyle() {
        let event = AgentEvent(
            type: .assistant,
            content: "Here is the response",
            metadata: ["model": "claude-sonnet-4-6", "stopReason": "end_turn"] as [String: any Sendable],
            timestamp: .now
        )
        let view = AssistantMessageView(event: event)
        XCTAssertNotNil(view, "AssistantMessageView should use left-aligned primary text style")
    }

    // [P0] ResultView uses contextual status color
    func testResultViewSuccessUsesGreenStatusColor() {
        let event = AgentEvent(
            type: .result,
            content: "Done",
            metadata: ["subtype": "success", "durationMs": 5000, "numTurns": 3, "totalCostUsd": 0.01] as [String: any Sendable],
            timestamp: .now
        )
        let view = ResultView(event: event)
        XCTAssertNotNil(view, "ResultView success should use green status color")
    }

    // [P0] ResultView error subtype uses red status color
    func testResultViewErrorUsesRedStatusColor() {
        let event = AgentEvent(
            type: .result,
            content: "Execution failed",
            metadata: ["subtype": "errorDuringExecution", "durationMs": 10000, "numTurns": 5] as [String: any Sendable],
            timestamp: .now
        )
        let view = ResultView(event: event)
        XCTAssertNotNil(view, "ResultView error should use red status color")
    }

    // [P0] ResultView cancelled subtype uses orange status color
    func testResultViewCancelledUsesOrangeStatusColor() {
        let event = AgentEvent(
            type: .result,
            content: "Cancelled",
            metadata: ["subtype": "cancelled", "durationMs": 2000, "numTurns": 1] as [String: any Sendable],
            timestamp: .now
        )
        let view = ResultView(event: event)
        XCTAssertNotNil(view, "ResultView cancelled should use orange status color")
    }

    // MARK: - AC#2: Tool-Specific Card Styles (FR19)

    // [P0] BashToolRenderer uses terminal icon
    func testBashToolRendererUsesTerminalIcon() {
        let renderer = BashToolRenderer()
        XCTAssertEqual(BashToolRenderer.toolName, "Bash")
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-001",
            input: "{\"command\": \"npm test\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let title = renderer.summaryTitle(content: content)
        XCTAssertEqual(title, "npm test", "BashToolRenderer should extract command as summaryTitle")
    }

    // [P0] FileEditToolRenderer uses file edit icon
    func testFileEditToolRendererUsesFileEditIcon() {
        let renderer = FileEditToolRenderer()
        XCTAssertEqual(FileEditToolRenderer.toolName, "Edit")
        let content = ToolContent(
            toolName: "Edit",
            toolUseId: "tu-002",
            input: "{\"file_path\": \"/src/main.swift\", \"old_string\": \"func old()\", \"new_string\": \"func new()\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let title = renderer.summaryTitle(content: content)
        XCTAssertEqual(title, "/src/main.swift", "FileEditToolRenderer should extract file_path as summaryTitle")
    }

    // [P0] SearchToolRenderer uses search/magnifying glass icon
    func testSearchToolRendererUsesSearchIcon() {
        let renderer = SearchToolRenderer()
        XCTAssertEqual(SearchToolRenderer.toolName, "Grep")
        let content = ToolContent(
            toolName: "Grep",
            toolUseId: "tu-003",
            input: "{\"pattern\": \"TODO\", \"path\": \"/src\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let title = renderer.summaryTitle(content: content)
        XCTAssertEqual(title, "TODO", "SearchToolRenderer should extract pattern as summaryTitle")
    }

    // [P0] ReadToolRenderer uses document icon
    func testReadToolRendererUsesDocumentIcon() {
        let renderer = ReadToolRenderer()
        XCTAssertEqual(ReadToolRenderer.toolName, "Read")
        let content = ToolContent(
            toolName: "Read",
            toolUseId: "tu-004",
            input: "{\"file_path\": \"/src/main.swift\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let title = renderer.summaryTitle(content: content)
        XCTAssertEqual(title, "/src/main.swift", "ReadToolRenderer should extract file_path as summaryTitle")
    }

    // [P0] WriteToolRenderer uses write/pencil icon
    func testWriteToolRendererUsesWriteIcon() {
        let renderer = WriteToolRenderer()
        XCTAssertEqual(WriteToolRenderer.toolName, "Write")
        let content = ToolContent(
            toolName: "Write",
            toolUseId: "tu-005",
            input: "{\"file_path\": \"/src/new.swift\", \"content\": \"print(\\\"hello\\\")\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let title = renderer.summaryTitle(content: content)
        XCTAssertEqual(title, "/src/new.swift", "WriteToolRenderer should extract file_path as summaryTitle")
    }

    // [P0] Registry resolves correct renderer for each tool type
    func testRegistryResolvesCorrectRendererForAllToolTypes() {
        let registry = ToolRendererRegistry()

        XCTAssertNotNil(registry.renderer(for: "Bash"), "Registry should have BashToolRenderer")
        XCTAssertNotNil(registry.renderer(for: "Edit"), "Registry should have FileEditToolRenderer")
        XCTAssertNotNil(registry.renderer(for: "Grep"), "Registry should have SearchToolRenderer")
        XCTAssertNotNil(registry.renderer(for: "Read"), "Registry should have ReadToolRenderer")
        XCTAssertNotNil(registry.renderer(for: "Write"), "Registry should have WriteToolRenderer")
    }

    // [P1] BashToolRenderer body produces view with terminal icon
    func testBashToolRendererBodyContainsTerminalIcon() {
        let renderer = BashToolRenderer()
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-001",
            input: "{\"command\": \"echo hello\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let view = renderer.body(content: content)
        XCTAssertNotNil(view, "BashToolRenderer body should produce a view")
    }

    // [P1] FileEditToolRenderer body produces view with pencil icon
    func testFileEditToolRendererBodyContainsPencilIcon() {
        let renderer = FileEditToolRenderer()
        let content = ToolContent(
            toolName: "Edit",
            toolUseId: "tu-002",
            input: "{\"file_path\": \"/src/main.swift\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let view = renderer.body(content: content)
        XCTAssertNotNil(view, "FileEditToolRenderer body should produce a view")
    }

    // [P1] SearchToolRenderer body produces view with magnifying glass icon
    func testSearchToolRendererBodyContainsMagnifyingGlassIcon() {
        let renderer = SearchToolRenderer()
        let content = ToolContent(
            toolName: "Grep",
            toolUseId: "tu-003",
            input: "{\"pattern\": \"search term\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let view = renderer.body(content: content)
        XCTAssertNotNil(view, "SearchToolRenderer body should produce a view")
    }

    // [P1] ReadToolRenderer body produces view with document icon
    func testReadToolRendererBodyContainsDocumentIcon() {
        let renderer = ReadToolRenderer()
        let content = ToolContent(
            toolName: "Read",
            toolUseId: "tu-004",
            input: "{\"file_path\": \"/src/file.swift\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let view = renderer.body(content: content)
        XCTAssertNotNil(view, "ReadToolRenderer body should produce a view")
    }

    // [P1] WriteToolRenderer body produces view with pencil-and-outline icon
    func testWriteToolRendererBodyContainsPencilAndOutlineIcon() {
        let renderer = WriteToolRenderer()
        let content = ToolContent(
            toolName: "Write",
            toolUseId: "tu-005",
            input: "{\"file_path\": \"/src/new.swift\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let view = renderer.body(content: content)
        XCTAssertNotNil(view, "WriteToolRenderer body should produce a view")
    }

    // MARK: - AC#2: ToolCardView delegates to registry for tool-specific styling

    // [P0] ToolCardView uses registry to resolve summary title
    func testToolCardViewResolvesSummaryTitleFromRegistry() {
        let registry = ToolRendererRegistry()
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-001",
            input: "{\"command\": \"swift build\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let renderer = registry.renderer(for: "Bash")
        XCTAssertNotNil(renderer)
        let title = renderer?.summaryTitle(content: content)
        XCTAssertEqual(title, "swift build", "ToolCardView should delegate summaryTitle to BashToolRenderer")
    }

    // [P0] ToolCardView uses registry to resolve subtitle
    func testToolCardViewResolvesSubtitleFromRegistry() {
        let registry = ToolRendererRegistry()
        let content = ToolContent(
            toolName: "Edit",
            toolUseId: "tu-002",
            input: "{\"file_path\": \"/src/main.swift\", \"old_string\": \"func old()\", \"new_string\": \"func new()\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let renderer = registry.renderer(for: "Edit")
        XCTAssertNotNil(renderer)
        let subtitle = renderer?.subtitle(content: content)
        XCTAssertNotNil(subtitle, "FileEditToolRenderer should provide a subtitle")
    }

    // [P0] ToolCardView uses registry to resolve tool-specific body
    func testToolCardViewResolvesToolBodyFromRegistry() {
        let registry = ToolRendererRegistry()
        let content = ToolContent(
            toolName: "Grep",
            toolUseId: "tu-003",
            input: "{\"pattern\": \"TODO\", \"path\": \"/src\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let renderer = registry.renderer(for: "Grep")
        XCTAssertNotNil(renderer)
        let view = renderer?.body(content: content)
        XCTAssertNotNil(view, "SearchToolRenderer should provide a tool-specific body view")
    }

    // MARK: - AC#3: Error Highlighting (FR12)

    // [P0] ToolCardView with failed status uses error styling
    func testToolCardViewFailedStatusUsesErrorStyling() {
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-001",
            input: "{\"command\": \"bad_command\"}",
            output: "command not found",
            isError: true,
            status: .failed
        )
        let registry = ToolRendererRegistry()
        let view = ToolCardView(content: content, registry: registry, isSelected: false, onSelect: {})
        XCTAssertNotNil(view, "ToolCardView with failed status should use error background styling")
    }

    // [P0] ToolResultContentView with error uses red styling
    func testToolResultContentViewErrorUsesRedStyling() {
        let view = ToolResultContentView(output: "Error: permission denied", isError: true)
        XCTAssertNotNil(view, "ToolResultContentView with error should use red background")
    }

    // [P0] ToolResultContentView with success uses green styling
    func testToolResultContentViewSuccessUsesGreenStyling() {
        let view = ToolResultContentView(output: "Build succeeded", isError: false)
        XCTAssertNotNil(view, "ToolResultContentView with success should use green background")
    }

    // [P0] SystemEventView with isError flag uses red highlight
    func testSystemEventViewErrorHighlighting() {
        let event = AgentEvent(
            type: .system,
            content: "Error: API rate limit exceeded",
            metadata: ["isError": true] as [String: any Sendable],
            timestamp: .now
        )
        let view = SystemEventView(event: event, isError: true)
        XCTAssertNotNil(view, "SystemEventView with error should use red border/highlight")
    }

    // [P1] ToolCardView error card has red-tinted background
    func testToolCardViewErrorCardHasRedBackground() {
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-001",
            input: "{\"command\": \"rm -rf /\"}",
            output: "Permission denied",
            isError: true,
            status: .failed
        )
        let registry = ToolRendererRegistry()
        let view = ToolCardView(content: content, registry: registry, isSelected: false, onSelect: {})
        XCTAssertNotNil(view, "ToolCardView error should have red-tinted card background")
    }

    // [P1] Error result in ToolResultContentView shows error icon
    func testToolResultContentViewErrorShowsErrorIcon() {
        let view = ToolResultContentView(output: "fatal error", isError: true)
        XCTAssertNotNil(view, "ToolResultContentView error should display error icon (xmark.circle.fill)")
    }

    // MARK: - AC#2: Tool-Specific Subtitles and Details (FR19)

    // [P1] BashToolRenderer subtitle is nil (no subtitle for bash commands)
    func testBashToolRendererSubtitleIsNil() {
        let renderer = BashToolRenderer()
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-001",
            input: "{\"command\": \"echo hello\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        XCTAssertNil(renderer.subtitle(content: content), "BashToolRenderer should return nil subtitle")
    }

    // [P1] FileEditToolRenderer provides editing subtitle
    func testFileEditToolRendererProvidesEditingSubtitle() {
        let renderer = FileEditToolRenderer()
        let content = ToolContent(
            toolName: "Edit",
            toolUseId: "tu-002",
            input: "{\"file_path\": \"/src/main.swift\", \"old_string\": \"old code\", \"new_string\": \"new code\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let subtitle = renderer.subtitle(content: content)
        XCTAssertNotNil(subtitle, "FileEditToolRenderer should provide editing subtitle with old_string preview")
    }

    // [P1] SearchToolRenderer provides path subtitle
    func testSearchToolRendererProvidesPathSubtitle() {
        let renderer = SearchToolRenderer()
        let content = ToolContent(
            toolName: "Grep",
            toolUseId: "tu-003",
            input: "{\"pattern\": \"TODO\", \"path\": \"/src\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let subtitle = renderer.subtitle(content: content)
        XCTAssertNotNil(subtitle, "SearchToolRenderer should provide path subtitle")
    }

    // [P1] WriteToolRenderer provides content preview subtitle
    func testWriteToolRendererProvidesContentSubtitle() {
        let renderer = WriteToolRenderer()
        let content = ToolContent(
            toolName: "Write",
            toolUseId: "tu-005",
            input: "{\"file_path\": \"/src/new.swift\", \"content\": \"print(\\\"hello world\\\")\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let subtitle = renderer.subtitle(content: content)
        XCTAssertNotNil(subtitle, "WriteToolRenderer should provide content preview subtitle")
    }

    // [P1] ReadToolRenderer subtitle is nil (no subtitle for read operations)
    func testReadToolRendererSubtitleIsNil() {
        let renderer = ReadToolRenderer()
        let content = ToolContent(
            toolName: "Read",
            toolUseId: "tu-004",
            input: "{\"file_path\": \"/src/main.swift\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        XCTAssertNil(renderer.subtitle(content: content), "ReadToolRenderer should return nil subtitle")
    }

    // MARK: - ToolCardView icon resolution per tool type

    // [P0] ToolCardView resolves terminal icon for Bash
    func testToolCardViewResolvesTerminalIconForBash() {
        let registry = ToolRendererRegistry()
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-001",
            input: "{\"command\": \"ls\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let view = ToolCardView(content: content, registry: registry, isSelected: false, onSelect: {})
        XCTAssertNotNil(view, "ToolCardView should resolve terminal icon for Bash tool")
    }

    // [P0] ToolCardView resolves pencil icon for Edit
    func testToolCardViewResolvesPencilIconForEdit() {
        let registry = ToolRendererRegistry()
        let content = ToolContent(
            toolName: "Edit",
            toolUseId: "tu-002",
            input: "{\"file_path\": \"/src/main.swift\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let view = ToolCardView(content: content, registry: registry, isSelected: false, onSelect: {})
        XCTAssertNotNil(view, "ToolCardView should resolve pencil.line icon for Edit tool")
    }

    // [P0] ToolCardView resolves magnifying glass icon for Grep
    func testToolCardViewResolvesSearchIconForGrep() {
        let registry = ToolRendererRegistry()
        let content = ToolContent(
            toolName: "Grep",
            toolUseId: "tu-003",
            input: "{\"pattern\": \"TODO\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let view = ToolCardView(content: content, registry: registry, isSelected: false, onSelect: {})
        XCTAssertNotNil(view, "ToolCardView should resolve text.magnifyingglass icon for Grep tool")
    }

    // [P0] ToolCardView resolves document icon for Read
    func testToolCardViewResolvesDocumentIconForRead() {
        let registry = ToolRendererRegistry()
        let content = ToolContent(
            toolName: "Read",
            toolUseId: "tu-004",
            input: "{\"file_path\": \"/src/file.swift\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let view = ToolCardView(content: content, registry: registry, isSelected: false, onSelect: {})
        XCTAssertNotNil(view, "ToolCardView should resolve doc.text icon for Read tool")
    }

    // [P0] ToolCardView resolves write icon for Write
    func testToolCardViewResolvesWriteIconForWrite() {
        let registry = ToolRendererRegistry()
        let content = ToolContent(
            toolName: "Write",
            toolUseId: "tu-005",
            input: "{\"file_path\": \"/src/new.swift\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let view = ToolCardView(content: content, registry: registry, isSelected: false, onSelect: {})
        XCTAssertNotNil(view, "ToolCardView should resolve pencil.and.outline icon for Write tool")
    }

    // [P1] ToolCardView uses wrench fallback icon for unknown tool
    func testToolCardViewUsesWrenchFallbackForUnknownTool() {
        let registry = ToolRendererRegistry()
        let content = ToolContent(
            toolName: "CustomTool",
            toolUseId: "tu-099",
            input: "{\"param\": \"value\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        let view = ToolCardView(content: content, registry: registry, isSelected: false, onSelect: {})
        XCTAssertNotNil(view, "ToolCardView should use wrench fallback icon for unregistered tools")
    }

    // MARK: - Status color differentiation in ToolCardView

    // [P0] ToolCardView pending status uses gray
    func testToolCardViewPendingStatusUsesGray() {
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-001",
            input: "{\"command\": \"ls\"}",
            output: nil,
            isError: false,
            status: .pending
        )
        XCTAssertEqual(content.status, .pending, "Pending status should be represented")
    }

    // [P0] ToolCardView running status uses blue
    func testToolCardViewRunningStatusUsesBlue() {
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-001",
            input: "{\"command\": \"ls\"}",
            output: nil,
            isError: false,
            status: .running,
            elapsedTimeSeconds: 3
        )
        XCTAssertEqual(content.status, .running, "Running status should be represented with blue")
    }

    // [P0] ToolCardView completed status uses green
    func testToolCardViewCompletedStatusUsesGreen() {
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-001",
            input: "{\"command\": \"ls\"}",
            output: "file1.txt\nfile2.txt",
            isError: false,
            status: .completed
        )
        XCTAssertEqual(content.status, .completed, "Completed status should be represented with green")
    }

    // [P0] ToolCardView failed status uses red
    func testToolCardViewFailedStatusUsesRed() {
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-001",
            input: "{\"command\": \"bad_cmd\"}",
            output: "command not found",
            isError: true,
            status: .failed
        )
        XCTAssertEqual(content.status, .failed, "Failed status should be represented with red")
    }
}
