import Foundation
import SwiftData

@Model
final class Session {
    enum WorkspaceBindingMode: String, Codable, Sendable {
        case bound
        case unbound
    }

    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var workspacePath: String?
    var workspaceBookmark: Data?
    var hasUnreadResult: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \Event.session)
    var events: [Event]

    init(
        title: String = "新会话",
        workspacePath: String? = nil,
        workspaceBookmark: Data? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date.now
        self.updatedAt = Date.now
        self.workspacePath = workspacePath
        self.workspaceBookmark = workspaceBookmark
        self.events = []
    }

    var workspaceBindingMode: WorkspaceBindingMode {
        workspacePath == nil ? .unbound : .bound
    }
}
