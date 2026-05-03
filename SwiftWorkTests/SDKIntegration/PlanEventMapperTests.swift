import XCTest
@testable import SwiftWork
import OpenAgentSDK

// ATDD Red Phase — Story 3.5: 执行计划可视化
// Unit tests for EventMapper plan-related tool mapping.
// These tests will FAIL until Story 3.5 Task 2 is implemented.

final class PlanEventMapperTests: XCTestCase {

    // MARK: - AC#1 — EnterPlanMode toolUse → .plan event

    // [P0] EnterPlanMode toolUse maps to AgentEvent(type: .plan)
    func testMapEnterPlanModeToolUse() throws {
        // Given: SDK sends .toolUse with toolName = "EnterPlanMode"
        let data = SDKMessage.ToolUseData(
            toolName: "EnterPlanMode",
            toolUseId: "tu-plan-001",
            input: "{}"
        )
        let message = SDKMessage.toolUse(data)

        // When: EventMapper maps the message
        let event = EventMapper.map(message)

        // Then: Event type should be .plan (not .toolUse)
        XCTAssertEqual(event.type, .plan, "EnterPlanMode should map to .plan event type")
    }

    // [P0] EnterPlanMode event has planAction = "enter" in metadata
    func testMapEnterPlanModeMetadata() throws {
        let data = SDKMessage.ToolUseData(
            toolName: "EnterPlanMode",
            toolUseId: "tu-plan-002",
            input: "{}"
        )
        let message = SDKMessage.toolUse(data)
        let event = EventMapper.map(message)

        XCTAssertEqual(event.metadata["planAction"] as? String, "enter")
    }

    // [P0] EnterPlanMode event preserves toolUseId
    func testMapEnterPlanModePreservesToolUseId() throws {
        let data = SDKMessage.ToolUseData(
            toolName: "EnterPlanMode",
            toolUseId: "tu-plan-enter-001",
            input: "{}"
        )
        let message = SDKMessage.toolUse(data)
        let event = EventMapper.map(message)

        XCTAssertEqual(event.metadata["toolUseId"] as? String, "tu-plan-enter-001")
    }

    // MARK: - AC#1 — ExitPlanMode toolUse → .plan event

