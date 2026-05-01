import XCTest
@testable import SwiftWork
import OpenAgentSDK

// ATDD Red Phase — Story 1.4: 消息输入与 Agent 执行
// Unit tests for EventMapper: SDKMessage → AgentEvent mapping.
// These tests will FAIL until EventMapper is implemented.

final class EventMapperTests: XCTestCase {

    // MARK: - AC#1 — partialMessage mapping

    // [P0] .partialMessage maps to AgentEvent(type: .partialMessage)
    func testMapPartialMessage() throws {
        let data = SDKMessage.PartialData(text: "Hello, ")
        let message = SDKMessage.partialMessage(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .partialMessage)
        XCTAssertEqual(event.content, "Hello, ")
    }

    // [P0] .partialMessage preserves text with parentToolUseId
    func testMapPartialMessageWithParentToolUseId() throws {
        let data = SDKMessage.PartialData(text: "thinking...", parentToolUseId: "tool-123")
        let message = SDKMessage.partialMessage(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .partialMessage)
        XCTAssertEqual(event.content, "thinking...")
    }

    // MARK: - AC#1 — assistant mapping

    // [P0] .assistant maps to AgentEvent(type: .assistant) with model and stopReason
    func testMapAssistant() throws {
        let data = SDKMessage.AssistantData(text: "Here is the answer.", model: "claude-sonnet-4-6", stopReason: "end_turn")
        let message = SDKMessage.assistant(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .assistant)
        XCTAssertEqual(event.content, "Here is the answer.")
        XCTAssertEqual(event.metadata["model"] as? String, "claude-sonnet-4-6")
        XCTAssertEqual(event.metadata["stopReason"] as? String, "end_turn")
    }

    // [P1] .assistant with tool_use stop reason
    func testMapAssistantWithToolUseStopReason() throws {
        let data = SDKMessage.AssistantData(text: "I'll read that file.", model: "claude-sonnet-4-6", stopReason: "tool_use")
        let message = SDKMessage.assistant(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .assistant)
        XCTAssertEqual(event.metadata["stopReason"] as? String, "tool_use")
    }

    // MARK: - AC#1 — toolUse mapping

    // [P0] .toolUse maps to AgentEvent(type: .toolUse) with toolName, toolUseId, input
    func testMapToolUse() throws {
        let data = SDKMessage.ToolUseData(toolName: "FileRead", toolUseId: "tu-001", input: "{\"path\": \"/tmp/test.swift\"}")
        let message = SDKMessage.toolUse(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .toolUse)
        XCTAssertEqual(event.content, "FileRead")
        XCTAssertEqual(event.metadata["toolName"] as? String, "FileRead")
        XCTAssertEqual(event.metadata["toolUseId"] as? String, "tu-001")
        XCTAssertEqual(event.metadata["input"] as? String, "{\"path\": \"/tmp/test.swift\"}")
    }

    // [P1] .toolUse with complex JSON input string
    func testMapToolUseWithComplexInput() throws {
        let jsonInput = "{\"path\": \"/src/main.swift\", \"offset\": 10, \"limit\": 50}"
        let data = SDKMessage.ToolUseData(toolName: "FileEdit", toolUseId: "tu-002", input: jsonInput)
        let message = SDKMessage.toolUse(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .toolUse)
        XCTAssertEqual(event.metadata["input"] as? String, jsonInput)
    }

    // MARK: - AC#1 — toolResult mapping

    // [P0] .toolResult maps to AgentEvent(type: .toolResult) with isError = false
    func testMapToolResultSuccess() throws {
        let data = SDKMessage.ToolResultData(toolUseId: "tu-001", content: "file contents here", isError: false)
        let message = SDKMessage.toolResult(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .toolResult)
        XCTAssertEqual(event.content, "file contents here")
        XCTAssertEqual(event.metadata["toolUseId"] as? String, "tu-001")
        XCTAssertEqual(event.metadata["isError"] as? Bool, false)
    }

