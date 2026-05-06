import Foundation

struct AgentEvent: Identifiable, Sendable {
    let id: UUID
    let type: AgentEventType
    let content: String
    let metadata: [String: any Sendable]
    let timestamp: Date

    init(
        id: UUID = UUID(),
        type: AgentEventType,
        content: String,
        metadata: [String: any Sendable] = [:],
        timestamp: Date
    ) {
        self.id = id
        self.type = type
        self.content = content
        self.metadata = metadata
        self.timestamp = timestamp
    }

    var isHiddenToolUseTransitionAssistant: Bool {
        type == .assistant &&
            content.isEmpty &&
            (metadata["stopReason"] as? String) == "tool_use"
    }
}
