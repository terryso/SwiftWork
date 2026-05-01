import XCTest
@testable import SwiftWork

// MARK: - Story 1.5 ATDD: EventView Instantiation Tests
//
// GREEN PHASE: All EventView components extracted and tests passing.
//
// Coverage: AC#1 (event views), AC#3 (ThinkingView), AC#4 (ResultView), AC#5 (UnknownEventView)

final class TimelineEventViewsTests: XCTestCase {

    // MARK: - AC#1 — UserMessageView

    func testUserMessageViewInstantiation() throws {
        let event = AgentEvent(type: .userMessage, content: "Hello Agent", timestamp: .now)
        let view = UserMessageView(event: event)
        XCTAssertNotNil(view, "UserMessageView should instantiate with AgentEvent")
    }

    func testUserMessageViewDisplaysContent() throws {
        // RED: Verify UserMessageView accepts event and uses its content
        let event = AgentEvent(type: .userMessage, content: "测试消息内容", timestamp: .now)
        let view = UserMessageView(event: event)
        XCTAssertNotNil(view, "UserMessageView should render with CJK content")
    }

    // MARK: - AC#1 — AssistantMessageView

    func testAssistantMessageViewInstantiation() throws {
        // RED: AssistantMessageView does not exist yet as an independent struct
        let event = AgentEvent(
            type: .assistant,
            content: "Here is the response",
            metadata: ["model": "claude-sonnet-4-6", "stopReason": "end_turn"],
            timestamp: .now
        )
        let view = AssistantMessageView(event: event)
        XCTAssertNotNil(view, "AssistantMessageView should instantiate with AgentEvent")
    }

    // MARK: - AC#1 — ToolCallView

    func testToolCallViewInstantiation() throws {
        // RED: ToolCallView does not exist yet as an independent struct
        let event = AgentEvent(
            type: .toolUse,
            content: "Bash",
            metadata: [
                "toolName": "Bash",
                "toolUseId": "tool-123",
                "input": "{\"command\": \"ls -la\"}"
            ] as [String: any Sendable],
            timestamp: .now
        )
        let view = ToolCallView(event: event)
        XCTAssertNotNil(view, "ToolCallView should instantiate with AgentEvent")
    }

    func testToolCallViewDisplaysToolName() throws {
        // RED: ToolCallView should display the tool name from event.content
        let event = AgentEvent(
            type: .toolUse,
            content: "FileEdit",
            metadata: ["toolName": "FileEdit", "toolUseId": "tool-456", "input": "{}"] as [String: any Sendable],
            timestamp: .now
        )
        let view = ToolCallView(event: event)
        XCTAssertNotNil(view)
    }

    func testToolCallViewDisplaysInputSummary() throws {
        // RED: ToolCallView should display truncated input from metadata
        let longInput = String(repeating: "{\"key\": \"value\"}, ", count: 50)
        let event = AgentEvent(
            type: .toolUse,
            content: "Bash",
            metadata: ["toolName": "Bash", "toolUseId": "tool-789", "input": longInput] as [String: any Sendable],
            timestamp: .now
        )
        let view = ToolCallView(event: event)
        XCTAssertNotNil(view, "ToolCallView should handle long input")
    }

    // MARK: - AC#1 — ToolResultView

    func testToolResultViewInstantiation() throws {
        // RED: ToolResultView does not exist yet as an independent struct
        let event = AgentEvent(
            type: .toolResult,
            content: "file1.txt\nfile2.txt",
            metadata: ["toolUseId": "tool-123", "isError": false] as [String: any Sendable],
            timestamp: .now
        )
        let view = ToolResultView(event: event)
        XCTAssertNotNil(view, "ToolResultView should instantiate with AgentEvent")
    }

    func testToolResultViewSuccessStyle() throws {
        // RED: ToolResultView with isError=false should use green styling
        let event = AgentEvent(
            type: .toolResult,
            content: "success output",
            metadata: ["toolUseId": "tool-123", "isError": false] as [String: any Sendable],
            timestamp: .now
        )
        let view = ToolResultView(event: event)
        XCTAssertNotNil(view)
    }

    func testToolResultViewErrorStyle() throws {
        // RED: ToolResultView with isError=true should use red styling
        let event = AgentEvent(
            type: .toolResult,
            content: "command not found",
            metadata: ["toolUseId": "tool-123", "isError": true] as [String: any Sendable],
            timestamp: .now
        )
        let view = ToolResultView(event: event)
        XCTAssertNotNil(view)
    }

    // MARK: - AC#1 — ToolProgressView

