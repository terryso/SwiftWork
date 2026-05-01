import Foundation

enum EventSerializer {
    private enum Keys {
        static let id = "id"
        static let type = "type"
        static let content = "content"
        static let metadata = "metadata"
        static let timestamp = "timestamp"
    }

    static func serialize(_ event: AgentEvent) throws -> Data {
        var dict: [String: Any] = [
            Keys.id: event.id.uuidString,
            Keys.type: event.type.rawValue,
            Keys.content: event.content,
            Keys.timestamp: event.timestamp.timeIntervalSinceReferenceDate
        ]
        if !event.metadata.isEmpty {
            dict[Keys.metadata] = event.metadata
        }
        return try JSONSerialization.data(withJSONObject: dict)
    }

    static func deserialize(_ stored: Event) throws -> AgentEvent {
        guard let dict = try JSONSerialization.jsonObject(with: stored.rawData) as? [String: Any] else {
            throw AppError(
                domain: .data,
                code: "EVENT_DESERIALIZE_FAILED",
                message: "Event rawData is not a JSON dictionary"
            )
        }

        guard let idString = dict[Keys.id] as? String,
              let id = UUID(uuidString: idString),
              let typeRaw = dict[Keys.type] as? String,
              let type = AgentEventType(rawValue: typeRaw),
              let content = dict[Keys.content] as? String,
              let timestampInterval = dict[Keys.timestamp] as? Double
        else {
            throw AppError(
                domain: .data,
                code: "EVENT_DESERIALIZE_INVALID_FIELDS",
                message: "Event missing required fields"
            )
        }

        let metadata = dict[Keys.metadata] as? [String: any Sendable] ?? [:]
        let timestamp = Date(timeIntervalSinceReferenceDate: timestampInterval)

        return AgentEvent(
            id: id,
            type: type,
            content: content,
            metadata: metadata,
            timestamp: timestamp
        )
    }
}
