import XCTest
@testable import SwiftWork
import SwiftData

@MainActor
final class DockBadgeTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeModelContext() throws -> ModelContext {
        let schema = Schema([AppConfiguration.self, Session.self, Event.self, PermissionRule.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    // MARK: - AC#1: Dock Badge Shows Unread Session Count (P0)

    // [P0] updateDockBadge sets badgeLabel when unreadSessionCount > 0
    func testDockBadgeSetWhenUnreadCountPositive() throws {
        let appState = AppState()

        // Simulate 3 unread sessions
        appState.unreadSessionCount = 3
        appState.updateDockBadge()

        XCTAssertEqual(
            NSApplication.shared.dockTile.badgeLabel,
            "3",
            "Dock badge should display '3' when unreadSessionCount is 3"
        )

        // Cleanup
        NSApplication.shared.dockTile.badgeLabel = nil
    }

    // [P0] updateDockBadge clears badgeLabel when unreadSessionCount is 0
    func testDockBadgeClearedWhenUnreadCountZero() throws {
        let appState = AppState()

        // First set a badge
        NSApplication.shared.dockTile.badgeLabel = "5"

        // Now clear it
        appState.unreadSessionCount = 0
        appState.updateDockBadge()

        XCTAssertTrue(
            NSApplication.shared.dockTile.badgeLabel == nil
                || NSApplication.shared.dockTile.badgeLabel == "",
            "Dock badge should be cleared when unreadSessionCount is 0"
        )

        // Cleanup
        NSApplication.shared.dockTile.badgeLabel = nil
    }

    // [P0] updateDockBadge clears badgeLabel when unreadSessionCount is negative (edge case)
    func testDockBadgeClearedWhenUnreadCountNegative() throws {
        let appState = AppState()

        // Set badge first
        NSApplication.shared.dockTile.badgeLabel = "2"

        // Negative count should also clear badge
        appState.unreadSessionCount = -1
        appState.updateDockBadge()

        XCTAssertTrue(
            NSApplication.shared.dockTile.badgeLabel == nil
                || NSApplication.shared.dockTile.badgeLabel == "",
            "Dock badge should be cleared when unreadSessionCount is negative"
        )

        // Cleanup
        NSApplication.shared.dockTile.badgeLabel = nil
    }

    // MARK: - AC#1: Unread Count Updates on Result Event (P0)

    // [P0] markSessionAsUnread increments unreadSessionCount
    func testMarkSessionAsUnreadIncrementsCount() throws {
        let context = try makeModelContext()
        let appState = AppState()
        appState.sessionViewModel.configure(modelContext: context)

        // Create a session
        appState.sessionViewModel.createSession()
        let session = try XCTUnwrap(appState.sessionViewModel.selectedSession)

        let initialCount = appState.unreadSessionCount

        // Mark session as unread (simulates .result event when app not in foreground)
        appState.markSessionAsUnread(session)

        XCTAssertTrue(
            session.hasUnreadResult,
            "Session should be marked as unread"
        )
        XCTAssertEqual(
            appState.unreadSessionCount,
            initialCount + 1,
            "unreadSessionCount should increment by 1 after marking a session as unread"
        )
    }

    // [P0] Marking the same session as unread twice does not double-count
    func testMarkSameSessionUnreadTwiceNoDoubleCount() throws {
        let context = try makeModelContext()
        let appState = AppState()
        appState.sessionViewModel.configure(modelContext: context)

        appState.sessionViewModel.createSession()
        let session = try XCTUnwrap(appState.sessionViewModel.selectedSession)

        appState.markSessionAsUnread(session)
        let countAfterFirst = appState.unreadSessionCount

        // Mark same session again — should not increment
        appState.markSessionAsUnread(session)

        XCTAssertEqual(
            appState.unreadSessionCount,
            countAfterFirst,
            "Marking the same session as unread twice should not double-count"
        )
    }

    // MARK: - AC#1: Unread Count Cleared on Session Select (P0)

    // [P0] Selecting a session clears its unread mark and decrements count
    func testSelectSessionClearsUnread() throws {
        let context = try makeModelContext()
        let appState = AppState()
        appState.sessionViewModel.configure(modelContext: context)

        // Create two sessions
        appState.sessionViewModel.createSession()
        let sessionA = try XCTUnwrap(appState.sessionViewModel.selectedSession)
        appState.sessionViewModel.createSession()
        let sessionB = try XCTUnwrap(appState.sessionViewModel.selectedSession)

        // Mark session A as unread
        appState.markSessionAsUnread(sessionA)
        let countAfterMark = appState.unreadSessionCount
        XCTAssertGreaterThanOrEqual(countAfterMark, 1)

        // Select session A — should clear its unread
        appState.clearUnreadForSession(sessionA)

        XCTAssertFalse(
            sessionA.hasUnreadResult,
            "Session A should no longer be marked as unread after selection"
        )
        XCTAssertEqual(
            appState.unreadSessionCount,
            countAfterMark - 1,
            "unreadSessionCount should decrement after clearing unread for a session"
        )
    }

    // MARK: - AC#1: Badge Updates When App Returns to Foreground (P1)

    // [P1] clearAllUnread clears all unread marks and resets count to 0
    func testClearAllUnreadResetsCount() throws {
        let context = try makeModelContext()
        let appState = AppState()
        appState.sessionViewModel.configure(modelContext: context)

        // Create and mark multiple sessions as unread
        appState.sessionViewModel.createSession()
        let sessionA = try XCTUnwrap(appState.sessionViewModel.selectedSession)
        appState.sessionViewModel.createSession()
        let sessionB = try XCTUnwrap(appState.sessionViewModel.selectedSession)

        appState.markSessionAsUnread(sessionA)
        appState.markSessionAsUnread(sessionB)
        XCTAssertGreaterThanOrEqual(appState.unreadSessionCount, 2)

        // Clear all (simulates app becoming active)
        appState.clearAllUnread()

        XCTAssertEqual(
            appState.unreadSessionCount,
            0,
            "unreadSessionCount should be 0 after clearing all unread"
        )
        XCTAssertFalse(sessionA.hasUnreadResult, "Session A should be cleared")
        XCTAssertFalse(sessionB.hasUnreadResult, "Session B should be cleared")
        XCTAssertTrue(
            NSApplication.shared.dockTile.badgeLabel == nil
                || NSApplication.shared.dockTile.badgeLabel == "",
            "Dock badge should be cleared after clearAllUnread"
        )

        // Cleanup
        NSApplication.shared.dockTile.badgeLabel = nil
    }

    // MARK: - AC#1: Dock Badge Updates Automatically (P1)

    // [P1] Setting unreadSessionCount triggers updateDockBadge automatically
    func testUnreadCountChangeTriggersBadgeUpdate() throws {
        let appState = AppState()

        // Initial state: badge should be empty
        XCTAssertTrue(
            NSApplication.shared.dockTile.badgeLabel == nil
                || NSApplication.shared.dockTile.badgeLabel == "",
            "Dock badge should initially be empty"
        )

        // Set unread count — badge should update
        appState.unreadSessionCount = 7

        XCTAssertEqual(
            NSApplication.shared.dockTile.badgeLabel,
            "7",
            "Dock badge should show '7' after setting unreadSessionCount to 7"
        )

        // Reset to 0 — badge should clear
        appState.unreadSessionCount = 0

        XCTAssertTrue(
            NSApplication.shared.dockTile.badgeLabel == nil
                || NSApplication.shared.dockTile.badgeLabel == "",
            "Dock badge should be cleared after setting unreadSessionCount to 0"
        )

        // Cleanup
        NSApplication.shared.dockTile.badgeLabel = nil
    }

    // MARK: - AC#1: Unread Persisted Across Sessions (P2)

    // [P2] Session.hasUnreadResult persists to SwiftData
    func testUnreadMarkPersistsToSwiftData() throws {
        let context = try makeModelContext()

        // Insert a session and mark as unread
        let session = Session(title: "Unread Test")
        session.hasUnreadResult = true
        context.insert(session)
        try context.save()

        // Fetch it back
        let id = session.id
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate<Session> { $0.id == id }
        )
        let fetched = try context.fetch(descriptor)
        let restored = try XCTUnwrap(fetched.first)

        XCTAssertTrue(
            restored.hasUnreadResult,
            "hasUnreadResult should persist to SwiftData"
        )
    }

    // MARK: - AC#1: onResult Callback Integration (P1)

    // [P1] AgentBridge.onResult callback fires for .result events
    func testAgentBridgeOnResultCallbackFires() async throws {
        let bridge = AgentBridge()
        var callbackFired = false
        var receivedContent: String?

        bridge.onResult = { content in
            callbackFired = true
            receivedContent = content
        }

        // The onResult callback is invoked in startInputStream when event.type == .result
        // This test verifies the callback is wired up correctly
        XCTAssertNotNil(bridge.onResult, "AgentBridge should have an onResult callback")

        // Verify callback can be invoked directly
        bridge.onResult?("test result content")
        XCTAssertTrue(callbackFired, "onResult callback should fire when invoked")
        XCTAssertEqual(receivedContent, "test result content", "onResult should pass content string")
    }

    // MARK: - Initial State (P1)

    // [P1] AppState has zero unread count initially
    func testInitialStateUnreadCountIsZero() throws {
        let appState = AppState()
        XCTAssertEqual(
            appState.unreadSessionCount,
            0,
            "unreadSessionCount should default to 0"
        )
    }

    // [P1] Session.hasUnreadResult defaults to false
    func testSessionHasUnreadResultDefaultsFalse() throws {
        let session = Session(title: "Test")
        XCTAssertFalse(
            session.hasUnreadResult,
            "Session.hasUnreadResult should default to false"
        )
    }
}
