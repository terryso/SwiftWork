import Foundation

struct PermissionAuditEntry: Sendable {
    enum AuditDecision: String, Sendable, Equatable {
        case approved
        case denied
    }

    let toolName: String
    let input: String
    let decision: AuditDecision
    let timestamp: Date
    let sessionOverride: Bool
}
