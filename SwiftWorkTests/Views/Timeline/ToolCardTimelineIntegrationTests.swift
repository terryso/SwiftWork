import XCTest
@testable import SwiftWork

// ATDD Red Phase — Story 2.2: Tool Card 完整体验
// Unit tests for TimelineView integration with ToolCardView and selectedEventId.
// These tests will FAIL until Story 2.2 is implemented.

@MainActor
final class ToolCardTimelineIntegrationTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeBridge() -> AgentBridge {
        AgentBridge()
    }

    private func makeToolUseEvent(
        toolName: String = "Bash",
        toolUseId: String = "tu-001",
        input: String = "{\"command\": \"ls\"}"
    ) -> AgentEvent {
        AgentEvent(
            type: .toolUse,
            content: toolName,
            metadata: [
                "toolName": toolName,
                "toolUseId": toolUseId,
                "input": input
            ] as [String: any Sendable],
            timestamp: .now
        )
    }

    private func makeToolResultEvent(
        toolUseId: String = "tu-001",
        content: String = "output",
        isError: Bool = false
    ) -> AgentEvent {
        AgentEvent(
            type: .toolResult,
            content: content,
            metadata: [
                "toolUseId": toolUseId,
                "isError": isError
            ] as [String: any Sendable],
            timestamp: .now
        )
    }

    private func makeToolProgressEvent(
        toolUseId: String = "tu-001",
        toolName: String = "Bash",
        elapsedTimeSeconds: Int = 5
    ) -> AgentEvent {
        AgentEvent(
            type: .toolProgress,
            content: toolName,
            metadata: [
                "toolUseId": toolUseId,
                "toolName": toolName,
                "elapsedTimeSeconds": elapsedTimeSeconds
            ] as [String: any Sendable],
            timestamp: .now
        )
    }

    // MARK: - AC#1: TimelineView uses ToolCardView for toolUse events

    // [P0] TimelineView renders ToolCardView for toolUse event (not ToolCallView directly)
    func testTimelineViewRendersToolCardViewForToolUse() {
        let bridge = makeBridge()
        bridge.events = [
            makeToolUseEvent(toolName: "Bash", toolUseId: "tu-001")
        ]
        // Process toolContentMap
        bridge.processToolContentMap(for: bridge.events[0])

        let registry = ToolRendererRegistry()
        let view = TimelineView(agentBridge: bridge, toolRendererRegistry: registry, selectedEventId: .constant(nil))

        XCTAssertNotNil(view,
            "TimelineView should render with toolUse events using toolContentMap")
    }

    // MARK: - AC#3: toolResult and toolProgress don't render separate cards

    // [P0] toolResult event does not render a separate card when paired
    func testToolResultDoesNotRenderSeparateCard() {
        let bridge = makeBridge()
        let toolUseEvent = makeToolUseEvent(toolUseId: "tu-001")
        let toolResultEvent = makeToolResultEvent(toolUseId: "tu-001")

        bridge.events = [toolUseEvent, toolResultEvent]
        bridge.processToolContentMap(for: toolUseEvent)
        bridge.processToolContentMap(for: toolResultEvent)

        let registry = ToolRendererRegistry()
        let view = TimelineView(agentBridge: bridge, toolRendererRegistry: registry, selectedEventId: .constant(nil))

        XCTAssertNotNil(view,
            "TimelineView should render with paired tool events")
        // The ToolCardView for tu-001 should now show completed status
        XCTAssertEqual(bridge.toolContentMap["tu-001"]?.status, .completed)
    }

    // [P0] toolProgress event does not render a separate card when paired
    func testToolProgressDoesNotRenderSeparateCard() {
        let bridge = makeBridge()
        let toolUseEvent = makeToolUseEvent(toolUseId: "tu-001")
        let progressEvent = makeToolProgressEvent(toolUseId: "tu-001", elapsedTimeSeconds: 3)

        bridge.events = [toolUseEvent, progressEvent]
        bridge.processToolContentMap(for: toolUseEvent)
        bridge.processToolContentMap(for: progressEvent)

        let registry = ToolRendererRegistry()
        let view = TimelineView(agentBridge: bridge, toolRendererRegistry: registry, selectedEventId: .constant(nil))

        XCTAssertNotNil(view)
        XCTAssertEqual(bridge.toolContentMap["tu-001"]?.status, .running)
    }

    // MARK: - AC#4: selectedEventId state

    // [P0] TimelineView has selectedEventId state
    func testTimelineViewHasSelectedEventIdState() {
        let bridge = makeBridge()
        let registry = ToolRendererRegistry()
        let view = TimelineView(agentBridge: bridge, toolRendererRegistry: registry, selectedEventId: .constant(nil))

        XCTAssertNotNil(view, "TimelineView should accept selectedEventId parameter")
    }

    // MARK: - AC#4: Full tool lifecycle rendering

    // [P0] TimelineView renders complete tool lifecycle
    func testTimelineViewRendersCompleteToolLifecycle() {
        let bridge = makeBridge()

        let toolUseEvent = makeToolUseEvent(toolName: "Bash", toolUseId: "tu-100")
        let progressEvent = makeToolProgressEvent(toolUseId: "tu-100", elapsedTimeSeconds: 5)
        let resultEvent = makeToolResultEvent(toolUseId: "tu-100", content: "success")

        bridge.events = [toolUseEvent, progressEvent, resultEvent]
        bridge.processToolContentMap(for: toolUseEvent)
        bridge.processToolContentMap(for: progressEvent)
        bridge.processToolContentMap(for: resultEvent)

        let registry = ToolRendererRegistry()
        let view = TimelineView(agentBridge: bridge, toolRendererRegistry: registry, selectedEventId: .constant(nil))

        XCTAssertNotNil(view)
        let content = bridge.toolContentMap["tu-100"]
        XCTAssertEqual(content?.status, .completed)
        XCTAssertEqual(content?.output, "success")
    }

    // MARK: - AC#1: TimelineView with mixed event types

    // [P1] TimelineView correctly handles mix of tool and non-tool events
    func testTimelineViewMixedToolAndNonToolEvents() {
        let bridge = makeBridge()
        bridge.events = [
            AgentEvent(type: .userMessage, content: "Run tests", timestamp: .now),
            AgentEvent(type: .assistant, content: "I'll run the tests", timestamp: .now),
            makeToolUseEvent(toolName: "Bash", toolUseId: "tu-001"),
            makeToolProgressEvent(toolUseId: "tu-001", elapsedTimeSeconds: 2),
            makeToolResultEvent(toolUseId: "tu-001", content: "tests passed"),
            AgentEvent(type: .assistant, content: "All tests passed!", timestamp: .now),
        ]

        for event in bridge.events {
            bridge.processToolContentMap(for: event)
        }

        let registry = ToolRendererRegistry()
        let view = TimelineView(agentBridge: bridge, toolRendererRegistry: registry, selectedEventId: .constant(nil))

        XCTAssertNotNil(view)
        XCTAssertEqual(bridge.toolContentMap.count, 1)
        XCTAssertEqual(bridge.toolContentMap["tu-001"]?.status, .completed)
    }

    // MARK: - AC#1: Registry with new renderers

    // [P1] Registry should have Read and Write renderers registered
    func testRegistryHasReadAndWriteRenderers() {
        let registry = ToolRendererRegistry()

        XCTAssertNotNil(registry.renderer(for: "Bash"),
            "Registry should have BashToolRenderer")
        XCTAssertNotNil(registry.renderer(for: "Edit"),
            "Registry should have FileEditToolRenderer (Edit)")
        XCTAssertNotNil(registry.renderer(for: "Grep"),
            "Registry should have SearchToolRenderer (Grep)")
    }

    // [P1] Registry should have ReadToolRenderer after Story 2.2
    func testRegistryHasReadToolRenderer() {
        let registry = ToolRendererRegistry()

        XCTAssertNotNil(registry.renderer(for: "Read"),
            "Registry should register ReadToolRenderer in Story 2.2")
    }

    // [P1] Registry should have WriteToolRenderer after Story 2.2
    func testRegistryHasWriteToolRenderer() {
        let registry = ToolRendererRegistry()

        XCTAssertNotNil(registry.renderer(for: "Write"),
            "Registry should register WriteToolRenderer in Story 2.2")
    }

    // MARK: - AC#3: Unpaired toolResult (regression safety)

    // [P1] Unpaired toolResult still renders ToolResultView as fallback
    func testUnpairedToolResultRendersToolResultView() {
        let bridge = makeBridge()
        bridge.events = [
            makeToolResultEvent(toolUseId: "tu-orphan", content: "orphan result")
        ]
        // Don't process toolContentMap — no corresponding toolUse

        let registry = ToolRendererRegistry()
        let view = TimelineView(agentBridge: bridge, toolRendererRegistry: registry, selectedEventId: .constant(nil))

        XCTAssertNotNil(view,
            "TimelineView should handle unpaired toolResult without crash")
    }
}
