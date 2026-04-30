import Foundation

enum PermissionDecision: Sendable {
    case approved
    case denied(reason: String)
    case requiresApproval(
        toolName: String,
        description: String,
        parameters: [String: any Sendable]
    )
}
