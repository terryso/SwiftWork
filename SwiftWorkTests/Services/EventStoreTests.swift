import XCTest
@testable import SwiftWork
import SwiftData

@MainActor
final class EventStoreTests: XCTestCase {

    private func makeContext() throws -> (ModelContainer, ModelContext) {
        let schema = Schema([Session.self as any PersistentModel.Type, Event.self as any PersistentModel.Type])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)
        return (container, context)
    }

    private func makeStore(context: ModelContext) -> SwiftDataEventStore {
        SwiftDataEventStore(modelContext: context)
    }

    private func makeSession(context: ModelContext) throws -> Session {
        let session = Session(title: "Test")
        context.insert(session)
        try context.save()
        return session
    }

    // MARK: - Persist + Fetch round-trip

    func testPersistAndFetchRoundTrip() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let session = try makeSession(context: context)

        let event = AgentEvent(type: .userMessage, content: "Hello", timestamp: .now)
        try store.persist(event, session: session, order: 0)

        let fetched = try store.fetchEvents(for: session.id)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.type, .userMessage)
        XCTAssertEqual(fetched.first?.content, "Hello")
    }

    func testFetchEventsReturnsEventsInOrder() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let session = try makeSession(context: context)

        let event1 = AgentEvent(type: .userMessage, content: "First", timestamp: .now)
        let event2 = AgentEvent(type: .assistant, content: "Second", timestamp: .now)
        let event3 = AgentEvent(type: .userMessage, content: "Third", timestamp: .now)

        try store.persist(event1, session: session, order: 0)
        try store.persist(event2, session: session, order: 1)
        try store.persist(event3, session: session, order: 2)

        let fetched = try store.fetchEvents(for: session.id)
        XCTAssertEqual(fetched.count, 3)
        XCTAssertEqual(fetched[0].content, "First")
        XCTAssertEqual(fetched[1].content, "Second")
        XCTAssertEqual(fetched[2].content, "Third")
    }

    func testFetchEventsForWrongSessionReturnsEmpty() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let session = try makeSession(context: context)

        let event = AgentEvent(type: .userMessage, content: "Hello", timestamp: .now)
        try store.persist(event, session: session, order: 0)

        let wrongID = UUID()
        let fetched = try store.fetchEvents(for: wrongID)
        XCTAssertTrue(fetched.isEmpty, "Fetching with wrong session ID should return empty")
    }

    func testPersistMultipleEventsAndFetchAll() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let session = try makeSession(context: context)

        for i in 0..<5 {
            let event = AgentEvent(type: .userMessage, content: "Event \(i)", timestamp: .now)
            try store.persist(event, session: session, order: i)
        }

        let fetched = try store.fetchEvents(for: session.id)
        XCTAssertEqual(fetched.count, 5)
    }

    func testPersistEventWithMetadata() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let session = try makeSession(context: context)

        let event = AgentEvent(
            type: .toolUse,
            content: "Bash",
            metadata: ["toolUseId" as String: "tu-001" as any Sendable],
            timestamp: .now
        )
        try store.persist(event, session: session, order: 0)

        let fetched = try store.fetchEvents(for: session.id)
        XCTAssertEqual(fetched.first?.metadata["toolUseId"] as? String, "tu-001")
    }

    func testFetchEventsEmptyWhenNoEventsPersisted() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let session = try makeSession(context: context)

        let fetched = try store.fetchEvents(for: session.id)
        XCTAssertTrue(fetched.isEmpty)
    }
}