    // [P0] .toolResult maps with isError = true
    func testMapToolResultError() throws {
        let data = SDKMessage.ToolResultData(toolUseId: "tu-003", content: "File not found", isError: true)
        let message = SDKMessage.toolResult(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .toolResult)
        XCTAssertEqual(event.metadata["isError"] as? Bool, true)
    }

    // MARK: - AC#1 — toolProgress mapping

    // [P0] .toolProgress maps to AgentEvent(type: .toolProgress)
    func testMapToolProgress() throws {
        let data = SDKMessage.ToolProgressData(toolUseId: "tu-001", toolName: "Bash", elapsedTimeSeconds: 3.5)
        let message = SDKMessage.toolProgress(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .toolProgress)
        XCTAssertEqual(event.content, "Bash")
        XCTAssertEqual(event.metadata["toolUseId"] as? String, "tu-001")
        XCTAssertEqual(event.metadata["toolName"] as? String, "Bash")
    }

    // [P1] .toolProgress with nil elapsedTimeSeconds
    func testMapToolProgressWithNilElapsedTime() throws {
        let data = SDKMessage.ToolProgressData(toolUseId: "tu-004", toolName: "Grep", elapsedTimeSeconds: nil)
        let message = SDKMessage.toolProgress(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .toolProgress)
        XCTAssertEqual(event.metadata["toolUseId"] as? String, "tu-004")
    }

    // MARK: - AC#1 — result mapping

    // [P0] .result maps to AgentEvent(type: .result) with subtype, numTurns, durationMs, totalCostUsd
    func testMapResultSuccess() throws {
        let data = SDKMessage.ResultData(
            subtype: .success,
            text: "Task completed.",
            usage: nil,
            numTurns: 3,
            durationMs: 5200,
            totalCostUsd: 0.045
        )
        let message = SDKMessage.result(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .result)
        XCTAssertEqual(event.content, "Task completed.")
        XCTAssertEqual(event.metadata["subtype"] as? String, "success")
        XCTAssertEqual(event.metadata["numTurns"] as? Int, 3)
        XCTAssertEqual(event.metadata["durationMs"] as? Int, 5200)
        XCTAssertEqual(event.metadata["totalCostUsd"] as? Double, 0.045)
    }

    // [P0] .result with cancelled subtype (AC#2)
    func testMapResultCancelled() throws {
        let data = SDKMessage.ResultData(
            subtype: .cancelled,
            text: "Cancelled.",
            usage: nil,
            numTurns: 1,
            durationMs: 1200,
            totalCostUsd: 0.01
        )
        let message = SDKMessage.result(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .result)
        XCTAssertEqual(event.metadata["subtype"] as? String, "cancelled")
    }

    // [P1] .result with errorDuringExecution subtype
    func testMapResultErrorDuringExecution() throws {
        let data = SDKMessage.ResultData(
            subtype: .errorDuringExecution,
            text: "An error occurred.",
            usage: nil,
            numTurns: 2,
            durationMs: 3000,
            totalCostUsd: 0.02,
            errors: ["API rate limit exceeded"]
        )
        let message = SDKMessage.result(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .result)
        XCTAssertEqual(event.metadata["subtype"] as? String, "errorDuringExecution")
    }

    // MARK: - AC#1 — system mapping

    // [P0] .system maps to AgentEvent(type: .system) with subtype
    func testMapSystem() throws {
        let data = SDKMessage.SystemData(subtype: .`init`, message: "Session initialized")
        let message = SDKMessage.system(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, AgentEventType.system)
        XCTAssertEqual(event.content, "Session initialized")
        XCTAssertEqual(event.metadata["subtype"] as? String, "init")
    }

    // [P1] .system with status subtype
    func testMapSystemStatus() throws {
        let data = SDKMessage.SystemData(subtype: .status, message: "Compacting...")
        let message = SDKMessage.system(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .system)
        XCTAssertEqual(event.metadata["subtype"] as? String, "status")
    }

    // MARK: - AC#1 — userMessage mapping

    // [P0] .userMessage maps to AgentEvent(type: .userMessage)
    func testMapUserMessage() throws {
        let data = SDKMessage.UserMessageData(message: "Help me refactor this code")
        let message = SDKMessage.userMessage(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .userMessage)
        XCTAssertEqual(event.content, "Help me refactor this code")
    }

