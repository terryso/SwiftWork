import SwiftUI

extension Color {
    static func forEventType(_ type: AgentEventType) -> Color {
        switch type {
        case .toolUse, .toolResult, .toolProgress: return .blue
        case .result: return .green
        case .assistant: return .purple
        case .userMessage: return .orange
        case .system: return .gray
        case .plan: return .teal
        default: return .secondary
        }
    }
}
