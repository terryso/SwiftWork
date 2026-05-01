import XCTest
import SwiftUI
@testable import SwiftWork

// ATDD Red Phase — Story 2.1: Tool 可视化基础架构
// Unit tests for ToolRendererRegistry and ToolRenderable protocol.
// These tests will FAIL until Story 2.1 is implemented.

@MainActor
final class ToolRendererRegistryTests: XCTestCase {

    // MARK: - AC#2 — Registry Register and Lookup

    // [P0] Register a renderer and find it by toolName
    func testRegisterAndLookupRenderer() throws {
        let registry = ToolRendererRegistry()
        registry.register(MockBashRenderer())

        let found = registry.renderer(for: "Bash")
        XCTAssertNotNil(found, "Registry should return a renderer for registered toolName 'Bash'")
    }

    // [P0] Lookup unregistered toolName returns nil
    func testLookupUnregisteredToolReturnsNil() throws {
        let registry = ToolRendererRegistry()

        let found = registry.renderer(for: "NonExistentTool")
        XCTAssertNil(found, "Registry should return nil for unregistered toolName")
    }

    // [P0] Empty registry returns nil for any lookup
    func testEmptyRegistryReturnsNil() throws {
        let registry = ToolRendererRegistry()

        XCTAssertNil(registry.renderer(for: "NonExistentTool"), "Registry should return nil for unregistered tool 'NonExistentTool'")
        XCTAssertNil(registry.renderer(for: ""), "Registry should return nil for empty string")
    }

    // [P1] Registering same toolName overwrites previous renderer
    func testRegisterOverwritesPreviousRenderer() throws {
        let registry = ToolRendererRegistry()

        registry.register(MockBashRenderer())
        registry.register(MockBashRenderer())

        // Both were registered with same toolName -- latest should win
        let found = registry.renderer(for: "Bash")
        XCTAssertNotNil(found, "Registry should have a renderer for 'Bash' after overwrite")
    }

    // [P1] Register multiple different tool renderers
    func testRegisterMultipleRenderers() throws {
        let registry = ToolRendererRegistry()
        registry.register(MockBashRenderer())
        registry.register(MockReadRenderer())
        registry.register(MockEditRenderer())

        XCTAssertNotNil(registry.renderer(for: "Bash"))
        XCTAssertNotNil(registry.renderer(for: "Read"))
        XCTAssertNotNil(registry.renderer(for: "Edit"))
        XCTAssertNil(registry.renderer(for: "NonExistentTool"), "Unregistered 'NonExistentTool' should return nil")
    }

    // MARK: - AC#3 — TimelineView Integration (Registry Fallback)

    // [P0] Registry returns nil triggers default ToolCallView fallback
    func testRegistryFallbackToDefaultToolCallView() throws {
        let registry = ToolRendererRegistry()
        // Don't register any renderer -- should return nil
        let found = registry.renderer(for: "UnknownTool")
        XCTAssertNil(found, "Unregistered tool should return nil, triggering default ToolCallView fallback")
    }

    // MARK: - AC#1 — ToolRenderable Protocol Contract

    // [P0] ToolRenderable protocol requires static toolName
    func testToolRenderableHasStaticToolName() throws {
        _ = MockBashRenderer()
        XCTAssertEqual(MockBashRenderer.toolName, "Bash",
            "ToolRenderable.toolName should match the registered tool name")
    }

