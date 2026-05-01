import XCTest
@testable import SwiftWork
import SwiftData

@MainActor
final class AppStateRestoreIntegrationTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeModelContext() throws -> ModelContext {
        let schema = Schema([AppConfiguration.self, Session.self, Event.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    private func makeViewModel() -> SessionViewModel {
        SessionViewModel()
    }

    private func makeManager() -> AppStateManager {
        AppStateManager()
    }

    // Helper: insert sessions with specific updatedAt timestamps
    private func insertSessions(
        _ context: ModelContext,
        titles: [String],
        updatedAts: [Date]
    ) throws -> [Session] {
        var sessions: [Session] = []
        for (index, title) in titles.enumerated() {
            let session = Session(title: title)
            session.updatedAt = updatedAts[index]
            context.insert(session)
            sessions.append(session)
        }
        try context.save()
        return sessions
    }

    // MARK: - AC#1: Full Restore Flow

    // [P0] Simulate app restart: save state -> reload -> session is selected
    func testRestoreSelectedSessionAfterRestart() throws {
        let context = try makeModelContext()

        // Step 1: Initial app run — create sessions, select one
        let now = Date.now
        let sessions = try insertSessions(
            context,
            titles: ["Session A", "Session B", "Session C"],
            updatedAts: [now, now.addingTimeInterval(-60), now.addingTimeInterval(-120)]
        )

        let manager = makeManager()
        manager.configure(modelContext: context)

        // Simulate user selecting Session B
        let selectedSession = sessions[1]
        manager.saveLastActiveSessionID(selectedSession.id)
        manager.saveInspectorVisibility(true)
        manager.saveWindowFrame(NSRect(x: 100, y: 200, width: 1200, height: 800))

        // Step 2: Simulate app restart — new ViewModel and Manager instances
        let restoredManager = makeManager()
        restoredManager.configure(modelContext: context)
        restoredManager.loadAppState()

        let restoredViewModel = makeViewModel()
        restoredViewModel.configure(modelContext: context)

        // Step 3: Restore selection using loaded state
        if let restoredID = restoredManager.lastActiveSessionID {
            let matching = restoredViewModel.sessions.first { $0.id == restoredID }
            if let match = matching {
                restoredViewModel.selectSession(match)
            } else {
                // Fallback: select first session
                if let first = restoredViewModel.sessions.first {
                    restoredViewModel.selectSession(first)
                }
            }
        }

        // Verify: selected session matches the one we saved
        XCTAssertEqual(
            restoredViewModel.selectedSession?.id,
            selectedSession.id,
            "After restart, the previously selected session should be restored"
        )
    }

    // [P0] Selected session ID matches the persisted lastActiveSessionID
    func testSelectedSessionMatchesPersistedID() throws {
        let context = try makeModelContext()
        let sessions = try insertSessions(
            context,
            titles: ["Alpha", "Beta"],
            updatedAts: [Date.now, Date.now.addingTimeInterval(-60)]
        )

        let manager = makeManager()
        manager.configure(modelContext: context)
        manager.saveLastActiveSessionID(sessions[1].id)

        // Reload
        let restoredManager = makeManager()
        restoredManager.configure(modelContext: context)
        restoredManager.loadAppState()

        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        let targetID = restoredManager.lastActiveSessionID
        let match = viewModel.sessions.first { $0.id == targetID }
        XCTAssertNotNil(match, "Should find a session matching the persisted ID")
        XCTAssertEqual(match?.id, sessions[1].id)
    }

    // [P0] Window frame persisted and restored correctly
    func testRestoreWindowFrameAfterRestart() throws {
        let context = try makeModelContext()
        let manager = makeManager()
        manager.configure(modelContext: context)

        let originalFrame = NSRect(x: 50, y: 75, width: 1400, height: 900)
        manager.saveWindowFrame(originalFrame)

        // Reload
        let restoredManager = makeManager()
        restoredManager.configure(modelContext: context)
        restoredManager.loadAppState()

        XCTAssertEqual(
            restoredManager.windowFrame,
            originalFrame,
            "Window frame should be restored after reload"
        )
    }

    // [P0] Inspector visibility persisted and restored correctly
    func testRestoreInspectorStateAfterRestart() throws {
        let context = try makeModelContext()
        let manager = makeManager()
        manager.configure(modelContext: context)

        manager.saveInspectorVisibility(true)

        // Reload
        let restoredManager = makeManager()
        restoredManager.configure(modelContext: context)
        restoredManager.loadAppState()

        XCTAssertTrue(
            restoredManager.isInspectorVisible,
            "Inspector visibility should be restored after reload"
        )
    }

    // MARK: - AC#2: Crash Recovery

    // [P0] Crash mid-session: restart restores to last saved state
    func testRestoreAfterSimulatedCrash() throws {
        let context = try makeModelContext()

        // Simulate: user was using session, state was saved in real-time
        let sessions = try insertSessions(
            context,
            titles: ["Working Session"],
            updatedAts: [Date.now]
        )

        let manager = makeManager()
        manager.configure(modelContext: context)
        manager.saveLastActiveSessionID(sessions[0].id)
        manager.saveInspectorVisibility(false)

        // Simulate crash — no willTerminate notification
        // On restart, a new manager loads whatever was last saved
        let restoredManager = makeManager()
        restoredManager.configure(modelContext: context)
        restoredManager.loadAppState()

        XCTAssertEqual(restoredManager.lastActiveSessionID, sessions[0].id)
        XCTAssertFalse(restoredManager.isInspectorVisible)
    }

    // [P0] Events persisted before crash survive restart
    func testEventsPreservedAfterCrash() throws {
        let context = try makeModelContext()

        // Create a session with events
        let session = Session(title: "Crash Test")
        context.insert(session)

        // Simulate events that were persisted before crash
        let event1 = Event(
            sessionID: session.id,
            eventType: "partialMessage",
            rawData: Data("Hello".utf8),
            timestamp: Date.now.addingTimeInterval(-10),
            order: 0
        )
        let event2 = Event(
            sessionID: session.id,
            eventType: "assistant",
            rawData: Data("World".utf8),
            timestamp: Date.now,
            order: 1
        )
        session.events.append(event1)
        session.events.append(event2)
        context.insert(event1)
        context.insert(event2)
        try context.save()

        // Verify events survived (simulating restart read)
        let sessionID = session.id
        var descriptor = FetchDescriptor<Event>(
            predicate: #Predicate { $0.sessionID == sessionID }
        )
        descriptor.sortBy = [SortDescriptor(\.order)]
        let events = try context.fetch(descriptor)

        XCTAssertEqual(events.count, 2, "Events persisted before crash should survive")
        XCTAssertEqual(events[0].eventType, "partialMessage")
        XCTAssertEqual(events[1].eventType, "assistant")
    }

    // MARK: - AC#2: Fallback

    // [P0] Saved session was deleted, restore falls back to sessions.first
    func testFallbackToFirstSessionWhenSavedDeleted() throws {
        let context = try makeModelContext()

        // Create sessions
        let now = Date.now
        var sessions = try insertSessions(
            context,
            titles: ["Session A", "Session B", "Session C"],
            updatedAts: [now, now.addingTimeInterval(-60), now.addingTimeInterval(-120)]
        )

        // Save session B as active
        let manager = makeManager()
        manager.configure(modelContext: context)
        manager.saveLastActiveSessionID(sessions[1].id)

        // Delete session B (simulating user deleted it before restart)
        context.delete(sessions[1])
        try context.save()

        // Reload — saved ID no longer matches any session
        let restoredManager = makeManager()
        restoredManager.configure(modelContext: context)
        restoredManager.loadAppState()

        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        // Attempt restore with fallback
        let targetID = restoredManager.lastActiveSessionID
        let match = viewModel.sessions.first { $0.id == targetID }
        if let match = match {
            viewModel.selectSession(match)
        } else {
            // Fallback: select most recent session
            if let first = viewModel.sessions.first {
                viewModel.selectSession(first)
            }
        }

        XCTAssertEqual(
            viewModel.selectedSession?.id,
            viewModel.sessions.first?.id,
            "Should fall back to the first (most recent) session when saved session is deleted"
        )
    }

    // [P0] No sessions exist, restore does not crash
    func testEmptySessionsNoCrashOnRestore() throws {
        let context = try makeModelContext()

        let manager = makeManager()
        manager.configure(modelContext: context)
        manager.saveLastActiveSessionID(UUID()) // saved ID, but no sessions

        // Reload with empty sessions
        let restoredManager = makeManager()
        restoredManager.configure(modelContext: context)
        restoredManager.loadAppState()

        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        // Should not crash — no session to select
        let targetID = restoredManager.lastActiveSessionID
        let match = viewModel.sessions.first { $0.id == targetID }
        if let match = match {
            viewModel.selectSession(match)
        } else if let first = viewModel.sessions.first {
            viewModel.selectSession(first)
        }

        XCTAssertNil(viewModel.selectedSession, "With no sessions, selection should be nil")
        XCTAssertTrue(viewModel.sessions.isEmpty, "Sessions should be empty")
    }
}
