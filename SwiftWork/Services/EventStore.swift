import Foundation
import SwiftData

@MainActor
protocol EventStoring {
    func persist(_ event: AgentEvent, session: Session, order: Int) throws
    func fetchEvents(for sessionID: UUID) throws -> [AgentEvent]
}

@MainActor
final class SwiftDataEventStore: EventStoring {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func persist(_ event: AgentEvent, session: Session, order: Int) throws {
        let data = try EventSerializer.serialize(event)
        let stored = Event(
            sessionID: session.id,
            eventType: event.type.rawValue,
            rawData: data,
            timestamp: event.timestamp,
            order: order
        )
        stored.session = session
        modelContext.insert(stored)
        try modelContext.save()
    }

    func fetchEvents(for sessionID: UUID) throws -> [AgentEvent] {
        let descriptor = FetchDescriptor<Event>(
            predicate: #Predicate { $0.sessionID == sessionID },
            sortBy: [SortDescriptor(\.order)]
        )
        let stored = try modelContext.fetch(descriptor)
        return stored.compactMap { try? EventSerializer.deserialize($0) }
    }
}
