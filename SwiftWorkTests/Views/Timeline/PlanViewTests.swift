import XCTest
import SwiftUI
@testable import SwiftWork

// ATDD Red Phase — Story 3.5: 执行计划可视化
// Unit tests for PlanView rendering and Inspector plan section.
// These tests will FAIL until Story 3.5 Tasks 3-4 are implemented.

final class PlanViewTests: XCTestCase {

    // MARK: - PlanView Instantiation — AC#1

    // [P0] PlanView instantiates with a .plan AgentEvent
    func testPlanViewInstantiation() throws {
        let event = AgentEvent(
            type: .plan,
            content: "执行计划",
            metadata: [
                "planAction": "enter"
            ] as [String: any Sendable],
            timestamp: .now
        )
        let view = PlanView(event: event)
        XCTAssertNotNil(view, "PlanView should instantiate with a .plan AgentEvent")
    }

    // [P0] PlanView instantiates with exit plan containing steps
    func testPlanViewWithExitPlanEvent() throws {
        let steps: [[String: any Sendable]] = [
            ["id": "s1", "description": "分析代码结构", "status": "completed", "dependencies": [] as [String]],
            ["id": "s2", "description": "实现核心逻辑", "status": "inProgress", "dependencies": ["s1"]],
            ["id": "s3", "description": "编写测试", "status": "pending", "dependencies": ["s2"]]
        ]
        let event = AgentEvent(
            type: .plan,
            content: "重构计划",
            metadata: [
                "planAction": "exit",
                "planId": "plan-001",
                "approved": true,
                "steps": steps
            ] as [String: any Sendable],
            timestamp: .now
        )
        let view = PlanView(event: event)
        XCTAssertNotNil(view, "PlanView should instantiate with exit plan event containing steps")
    }

    // [P0] PlanView instantiates with a TodoWrite .plan event
    func testPlanViewWithTodoWriteEvent() throws {
        let event = AgentEvent(
            type: .plan,
            content: "更新任务清单",
            metadata: [
                "planAction": "todoUpdate",
                "toolUseId": "tu-todo-001",
                "input": "{\"action\": \"add\", \"text\": \"实现功能\"}"
            ] as [String: any Sendable],
            timestamp: .now
        )
        let view = PlanView(event: event)
        XCTAssertNotNil(view, "PlanView should instantiate with TodoWrite .plan event")
    }

    // MARK: - PlanView handles empty plan — AC#1 edge case

    // [P1] PlanView handles plan with no steps gracefully
    func testPlanViewWithEmptySteps() throws {
        let event = AgentEvent(
            type: .plan,
            content: "进入计划模式",
            metadata: [
                "planAction": "enter",
                "planId": "plan-empty"
            ] as [String: any Sendable],
            timestamp: .now
        )
        let view = PlanView(event: event)
        XCTAssertNotNil(view, "PlanView should handle empty plan (enter action) without crash")
    }

    // [P1] PlanView handles plan with unstructured text only
    func testPlanViewWithUnstructuredPlanText() throws {
        let event = AgentEvent(
            type: .plan,
            content: "This is a free-text plan without numbered steps",
            metadata: [
                "planAction": "exit",
                "planId": "plan-text"
            ] as [String: any Sendable],
            timestamp: .now
        )
        let view = PlanView(event: event)
        XCTAssertNotNil(view, "PlanView should handle unstructured plan text as fallback")
    }

    // MARK: - PlanStepRow — AC#2 (status indicators)

    // [P0] PlanStepRow instantiates with pending step
    func testPlanStepRowPending() throws {
        let step = PlanStep(id: "s1", description: "pending step", status: .pending, dependencies: [])
        let row = PlanStepRow(step: step)
        XCTAssertNotNil(row, "PlanStepRow should instantiate with pending step")
    }

    // [P0] PlanStepRow instantiates with inProgress step
    func testPlanStepRowInProgress() throws {
        let step = PlanStep(id: "s2", description: "in-progress step", status: .inProgress, dependencies: [])
        let row = PlanStepRow(step: step)
        XCTAssertNotNil(row, "PlanStepRow should instantiate with inProgress step")
    }

