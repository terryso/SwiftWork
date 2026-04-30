import XCTest
@testable import SwiftWork

final class EventModelTests: XCTestCase {

    // MARK: - AC#4: Event Model Definition

    // [P0] Event can be instantiated with required properties
    func testEventInstantiation() throws {
        let sessionID = UUID()
        let rawData = Data("{\"text\": \"hello\"}".utf8)
        let event = Event(
            sessionID: sessionID,
            eventType: "partialMessage",
            rawData: rawData,
            timestamp: Date.now,
            order: 0
        )

        XCTAssertEqual(event.sessionID, sessionID)
        XCTAssertEqual(event.eventType, "partialMessage")
        XCTAssertEqual(event.rawData, rawData)
        XCTAssertNotNil(event.id)
    }

    // [P0] Event has UUID unique primary key
    func testEventHasUUIDPrimaryKey() throws {
        let eventA = Event(sessionID: UUID(), eventType: "toolUse", rawData: Data(), timestamp: Date.now, order: 0)
        let eventB = Event(sessionID: UUID(), eventType: "toolUse", rawData: Data(), timestamp: Date.now, order: 1)

        XCTAssertNotEqual(eventA.id, eventB.id)
    }

    // [P1] Event stores eventType as raw String (SDKMessage case name)
    func testEventEventTypeIsRawString() throws {
        let allKnownTypes = [
            "partialMessage", "assistant", "toolUse", "toolResult", "toolProgress",
            "result", "userMessage", "system",
            "hookStarted", "hookProgress", "hookResponse",
            "taskStarted", "taskProgress",
            "authStatus", "filesPersisted", "localCommandOutput",
            "promptSuggestion", "toolUseSummary"
        ]

        for (index, eventType) in allKnownTypes.enumerated() {
            let event = Event(
                sessionID: UUID(),
                eventType: eventType,
                rawData: Data(),
                timestamp: Date.now,
                order: index
            )
            XCTAssertEqual(event.eventType, eventType)
        }
    }

    // [P1] Event rawData stores full JSON (not expanded fields)
    func testEventRawDataIsJSONData() throws {
        let json = """
        {"toolName": "Read", "toolUseId": "abc-123", "input": "{}"}
        """
        let rawData = Data(json.utf8)

        let event = Event(
            sessionID: UUID(),
            eventType: "toolUse",
            rawData: rawData,
            timestamp: Date.now,
            order: 0
        )

        XCTAssertEqual(event.rawData, rawData)
        // Verify the raw data is valid JSON
        let parsed = try JSONSerialization.jsonObject(with: event.rawData)
        XCTAssertNotNil(parsed)
    }

    // [P1] Event order property is used for timeline sorting
    func testEventOrderForSorting() throws {
        let event0 = Event(sessionID: UUID(), eventType: "a", rawData: Data(), timestamp: Date.now, order: 0)
        let event1 = Event(sessionID: UUID(), eventType: "b", rawData: Data(), timestamp: Date.now, order: 1)
        let event2 = Event(sessionID: UUID(), eventType: "c", rawData: Data(), timestamp: Date.now, order: 2)

        let sorted = [event2, event0, event1].sorted { $0.order < $1.order }
        XCTAssertEqual(sorted.map(\.eventType), ["a", "b", "c"])
    }

    // [P0] Event has inverse relationship to Session
    func testEventSessionInverseRelationship() throws {
        let session = Session(title: "Rel Test")
        let event = Event(
            sessionID: session.id,
            eventType: "partialMessage",
            rawData: Data(),
            timestamp: Date.now,
            order: 0
        )

        // Event should have optional session reference
        XCTAssertNil(event.session) // Not yet associated

        session.events.append(event)
        XCTAssertNotNil(event.session)
        XCTAssertEqual(event.session?.id, session.id)
    }
}