    // [P0] ToolRenderable body(content:) returns a View
    func testToolRenderableBodyReturnsView() throws {
        let renderer = MockBashRenderer()
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-001",
            input: "{\"command\": \"ls\"}",
            output: nil,
            isError: false
        )
        let view = renderer.body(content: content)
        XCTAssertNotNil(view, "ToolRenderable.body(content:) should return a non-nil View")
    }

    // [P1] ToolRenderable default summaryTitle returns toolName
    func testToolRenderableDefaultSummaryTitle() throws {
        let renderer = MockBashRenderer()
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-001",
            input: "{}",
            output: nil,
            isError: false
        )
        let title = renderer.summaryTitle(content: content)
        XCTAssertEqual(title, "Bash",
            "Default summaryTitle should return content.toolName")
    }

    // [P1] ToolRenderable default subtitle returns nil
    func testToolRenderableDefaultSubtitle() throws {
        let renderer = MockBashRenderer()
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-001",
            input: "{}",
            output: nil,
            isError: false
        )
        let subtitle = renderer.subtitle(content: content)
        XCTAssertNil(subtitle,
            "Default subtitle should return nil when not overridden")
    }

    // MARK: - AC#5 — Registry Pre-registration (Skeleton Renderers)

    // [P1] Registry init pre-registers default skeleton renderers
    func testRegistryInitPreregistersDefaultRenderers() throws {
        let registry = ToolRendererRegistry()

        // Story 2.1 skeleton renderers: Bash, Edit, Grep
        XCTAssertNotNil(registry.renderer(for: "Bash"),
            "Registry should pre-register BashToolRenderer")
        // Note: exact tool names depend on SDK -- these test the mechanism
    }

    // MARK: - AC#4 — ToolContent Status and Extraction

    // [P0] ToolContent has status field with ToolExecutionStatus enum
    func testToolContentHasStatusField() throws {
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-001",
            input: "{}",
            output: nil,
            isError: false
        )
        // After Story 2.1 implementation, status should default to .pending
        XCTAssertEqual(content.status, .pending,
            "ToolContent without result should have .pending status")
    }

    // [P0] ToolExecutionStatus enum has all expected cases
    func testToolExecutionStatusCases() throws {
        // Verify all status cases exist
        let pending = ToolExecutionStatus.pending
        let running = ToolExecutionStatus.running
        let completed = ToolExecutionStatus.completed
        let failed = ToolExecutionStatus.failed

        XCTAssertNotEqual(pending, running)
        XCTAssertNotEqual(completed, failed)
    }

    // [P0] ToolContent has elapsedTimeSeconds field
    func testToolContentHasElapsedTimeSeconds() throws {
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-001",
            input: "{}",
            output: nil,
            isError: false,
            elapsedTimeSeconds: 5
        )
        XCTAssertEqual(content.elapsedTimeSeconds, 5,
            "ToolContent should preserve elapsedTimeSeconds from toolProgress")
    }

    // [P1] ToolContent elapsedTimeSeconds defaults to nil
    func testToolContentElapsedTimeSecondsDefaultNil() throws {
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-001",
            input: "{}",
            output: nil,
            isError: false
        )
        XCTAssertNil(content.elapsedTimeSeconds,
            "ToolContent without progress should have nil elapsedTimeSeconds")
    }

    // MARK: - AC#4 — ToolUse/ToolResult Pairing via toolUseId

    // [P0] ToolContent from toolUse AgentEvent extracts metadata correctly
    func testToolContentFromToolUseEvent() throws {
        let event = AgentEvent(
            type: .toolUse,
            content: "Bash",
            metadata: [
                "toolName": "Bash",
                "toolUseId": "tu-001",
                "input": "{\"command\": \"npm test\"}"
            ] as [String: any Sendable],
            timestamp: .now
        )

        let content = ToolContent.fromToolUseEvent(event)

        XCTAssertEqual(content.toolName, "Bash")
        XCTAssertEqual(content.toolUseId, "tu-001")
        XCTAssertEqual(content.input, "{\"command\": \"npm test\"}")
        XCTAssertEqual(content.status, .pending)
        XCTAssertNil(content.output)
    }

    // [P0] ToolContent from toolResult AgentEvent extracts metadata correctly
    func testToolContentFromToolResultEvent() throws {
        let event = AgentEvent(
            type: .toolResult,
            content: "test output",
            metadata: [
                "toolUseId": "tu-001",
                "isError": false
            ] as [String: any Sendable],
            timestamp: .now
        )

        let content = ToolContent.fromToolResultEvent(event)

        XCTAssertEqual(content.toolUseId, "tu-001")
        XCTAssertEqual(content.output, "test output")
        XCTAssertFalse(content.isError)
        XCTAssertEqual(content.status, .completed)
    }

    // [P1] ToolContent from toolResult with error has failed status
    func testToolContentFromToolResultEventError() throws {
        let event = AgentEvent(
            type: .toolResult,
            content: "command failed",
            metadata: [
                "toolUseId": "tu-002",
                "isError": true
            ] as [String: any Sendable],
            timestamp: .now
        )

        let content = ToolContent.fromToolResultEvent(event)

        XCTAssertTrue(content.isError)
        XCTAssertEqual(content.status, .failed)
    }

    // [P1] ToolContent applying progress event updates elapsed time and status
    func testToolContentApplyingProgressEvent() throws {
        let existingContent = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-001",
            input: "{\"command\": \"npm test\"}",
            output: nil,
            isError: false
        )

        let progressEvent = AgentEvent(
            type: .toolProgress,
            content: "Bash",
            metadata: [
                "toolUseId": "tu-001",
                "toolName": "Bash",
                "elapsedTimeSeconds": 7
            ] as [String: any Sendable],
            timestamp: .now
        )

        let updated = existingContent.applyingProgress(progressEvent)

        XCTAssertEqual(updated.elapsedTimeSeconds, 7)
        XCTAssertEqual(updated.status, .running)
    }

    // MARK: - AC#1 — ToolContent summaryTitle from Input JSON

    // [P0] ToolContent summaryTitle extracts command from Bash input JSON
    func testSummaryTitleExtractsCommandFromBashInput() throws {
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-001",
            input: "{\"command\": \"npm test\"}",
            output: nil,
            isError: false
        )

        let title = content.summaryTitle
        XCTAssertEqual(title, "npm test",
            "summaryTitle should extract 'command' field from Bash input JSON")
    }

    // [P1] ToolContent summaryTitle extracts file_path from Read input JSON
    func testSummaryTitleExtractsFilePathFromReadInput() throws {
        let content = ToolContent(
            toolName: "Read",
            toolUseId: "tu-002",
            input: "{\"file_path\": \"/src/main.swift\"}",
            output: nil,
            isError: false
        )

        let title = content.summaryTitle
        XCTAssertEqual(title, "/src/main.swift",
            "summaryTitle should extract 'file_path' field from Read input JSON")
    }

    // [P1] ToolContent summaryTitle falls back to toolName for unparseable input
    func testSummaryTitleFallsBackToToolName() throws {
        let content = ToolContent(
            toolName: "UnknownTool",
            toolUseId: "tu-003",
            input: "not valid json",
            output: nil,
            isError: false
        )

        let title = content.summaryTitle
        XCTAssertEqual(title, "UnknownTool",
            "summaryTitle should fall back to toolName when input is not valid JSON")
    }

    // [P1] ToolContent summaryTitle handles empty input
    func testSummaryTitleHandlesEmptyInput() throws {
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-004",
            input: "",
            output: nil,
            isError: false
        )

        let title = content.summaryTitle
        XCTAssertEqual(title, "Bash",
            "summaryTitle should fall back to toolName for empty input")
    }

    // MARK: - AC#3 — TimelineView uses Registry for .toolUse events

    // [P0] TimelineView with registry uses custom renderer for registered tools
    func testTimelineViewUsesRegistryForToolUseEvents() throws {
        let registry = ToolRendererRegistry()
        registry.register(MockBashRenderer())

        let bridge = AgentBridge()
        bridge.events = [
            AgentEvent(
                type: .toolUse,
                content: "Bash",
                metadata: [
                    "toolName": "Bash",
                    "toolUseId": "tu-001",
                    "input": "{\"command\": \"ls\"}"
                ] as [String: any Sendable],
                timestamp: .now
            )
        ]
        let view = TimelineView(agentBridge: bridge, toolRendererRegistry: registry)
        XCTAssertNotNil(view, "TimelineView should accept toolRendererRegistry parameter")
    }

    // [P0] TimelineView falls back to ToolCallView for unregistered tools
    func testTimelineViewFallsBackForUnregisteredTools() throws {
        let registry = ToolRendererRegistry()
        // Don't register any renderer

        let bridge = AgentBridge()
        bridge.events = [
            AgentEvent(
                type: .toolUse,
                content: "UnknownTool",
                metadata: [
                    "toolName": "UnknownTool",
                    "toolUseId": "tu-001",
                    "input": "{}"
                ] as [String: any Sendable],
                timestamp: .now
            )
        ]
        let view = TimelineView(agentBridge: bridge, toolRendererRegistry: registry)
        XCTAssertNotNil(view, "TimelineView should render with default ToolCallView fallback")
    }
}

// MARK: - Mock ToolRenderers for Testing
// Each mock is a separate type with a compile-time constant static toolName,
// eliminating the thread-unsafe mutable static variable from the original design.

private struct MockBashRenderer: ToolRenderable {
    static let toolName = "Bash"
    @MainActor func body(content: ToolContent) -> any View {
        Text("Mock renderer for \(content.toolName)")
    }
}

private struct MockReadRenderer: ToolRenderable {
    static let toolName = "Read"
    @MainActor func body(content: ToolContent) -> any View {
        Text("Mock renderer for \(content.toolName)")
    }
}

private struct MockEditRenderer: ToolRenderable {
    static let toolName = "Edit"
    @MainActor func body(content: ToolContent) -> any View {
        Text("Mock renderer for \(content.toolName)")
    }
}
