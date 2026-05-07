import SwiftUI
import OpenAgentSDK

/// UI-layer status enum that maps SDK `McpServerStatusEnum` to display states.
enum MCPServerDisplayStatus: Equatable, Sendable {
    case connected
    case failed
    case pending
    case disabled
    case disconnected
    case offline

    var colorName: String {
        switch self {
        case .connected: return "green"
        case .failed: return "red"
        case .pending: return "orange"
        case .disabled, .disconnected, .offline: return "gray"
        }
    }

    var color: Color {
        switch self {
        case .connected: return .green
        case .failed: return .red
        case .pending: return .orange
        case .disabled, .disconnected, .offline: return .gray
        }
    }

    var label: String {
        switch self {
        case .connected: return "已连接"
        case .failed: return "连接失败"
        case .pending: return "连接中..."
        case .disabled: return "已禁用"
        case .disconnected: return "未连接"
        case .offline: return "离线"
        }
    }

    static func from(_ sdkStatus: McpServerStatusEnum) -> MCPServerDisplayStatus {
        switch sdkStatus {
        case .connected: return .connected
        case .failed: return .failed
        case .pending: return .pending
        case .disabled: return .disabled
        case .needsAuth: return .failed
        }
    }
}
