import XCTest
@testable import SwiftWork
import SwiftData

// ATDD Red Phase — Story 1.3: 会话管理与 Sidebar
// Integration tests for session management flow: ContentView integration,
// SwiftData persistence, cascade delete, and NavigationSplitView wiring.

@MainActor
final class SessionManagementIntegrationTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeModelContext() throws -> ModelContext {
        let schema = Schema([Session.self, Event.self, AppConfiguration.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    private func makeConfiguredViewModel() throws -> (SessionViewModel, ModelContext) {
        let viewModel = SessionViewModel()
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)
        return (viewModel, context)
    }

    // Mirror-based accessors removed — using SessionViewModel extension from SessionViewModelTests.swift
    // After implementation, use direct property access: vm.sessions, vm.selectedSession

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

    // MARK: - AC#1: Session list display in Sidebar

    // [P0] SidebarView can be instantiated
    func testSidebarViewInstantiation() {
        let vm = SessionViewModel()
        let sidebarView = SidebarView(sessionViewModel: vm)
        XCTAssertNotNil(sidebarView, "SidebarView should be instantiable")
    }

    // [P0] SessionRowView can be instantiated
    func testSessionRowViewInstantiation() {
        let session = Session(title: "Test")
        let rowView = SessionRowView(session: session)
        XCTAssertNotNil(rowView, "SessionRowView should be instantiable")
    }

    // [P1] ContentView integrates SessionViewModel (instantiation check)
    func testContentViewHasSessionViewModel() {
        let contentView = ContentView()
        XCTAssertNotNil(contentView, "ContentView should be instantiable with SessionViewModel integration")
    }

    // MARK: - AC#2: Create session flow (end-to-end)

    // [P0] Creating a session persists and is retrievable via new ModelContext
    func testSessionCreationEndToEnd() throws {
        let schema = Schema([Session.self, Event.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)

        let context = ModelContext(container)
        let viewModel = SessionViewModel()
        viewModel.configure(modelContext: context)

        viewModel.createSession()

        XCTAssertEqual(viewModel.sessions.count, 1)
        XCTAssertNotNil(viewModel.selectedSession)

        // Verify in a fresh context
        let freshContext = ModelContext(container)
        let descriptor = FetchDescriptor<Session>()
        let persisted = try freshContext.fetch(descriptor)
        XCTAssertEqual(persisted.count, 1, "Session should survive context recreation")
        XCTAssertEqual(persisted.first?.title, "新会话")
    }

    // [P1] Multiple sessions can be created and all persist
    func testMultipleSessionCreation() throws {
        let (viewModel, _) = try makeConfiguredViewModel()

        viewModel.createSession()
        viewModel.createSession()
        viewModel.createSession()

        let list = viewModel.sessions
        let selected = viewModel.selectedSession
        XCTAssertEqual(list.count, 3, "Should have 3 sessions")
        XCTAssertEqual(selected?.id, list.first?.id, "Last created should be selected")
    }

    // MARK: - AC#3: Session switching (end-to-end)

    // [P0] Switching sessions preserves data in both sessions
    func testSessionSwitchingPreservesData() throws {
        let (viewModel, context) = try makeConfiguredViewModel()

        let now = Date.now
        let sessionsArray = try insertSessions(
            context,
            titles: ["Session Alpha", "Session Beta"],
            updatedAts: [now, now.addingTimeInterval(-60)]
        )

        viewModel.fetchSessions()

        // Add events to Session Alpha
        let event = Event(
            sessionID: sessionsArray[0].id,
            eventType: "partialMessage",
            rawData: Data("hello".utf8),
            timestamp: .now,
            order: 0
        )
        sessionsArray[0].events.append(event)
        context.insert(event)
        try context.save()

        // Switch to Session Beta
        viewModel.selectSession(sessionsArray[1])
        XCTAssertEqual(viewModel.selectedSession?.title, "Session Beta")

        // Switch back to Session Alpha — events should still be there
        viewModel.selectSession(sessionsArray[0])
        XCTAssertEqual(viewModel.selectedSession?.events.count, 1, "Events should persist after switching back")
    }

    // MARK: - Cascade delete (SwiftData relationship verification)

    // [P0] Deleting a session cascade-deletes all its events
    func testCascadeDeleteRemovesAllEvents() throws {
        let (viewModel, context) = try makeConfiguredViewModel()

        let session = Session(title: "To Delete")
        context.insert(session)

        // Add multiple events
        for i in 0..<5 {
            let event = Event(
                sessionID: session.id,
                eventType: "partialMessage",
                rawData: Data("event \(i)".utf8),
                timestamp: .now,
                order: i
            )
            session.events.append(event)
            context.insert(event)
        }
        try context.save()

        XCTAssertEqual(session.events.count, 5)

        viewModel.fetchSessions()
        viewModel.deleteSession(session)

        // Verify all events are gone
        let allEvents = try context.fetch(FetchDescriptor<Event>())
        XCTAssertTrue(allEvents.isEmpty, "All events should be cascade-deleted with session")
    }

    // [P1] Deleting one session does not affect another session's events
    func testDeleteSessionDoesNotAffectOtherSessionEvents() throws {
        let (viewModel, context) = try makeConfiguredViewModel()

        let now = Date.now
        let sessionsArray = try insertSessions(
            context,
            titles: ["Keep", "Delete"],
            updatedAts: [now, now.addingTimeInterval(-60)]
        )

        // Add events to both sessions
        let keepEvent = Event(
            sessionID: sessionsArray[0].id,
            eventType: "partialMessage",
            rawData: Data("keep".utf8),
            timestamp: .now,
            order: 0
        )
        sessionsArray[0].events.append(keepEvent)
        context.insert(keepEvent)

        let deleteEvent = Event(
            sessionID: sessionsArray[1].id,
            eventType: "partialMessage",
            rawData: Data("delete".utf8),
            timestamp: .now,
            order: 0
        )
        sessionsArray[1].events.append(deleteEvent)
        context.insert(deleteEvent)
        try context.save()

        viewModel.fetchSessions()
        viewModel.deleteSession(sessionsArray[1])

        // "Keep" session's event should still exist
        XCTAssertEqual(sessionsArray[0].events.count, 1, "Remaining session should still have its event")
    }

    // MARK: - AC#1: Session ordering after various operations

    // [P0] Sessions remain correctly ordered after mixed CRUD operations
    func testSessionOrderingAfterCRUDOperations() throws {
        let (viewModel, context) = try makeConfiguredViewModel()

        let now = Date.now
        let sessionsArray = try insertSessions(
            context,
            titles: ["A", "B"],
            updatedAts: [now.addingTimeInterval(-7200), now.addingTimeInterval(-3600)]
        )

        viewModel.fetchSessions()
        XCTAssertEqual(viewModel.sessions.first?.title, "B", "B is newer, should be first")

        // Update A's title — this bumps its updatedAt
        viewModel.updateSessionTitle(sessionsArray[0], title: "A Updated")

        XCTAssertEqual(viewModel.sessions.first?.title, "A Updated", "A should now be first after update")

        // Create a new session — should go to head
        viewModel.createSession()
        XCTAssertEqual(viewModel.sessions.first?.title, "新会话", "New session should be at head")
    }
}
