import XCTest
@testable import SwiftWork

@MainActor
final class SessionWorkspaceServiceTests: XCTestCase {
    private func makeService() -> SessionWorkspaceService {
        SessionWorkspaceService()
    }

    func testResolveStateReturnsUnboundWhenWorkspaceMissing() {
        let service = makeService()
        let session = Session(title: "Unbound")

        XCTAssertEqual(service.resolveState(for: session), .unbound)
    }

    func testResolveStateReturnsReadyForExistingDirectory() {
        let service = makeService()
        let path = FileManager.default.currentDirectoryPath
        let session = Session(title: "Ready", workspacePath: path)

        XCTAssertEqual(
            service.resolveState(for: session),
            .ready(SessionWorkspaceBinding(path: path, bookmarkData: nil))
        )
    }

    func testResolveStateReturnsNeedsRepairForMissingDirectory() {
        let service = makeService()
        let session = Session(title: "Broken", workspacePath: "/definitely/missing/workspace")

        XCTAssertEqual(
            service.resolveState(for: session),
            .needsRepair(lastKnownPath: "/definitely/missing/workspace")
        )
    }

    func testResolveStatePrefersBookmarkPathWhenItDiffersFromStoredPath() throws {
        let service = makeService()
        let fileManager = FileManager.default
        let baseURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let liveURL = baseURL.appendingPathComponent("live", isDirectory: true)

        try fileManager.createDirectory(at: liveURL, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: baseURL) }

        let bookmarkData = try liveURL.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        let state = service.resolveState(
            workspacePath: "/definitely/missing/workspace",
            bookmarkData: bookmarkData
        )

        XCTAssertEqual(
            state,
            .ready(SessionWorkspaceBinding(path: liveURL.path, bookmarkData: bookmarkData))
        )
    }

    func testMostRecentValidWorkspaceSkipsInvalidEntries() {
        let service = makeService()
        let valid = Session(title: "Valid", workspacePath: FileManager.default.currentDirectoryPath)
        let invalid = Session(title: "Invalid", workspacePath: "/definitely/missing/workspace")

        let binding = service.mostRecentValidWorkspace(in: [invalid, valid])

        XCTAssertEqual(binding?.path, FileManager.default.currentDirectoryPath)
    }

    func testAgentWorkingDirectoryUsesSafeFallbackForUnboundState() {
        let service = makeService()

        let directory = service.agentWorkingDirectory(for: .unbound)

        var isDirectory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
    }

    func testAgentWorkingDirectoryUsesSafeFallbackForRepairState() {
        let service = makeService()

        let directory = service.agentWorkingDirectory(for: .needsRepair(lastKnownPath: "/missing/workspace"))

        XCTAssertFalse(directory.contains("/missing/workspace"))
        var isDirectory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
    }
}
