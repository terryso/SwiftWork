import XCTest
@testable import SwiftWork

final class EventSerializerTests: XCTestCase {

    private func makeEvent(
        type: AgentEventType = .assistant,
        content: String = "test content",
        metadata: [String: any Sendable] = [:]
    ) -> AgentEvent {
        AgentEvent(type: type, content: content, metadata: metadata, timestamp: .now)
    }

    // MARK: - Round-trip

    func testRoundTripSerializeDeserialize() throws {
        let original = makeEvent(
            type: .assistant,
            content: "Hello world",
            metadata: ["model": "claude-sonnet-4-6" as any Sendable]
        )

        let data = try EventSerializer.serialize(original)
        let stored = Event(
            sessionID: UUID(),
            eventType: original.type.rawValue,
            rawData: data,
            timestamp: original.timestamp,
            order: 0
        )
        let restored = try EventSerializer.deserialize(stored)

        XCTAssertEqual(restored.id, original.id)
        XCTAssertEqual(restored.type, original.type)
        XCTAssertEqual(restored.content, original.content)
        XCTAssertEqual(restored.metadata["model"] as? String, "claude-sonnet-4-6")
    }

    func testRoundTripPreservesTimestamp() throws {
        let original = makeEvent()
        let data = try EventSerializer.serialize(original)
        let stored = Event(
            sessionID: UUID(),
            eventType: original.type.rawValue,
            rawData: data,
            timestamp: original.timestamp,
            order: 0
        )
        let restored = try EventSerializer.deserialize(stored)

        XCTAssertEqual(restored.timestamp.timeIntervalSinceReferenceDate,
                       original.timestamp.timeIntervalSinceReferenceDate,
                       accuracy: 0.001)
    }

    // MARK: - Serialize

    func testSerializeIncludesRequiredFields() throws {
        let event = makeEvent(type: .userMessage, content: "hi")
        let data = try EventSerializer.serialize(event)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(dict)
        XCTAssertNotNil(dict?["id"])
        XCTAssertEqual(dict?["type"] as? String, "userMessage")
        XCTAssertEqual(dict?["content"] as? String, "hi")
        XCTAssertNotNil(dict?["timestamp"])
    }

    func testSerializeOmitsMetadataWhenEmpty() throws {
        let event = makeEvent(metadata: [:])
        let data = try EventSerializer.serialize(event)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNil(dict?["metadata"], "metadata key should be omitted when empty")
    }

    func testSerializePreservesMetadataWhenNonEmpty() throws {
        let event = makeEvent(metadata: ["key": "value" as any Sendable, "num": 42 as any Sendable])
        let data = try EventSerializer.serialize(event)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(dict?["metadata"])
        let metadata = dict?["metadata"] as? [String: Any]
        XCTAssertEqual(metadata?["key"] as? String, "value")
        XCTAssertEqual(metadata?["num"] as? Int, 42)
    }

    // MARK: - Deserialize errors

    func testDeserializeThrowsOnInvalidJSON() throws {
        let stored = Event(
            sessionID: UUID(),
            eventType: "test",
            rawData: Data("not json".utf8),
            timestamp: .now,
            order: 0
        )
        XCTAssertThrowsError(try EventSerializer.deserialize(stored))
    }

    func testDeserializeThrowsOnMissingRequiredFields() throws {
        let dict: [String: Any] = ["id": "not-a-uuid"]
        let data = try JSONSerialization.data(withJSONObject: dict)
        let stored = Event(
            sessionID: UUID(),
            eventType: "test",
            rawData: data,
            timestamp: .now,
            order: 0
        )
        XCTAssertThrowsError(try EventSerializer.deserialize(stored))
    }

    func testDeserializeThrowsOnInvalidType() throws {
        let uuid = UUID().uuidString
        let dict: [String: Any] = [
            "id": uuid,
            "type": "nonExistentType",
            "content": "text",
            "timestamp": Date.now.timeIntervalSinceReferenceDate
        ]
        let data = try JSONSerialization.data(withJSONObject: dict)
        let stored = Event(
            sessionID: UUID(),
            eventType: "test",
            rawData: data,
            timestamp: .now,
            order: 0
        )
        XCTAssertThrowsError(try EventSerializer.deserialize(stored))
    }

    func testDeserializeHandlesMissingOptionalMetadata() throws {
        let uuid = UUID().uuidString
        let dict: [String: Any] = [
            "id": uuid,
            "type": "assistant",
            "content": "text",
            "timestamp": Date.now.timeIntervalSinceReferenceDate
        ]
        let data = try JSONSerialization.data(withJSONObject: dict)
        let stored = Event(
            sessionID: UUID(),
            eventType: "assistant",
            rawData: data,
            timestamp: .now,
            order: 0
        )
        let event = try EventSerializer.deserialize(stored)
        XCTAssertTrue(event.metadata.isEmpty, "Missing metadata should default to empty")
    }

    // MARK: - All event types round-trip

    func testRoundTripAllEventTypes() throws {
        let types: [AgentEventType] = [
            .partialMessage, .assistant, .toolUse, .toolResult,
            .toolProgress, .result, .userMessage, .system
        ]
        for type in types {
            let event = makeEvent(type: type, content: "\(type) content")
            let data = try EventSerializer.serialize(event)
            let stored = Event(
                sessionID: UUID(),
                eventType: event.type.rawValue,
                rawData: data,
                timestamp: event.timestamp,
                order: 0
            )
            let restored = try EventSerializer.deserialize(stored)
            XCTAssertEqual(restored.type, type, "Round-trip failed for \(type)")
        }
    }
}
