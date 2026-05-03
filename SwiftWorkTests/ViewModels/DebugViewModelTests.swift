import XCTest
@testable import SwiftWork

// ATDD Red Phase -- Story 4.1: Debug Panel
// Unit tests for DebugViewModel: raw event stream, token statistics, tool execution logs.
// These tests will FAIL until Story 4.1 is implemented.

@MainActor
final class DebugViewModelTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeBridge() -> AgentBridge {
        AgentBridge()
    }

    private func makeResultEvent(
        durationMs: Int = 3500,
        totalCostUsd: Double = 0.045,
        numTurns: Int = 5,
        inputTokens: Int? = nil,
        outputTokens: Int? = nil
    ) -> AgentEvent {
        var metadata: [String: any Sendable] = [
            "durationMs": durationMs,
            "totalCostUsd": totalCostUsd,
            "numTurns": numTurns
        ]
        if let inputTokens, let outputTokens {
            metadata["usage"] = [
                "inputTokens": inputTokens,
                "outputTokens": outputTokens
            ] as [String: any Sendable]
        }
        return AgentEvent(
            type: .result,
            content: "success",
            metadata: metadata,
            timestamp: Date()
        )
    }

    private func makeToolUseEvent(
        toolName: String = "Bash",
        toolUseId: String = "tu-debug-001",
        input: String = "{\"command\": \"ls -la\"}",
        timestamp: Date = Date()
    ) -> AgentEvent {
        AgentEvent(
            type: .toolUse,
            content: toolName,
            metadata: [
                "toolName": toolName,
                "toolUseId": toolUseId,
                "input": input
            ] as [String: any Sendable],
            timestamp: timestamp
        )
    }

    private func makeToolResultEvent(
        toolUseId: String = "tu-debug-001",
        content: String = "file1.txt\nfile2.txt",
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

    private func makeAssistantEvent(content: String = "Response text") -> AgentEvent {
        AgentEvent(
            type: .assistant,
            content: content,
            metadata: ["model": "claude-sonnet-4-6", "stopReason": "end_turn"] as [String: any Sendable],
            timestamp: Date()
        )
    }

    private func makePartialMessageEvent(text: String = "partial") -> AgentEvent {
        AgentEvent(
            type: .partialMessage,
            content: text,
            timestamp: Date()
        )
    }

    private func makeSystemEvent(subtype: String = "init") -> AgentEvent {
        AgentEvent(
            type: .system,
            content: "System initialized",
            metadata: ["subtype": subtype, "sessionId": "sess-001"] as [String: any Sendable],
            timestamp: Date()
        )
    }

    // MARK: - AC#1: filteredEvents -- Raw Event Stream (FR38)

    // [P0] DebugViewModel.filteredEvents excludes partialMessage events
    func testFilteredEventsExcludesPartialMessage() {
        let bridge = makeBridge()
        bridge.events = [
            makePartialMessageEvent(),
            makeAssistantEvent(),
            makePartialMessageEvent(text: "more"),
            makeToolUseEvent()
        ]

        let vm = DebugViewModel(agentBridge: bridge)
        let filtered = vm.filteredEvents

        XCTAssertEqual(filtered.count, 2, "Should exclude partialMessage events")
        XCTAssertTrue(filtered.allSatisfy { $0.type != .partialMessage },
                       "No partialMessage events in filtered list")
    }

    // [P0] DebugViewModel.filteredEvents returns all non-partialMessage events
    func testFilteredEventsReturnsAllNonPartial() {
        let bridge = makeBridge()
        let events: [AgentEvent] = [
            makeAssistantEvent(),
            makeToolUseEvent(),
            makeToolResultEvent(),
            makeResultEvent(),
            makeSystemEvent()
        ]
        bridge.events = events

        let vm = DebugViewModel(agentBridge: bridge)
        let filtered = vm.filteredEvents

        XCTAssertEqual(filtered.count, 5, "Should return all non-partialMessage events")
    }

    // [P0] DebugViewModel.filteredEvents returns empty for empty session
    func testFilteredEventsEmptyWhenNoEvents() {
        let bridge = makeBridge()
        bridge.events = []

        let vm = DebugViewModel(agentBridge: bridge)
        let filtered = vm.filteredEvents

        XCTAssertTrue(filtered.isEmpty, "Should return empty when no events")
    }

    // [P1] DebugViewModel.filteredEvents preserves event order
    func testFilteredEventsPreservesOrder() {
        let bridge = makeBridge()
        let event1 = makeAssistantEvent(content: "first")
        let event2 = makeToolUseEvent(toolUseId: "tu-order-1")
        let event3 = makeToolResultEvent(toolUseId: "tu-order-1")
        bridge.events = [
            makePartialMessageEvent(),
            event1,
            makePartialMessageEvent(text: "mid"),
            event2,
            event3
        ]

        let vm = DebugViewModel(agentBridge: bridge)
        let filtered = vm.filteredEvents

        XCTAssertEqual(filtered.count, 3)
        XCTAssertEqual(filtered[0].id, event1.id)
        XCTAssertEqual(filtered[1].id, event2.id)
        XCTAssertEqual(filtered[2].id, event3.id)
    }

    // [P1] DebugViewModel formats events as serializable JSON strings
    func testEventJSONSerialization() throws {
        let bridge = makeBridge()
        let event = makeToolUseEvent()
        bridge.events = [event]

        let vm = DebugViewModel(agentBridge: bridge)

        // DebugViewModel should expose raw JSON string for each event
        // Using same pattern as InspectorView.rawJSONString
        let jsonStrings = vm.rawEventJSONStrings
        XCTAssertEqual(jsonStrings.count, 1, "Should produce one JSON string per event")

        let jsonString = jsonStrings[0]
        let data = jsonString.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(parsed, "Should produce valid JSON")
        XCTAssertEqual(parsed?["type"] as? String, "toolUse")
    }

    // MARK: - AC#2: tokenSummary -- Token Statistics (FR39)

    // [P0] DebugViewModel aggregates single result event token usage
    func testTokenSummarySingleResultEvent() {
        let bridge = makeBridge()
        bridge.events = [
            makeResultEvent(
                totalCostUsd: 0.045,
                inputTokens: 1500,
                outputTokens: 3200
            )
        ]

        let vm = DebugViewModel(agentBridge: bridge)
        let summary = vm.tokenSummary

        XCTAssertEqual(summary.totalInputTokens, 1500)
        XCTAssertEqual(summary.totalOutputTokens, 3200)
        XCTAssertEqual(summary.totalTokens, 4700)
        XCTAssertEqual(summary.totalCostUsd, 0.045, accuracy: 0.0001)
    }

    // [P0] DebugViewModel aggregates multiple result events
    func testTokenSummaryMultipleResultEvents() {
        let bridge = makeBridge()
        bridge.events = [
            makeResultEvent(totalCostUsd: 0.03, inputTokens: 1000, outputTokens: 2000),
            makeResultEvent(totalCostUsd: 0.02, inputTokens: 500, outputTokens: 800),
            makeToolUseEvent()  // Non-result event should be ignored
        ]

        let vm = DebugViewModel(agentBridge: bridge)
        let summary = vm.tokenSummary

        XCTAssertEqual(summary.totalInputTokens, 1500)
        XCTAssertEqual(summary.totalOutputTokens, 2800)
        XCTAssertEqual(summary.totalTokens, 4300)
        XCTAssertEqual(summary.totalCostUsd, 0.05, accuracy: 0.0001)
    }

    // [P0] DebugViewModel returns zero summary for empty session
    func testTokenSummaryEmptySession() {
        let bridge = makeBridge()
        bridge.events = []

        let vm = DebugViewModel(agentBridge: bridge)
        let summary = vm.tokenSummary

        XCTAssertEqual(summary.totalInputTokens, 0)
        XCTAssertEqual(summary.totalOutputTokens, 0)
        XCTAssertEqual(summary.totalTokens, 0)
        XCTAssertEqual(summary.totalCostUsd, 0.0, accuracy: 0.0001)
    }

    // [P1] DebugViewModel extracts totalCostUsd correctly
    func testTokenSummaryCostExtraction() {
        let bridge = makeBridge()
        bridge.events = [
            makeResultEvent(totalCostUsd: 0.1234)
        ]

        let vm = DebugViewModel(agentBridge: bridge)
        let summary = vm.tokenSummary

        XCTAssertEqual(summary.totalCostUsd, 0.1234, accuracy: 0.0001)
    }

    // [P1] DebugViewModel handles result event with missing usage data
    func testTokenSummaryMissingUsageData() {
        let bridge = makeBridge()
        // Result event without usage tokens
        bridge.events = [
            makeResultEvent(totalCostUsd: 0.01)
        ]

        let vm = DebugViewModel(agentBridge: bridge)
        let summary = vm.tokenSummary

        // Should not crash; tokens should be 0, cost should still be extracted
        XCTAssertEqual(summary.totalInputTokens, 0)
        XCTAssertEqual(summary.totalOutputTokens, 0)
        XCTAssertEqual(summary.totalCostUsd, 0.01, accuracy: 0.0001)
    }

    // MARK: - AC#3: toolLogs -- Tool Execution Logs (FR40)

    // [P0] DebugViewModel extracts tool logs from toolContentMap
    func testToolLogsExtractsFromToolContentMap() {
        let bridge = makeBridge()
        let toolUseId = "tu-log-001"
        bridge.events = [
            makeToolUseEvent(toolUseId: toolUseId),
            makeToolResultEvent(toolUseId: toolUseId, content: "Build succeeded")
        ]
        bridge.toolContentMap = [
            toolUseId: ToolContent(
                toolName: "Bash",
                toolUseId: toolUseId,
                input: "{\"command\": \"make\"}",
                output: "Build succeeded",
                isError: false,
                status: .completed,
                elapsedTimeSeconds: 3
            )
        ]

        let vm = DebugViewModel(agentBridge: bridge)
        let logs = vm.toolLogs

        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs[0].toolName, "Bash")
        XCTAssertEqual(logs[0].status, .completed)
        XCTAssertEqual(logs[0].elapsedTimeSeconds, 3)
    }

    // [P0] DebugViewModel returns empty logs for empty session
    func testToolLogsEmptySession() {
        let bridge = makeBridge()
        bridge.events = []
        bridge.toolContentMap = [:]

        let vm = DebugViewModel(agentBridge: bridge)
        let logs = vm.toolLogs

        XCTAssertTrue(logs.isEmpty)
    }

    // [P1] DebugViewModel matches tool timestamps via toolUseId lookup
    func testToolLogsTimestampFromEvents() {
        let bridge = makeBridge()
        let toolUseId = "tu-ts-001"
        let toolTimestamp = Date(timeIntervalSince1970: 1700000000)
        bridge.events = [
            makeToolUseEvent(toolUseId: toolUseId, timestamp: toolTimestamp)
        ]
        bridge.toolContentMap = [
            toolUseId: ToolContent(
                toolName: "Bash",
                toolUseId: toolUseId,
                input: "{\"command\": \"ls\"}",
                output: nil,
                isError: false,
                status: .pending
            )
        ]

        let vm = DebugViewModel(agentBridge: bridge)
        let logs = vm.toolLogs

        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs[0].timestamp, toolTimestamp,
                        "Tool log should carry timestamp from matching toolUse event")
    }

    // [P0] DebugViewModel includes tool status for each log entry
    func testToolLogsStatusCompletedFailedRunning() {
        let bridge = makeBridge()
        bridge.events = [
            makeToolUseEvent(toolUseId: "tu-s1"),
            makeToolUseEvent(toolUseId: "tu-s2"),
            makeToolUseEvent(toolUseId: "tu-s3")
        ]
        bridge.toolContentMap = [
            "tu-s1": ToolContent(
                toolName: "Bash", toolUseId: "tu-s1",
                input: "", output: "ok", isError: false, status: .completed
            ),
            "tu-s2": ToolContent(
                toolName: "Grep", toolUseId: "tu-s2",
                input: "", output: "error", isError: true, status: .failed
            ),
            "tu-s3": ToolContent(
                toolName: "Read", toolUseId: "tu-s3",
                input: "", output: nil, isError: false, status: .running, elapsedTimeSeconds: 5
            )
        ]

        let vm = DebugViewModel(agentBridge: bridge)
        let logs = vm.toolLogs

        XCTAssertEqual(logs.count, 3)
        let statuses = logs.map(\.status)
        XCTAssertTrue(statuses.contains(.completed))
        XCTAssertTrue(statuses.contains(.failed))
        XCTAssertTrue(statuses.contains(.running))
    }

    // [P2] DebugViewModel truncates long result output in tool logs
    func testToolLogsTruncatesLongOutput() {
        let bridge = makeBridge()
        let toolUseId = "tu-trunc-001"
        let longOutput = String(repeating: "x", count: 500)
        bridge.events = [makeToolUseEvent(toolUseId: toolUseId)]
        bridge.toolContentMap = [
            toolUseId: ToolContent(
                toolName: "Bash",
                toolUseId: toolUseId,
                input: "{\"command\": \"cat large.log\"}",
                output: longOutput,
                isError: false,
                status: .completed
            )
        ]

        let vm = DebugViewModel(agentBridge: bridge)
        let logs = vm.toolLogs

        XCTAssertEqual(logs.count, 1)
        XCTAssertLessThanOrEqual(logs[0].resultPreview.count, 200,
                                  "Result preview should be truncated to ~200 chars")
    }
}
