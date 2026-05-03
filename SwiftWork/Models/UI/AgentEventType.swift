import Foundation

enum AgentEventType: String, Codable, CaseIterable, Sendable {
    case partialMessage
    case assistant
    case toolUse
    case toolResult
    case toolProgress
    case result
    case userMessage
    case system
    case hookStarted
    case hookProgress
    case hookResponse
    case taskStarted
    case taskProgress
    case authStatus
    case filesPersisted
    case localCommandOutput
    case promptSuggestion
    case toolUseSummary
    case plan
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = AgentEventType(rawValue: rawValue) ?? .unknown
    }
}
