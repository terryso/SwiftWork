import Foundation
import SwiftData

enum Decision: String, Codable, Sendable {
    case allow
    case deny
}

@Model
final class PermissionRule {
    @Attribute(.unique) var id: UUID
    var toolName: String
    var pattern: String
    var decision: Decision
    var createdAt: Date

    init(
        toolName: String,
        pattern: String,
        decision: Decision
    ) {
        self.id = UUID()
        self.toolName = toolName
        self.pattern = pattern
        self.decision = decision
        self.createdAt = Date.now
    }
}
