import XCTest
@testable import SwiftWork

final class PermissionDecisionTests: XCTestCase {

    // MARK: - AC#4: PermissionDecision Enum

    // [P0] PermissionDecision has approved, denied, requiresApproval cases
    func testPermissionDecisionAllCases() throws {
        let approved = PermissionDecision.approved
        let denied = PermissionDecision.denied(reason: "User rejected")
        let requiresApproval = PermissionDecision.requiresApproval(
            toolName: "Bash",
            description: "Run shell command",
            parameters: ["command": "ls -la"]
        )

        // Verify all three cases exist
        switch approved {
        case .approved: break
        default: XCTFail("Expected .approved")
        }

        switch denied {
        case .denied: break
        default: XCTFail("Expected .denied")
        }

        switch requiresApproval {
        case .requiresApproval: break
        default: XCTFail("Expected .requiresApproval")
        }
    }

    // [P0] PermissionDecision is Sendable
    func testPermissionDecisionIsSendable() throws {
        let decision: PermissionDecision = .approved
        let _: any Sendable = decision
    }

    // [P1] PermissionDecision.denied carries a reason
    func testPermissionDecisionDeniedReason() throws {
        let denied = PermissionDecision.denied(reason: "Dangerous command")

        if case .denied(let reason) = denied {
            XCTAssertEqual(reason, "Dangerous command")
        } else {
            XCTFail("Expected .denied with reason")
        }
    }

    // [P1] PermissionDecision.requiresApproval carries tool metadata
    func testPermissionDecisionRequiresApprovalMetadata() throws {
        let requires = PermissionDecision.requiresApproval(
            toolName: "Write",
            description: "Write to file",
            parameters: ["filePath": "/etc/config"]
        )

        if case .requiresApproval(let toolName, let description, _) = requires {
            XCTAssertEqual(toolName, "Write")
            XCTAssertEqual(description, "Write to file")
        } else {
            XCTFail("Expected .requiresApproval with metadata")
        }
    }
}
