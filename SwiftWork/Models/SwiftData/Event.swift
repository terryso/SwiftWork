import Foundation
import SwiftData

@Model
final class Event {
    @Attribute(.unique) var id: UUID
    var sessionID: UUID
    var eventType: String
    var rawData: Data
    var timestamp: Date
    var order: Int
    var session: Session?

    init(
        sessionID: UUID,
        eventType: String,
        rawData: Data,
        timestamp: Date,
        order: Int
    ) {
        self.id = UUID()
        self.sessionID = sessionID
        self.eventType = eventType
        self.rawData = rawData
        self.timestamp = timestamp
        self.order = order
    }
}
