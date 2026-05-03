import XCTest
@testable import SwiftWork

// ATDD Red Phase — Story 3.5: 执行计划可视化
// Unit tests for PlanStep, PlanStepStatus, and PlanData data models.
// These tests will FAIL until Story 3.5 Task 1 is implemented.

final class PlanStepModelTests: XCTestCase {

    // MARK: - PlanStepStatus — AC#2 (step status indicators)

    // [P0] PlanStepStatus has all required cases
    func testPlanStepStatusHasAllCases() throws {
        // Given: PlanStepStatus enum should define pending, inProgress, completed, failed
        let allCases: [PlanStepStatus] = [.pending, .inProgress, .completed, .failed]
        XCTAssertEqual(allCases.count, 4, "PlanStepStatus should have exactly 4 cases")
    }

    // [P0] PlanStepStatus conforms to Sendable
    func testPlanStepStatusIsSendable() throws {
        // Given: PlanStepStatus must be Sendable for safe concurrency
        let status: PlanStepStatus = .pending
        // This compiles only if PlanStepStatus: Sendable
        _ = status as any Sendable
    }

    // [P0] PlanStepStatus conforms to Equatable
    func testPlanStepStatusEquality() throws {
        // Given: PlanStepStatus should support equality comparison
        XCTAssertEqual(PlanStepStatus.pending, PlanStepStatus.pending)
        XCTAssertNotEqual(PlanStepStatus.pending, PlanStepStatus.inProgress)
        XCTAssertNotEqual(PlanStepStatus.completed, PlanStepStatus.failed)
    }

    // [P0] PlanStepStatus conforms to String (raw value)
    func testPlanStepStatusRawValue() throws {
        // Given: PlanStepStatus raw values should be lowercase strings
        // pending → "pending", inProgress → "inProgress", etc.
        XCTAssertEqual(PlanStepStatus.pending.rawValue, "pending")
        XCTAssertEqual(PlanStepStatus.inProgress.rawValue, "inProgress")
        XCTAssertEqual(PlanStepStatus.completed.rawValue, "completed")
        XCTAssertEqual(PlanStepStatus.failed.rawValue, "failed")
    }

    // MARK: - PlanStep — AC#1 (step list display), AC#3 (dependency)

    // [P0] PlanStep initializes with all required properties
    func testPlanStepInitialization() throws {
        // Given: PlanStep should have id, description, status, dependencies
        let step = PlanStep(
            id: "step-1",
            description: "分析代码结构",
            status: .pending,
            dependencies: []
        )
        XCTAssertEqual(step.id, "step-1")
        XCTAssertEqual(step.description, "分析代码结构")
        XCTAssertEqual(step.status, .pending)
        XCTAssertTrue(step.dependencies.isEmpty)
    }

    // [P0] PlanStep conforms to Identifiable
    func testPlanStepIsIdentifiable() throws {
        // Given: PlanStep.id is the identifying key
        let step = PlanStep(id: "unique-id", description: "test", status: .pending, dependencies: [])
        XCTAssertEqual(step.id, "unique-id")
    }

    // [P0] PlanStep conforms to Sendable
    func testPlanStepIsSendable() throws {
        // Given: PlanStep must be Sendable for concurrent access
        let step = PlanStep(id: "s1", description: "test", status: .completed, dependencies: [])
        _ = step as any Sendable
    }

    // [P1] PlanStep with dependencies — AC#3
    func testPlanStepWithDependencies() throws {
        // Given: A step can depend on other steps by ID
        let step = PlanStep(
            id: "step-3",
            description: "编写测试",
            status: .pending,
            dependencies: ["step-1", "step-2"]
        )
        XCTAssertEqual(step.dependencies.count, 2)
        XCTAssertEqual(step.dependencies[0], "step-1")
        XCTAssertEqual(step.dependencies[1], "step-2")
    }