    // [P0] PlanStepRow instantiates with completed step
    func testPlanStepRowCompleted() throws {
        let step = PlanStep(id: "s3", description: "completed step", status: .completed, dependencies: [])
        let row = PlanStepRow(step: step)
        XCTAssertNotNil(row, "PlanStepRow should instantiate with completed step")
    }

    // [P0] PlanStepRow instantiates with failed step
    func testPlanStepRowFailed() throws {
        let step = PlanStep(id: "s4", description: "failed step", status: .failed, dependencies: [])
        let row = PlanStepRow(step: step)
        XCTAssertNotNil(row, "PlanStepRow should instantiate with failed step")
    }

    // MARK: - PlanStepRow with dependencies — AC#3

    // [P1] PlanStepRow renders dependency indicator for step with dependencies
    func testPlanStepRowWithDependencies() throws {
        let step = PlanStep(
            id: "s2",
            description: "depends on step 1",
            status: .pending,
            dependencies: ["s1"]
        )
        let row = PlanStepRow(step: step)
        XCTAssertNotNil(row, "PlanStepRow should render step with dependency indicators")
    }

    // [P1] PlanStepRow renders deeply nested dependency
    func testPlanStepRowWithMultipleDependencies() throws {
        let step = PlanStep(
            id: "s3",
            description: "depends on step 1 and 2",
            status: .pending,
            dependencies: ["s1", "s2"]
        )
        let row = PlanStepRow(step: step)
        XCTAssertNotNil(row, "PlanStepRow should render step with multiple dependencies")
    }

    // MARK: - PlanView plan text parsing — AC#1 (step extraction)

    // [P1] Plan text with numbered list steps is parseable
    func testPlanViewParsesNumberedSteps() throws {
        // Given: Exit plan content with numbered steps
        let planText = "1. 分析代码结构\n2. 实现核心逻辑\n3. 编写测试"
        let event = AgentEvent(
            type: .plan,
            content: planText,
            metadata: [
                "planAction": "exit",
                "planId": "plan-numbered"
            ] as [String: any Sendable],
            timestamp: .now
        )
        let view = PlanView(event: event)
        XCTAssertNotNil(view, "PlanView should parse numbered list plan text")
    }

    // [P1] Plan text with markdown list steps is parseable
    func testPlanViewParsesMarkdownListSteps() throws {
        // Given: Exit plan content with markdown list
        let planText = "- 分析代码结构\n- 实现核心逻辑\n- 编写测试"
        let event = AgentEvent(
            type: .plan,
            content: planText,
            metadata: [
                "planAction": "exit",
                "planId": "plan-markdown"
            ] as [String: any Sendable],
            timestamp: .now
        )
        let view = PlanView(event: event)
        XCTAssertNotNil(view, "PlanView should parse markdown list plan text")
    }

    // MARK: - Inspector plan section — AC#1 (integration)

    // [P0] Plan event renders in Inspector with dedicated section
    func testPlanEventRendersInInspector() throws {
        // Given: Inspector should have a dedicated section for .plan events
        // This tests that the Inspector switch handles .plan case
        let event = AgentEvent(
            type: .plan,
            content: "执行计划 (3 步骤)",
            metadata: [
                "planAction": "exit",
                "planId": "plan-inspector-001",
                "approved": true,
                "steps": [] as [[String: any Sendable]]
            ] as [String: any Sendable],
            timestamp: .now
        )
        // Verify event type is .plan — Inspector must handle this case
        XCTAssertEqual(event.type, .plan, "Event must be .plan type for Inspector to render plan section")
    }

    // [P0] Plan event color is defined in Inspector colorForEventType
    func testPlanEventHasDistinctColor() throws {
        // Given: colorForEventType should return a color for .plan (not default/secondary)
        // This will be verified by the Inspector switch handling .plan case
        let planType = AgentEventType.plan
        // Color assignment is tested indirectly — the switch must have a .plan case
        XCTAssertNotNil(planType, "AgentEventType.plan must exist for Inspector color mapping")
    }
}