    // [P0] ExitPlanMode toolUse maps to AgentEvent(type: .plan)
    func testMapExitPlanModeToolUse() throws {
        let planContent = "1. 分析代码结构\n2. 实现核心逻辑\n3. 编写测试"
        let inputJSON = "{\"plan\": \"\(planContent)\", \"approved\": true}"
        let data = SDKMessage.ToolUseData(
            toolName: "ExitPlanMode",
            toolUseId: "tu-plan-003",
            input: inputJSON
        )
        let message = SDKMessage.toolUse(data)
        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .plan, "ExitPlanMode should map to .plan event type")
    }

    // [P0] ExitPlanMode event has planAction = "exit" in metadata
    func testMapExitPlanModeMetadataAction() throws {
        let inputJSON = "{\"plan\": \"步骤列表\", \"approved\": true}"
        let data = SDKMessage.ToolUseData(
            toolName: "ExitPlanMode",
            toolUseId: "tu-plan-004",
            input: inputJSON
        )
        let message = SDKMessage.toolUse(data)
        let event = EventMapper.map(message)

        XCTAssertEqual(event.metadata["planAction"] as? String, "exit")
    }

    // [P0] ExitPlanMode event carries plan content
    func testMapExitPlanModeContent() throws {
        let planText = "1. 分析代码结构\\n2. 实现核心逻辑"
        let inputJSON = "{\"plan\": \"\(planText)\", \"approved\": true}"
        let data = SDKMessage.ToolUseData(
            toolName: "ExitPlanMode",
            toolUseId: "tu-plan-005",
            input: inputJSON
        )
        let message = SDKMessage.toolUse(data)
        let event = EventMapper.map(message)

        // Content should contain the plan text
        XCTAssertTrue(event.content.contains("分析代码结构") || event.content.contains("plan"),
                       "ExitPlanMode event content should include plan information")
    }

    // [P0] ExitPlanMode event carries approved status
    func testMapExitPlanModeApprovedStatus() throws {
        let inputJSON = "{\"plan\": \"some plan\", \"approved\": true}"
        let data = SDKMessage.ToolUseData(
            toolName: "ExitPlanMode",
            toolUseId: "tu-plan-006",
            input: inputJSON
        )
        let message = SDKMessage.toolUse(data)
        let event = EventMapper.map(message)

        // Metadata should include approved status
        let approved = event.metadata["approved"]
        XCTAssertNotNil(approved, "ExitPlanMode should include approved status in metadata")
    }

    // [P1] ExitPlanMode with unapproved plan
    func testMapExitPlanModeUnapproved() throws {
        let inputJSON = "{\"plan\": \"draft plan\", \"approved\": false}"
        let data = SDKMessage.ToolUseData(
            toolName: "ExitPlanMode",
            toolUseId: "tu-plan-007",
            input: inputJSON
        )
        let message = SDKMessage.toolUse(data)
        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .plan)
    }

    // MARK: - AC#1 — TodoWrite toolUse → .plan event

    // [P0] TodoWrite toolUse maps to AgentEvent(type: .plan)
    func testMapTodoWriteToolUse() throws {
        let inputJSON = "{\"action\": \"add\", \"text\": \"实现功能 X\", \"id\": \"todo-1\"}"
        let data = SDKMessage.ToolUseData(
            toolName: "TodoWrite",
            toolUseId: "tu-todo-001",
            input: inputJSON
        )
        let message = SDKMessage.toolUse(data)
        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .plan, "TodoWrite should map to .plan event type")
    }

    // [P0] TodoWrite event has planAction = "todoUpdate" in metadata
    func testMapTodoWriteMetadataAction() throws {
        let inputJSON = "{\"action\": \"add\", \"text\": \"实现功能 X\", \"id\": \"todo-1\"}"
        let data = SDKMessage.ToolUseData(
            toolName: "TodoWrite",
            toolUseId: "tu-todo-002",
            input: inputJSON
        )
        let message = SDKMessage.toolUse(data)
        let event = EventMapper.map(message)

        XCTAssertEqual(event.metadata["planAction"] as? String, "todoUpdate")
    }

    // [P1] TodoWrite event carries todo operation info
    func testMapTodoWriteCarriesInput() throws {
        let inputJSON = "{\"action\": \"toggle\", \"id\": \"todo-3\"}"
        let data = SDKMessage.ToolUseData(
            toolName: "TodoWrite",
            toolUseId: "tu-todo-003",
            input: inputJSON
        )
        let message = SDKMessage.toolUse(data)
        let event = EventMapper.map(message)

        // Should preserve the input data for PlanView to consume
        XCTAssertNotNil(event.metadata["input"], "TodoWrite .plan event should carry input data")
    }

    // MARK: - Regression — non-plan toolUse still maps to .toolUse

    // [P0] Regular toolUse (not Plan tools) still maps to .toolUse
    func testNonPlanToolUseStillMapsToToolUse() throws {
        let data = SDKMessage.ToolUseData(
            toolName: "Bash",
            toolUseId: "tu-bash-001",
            input: "{\"command\": \"ls -la\"}"
        )
        let message = SDKMessage.toolUse(data)
        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .toolUse, "Non-plan toolUse should still map to .toolUse")
    }

    // [P0] FileRead toolUse still maps to .toolUse
    func testFileReadToolUseStillMapsToToolUse() throws {
        let data = SDKMessage.ToolUseData(
            toolName: "FileRead",
            toolUseId: "tu-read-001",
            input: "{\"path\": \"/tmp/test.swift\"}"
        )
        let message = SDKMessage.toolUse(data)
        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .toolUse, "FileRead should still map to .toolUse")
    }

    // [P0] toolResult for plan tools still maps to .toolResult
    func testPlanToolResultMapsToToolResult() throws {
        // Plan tool result events (.toolResult) are NOT remapped — only .toolUse is remapped
        let data = SDKMessage.ToolResultData(
            toolUseId: "tu-plan-001",
            content: "Entered plan mode",
            isError: false
        )
        let message = SDKMessage.toolResult(data)
        let event = EventMapper.map(message)

        // toolResult for plan tools still maps to .toolResult (EventMapper is stateless)
        XCTAssertEqual(event.type, .toolResult, "toolResult should still map to .toolResult regardless of toolName")
    }

    // MARK: - AgentEventType regression

    // [P0] AgentEventType includes .plan case
    func testAgentEventTypeIncludesPlan() throws {
        // Given: AgentEventType should have a .plan case after Story 3.5
        let planType = AgentEventType.plan
        XCTAssertEqual(planType.rawValue, "plan")
    }

    // [P0] AgentEventType.plan is included in CaseIterable allCases
    func testAgentEventTypePlanInAllCases() throws {
        // Given: .plan must be in CaseIterable.allCases for exhaustive switch coverage
        let allCases = AgentEventType.allCases
        XCTAssertTrue(allCases.contains(.plan), "AgentEventType.allCases must include .plan")
    }
}
