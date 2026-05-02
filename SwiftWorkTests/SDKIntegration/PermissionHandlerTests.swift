import XCTest
@testable import SwiftWork

// Story 3.1: 权限系统实现
// Unit tests for PermissionHandler: permission evaluation engine.

@MainActor
final class PermissionHandlerTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeHandler(globalMode: GlobalPermissionMode = .autoApprove) -> PermissionHandler {
        let handler = PermissionHandler()
        handler.globalMode = globalMode
        return handler
    }

    private func assertApproved(_ decision: PermissionDecision, file: StaticString = #file, line: UInt = #line) {
        if case .approved = decision {
            // expected
        } else {
            XCTFail("Expected .approved, got \(decision)", file: file, line: line)
        }
    }

    private func assertDenied(_ decision: PermissionDecision, file: StaticString = #file, line: UInt = #line) {
        if case .denied = decision {
            // expected
        } else {
            XCTFail("Expected .denied, got \(decision)", file: file, line: line)
        }
    }

    private func assertRequiresApproval(
        _ decision: PermissionDecision,
        expectedToolName: String? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        if case .requiresApproval(let toolName, _, _) = decision {
            if let expected = expectedToolName {
                XCTAssertEqual(toolName, expected, file: file, line: line)
            }
        } else {
            XCTFail("Expected .requiresApproval, got \(decision)", file: file, line: line)
        }
    }

    // MARK: - AC#1: PermissionHandler evaluates tool calls based on global mode

    // [P0] autoApprove mode returns .approved for any tool
    func testAutoApproveReturnsApproved() {
        let handler = makeHandler(globalMode: .autoApprove)
        let decision = handler.evaluate(toolName: "Bash", input: ["command": "rm -rf /tmp/build"])
        assertApproved(decision)
    }

    // [P0] denyAll mode returns .denied for any tool
    func testDenyAllReturnsDenied() {
        let handler = makeHandler(globalMode: .denyAll)
        let decision = handler.evaluate(toolName: "Read", input: ["filePath": "/etc/hosts"])
        assertDenied(decision)
    }

    // [P0] manualReview mode with no matching rules returns .requiresApproval
    func testManualReviewNoRulesReturnsRequiresApproval() {
        let handler = makeHandler(globalMode: .manualReview)
        let decision = handler.evaluate(toolName: "Bash", input: ["command": "ls"])
        assertRequiresApproval(decision, expectedToolName: "Bash")
    }

    // MARK: - AC#1: manualReview mode with persistent rules

    // [P0] manualReview mode matches persistent PermissionRule and returns .approved
    func testManualReviewMatchesPersistentAllowRule() {
        let handler = makeHandler(globalMode: .manualReview)
        handler.addPersistentRule(toolName: "Read", pattern: "*", decision: .allow)

        let decision = handler.evaluate(toolName: "Read", input: ["filePath": "/tmp/test.txt"])
        assertApproved(decision)
    }

    // [P0] manualReview mode matches persistent PermissionRule and returns .denied
    func testManualReviewMatchesPersistentDenyRule() {
        let handler = makeHandler(globalMode: .manualReview)
        handler.addPersistentRule(toolName: "Bash", pattern: "rm *", decision: .deny)

        let decision = handler.evaluate(toolName: "Bash", input: ["command": "rm -rf /tmp/build"])
        assertDenied(decision)
    }

    // [P1] manualReview mode prioritizes persistent rules over session overrides
    func testManualReviewPersistentRuleOverridesSessionOverride() {
        let handler = makeHandler(globalMode: .manualReview)

        // Add persistent deny rule
        handler.addPersistentRule(toolName: "Bash", pattern: "*", decision: .deny)
        // Add session override for allow
        handler.addSessionOverride(toolName: "Bash", decision: .approved)

        // Persistent rule should take precedence
        let decision = handler.evaluate(toolName: "Bash", input: ["command": "ls"])
        assertDenied(decision)
    }

    // MARK: - AC#2: Allow Once (session override)

    // [P0] addSessionOverride allows tool for current session
    func testAddSessionOverrideAllowsToolForSession() {
        let handler = makeHandler(globalMode: .manualReview)

        handler.addSessionOverride(toolName: "Bash", decision: .approved)

        let decision = handler.evaluate(toolName: "Bash", input: ["command": "ls"])
        assertApproved(decision)
    }

    // [P1] Session overrides are scoped to the current session only
    func testSessionOverrideIsSessionScoped() {
        let handler = makeHandler(globalMode: .manualReview)

        handler.addSessionOverride(toolName: "Read", decision: .approved)

        // Verify override is present
        let decision = handler.evaluate(toolName: "Read", input: ["filePath": "/tmp/test.txt"])
        assertApproved(decision)

        // Clear session (simulate new session)
        handler.clearSessionOverrides()

        // Now it should require approval again
        let newDecision = handler.evaluate(toolName: "Read", input: ["filePath": "/tmp/test.txt"])
        assertRequiresApproval(newDecision)
    }

    // MARK: - AC#3: Always Allow (persistent rule)

    // [P0] addPersistentRule creates a PermissionRule in SwiftData
    func testAddPersistentRuleCreatesPermissionRule() {
        let handler = makeHandler(globalMode: .manualReview)

        handler.addPersistentRule(toolName: "Read", pattern: "*", decision: .allow)

        let decision = handler.evaluate(toolName: "Read", input: ["filePath": "/any/path"])
        assertApproved(decision)
    }

    // [P1] Persistent rules match by toolName
    func testPersistentRuleMatchesByToolName() {
        let handler = makeHandler(globalMode: .manualReview)

        handler.addPersistentRule(toolName: "Read", pattern: "*", decision: .allow)

        // Read should be allowed
        let readDecision = handler.evaluate(toolName: "Read", input: ["filePath": "/tmp/file"])
        assertApproved(readDecision)

        // Bash should still require approval (no rule)
        let bashDecision = handler.evaluate(toolName: "Bash", input: ["command": "ls"])
        assertRequiresApproval(bashDecision)
    }

    // MARK: - AC#4: Deny

    // [P0] denyAll mode denies all tools
    func testDenyAllDeniesAllTools() {
        let handler = makeHandler(globalMode: .denyAll)

        let tools = ["Bash", "Read", "Write", "Edit", "Grep", "Glob"]
        for tool in tools {
            let decision = handler.evaluate(toolName: tool, input: [:])
            assertDenied(decision)
        }
    }

    // [P0] User deny decision in manualReview returns .denied
    func testManualReviewDenyRuleReturnsDenied() {
        let handler = makeHandler(globalMode: .manualReview)
        handler.addPersistentRule(toolName: "Bash", pattern: "rm *", decision: .deny)

        let decision = handler.evaluate(toolName: "Bash", input: ["command": "rm -rf /tmp/build"])
        if case .denied(let reason) = decision {
            XCTAssertFalse(reason.isEmpty, "Deny reason should not be empty")
        } else {
            XCTFail("Should be denied for matching deny rule")
        }
    }

    // MARK: - AC#5: Audit log

    // [P0] Every permission decision is recorded in audit log
    func testAuditLogRecordsEveryDecision() {
        let handler = makeHandler(globalMode: .autoApprove)

        _ = handler.evaluate(toolName: "Bash", input: ["command": "ls"])
        _ = handler.evaluate(toolName: "Read", input: ["filePath": "/tmp/test"])

        XCTAssertEqual(handler.auditLog.count, 2, "Audit log should have 2 entries after 2 evaluations")
    }

    // [P0] Audit log entry contains correct fields
    func testAuditLogEntryContainsCorrectFields() {
        let handler = makeHandler(globalMode: .autoApprove)

        _ = handler.evaluate(toolName: "Bash", input: ["command": "ls -la"])

        guard let entry = handler.auditLog.first else {
            XCTFail("Audit log should have at least one entry")
            return
        }
        XCTAssertEqual(entry.toolName, "Bash")
        XCTAssertEqual(entry.decision, .approved)
        XCTAssertFalse(entry.timestamp > Date.now)
    }

    // [P1] Audit log records session override decisions
    func testAuditLogRecordsSessionOverrideDecisions() {
        let handler = makeHandler(globalMode: .manualReview)
        handler.addSessionOverride(toolName: "Read", decision: .approved)

        _ = handler.evaluate(toolName: "Read", input: ["filePath": "/tmp/file"])

        guard let entry = handler.auditLog.first else {
            XCTFail("Audit log should record session override decision")
            return
        }
        XCTAssertTrue(entry.sessionOverride, "Entry should be flagged as session override")
    }

    // MARK: - Edge cases

    // [P1] evaluate handles nil/empty input gracefully
    func testEvaluateHandlesEmptyInput() {
        let handler = makeHandler(globalMode: .manualReview)

        let decision = handler.evaluate(toolName: "Bash", input: [:])
        assertRequiresApproval(decision)
    }

    // [P1] evaluate handles unknown tool names
    func testEvaluateHandlesUnknownToolName() {
        let handler = makeHandler(globalMode: .manualReview)

        let decision = handler.evaluate(toolName: "FutureTool", input: [:])
        assertRequiresApproval(decision)
    }

    // [P2] GlobalPermissionMode can be switched at runtime
    func testGlobalModeSwitchAtRuntime() {
        let handler = makeHandler(globalMode: .autoApprove)

        // Initially autoApprove
        assertApproved(handler.evaluate(toolName: "Bash", input: [:]))

        // Switch to denyAll
        handler.globalMode = .denyAll
        assertDenied(handler.evaluate(toolName: "Bash", input: [:]))
    }

    // [P2] Default global mode is autoApprove (backward compatible)
    func testDefaultGlobalModeIsAutoApprove() {
        let handler = PermissionHandler()
        XCTAssertEqual(handler.globalMode, .autoApprove, "Default mode should be autoApprove for backward compatibility")
    }
}