    // [P1] PlanStep status transition reflects execution progress — AC#2
    func testPlanStepStatusTransition() throws {
        // Given: Steps progress through status lifecycle
        // pending → inProgress → completed (or failed)
        let step1 = PlanStep(id: "s1", description: "first", status: .pending, dependencies: [])
        XCTAssertEqual(step1.status, .pending)

        let step2 = PlanStep(id: "s1", description: "first", status: .inProgress, dependencies: [])
        XCTAssertEqual(step2.status, .inProgress)

        let step3 = PlanStep(id: "s1", description: "first", status: .completed, dependencies: [])
        XCTAssertEqual(step3.status, .completed)

        let step4 = PlanStep(id: "s1", description: "first", status: .failed, dependencies: [])
        XCTAssertEqual(step4.status, .failed)
    }

    // MARK: - PlanData — AC#1 (plan content), AC#3 (dependency structure)

    // [P0] PlanData initializes with plan metadata and step list
    func testPlanDataInitialization() throws {
        // Given: PlanData aggregates plan metadata and ordered steps
        let steps = [
            PlanStep(id: "s1", description: "步骤 1", status: .pending, dependencies: []),
            PlanStep(id: "s2", description: "步骤 2", status: .pending, dependencies: ["s1"])
        ]
        let planData = PlanData(
            planId: "plan-001",
            content: "重构代码的计划",
            approved: true,
            steps: steps
        )
        XCTAssertEqual(planData.planId, "plan-001")
        XCTAssertEqual(planData.content, "重构代码的计划")
        XCTAssertTrue(planData.approved)
        XCTAssertEqual(planData.steps.count, 2)
    }

    // [P0] PlanData conforms to Sendable
    func testPlanDataIsSendable() throws {
        // Given: PlanData must be Sendable for use in AgentEvent.metadata
        let planData = PlanData(planId: "p1", content: nil, approved: false, steps: [])
        _ = planData as any Sendable
    }

    // [P1] PlanData with empty steps list
    func testPlanDataWithEmptySteps() throws {
        // Given: Plan can have no parsed steps (unstructured plan text)
        let planData = PlanData(planId: "p2", content: "自由文本计划", approved: false, steps: [])
        XCTAssertTrue(planData.steps.isEmpty)
        XCTAssertEqual(planData.content, "自由文本计划")
    }

    // [P1] PlanData with nil content (plan steps only)
    func testPlanDataWithNilContent() throws {
        // Given: Plan may have steps parsed from input but no free-text content
        let steps = [PlanStep(id: "s1", description: "do thing", status: .pending, dependencies: [])]
        let planData = PlanData(planId: "p3", content: nil, approved: true, steps: steps)
        XCTAssertNil(planData.content)
        XCTAssertEqual(planData.steps.count, 1)
    }

    // MARK: - PlanData step dependency graph — AC#3

    // [P1] PlanData steps form a dependency chain
    func testPlanDataDependencyChain() throws {
        // Given: Steps form a sequential dependency chain
        let steps = [
            PlanStep(id: "s1", description: "step 1", status: .completed, dependencies: []),
            PlanStep(id: "s2", description: "step 2", status: .inProgress, dependencies: ["s1"]),
            PlanStep(id: "s3", description: "step 3", status: .pending, dependencies: ["s2"])
        ]
        let planData = PlanData(planId: "chain", content: nil, approved: true, steps: steps)

        // Verify chain: s1 → s2 → s3
        XCTAssertTrue(planData.steps[0].dependencies.isEmpty)
        XCTAssertEqual(planData.steps[1].dependencies, ["s1"])
        XCTAssertEqual(planData.steps[2].dependencies, ["s2"])
    }

    // [P1] PlanData with parallel independent steps (no dependencies)
    func testPlanDataParallelSteps() throws {
        // Given: Steps with no dependencies can run in parallel
        let steps = [
            PlanStep(id: "s1", description: "independent 1", status: .pending, dependencies: []),
            PlanStep(id: "s2", description: "independent 2", status: .pending, dependencies: []),
            PlanStep(id: "s3", description: "independent 3", status: .pending, dependencies: [])
        ]
        let planData = PlanData(planId: "parallel", content: nil, approved: true, steps: steps)

        // All steps have empty dependencies
        XCTAssertTrue(planData.steps.allSatisfy { $0.dependencies.isEmpty })
    }
}
