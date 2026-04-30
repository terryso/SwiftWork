import XCTest
@testable import SwiftWork

final class PermissionRuleModelTests: XCTestCase {

    // MARK: - AC#4: PermissionRule Model Definition

    // [P0] PermissionRule can be instantiated with required properties
    func testPermissionRuleInstantiation() throws {
        let rule = PermissionRule(
            toolName: "Bash",
            pattern: "git *",
            decision: .allow
        )

        XCTAssertEqual(rule.toolName, "Bash")
        XCTAssertEqual(rule.pattern, "git *")
        XCTAssertEqual(rule.decision, .allow)
        XCTAssertNotNil(rule.id)
        XCTAssertNotNil(rule.createdAt)
    }

    // [P0] PermissionRule has UUID unique primary key
    func testPermissionRuleUUIDPrimaryKey() throws {
        let ruleA = PermissionRule(toolName: "Read", pattern: "*", decision: .allow)
        let ruleB = PermissionRule(toolName: "Write", pattern: "*", decision: .deny)

        XCTAssertNotEqual(ruleA.id, ruleB.id)
    }

    // [P1] PermissionRule decision is "allow" or "deny" string
    func testPermissionRuleDecisionValues() throws {
        let allowRule = PermissionRule(toolName: "Read", pattern: "*", decision: .allow)
        let denyRule = PermissionRule(toolName: "Bash", pattern: "rm -rf *", decision: .deny)

        XCTAssertEqual(allowRule.decision, .allow)
        XCTAssertEqual(denyRule.decision, .deny)
    }

    // [P1] PermissionRule createdAt is set on init
    func testPermissionRuleCreatedAtOnInit() throws {
        let before = Date.now
        let rule = PermissionRule(toolName: "Read", pattern: "*", decision: .allow)
        let after = Date.now

        XCTAssertGreaterThanOrEqual(rule.createdAt, before)
        XCTAssertLessThanOrEqual(rule.createdAt, after)
    }
}
