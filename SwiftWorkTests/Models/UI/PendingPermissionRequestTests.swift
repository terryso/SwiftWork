import XCTest
@testable import SwiftWork

// Story 3.1: 权限系统实现
// Unit tests for PendingPermissionRequest and PermissionDialogResult.

@MainActor
final class PendingPermissionRequestTests: XCTestCase {

    // MARK: - AC#1: PendingPermissionRequest model structure

    // [P0] PendingPermissionRequest stores toolName, description, parameters, input
    func testPendingPermissionRequestStoresMetadata() {
        let request = PendingPermissionRequest(
            toolName: "Bash",
            description: "Run shell command",
            parameters: ["command": "ls -la"],
            input: ["command": "ls -la", "cwd": "/tmp"]
        )

        XCTAssertEqual(request.toolName, "Bash")
        XCTAssertEqual(request.description, "Run shell command")
        XCTAssertEqual(request.parameters["command"] as? String, "ls -la")
    }

    // [P0] PendingPermissionRequest is Identifiable for .sheet(item:) binding
    func testPendingPermissionRequestIsIdentifiable() {
        let request = PendingPermissionRequest(
            toolName: "Read",
            description: "Read file",
            parameters: [:],
            input: [:]
        )

        // Must conform to Identifiable for SwiftUI .sheet(item:)
        let _: any Identifiable = request
    }

    // [P0] Two PendingPermissionRequests with same id are considered equal
    func testPendingPermissionRequestIdentity() {
        let request1 = PendingPermissionRequest(
            toolName: "Bash",
            description: "Run command",
            parameters: ["command": "ls"],
            input: ["command": "ls"]
        )
        let request2 = PendingPermissionRequest(
            toolName: "Read",
            description: "Read file",
            parameters: ["filePath": "/tmp"],
            input: ["filePath": "/tmp"]
        )

        XCTAssertNotEqual(request1.id, request2.id, "Different requests should have different IDs")
    }

    // MARK: - AC#2/#3/#4: Continuation lifecycle

    // [P0] PendingPermissionRequest resolves with .allow for Allow Once
    func testResolveAllowOnce() async {
        let request = PendingPermissionRequest(
            toolName: "Bash",
            description: "Run shell command",
            parameters: ["command": "ls"],
            input: ["command": "ls"]
        )

        // Start waiting in background
        let task = Task {
            await request.waitForResult()
        }

        // Give it a moment to set up the continuation
        try? await Task.sleep(nanoseconds: 10_000_000)

        request.resolve(.allowOnce)
        let result = await task.value
        XCTAssertEqual(result, .allowOnce)
    }

    // [P0] PendingPermissionRequest resolves with .alwaysAllow
    func testResolveAlwaysAllow() async {
        let request = PendingPermissionRequest(
            toolName: "Read",
            description: "Read file",
            parameters: ["filePath": "/tmp/file.txt"],
            input: ["filePath": "/tmp/file.txt"]
        )

        let task = Task {
            await request.waitForResult()
        }

        try? await Task.sleep(nanoseconds: 10_000_000)

        request.resolve(.alwaysAllow)
        let result = await task.value
        XCTAssertEqual(result, .alwaysAllow)
    }

    // [P0] PendingPermissionRequest resolves with .deny
    func testResolveDeny() async {
        let request = PendingPermissionRequest(
            toolName: "Bash",
            description: "Run shell command",
            parameters: ["command": "rm -rf /"],
            input: ["command": "rm -rf /"]
        )

        let task = Task {
            await request.waitForResult()
        }

        try? await Task.sleep(nanoseconds: 10_000_000)

        request.resolve(.deny)
        let result = await task.value
        XCTAssertEqual(result, .deny)
    }

    // [P1] Resolving twice does not crash (second call is no-op)
    func testResolveTwiceDoesNotCrash() async {
        let request = PendingPermissionRequest(
            toolName: "Bash",
            description: "Run command",
            parameters: [:],
            input: [:]
        )

        let task = Task {
            await request.waitForResult()
        }

        try? await Task.sleep(nanoseconds: 10_000_000)

        request.resolve(.allowOnce)
        _ = await task.value

        // Second resolve should be a no-op, not crash
        request.resolve(.deny)
    }

    // MARK: - PermissionDialogResult enum

    // [P0] PermissionDialogResult has allowOnce, alwaysAllow, deny cases
    func testPermissionDialogResultAllCases() {
        let allowOnce = PermissionDialogResult.allowOnce
        let alwaysAllow = PermissionDialogResult.alwaysAllow
        let deny = PermissionDialogResult.deny

        // Verify exhaustiveness
        switch allowOnce {
        case .allowOnce: break
        case .alwaysAllow, .deny: XCTFail("Wrong case")
        }
        switch alwaysAllow {
        case .alwaysAllow: break
        case .allowOnce, .deny: XCTFail("Wrong case")
        }
        switch deny {
        case .deny: break
        case .allowOnce, .alwaysAllow: XCTFail("Wrong case")
        }
    }

    // [P0] PermissionAuditEntry stores toolName, decision, timestamp, sessionOverride
    func testPermissionAuditEntryStructure() {
        let entry = PermissionAuditEntry(
            toolName: "Bash",
            input: "ls -la",
            decision: .approved,
            timestamp: .now,
            sessionOverride: false
        )

        XCTAssertEqual(entry.toolName, "Bash")
        XCTAssertEqual(entry.input, "ls -la")
        XCTAssertEqual(entry.decision, .approved)
        XCTAssertFalse(entry.sessionOverride)
    }

    // [P1] PermissionAuditEntry is Sendable
    func testPermissionAuditEntryIsSendable() {
        let entry = PermissionAuditEntry(
            toolName: "Bash",
            input: "ls",
            decision: .approved,
            timestamp: .now,
            sessionOverride: false
        )
        let _: any Sendable = entry
    }
}
