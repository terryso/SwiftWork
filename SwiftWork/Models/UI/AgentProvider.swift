import Foundation

enum AgentProvider: String, CaseIterable, Identifiable, Sendable {
    case anthropic
    case openAI = "openai"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .anthropic:
            "Anthropic"
        case .openAI:
            "OpenAI Compatible"
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .anthropic:
            "https://api.anthropic.com"
        case .openAI:
            "https://api.openai.com/v1"
        }
    }
}
