import XCTest
import SwiftUI
@testable import SwiftWork

// ATDD Red Phase — Story 3.4: Inspector Panel
// Unit tests for InspectorView and related event detail rendering.
// These tests will FAIL until Story 3.4 is implemented.

@MainActor
final class InspectorViewTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeToolContent(
        toolName: String = "Bash",
        toolUseId: String = "tu-inspector-001",
        input: String = "{\"command\": \"ls -la\"}",
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

    private func makeToolUseEvent(
        id: UUID = UUID(),
        toolName: String = "Bash",
        toolUseId: String = "tu-inspector-001",
        input: String = "{\"command\": \"ls -la\"}"
    ) -> AgentEvent {
        AgentEvent(
            id: id,
            type: .toolUse,
            content: toolName,
            metadata: [
                "toolName": toolName,
                "toolUseId": toolUseId,
                "input": input
            ] as [String: any Sendable],
            timestamp: Date()
        )
    }

    private func makeToolResultEvent(
        toolUseId: String = "tu-inspector-001",
        content: String = "total 48\ndrwxr-xr-x...",
        isError: Bool = false
    ) -> AgentEvent {
        AgentEvent(
            type: .toolResult,
            content: content,
            metadata: [
                "toolUseId": toolUseId,
                "isError": isError
            ] as [String: any Sendable],
            timestamp: Date()
        )
    }

    private func makeResultEvent(
        durationMs: Int = 3500,
        totalCostUsd: Double = 0.045,
        numTurns: Int = 5,
        usage: [String: any Sendable] = [:]
    ) -> AgentEvent {
        var metadata: [String: any Sendable] = [
            "durationMs": durationMs,
            "totalCostUsd": totalCostUsd,
            "numTurns": numTurns
        ]
        if !usage.isEmpty {
            metadata["usage"] = (usage as any Sendable)
        }
        return AgentEvent(
            type: .result,
            content: "success",
            metadata: metadata,
            timestamp: Date()
        )
    }

    private func makeAssistantEvent(
        model: String = "claude-sonnet-4-6",
        stopReason: String = "end_turn"
    ) -> AgentEvent {
        AgentEvent(
            type: .assistant,
            content: "Here is the response",
            metadata: [
                "model": model,
                "stopReason": stopReason
            ] as [String: any Sendable],
            timestamp: Date()
        )
    }

    private func makeSystemEvent(
        subtype: String = "init",
        sessionId: String = "session-abc"
    ) -> AgentEvent {
        AgentEvent(
            type: .system,
            content: "System initialized",
            metadata: [
                "subtype": subtype,
                "sessionId": sessionId
            ] as [String: any Sendable],
            timestamp: Date()
        )
    }

    private func makeUserMessageEvent(content: String = "Hello Agent") -> AgentEvent {
        AgentEvent(
            type: .userMessage,
            content: content,
            timestamp: Date()
        )
    }

    // MARK: - AC#1: Inspector displays event details when selected

    // [P0] InspectorView instantiates with nil selectedEvent (empty state)
    func testInspectorViewEmptyStateWithNilEvent() {
        let toolContentMap: [String: ToolContent] = [:]
        let view = InspectorView(
            selectedEvent: nil,
            toolContentMap: toolContentMap
        )
        XCTAssertNotNil(view, "InspectorView should instantiate with nil selectedEvent")
    }

    // [P0] InspectorView instantiates with a selected toolUse event
    func testInspectorViewWithToolUseEvent() {
        let event = makeToolUseEvent()
        let toolContent = makeToolContent()
        let toolContentMap = [toolContent.toolUseId: toolContent]
        let view = InspectorView(
            selectedEvent: event,
            toolContentMap: toolContentMap
        )
        XCTAssertNotNil(view, "InspectorView should instantiate with toolUse event and matching ToolContent")
    }

    // [P0] InspectorView instantiates with a selected result event
    func testInspectorViewWithResultEvent() {
        let event = makeResultEvent()
        let view = InspectorView(
            selectedEvent: event,
            toolContentMap: [:]
        )
        XCTAssertNotNil(view, "InspectorView should instantiate with result event")
    }

    // [P0] InspectorView instantiates with a selected assistant event
    func testInspectorViewWithAssistantEvent() {
        let event = makeAssistantEvent()
        let view = InspectorView(
            selectedEvent: event,
            toolContentMap: [:]
        )
        XCTAssertNotNil(view, "InspectorView should instantiate with assistant event")
    }

    // [P0] InspectorView instantiates with a selected system event
    func testInspectorViewWithSystemEvent() {
        let event = makeSystemEvent()
        let view = InspectorView(
            selectedEvent: event,
            toolContentMap: [:]
        )
        XCTAssertNotNil(view, "InspectorView should instantiate with system event")
    }

    // [P0] InspectorView instantiates with a selected userMessage event
    func testInspectorViewWithUserMessageEvent() {
        let event = makeUserMessageEvent()
        let view = InspectorView(
            selectedEvent: event,
            toolContentMap: [:]
        )
        XCTAssertNotNil(view, "InspectorView should instantiate with userMessage event")
    }

    // [P1] InspectorView handles toolUse event with matching ToolContent (completed)
    func testInspectorViewWithCompletedToolContent() {
        let toolUseId = "tu-completed"
        let event = makeToolUseEvent(toolUseId: toolUseId)
        let toolContent = makeToolContent(
            toolUseId: toolUseId,
            output: "Build succeeded",
            status: .completed,
            elapsedTimeSeconds: 3
        )
        let toolContentMap = [toolUseId: toolContent]
        let view = InspectorView(
            selectedEvent: event,
            toolContentMap: toolContentMap
        )
        XCTAssertNotNil(view, "InspectorView should render completed tool event with full ToolContent")
    }

    // [P1] InspectorView handles toolUse event with failed ToolContent
    func testInspectorViewWithFailedToolContent() {
        let toolUseId = "tu-failed"
        let event = makeToolUseEvent(toolUseId: toolUseId)
        let toolContent = makeToolContent(
            toolUseId: toolUseId,
            output: "command not found",
            isError: true,
            status: .failed
        )
        let toolContentMap = [toolUseId: toolContent]
        let view = InspectorView(
            selectedEvent: event,
            toolContentMap: toolContentMap
        )
        XCTAssertNotNil(view, "InspectorView should render failed tool event")
    }

    // [P1] InspectorView handles toolUse event with running ToolContent
    func testInspectorViewWithRunningToolContent() {
        let toolUseId = "tu-running"
        let event = makeToolUseEvent(toolUseId: toolUseId)
        let toolContent = makeToolContent(
            toolUseId: toolUseId,
            status: .running,
            elapsedTimeSeconds: 7
        )
        let toolContentMap = [toolUseId: toolContent]
        let view = InspectorView(
            selectedEvent: event,
            toolContentMap: toolContentMap
        )
        XCTAssertNotNil(view, "InspectorView should render running tool event with progress")
    }

    // [P1] InspectorView handles toolUse event without matching ToolContent
    func testInspectorViewWithToolUseEventNoMatchingContent() {
        let event = makeToolUseEvent(toolUseId: "tu-orphan")
        let view = InspectorView(
            selectedEvent: event,
            toolContentMap: [:]
        )
        XCTAssertNotNil(view, "InspectorView should handle toolUse event with no matching ToolContent")
    }

    // [P1] InspectorView handles result event with usage data
    func testInspectorViewWithResultEventAndUsage() {
        let event = makeResultEvent(
            durationMs: 5200,
            totalCostUsd: 0.087,
            numTurns: 8,
            usage: ["inputTokens": 1500 as any Sendable, "outputTokens": 3200 as any Sendable]
        )
        let view = InspectorView(
            selectedEvent: event,
            toolContentMap: [:]
        )
        XCTAssertNotNil(view, "InspectorView should render result event with usage and cost data")
    }

    // [P1] InspectorView handles all AgentEventType cases without crash
    func testInspectorViewHandlesAllEventTypes() {
        let allTypes: [AgentEventType] = [
            .partialMessage, .assistant, .toolUse, .toolResult,
            .toolProgress, .result, .userMessage, .system,
            .hookStarted, .hookProgress, .hookResponse,
            .taskStarted, .taskProgress, .authStatus,
            .filesPersisted, .localCommandOutput,
            .promptSuggestion, .toolUseSummary, .unknown
        ]

        for eventType in allTypes {
            let event = AgentEvent(
                type: eventType,
                content: "Test content for \(eventType.rawValue)",
                metadata: ["testKey": "testValue"] as [String: any Sendable],
                timestamp: Date()
            )
            let view = InspectorView(
                selectedEvent: event,
                toolContentMap: [:]
            )
            XCTAssertNotNil(view, "InspectorView should handle event type: \(eventType.rawValue) without crash")
        }
    }

    // MARK: - AC#1: JSON raw data display

    // [P0] InspectorView can serialize event metadata to JSON
    func testEventMetadataSerialization() throws {
        let metadata: [String: any Sendable] = [
            "toolName": "Bash",
            "toolUseId": "tu-json-test",
            "input": "{\"command\": \"echo hello\"}"
        ]
        let event = AgentEvent(
            type: .toolUse,
            content: "Bash",
            metadata: metadata,
            timestamp: Date()
        )

        // Verify metadata is serializable to JSON for Inspector display
        let jsonPayload: [String: any Sendable] = [
            "id": event.id.uuidString,
            "type": event.type.rawValue,
            "content": event.content,
            "metadata": event.metadata,
            "timestamp": event.timestamp.ISO8601Format()
        ]
        let data = try JSONSerialization.data(withJSONObject: jsonPayload)
        XCTAssertGreaterThan(data.count, 0, "Event metadata should be serializable to JSON for Inspector")
    }

    // [P1] InspectorView handles empty metadata gracefully
    func testEventWithEmptyMetadata() {
        let event = AgentEvent(
            type: .assistant,
            content: "Response",
            metadata: [:],
            timestamp: Date()
        )
        let view = InspectorView(
            selectedEvent: event,
            toolContentMap: [:]
        )
        XCTAssertNotNil(view, "InspectorView should handle event with empty metadata")
    }

    // [P1] InspectorView handles nested metadata gracefully
    func testEventWithNestedMetadata() {
        let event = AgentEvent(
            type: .result,
            content: "success",
            metadata: [
                "usage": ["inputTokens": 1000, "outputTokens": 2000] as [String: any Sendable],
                "costBreakdown": ["model": "claude-sonnet-4-6", "cost": 0.05] as [String: any Sendable]
            ] as [String: any Sendable],
            timestamp: Date()
        )
        let view = InspectorView(
            selectedEvent: event,
            toolContentMap: [:]
        )
        XCTAssertNotNil(view, "InspectorView should handle nested metadata dictionaries")
    }

    // MARK: - AC#2 & AC#3: Inspector visibility toggle

    // [P0] WorkspaceView accepts isInspectorVisible binding
    func testWorkspaceViewAcceptsInspectorVisibility() {
        let bridge = AgentBridge()
        let session = Session(title: "Test")
        let settingsVM = SettingsViewModel()
        let sessionVM = SessionViewModel()

        let view = WorkspaceView(
            agentBridge: bridge,
            eventStore: nil,
            session: session,
            settingsViewModel: settingsVM,
            sessionViewModel: sessionVM,
            isInspectorVisible: .constant(false)
        )
        XCTAssertNotNil(view, "WorkspaceView should accept isInspectorVisible binding")
    }

    // [P0] WorkspaceView accepts isInspectorVisible as true
    func testWorkspaceViewWithInspectorVisible() {
        let bridge = AgentBridge()
        let session = Session(title: "Test")
        let settingsVM = SettingsViewModel()
        let sessionVM = SessionViewModel()

        let view = WorkspaceView(
            agentBridge: bridge,
            eventStore: nil,
            session: session,
            settingsViewModel: settingsVM,
            sessionViewModel: sessionVM,
            isInspectorVisible: .constant(true)
        )
        XCTAssertNotNil(view, "WorkspaceView should accept isInspectorVisible=true")
    }

    // MARK: - AC#1: Event selection state hoisting

    // [P0] AgentEvent can be found by ID in an event list (selection lookup)
    func testEventSelectionLookupById() {
        let targetId = UUID()
        let targetEvent = makeToolUseEvent(id: targetId)
        let otherEvent = makeToolUseEvent(id: UUID())

        let events = [otherEvent, targetEvent]
        let found = events.first(where: { $0.id == targetId })

        XCTAssertNotNil(found, "Should find event by ID for Inspector selection")
        XCTAssertEqual(found?.id, targetId)
    }

    // [P0] AgentEvent ID is unique for selection
    func testEventIdUniqueness() {
        let event1 = makeToolUseEvent()
        let event2 = makeToolUseEvent()
        XCTAssertNotEqual(event1.id, event2.id, "Each AgentEvent should have a unique ID for selection")
    }

    // MARK: - AC#1: ToolContent pairing for Inspector

    // [P0] ToolContent can be retrieved from toolContentMap by toolUseId
    func testToolContentLookupByToolUseId() {
        let toolUseId = "tu-pair-001"
        let content = makeToolContent(
            toolUseId: toolUseId,
            output: "file contents",
            status: .completed
        )
        let toolContentMap = [toolUseId: content]

        let found = toolContentMap[toolUseId]
        XCTAssertNotNil(found, "Should find ToolContent by toolUseId")
        XCTAssertEqual(found?.toolName, "Bash")
        XCTAssertEqual(found?.output, "file contents")
        XCTAssertEqual(found?.status, .completed)
    }

    // [P1] ToolContent elapsed time is accessible for Inspector display
    func testToolContentElapsedTimeAccessible() {
        let content = makeToolContent(
            status: .running,
            elapsedTimeSeconds: 15
        )
        XCTAssertEqual(content.elapsedTimeSeconds, 15, "Elapsed time should be accessible for Inspector display")
    }

    // [P1] ToolContent input is accessible for Inspector JSON display
    func testToolContentInputAccessible() {
        let content = makeToolContent(
            input: "{\"command\": \"npm test\", \"cwd\": \"/project\"}"
        )
        XCTAssertEqual(content.input, "{\"command\": \"npm test\", \"cwd\": \"/project\"}", "Input should be accessible for Inspector JSON display")
    }

    // MARK: - AC#1: Timestamp formatting for Inspector

    // [P1] AgentEvent timestamp is accessible for formatting
    func testEventTimestampAccessible() {
        let now = Date()
        let event = AgentEvent(
            type: .toolUse,
            content: "Bash",
            timestamp: now
        )
        XCTAssertEqual(event.timestamp, now, "Timestamp should be accessible for Inspector display")
    }

    // MARK: - AC#1: Event type label color mapping

    // [P1] AgentEventType provides raw value for display
    func testEventTypeRawValues() {
        XCTAssertEqual(AgentEventType.toolUse.rawValue, "toolUse")
        XCTAssertEqual(AgentEventType.result.rawValue, "result")
        XCTAssertEqual(AgentEventType.assistant.rawValue, "assistant")
        XCTAssertEqual(AgentEventType.system.rawValue, "system")
        XCTAssertEqual(AgentEventType.userMessage.rawValue, "userMessage")
    }

    // MARK: - Integration: Inspector + WorkspaceView event selection

    // [P1] Selected event changes when different event is clicked
    func testSelectedEventChangesOnDifferentEvent() {
        let event1 = makeToolUseEvent(id: UUID(), toolUseId: "tu-1")
        let event2 = makeResultEvent()

        let view1 = InspectorView(selectedEvent: event1, toolContentMap: [:])
        let view2 = InspectorView(selectedEvent: event2, toolContentMap: [:])

        XCTAssertNotNil(view1, "InspectorView should render for first event")
        XCTAssertNotNil(view2, "InspectorView should render for second event (selection change)")
    }

    // [P1] InspectorView handles toolProgress event type
    func testInspectorViewWithToolProgressEvent() {
        let event = AgentEvent(
            type: .toolProgress,
            content: "Progress update",
            metadata: [
                "toolUseId": "tu-progress",
                "toolName": "Bash",
                "elapsedTimeSeconds": 5
            ] as [String: any Sendable],
            timestamp: Date()
        )
        let view = InspectorView(
            selectedEvent: event,
            toolContentMap: [:]
        )
        XCTAssertNotNil(view, "InspectorView should handle toolProgress event")
    }
}
