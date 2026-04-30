import XCTest
@testable import SwiftWork
import SwiftData

final class SessionModelTests: XCTestCase {

    // MARK: - AC#4: Session Model Definition

    // [P0] Session can be instantiated with required properties
    func testSessionInstantiation() throws {
        let session = Session(title: "Test Session")

        XCTAssertEqual(session.title, "Test Session")
        XCTAssertNotNil(session.id)
        XCTAssertNotNil(session.createdAt)
        XCTAssertNotNil(session.updatedAt)
    }

    // [P0] Session uses UUID as unique primary key
    func testSessionHasUUIDPrimaryKey() throws {
        let sessionA = Session(title: "A")
        let sessionB = Session(title: "B")

        XCTAssertNotEqual(sessionA.id, sessionB.id)
    }

    // [P0] Session default title is "新会话"
    func testSessionDefaultTitle() throws {
        let session = Session()

        XCTAssertEqual(session.title, "新会话")
    }

    // [P1] Session timestamps are set to Date.now on creation
    func testSessionTimestampsOnInit() throws {
        let before = Date.now
        let session = Session()
        let after = Date.now

        XCTAssertGreaterThanOrEqual(session.createdAt, before)
        XCTAssertLessThanOrEqual(session.createdAt, after)
        XCTAssertGreaterThanOrEqual(session.updatedAt, before)
        XCTAssertLessThanOrEqual(session.updatedAt, after)
    }

    // [P0] Session has cascade-delete relationship to Event
    func testSessionEventCascadeDelete() throws {
        let session = Session(title: "Delete Test")
        let event = Event(
            sessionID: session.id,
            eventType: "partialMessage",
            rawData: Data(),
            timestamp: Date.now,
            order: 0
        )
        session.events.append(event)

        XCTAssertEqual(session.events.count, 1)

        // When session is deleted, events should cascade-delete
        // This will be verified through SwiftData ModelContext in integration tests
    }

    // [P1] Session workspacePath is optional (nullable)
    func testSessionWorkspacePathIsOptional() throws {
        let session = Session(title: "No Workspace")

        XCTAssertNil(session.workspacePath)

        session.workspacePath = "/Users/test/project"
        XCTAssertEqual(session.workspacePath, "/Users/test/project")
    }

    // [P1] Session is a SwiftData @Model class (PersistentModel)
    func testSessionIsSwiftDataModel() throws {
        let session = Session(title: "SwiftData Check")
        // Session is a @Model class; verify it can be created and used
        XCTAssertNotNil(session.id)
        XCTAssertNotNil(session.createdAt)
    }
}
