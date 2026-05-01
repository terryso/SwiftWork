import XCTest
@testable import SwiftWork

// ATDD Red Phase — Story 2.2: Tool Card 完整体验
// Unit tests for toolContentMap pairing mechanism in AgentBridge.
// These tests will FAIL until Story 2.2 is implemented.

@MainActor
final class ToolContentPairingTests: XCTestCase {

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

    private func makeToolResultEvent(
        toolUseId: String = "tu-001",
        content: String = "output text",
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

    // MARK: - AC#1: toolContentMap Initial State

    // [P0] AgentBridge has empty toolContentMap initially
    func testToolContentMapStartsEmpty() {
        let bridge = makeBridge()

        XCTAssertTrue(bridge.toolContentMap.isEmpty,
            "toolContentMap should start empty")
    }

    // MARK: - AC#1: toolUse event creates entry in toolContentMap

    // [P0] Appending toolUse event creates ToolContent entry
    func testToolUseEventCreatesToolContentMapEntry() {
        let bridge = makeBridge()
        let event = makeToolUseEvent(toolUseId: "tu-001")

        bridge.events.append(event)
        bridge.processToolContentMap(for: event)

        XCTAssertNotNil(bridge.toolContentMap["tu-001"],
            "toolContentMap should contain entry for toolUseId 'tu-001'")
        XCTAssertEqual(bridge.toolContentMap["tu-001"]?.toolName, "Bash")
        XCTAssertEqual(bridge.toolContentMap["tu-001"]?.status, .pending)
    }

    // [P0] toolContentMap entry preserves input from toolUse
    func testToolContentMapEntryPreservesInput() {
        let bridge = makeBridge()
        let event = makeToolUseEvent(input: "{\"command\": \"npm test\"}")

        bridge.processToolContentMap(for: event)

        XCTAssertEqual(bridge.toolContentMap["tu-001"]?.input,
            "{\"command\": \"npm test\"}",
            "toolContentMap entry should preserve input JSON")
    }

    // MARK: - AC#2: toolProgress updates existing ToolContent

    // [P0] toolProgress updates status to running and sets elapsed time
    func testToolProgressUpdatesStatusToRunning() {
        let bridge = makeBridge()

        let toolUseEvent = makeToolUseEvent(toolUseId: "tu-001")
        bridge.processToolContentMap(for: toolUseEvent)

        let progressEvent = makeToolProgressEvent(toolUseId: "tu-001", elapsedTimeSeconds: 7)
        bridge.processToolContentMap(for: progressEvent)

        let content = bridge.toolContentMap["tu-001"]
        XCTAssertEqual(content?.status, .running,
            "toolProgress should update status to .running")
        XCTAssertEqual(content?.elapsedTimeSeconds, 7,
            "toolProgress should set elapsedTimeSeconds")
    }

    // [P0] toolProgress preserves original toolName and input
    func testToolProgressPreservesOriginalData() {
        let bridge = makeBridge()

        let toolUseEvent = makeToolUseEvent(toolName: "Edit", toolUseId: "tu-002", input: "{\"file_path\": \"/src/main.swift\"}")
        bridge.processToolContentMap(for: toolUseEvent)

        let progressEvent = makeToolProgressEvent(toolUseId: "tu-002", toolName: "Edit", elapsedTimeSeconds: 3)
        bridge.processToolContentMap(for: progressEvent)

        let content = bridge.toolContentMap["tu-002"]
        XCTAssertEqual(content?.toolName, "Edit",
            "toolProgress should not change toolName")
        XCTAssertEqual(content?.input, "{\"file_path\": \"/src/main.swift\"}",
            "toolProgress should not change input")
    }

    // [P1] toolProgress for unknown toolUseId is ignored
    func testToolProgressForUnknownToolUseIdIsIgnored() {
        let bridge = makeBridge()

        let progressEvent = makeToolProgressEvent(toolUseId: "tu-999")
        bridge.processToolContentMap(for: progressEvent)

        XCTAssertNil(bridge.toolContentMap["tu-999"],
            "toolProgress for unknown toolUseId should not create entry")
    }

    // MARK: - AC#3: toolResult merges with existing ToolContent

    // [P0] toolResult merges output and sets completed status
    func testToolResultMergesOutputAndSetsCompleted() {
        let bridge = makeBridge()

        let toolUseEvent = makeToolUseEvent(toolUseId: "tu-001")
        bridge.processToolContentMap(for: toolUseEvent)

        let resultEvent = makeToolResultEvent(toolUseId: "tu-001", content: "test passed", isError: false)
        bridge.processToolContentMap(for: resultEvent)

        let content = bridge.toolContentMap["tu-001"]
        XCTAssertEqual(content?.output, "test passed",
            "toolResult should merge output")
        XCTAssertEqual(content?.status, .completed,
            "toolResult with no error should set status to .completed")
        XCTAssertFalse(content?.isError ?? true,
            "toolResult isError should be false")
    }

    // [P0] toolResult with error sets failed status
    func testToolResultWithErrorSetsFailed() {
        let bridge = makeBridge()

        let toolUseEvent = makeToolUseEvent(toolUseId: "tu-001")
        bridge.processToolContentMap(for: toolUseEvent)

        let resultEvent = makeToolResultEvent(toolUseId: "tu-001", content: "command failed", isError: true)
        bridge.processToolContentMap(for: resultEvent)

        let content = bridge.toolContentMap["tu-001"]
        XCTAssertEqual(content?.status, .failed,
            "toolResult with error should set status to .failed")
        XCTAssertTrue(content?.isError ?? false,
            "toolResult isError should be true")
    }

    // [P0] toolResult preserves original toolName and input from toolUse
    func testToolResultPreservesOriginalData() {
        let bridge = makeBridge()

        let toolUseEvent = makeToolUseEvent(toolName: "Bash", toolUseId: "tu-001", input: "{\"command\": \"npm test\"}")
        bridge.processToolContentMap(for: toolUseEvent)

        let resultEvent = makeToolResultEvent(toolUseId: "tu-001", content: "ok")
        bridge.processToolContentMap(for: resultEvent)

        let content = bridge.toolContentMap["tu-001"]
        XCTAssertEqual(content?.toolName, "Bash",
            "Merged content should preserve toolName from toolUse")
        XCTAssertEqual(content?.input, "{\"command\": \"npm test\"}",
            "Merged content should preserve input from toolUse")
    }

    // [P1] toolResult for unknown toolUseId is ignored
    func testToolResultForUnknownToolUseIdIsIgnored() {
        let bridge = makeBridge()

        let resultEvent = makeToolResultEvent(toolUseId: "tu-999", content: "orphan result")
        bridge.processToolContentMap(for: resultEvent)

        XCTAssertNil(bridge.toolContentMap["tu-999"],
            "toolResult for unknown toolUseId should not create entry")
    }

    // MARK: - AC#1-3: Full pairing sequence (toolUse → toolProgress → toolResult)

    // [P0] Full sequence: toolUse → toolProgress → toolResult produces complete ToolContent
    func testFullPairingSequenceProducesCompleteToolContent() {
        let bridge = makeBridge()

        // Step 1: toolUse
        let toolUseEvent = makeToolUseEvent(toolUseId: "tu-100")
        bridge.processToolContentMap(for: toolUseEvent)

        XCTAssertEqual(bridge.toolContentMap["tu-100"]?.status, .pending)
        XCTAssertNil(bridge.toolContentMap["tu-100"]?.output)

        // Step 2: toolProgress
        let progressEvent = makeToolProgressEvent(toolUseId: "tu-100", elapsedTimeSeconds: 10)
        bridge.processToolContentMap(for: progressEvent)

        XCTAssertEqual(bridge.toolContentMap["tu-100"]?.status, .running)
        XCTAssertEqual(bridge.toolContentMap["tu-100"]?.elapsedTimeSeconds, 10)

        // Step 3: toolResult
        let resultEvent = makeToolResultEvent(toolUseId: "tu-100", content: "all tests passed")
        bridge.processToolContentMap(for: resultEvent)

        let final = bridge.toolContentMap["tu-100"]
        XCTAssertEqual(final?.toolName, "Bash")
        XCTAssertEqual(final?.input, "{\"command\": \"ls\"}")
        XCTAssertEqual(final?.output, "all tests passed")
        XCTAssertEqual(final?.status, .completed)
        XCTAssertFalse(final?.isError ?? true)
        XCTAssertEqual(final?.elapsedTimeSeconds, 10)
    }

    // [P0] Full sequence with error result
    func testFullPairingSequenceWithErrorResult() {
        let bridge = makeBridge()

        let toolUseEvent = makeToolUseEvent(toolUseId: "tu-200")
        bridge.processToolContentMap(for: toolUseEvent)

        let progressEvent = makeToolProgressEvent(toolUseId: "tu-200", elapsedTimeSeconds: 3)
        bridge.processToolContentMap(for: progressEvent)

        let resultEvent = makeToolResultEvent(toolUseId: "tu-200", content: "timeout exceeded", isError: true)
        bridge.processToolContentMap(for: resultEvent)

        let final = bridge.toolContentMap["tu-200"]
        XCTAssertEqual(final?.status, .failed)
        XCTAssertTrue(final?.isError ?? false)
        XCTAssertEqual(final?.output, "timeout exceeded")
    }

    // MARK: - AC#1: Multiple concurrent tool calls

    // [P1] Multiple toolUse events tracked independently
    func testMultipleConcurrentToolCallsTrackedIndependently() {
        let bridge = makeBridge()

        bridge.processToolContentMap(for: makeToolUseEvent(toolName: "Bash", toolUseId: "tu-001"))
        bridge.processToolContentMap(for: makeToolUseEvent(toolName: "Read", toolUseId: "tu-002", input: "{\"file_path\": \"/src/a.swift\"}"))
        bridge.processToolContentMap(for: makeToolUseEvent(toolName: "Edit", toolUseId: "tu-003", input: "{\"file_path\": \"/src/b.swift\"}"))

        XCTAssertEqual(bridge.toolContentMap.count, 3)
        XCTAssertEqual(bridge.toolContentMap["tu-001"]?.toolName, "Bash")
        XCTAssertEqual(bridge.toolContentMap["tu-002"]?.toolName, "Read")
        XCTAssertEqual(bridge.toolContentMap["tu-003"]?.toolName, "Edit")
    }

    // [P1] Results arrive out of order and merge correctly
    func testOutOfOrderResultsMergeCorrectly() {
        let bridge = makeBridge()

        bridge.processToolContentMap(for: makeToolUseEvent(toolUseId: "tu-001"))
        bridge.processToolContentMap(for: makeToolUseEvent(toolUseId: "tu-002"))

        // Result for tu-002 arrives first
        bridge.processToolContentMap(for: makeToolResultEvent(toolUseId: "tu-002", content: "read done"))
        // Result for tu-001 arrives second
        bridge.processToolContentMap(for: makeToolResultEvent(toolUseId: "tu-001", content: "bash done"))

        XCTAssertEqual(bridge.toolContentMap["tu-001"]?.output, "bash done")
        XCTAssertEqual(bridge.toolContentMap["tu-002"]?.output, "read done")
    }

    // MARK: - clearEvents clears toolContentMap

    // [P0] clearEvents also clears toolContentMap
    func testClearEventsClearsToolContentMap() {
        let bridge = makeBridge()

        bridge.processToolContentMap(for: makeToolUseEvent(toolUseId: "tu-001"))
        XCTAssertFalse(bridge.toolContentMap.isEmpty)

        bridge.clearEvents()

        XCTAssertTrue(bridge.toolContentMap.isEmpty,
            "clearEvents should also clear toolContentMap")
    }

    // MARK: - Non-tool events don't affect toolContentMap

    // [P1] Non-tool events (userMessage, assistant, etc.) don't affect toolContentMap
    func testNonToolEventsDontAffectToolContentMap() {
        let bridge = makeBridge()

        bridge.processToolContentMap(for: AgentEvent(type: .userMessage, content: "hello", timestamp: .now))
        bridge.processToolContentMap(for: AgentEvent(type: .assistant, content: "response", timestamp: .now))
        bridge.processToolContentMap(for: AgentEvent(type: .system, content: "init", timestamp: .now))

        XCTAssertTrue(bridge.toolContentMap.isEmpty,
            "Non-tool events should not affect toolContentMap")
    }
}
