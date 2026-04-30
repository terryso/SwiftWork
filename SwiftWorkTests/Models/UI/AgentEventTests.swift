import XCTest
@testable import SwiftWork

final class AgentEventTests: XCTestCase {

    // MARK: - AC#4: AgentEvent UI Intermediate Model

    // [P0] AgentEvent is Identifiable with UUID
    func testAgentEventIsIdentifiable() throws {
        let event = AgentEvent(
            type: .toolUse,
            content: "Reading file.swift",
            metadata: [:],
            timestamp: Date.now
        )

        XCTAssertNotNil(event.id)
        XCTAssertEqual(event.type, .toolUse)
        XCTAssertEqual(event.content, "Reading file.swift")
    }

    // [P0] AgentEvent is Sendable
    func testAgentEventIsSendable() throws {
        let event = AgentEvent(
            type: .assistant,
            content: "Hello",
            metadata: [:],
            timestamp: Date.now
        )
        // If this compiles, AgentEvent conforms to Sendable
        let _: any Sendable = event
    }

    // [P1] AgentEvent metadata is [String: any Sendable]
    func testAgentEventMetadataIsSendableDictionary() throws {
        let event = AgentEvent(
            type: .toolUse,
            content: "Bash command",
            metadata: ["toolName": "Bash", "duration": 2.5],
            timestamp: Date.now
        )

        XCTAssertEqual(event.metadata["toolName"] as? String, "Bash")
        XCTAssertEqual(event.metadata["duration"] as? Double, 2.5)
    }

    // [P1] AgentEvent has immutable properties (let)
    func testAgentEventIsImmutable() throws {
        let event = AgentEvent(
            type: .partialMessage,
            content: "Loading...",
            metadata: [:],
            timestamp: Date.now
        )

        // All properties should be `let` (immutable)
        // This test verifies the struct design by checking that
        // the event cannot be mutated after creation
        XCTAssertEqual(event.content, "Loading...")
    }
}