    // MARK: - MVP: hook/task/auth mappings → system type

    // [P1] .hookStarted maps to system event
    func testMapHookStarted() throws {
        let data = SDKMessage.HookStartedData(hookId: "h-1", hookName: "PreToolUse", hookEvent: "before")
        let message = SDKMessage.hookStarted(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .system)
        XCTAssertFalse(event.content.isEmpty)
    }

    // [P1] .hookProgress maps to system event
    func testMapHookProgress() throws {
        let data = SDKMessage.HookProgressData(hookId: "h-1", hookName: "PreToolUse", hookEvent: "before", stdout: "progress...")
        let message = SDKMessage.hookProgress(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .system)
    }

    // [P1] .hookResponse maps to system event
    func testMapHookResponse() throws {
        let data = SDKMessage.HookResponseData(hookId: "h-1", hookName: "PreToolUse", hookEvent: "before", output: "done", exitCode: 0)
        let message = SDKMessage.hookResponse(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .system)
    }

    // [P1] .taskStarted maps to system event
    func testMapTaskStarted() throws {
        let data = SDKMessage.TaskStartedData(taskId: "t-1", taskType: "subagent", description: "Research task")
        let message = SDKMessage.taskStarted(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .system)
        XCTAssertFalse(event.content.isEmpty)
    }

    // [P1] .taskProgress maps to system event
    func testMapTaskProgress() throws {
        let data = SDKMessage.TaskProgressData(taskId: "t-1", taskType: "subagent")
        let message = SDKMessage.taskProgress(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .system)
    }

    // MARK: - Remaining event types

    // [P1] .authStatus maps to system event
    func testMapAuthStatus() throws {
        let data = SDKMessage.AuthStatusData(status: "authenticated", message: "Token valid")
        let message = SDKMessage.authStatus(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .system)
        XCTAssertEqual(event.content, "Token valid")
    }

    // [P1] .filesPersisted maps to system event
    func testMapFilesPersisted() throws {
        let data = SDKMessage.FilesPersistedData(filePaths: ["/tmp/a.swift", "/tmp/b.swift"])
        let message = SDKMessage.filesPersisted(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .system)
        XCTAssertFalse(event.content.isEmpty)
    }

    // [P1] .localCommandOutput maps to system event
    func testMapLocalCommandOutput() throws {
        let data = SDKMessage.LocalCommandOutputData(output: "build succeeded", command: "swift build")
        let message = SDKMessage.localCommandOutput(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .system)
        XCTAssertEqual(event.content, "build succeeded")
    }

    // [P1] .promptSuggestion maps to system event
    func testMapPromptSuggestion() throws {
        let data = SDKMessage.PromptSuggestionData(suggestions: ["Try this", "Or that"])
        let message = SDKMessage.promptSuggestion(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .system)
        XCTAssertFalse(event.content.isEmpty)
    }

    // [P1] .toolUseSummary maps to system event
    func testMapToolUseSummary() throws {
        let data = SDKMessage.ToolUseSummaryData(toolUseCount: 5, tools: ["Bash", "FileRead"])
        let message = SDKMessage.toolUseSummary(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .system)
        XCTAssertFalse(event.content.isEmpty)
    }

    // MARK: - AgentEvent properties

    // [P0] Mapped events have unique IDs
    func testMappedEventsHaveUniqueIDs() throws {
        let data = SDKMessage.PartialData(text: "test")
        let event1 = EventMapper.map(.partialMessage(data))
        let event2 = EventMapper.map(.partialMessage(data))

        XCTAssertNotEqual(event1.id, event2.id, "Each mapped event should have a unique ID")
    }

    // [P0] Mapped events have recent timestamps
    func testMappedEventsHaveRecentTimestamps() throws {
        let before = Date.now
        let data = SDKMessage.PartialData(text: "test")
        let event = EventMapper.map(.partialMessage(data))
        let after = Date.now

        XCTAssertGreaterThanOrEqual(event.timestamp, before)
        XCTAssertLessThanOrEqual(event.timestamp, after)
    }
}
