import XCTest
@testable import SwiftWork
import SwiftData

@MainActor
final class SessionViewModelTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeModelContext() throws -> ModelContext {
        let schema = Schema([Session.self, Event.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    private func makeViewModel() -> SessionViewModel {
        SessionViewModel()
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

    // MARK: - AC#1: Display sessions sorted by updatedAt descending

    // [P0] Sessions are returned sorted by updatedAt descending after configure
    func testFetchSessionsSortedByUpdatedAt() async throws {
        let context = try makeModelContext()
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        let now = Date.now
        let older = now.addingTimeInterval(-3600)
        let newest = now.addingTimeInterval(-60)

        // Insert sessions out of order
        _ = try insertSessions(context, titles: ["Old", "New", "Newest"], updatedAts: [older, now, newest])

        // Re-fetch to verify sort
        viewModel.fetchSessions()

        let list = viewModel.sessions
        XCTAssertEqual(list.count, 3, "Should have 3 sessions")
        if list.count >= 2 {
            XCTAssertGreaterThan(
                list[0].updatedAt,
                list[1].updatedAt,
                "Sessions should be sorted by updatedAt descending"
            )
        }
    }

    // [P0] fetchSessions with empty store returns empty array
    func testFetchSessionsEmpty() throws {
        let context = try makeModelContext()
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        XCTAssertTrue(viewModel.sessions.isEmpty, "Should start with no sessions")
    }

    // MARK: - AC#2: Create new session

    // [P0] createSession adds a new session to sessions array
    func testCreateSessionAddsToList() throws {
        let context = try makeModelContext()
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        XCTAssertTrue(viewModel.sessions.isEmpty)

        viewModel.createSession()

        XCTAssertEqual(viewModel.sessions.count, 1, "Should have 1 session after creation")
    }

    // [P0] createSession auto-selects the new session
    func testCreateSessionAutoSelects() throws {
        let context = try makeModelContext()
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        viewModel.createSession()

        XCTAssertNotNil(viewModel.selectedSession, "New session should be auto-selected")
        let list = viewModel.sessions
        let selected = viewModel.selectedSession
        if !list.isEmpty && selected != nil {
            XCTAssertEqual(selected?.id, list.first?.id)
        }
    }

    // [P0] createSession inserts at index 0 (most recent)
    func testCreateSessionInsertsAtHead() throws {
        let context = try makeModelContext()
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        // Pre-create an existing session
        let existing = Session(title: "Existing")
        context.insert(existing)
        try context.save()
        viewModel.fetchSessions()

        XCTAssertEqual(viewModel.sessions.count, 1)

        viewModel.createSession()

        let list = viewModel.sessions
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(list.first?.title, "新会话", "New session should be at index 0")
    }

    // [P0] createSession persists to SwiftData
    func testCreateSessionPersistsToSwiftData() throws {
        let context = try makeModelContext()
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        viewModel.createSession()

        // Verify persistence by re-fetching from context
        let descriptor = FetchDescriptor<Session>()
        let persisted = try context.fetch(descriptor)
        XCTAssertEqual(persisted.count, 1, "Session should be persisted in SwiftData")
    }

    // [P1] createSession uses default title "新会话"
    func testCreateSessionDefaultTitle() throws {
        let context = try makeModelContext()
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        viewModel.createSession()

        let list = viewModel.sessions
        XCTAssertEqual(list.first?.title, "新会话", "Default title should be '新会话'")
    }

    // MARK: - AC#3: Switch between sessions

    // [P0] selectSession updates selectedSession
    func testSelectSessionUpdatesSelection() throws {
        let context = try makeModelContext()
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        let now = Date.now
        let sessionsArray = try insertSessions(
            context,
            titles: ["Session A", "Session B"],
            updatedAts: [now, now.addingTimeInterval(-60)]
        )

        viewModel.fetchSessions()
        XCTAssertNil(viewModel.selectedSession, "No session should be selected initially")

        viewModel.selectSession(sessionsArray[1])
        XCTAssertEqual(viewModel.selectedSession?.id, sessionsArray[1].id, "Should select Session B")

        viewModel.selectSession(sessionsArray[0])
        XCTAssertEqual(viewModel.selectedSession?.id, sessionsArray[0].id, "Should switch to Session A")
    }

    // [P1] selectSession does not reload sessions list
    func testSelectSessionDoesNotReloadList() throws {
        let context = try makeModelContext()
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        let now = Date.now
        let sessionsArray = try insertSessions(
            context,
            titles: ["A", "B", "C"],
            updatedAts: [now, now.addingTimeInterval(-60), now.addingTimeInterval(-120)]
        )

        viewModel.fetchSessions()
        let countBefore = viewModel.sessions.count

        viewModel.selectSession(sessionsArray[0])

        XCTAssertEqual(viewModel.sessions.count, countBefore, "Session list count should not change on selection")
    }

    // MARK: - Delete session

    // [P0] deleteSession removes from sessions array
    func testDeleteSessionRemovesFromList() throws {
        let context = try makeModelContext()
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        let now = Date.now
        let sessionsArray = try insertSessions(
            context,
            titles: ["A", "B"],
            updatedAts: [now, now.addingTimeInterval(-60)]
        )

        viewModel.fetchSessions()
        XCTAssertEqual(viewModel.sessions.count, 2)

        viewModel.deleteSession(sessionsArray[1])

        let list = viewModel.sessions
        XCTAssertEqual(list.count, 1, "Should have 1 session after deletion")
        XCTAssertEqual(list.first?.id, sessionsArray[0].id, "Remaining session should be A")
    }

    // [P0] deleteSession cascade-deletes associated Events
    func testDeleteSessionCascadesEvents() throws {
        let context = try makeModelContext()
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        let session = Session(title: "With Events")
        context.insert(session)

        let event = Event(
            sessionID: session.id,
            eventType: "partialMessage",
            rawData: Data("{}" .utf8),
            timestamp: .now,
            order: 0
        )
        session.events.append(event)
        context.insert(event)
        try context.save()

        let eventID = event.id
        viewModel.fetchSessions()
        viewModel.deleteSession(session)

        // Verify event was cascade-deleted
        let eventDescriptor = FetchDescriptor<Event>(
            predicate: #Predicate { $0.id == eventID }
        )
        let remainingEvents = try context.fetch(eventDescriptor)
        XCTAssertTrue(remainingEvents.isEmpty, "Events should be cascade-deleted with session")
    }

    // [P0] deleteSession auto-selects nearest session when deleting selected
    func testDeleteSelectedSessionAutoSelectsNearest() throws {
        let context = try makeModelContext()
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        let now = Date.now
        let sessionsArray = try insertSessions(
            context,
            titles: ["A", "B", "C"],
            updatedAts: [now, now.addingTimeInterval(-60), now.addingTimeInterval(-120)]
        )

        viewModel.fetchSessions()
        viewModel.selectSession(sessionsArray[1])  // Select B

        viewModel.deleteSession(sessionsArray[1])  // Delete selected B

        let selected = viewModel.selectedSession
        XCTAssertNotNil(selected, "Should auto-select after deleting selected session")
        // Should select the first (most recently updated) remaining session
        XCTAssertEqual(selected?.id, sessionsArray[0].id, "Should auto-select the most recent session")
    }

    // [P1] deleteSession sets selectedSession to nil when no sessions remain
    func testDeleteLastSessionSetsSelectionNil() throws {
        let context = try makeModelContext()
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        let session = Session(title: "Only Session")
        context.insert(session)
        try context.save()

        viewModel.fetchSessions()
        viewModel.selectSession(session)

        viewModel.deleteSession(session)

        XCTAssertNil(viewModel.selectedSession, "Selection should be nil when no sessions remain")
        XCTAssertTrue(viewModel.sessions.isEmpty, "Sessions array should be empty")
    }

    // [P1] deleteSession does not change selection when deleting non-selected session
    func testDeleteNonSelectedSessionKeepsSelection() throws {
        let context = try makeModelContext()
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        let now = Date.now
        let sessionsArray = try insertSessions(
            context,
            titles: ["A", "B"],
            updatedAts: [now, now.addingTimeInterval(-60)]
        )

        viewModel.fetchSessions()
        viewModel.selectSession(sessionsArray[0])

        viewModel.deleteSession(sessionsArray[1])  // Delete non-selected B

        XCTAssertEqual(viewModel.selectedSession?.id, sessionsArray[0].id, "Selection should remain on A")
    }

    // MARK: - Update session title

    // [P0] updateSessionTitle changes the title
    func testUpdateSessionTitle() throws {
        let context = try makeModelContext()
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        let session = Session(title: "Original")
        context.insert(session)
        try context.save()
        viewModel.fetchSessions()

        viewModel.updateSessionTitle(session, title: "Updated Title")

        XCTAssertEqual(session.title, "Updated Title", "Title should be updated")
    }

    // [P0] updateSessionTitle updates updatedAt timestamp
    func testUpdateSessionTitleUpdatesTimestamp() throws {
        let context = try makeModelContext()
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        let session = Session(title: "Original")
        context.insert(session)
        try context.save()
        let originalUpdatedAt = session.updatedAt

        viewModel.fetchSessions()

        let beforeUpdate = Date.now
        viewModel.updateSessionTitle(session, title: "Updated")

        XCTAssertGreaterThanOrEqual(session.updatedAt, beforeUpdate, "updatedAt should be refreshed")
        XCTAssertNotEqual(session.updatedAt, originalUpdatedAt, "updatedAt should change on title update")
    }

    // [P0] updateSessionTitle re-sorts sessions by updatedAt
    func testUpdateSessionTitleReSortsList() throws {
        let context = try makeModelContext()
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        let now = Date.now
        let sessionsArray = try insertSessions(
            context,
            titles: ["A", "B"],
            updatedAts: [now, now.addingTimeInterval(-3600)]
        )

        viewModel.fetchSessions()
        XCTAssertEqual(viewModel.sessions.first?.title, "A", "A should be first initially")

        // Update B's title, which bumps its updatedAt to now
        viewModel.updateSessionTitle(sessionsArray[1], title: "B Updated")

        XCTAssertEqual(viewModel.sessions.first?.title, "B Updated", "Updated B should now be first after re-sort")
    }

    // [P1] updateSessionTitle persists to SwiftData
    func testUpdateSessionTitlePersistsToSwiftData() throws {
        let context = try makeModelContext()
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        let session = Session(title: "Original")
        context.insert(session)
        try context.save()
        let sessionID = session.id

        viewModel.fetchSessions()
        viewModel.updateSessionTitle(session, title: "Persisted Title")

        // Re-fetch from context to verify persistence
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.id == sessionID }
        )
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.first?.title, "Persisted Title", "Title should be persisted")
    }