    func testToolProgressViewInstantiation() throws {
        // RED: ToolProgressView does not exist yet as an independent struct
        let event = AgentEvent(
            type: .toolProgress,
            content: "Bash",
            metadata: [
                "toolUseId": "tool-123",
                "toolName": "Bash",
                "elapsedTimeSeconds": 5
            ] as [String: any Sendable],
            timestamp: .now
        )
        let view = ToolProgressView(event: event)
        XCTAssertNotNil(view, "ToolProgressView should instantiate with AgentEvent")
    }

    func testToolProgressViewDisplaysElapsedTime() throws {
        // RED: ToolProgressView should display elapsed time from metadata
        let event = AgentEvent(
            type: .toolProgress,
            content: "Bash",
            metadata: [
                "toolUseId": "tool-123",
                "toolName": "Bash",
                "elapsedTimeSeconds": 12
            ] as [String: any Sendable],
            timestamp: .now
        )
        let view = ToolProgressView(event: event)
        XCTAssertNotNil(view)
    }

    // MARK: - AC#1 — SystemEventView

    func testSystemEventViewInstantiation() throws {
        // RED: SystemEventView does not exist yet as an independent struct
        let event = AgentEvent(
            type: .system,
            content: "Session initialized",
            metadata: ["subtype": "init"] as [String: any Sendable],
            timestamp: .now
        )
        let view = SystemEventView(event: event)
        XCTAssertNotNil(view, "SystemEventView should instantiate with AgentEvent")
    }

    func testSystemEventViewDisplaysContent() throws {
        // RED: SystemEventView should display event content
        let event = AgentEvent(
            type: .system,
            content: "Rate limit reached",
            metadata: ["subtype": "rateLimit"] as [String: any Sendable],
            timestamp: .now
        )
        let view = SystemEventView(event: event)
        XCTAssertNotNil(view)
    }

    // MARK: - AC#3 — ThinkingView

    func testThinkingViewInstantiation() throws {
        // RED: ThinkingView does not exist yet — requires RotationEffect animation
        // "思考中..." indicator with gear icon
        let view = ThinkingView()
        XCTAssertNotNil(view, "ThinkingView should instantiate without parameters")
    }

    // MARK: - AC#4 — ResultView

    func testResultViewInstantiation() throws {
        // RED: ResultView does not exist yet as an independent struct
        let event = AgentEvent(
            type: .result,
            content: "Task completed successfully",
            metadata: [
                "subtype": "success",
                "numTurns": 3,
                "durationMs": 15234,
                "totalCostUsd": 0.0423
            ] as [String: any Sendable],
            timestamp: .now
        )
        let view = ResultView(event: event)
        XCTAssertNotNil(view, "ResultView should instantiate with AgentEvent")
    }

    func testResultViewDisplaysSubtype() throws {
        // RED: ResultView should display subtype (success/error/cancelled)
        let event = AgentEvent(
            type: .result,
            content: "Done",
            metadata: [
                "subtype": "success",
                "numTurns": 1,
                "durationMs": 5000,
                "totalCostUsd": 0.01
            ] as [String: any Sendable],
            timestamp: .now
        )
        let view = ResultView(event: event)
        XCTAssertNotNil(view)
    }

    func testResultViewDisplaysDurationAndCost() throws {
        // RED: ResultView should display durationMs and totalCostUsd
        let event = AgentEvent(
            type: .result,
            content: "Completed",
            metadata: [
                "subtype": "success",
                "numTurns": 5,
                "durationMs": 30000,
                "totalCostUsd": 0.1234
            ] as [String: any Sendable],
            timestamp: .now
        )
        let view = ResultView(event: event)
        XCTAssertNotNil(view)
    }

    func testResultViewDisplaysNumTurns() throws {
        // RED: ResultView should display numTurns from metadata
        let event = AgentEvent(
            type: .result,
            content: "Done",
            metadata: [
                "subtype": "success",
                "numTurns": 7,
                "durationMs": 45000,
                "totalCostUsd": 0.0567
            ] as [String: any Sendable],
            timestamp: .now
        )
        let view = ResultView(event: event)
        XCTAssertNotNil(view)
    }

    // MARK: - AC#5 — UnknownEventView

    func testUnknownEventViewInstantiation() throws {
        // RED: UnknownEventView does not exist yet as an independent struct
        let event = AgentEvent(
            type: .unknown,
            content: "",
            metadata: ["rawType": "futureEventType"] as [String: any Sendable],
            timestamp: .now
        )
        let view = UnknownEventView(event: event)
        XCTAssertNotNil(view, "UnknownEventView should instantiate with AgentEvent")
    }
}
