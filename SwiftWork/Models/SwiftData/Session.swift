import Foundation
import SwiftData

@Model
final class Session {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var workspacePath: String?
    @Relationship(deleteRule: .cascade, inverse: \Event.session)
    var events: [Event]

    init(
        title: String = "新会话",
        workspacePath: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date.now
        self.updatedAt = Date.now
        self.workspacePath = workspacePath
        self.events = []
    }
}