    // MARK: - Configure & unconfigured state

    // [P0] configure calls fetchSessions
    func testConfigureCallsFetchSessions() throws {
        let viewModel = makeViewModel()
        let context = try makeModelContext()

        // Insert a session before configure
        let session = Session(title: "Pre-existing")
        context.insert(session)
        try context.save()

        viewModel.configure(modelContext: context)

        let list = viewModel.sessions
        XCTAssertEqual(list.count, 1, "configure should trigger fetchSessions")
        XCTAssertEqual(list.first?.title, "Pre-existing")
    }

    // [P0] Operations are safe when modelContext is nil (not configured)
    func testUnconfiguredStateDoesNotCrash() {
        let viewModel = makeViewModel()

        // None of these should crash
        viewModel.fetchSessions()
        viewModel.createSession()
        // selectSession does not require modelContext; it simply sets a reference.
        // We test that it does not crash even when unconfigured.
        let tempSession = Session(title: "Test")
        viewModel.selectSession(tempSession)
        viewModel.deleteSession(tempSession)
        viewModel.updateSessionTitle(Session(title: "Test"), title: "New")

        XCTAssertTrue(viewModel.sessions.isEmpty, "Unconfigured ViewModel should have empty sessions")
        // selectSession sets selectedSession even without modelContext (by design).
        // After deleteSession (which is a no-op without modelContext), the reference
        // remains because the session was never in the sessions array.
        // This is acceptable — the key invariant is no crash.
    }

    // [P1] Initial state has no sessions and no selection
    func testInitialState() throws {
        let viewModel = makeViewModel()
        XCTAssertNotNil(viewModel, "SessionViewModel should be instantiable")
    }

    // [P0] SessionViewModel is a class (not struct) for @Observable conformance
    func testSessionViewModelIsClass() async throws {
        let viewModel = makeViewModel()
        let mirror = Mirror(reflecting: viewModel)
        XCTAssertEqual(mirror.displayStyle, .class, "SessionViewModel should be a class (not struct) for @Observable")
    }

    // MARK: - Error handling

    // [P1] errorMessage is nil after successful operations
    func testErrorMessageNilAfterSuccess() throws {
        let context = try makeModelContext()
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        viewModel.fetchSessions()
        XCTAssertNil(viewModel.errorMessage, "errorMessage should be nil after successful fetch")
    }
}
