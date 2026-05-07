import Foundation
import SwiftData
import OpenAgentSDK

@MainActor
@Observable
final class MCPManagementViewModel {

    // MARK: - Data Source

    var servers: [MCPServerConfig] = []
    var serverStatuses: [String: McpServerStatus] = [:]
    var selectedServerName: String?
    var isLoading = false
    var errorMessage: String?

    // MARK: - Sheet State

    var showAddSheet = false
    var editingConfig: MCPServerConfig?

    // MARK: - Delete Confirmation

    var showDeleteConfirmation = false
    var serverToDelete: String?

    // MARK: - Dependencies

    private let store: MCPServerConfigStore
    private weak var agentBridge: AgentBridge?

    var isShowingEmptyState: Bool {
        servers.isEmpty
    }

    init(store: MCPServerConfigStore, agentBridge: AgentBridge? = nil) {
        self.store = store
        self.agentBridge = agentBridge
    }

    // MARK: - Server List (AC1, AC8)

    func loadServers() async {
        do {
            servers = try store.list()
        } catch {
            errorMessage = error.localizedDescription
            servers = []
        }
    }

    // MARK: - Selection (AC2)

    func selectServer(name: String) {
        if selectedServerName == name {
            selectedServerName = nil
        } else {
            selectedServerName = name
        }
    }

    // MARK: - Status Mapping (AC1, AC7)

    func statusForServer(_ config: MCPServerConfig) -> MCPServerDisplayStatus {
        if !config.enabled { return .disabled }
        guard let sdkStatus = serverStatuses[config.name] else {
            return (agentBridge?.isRunning ?? false) ? .disconnected : .offline
        }
        return MCPServerDisplayStatus.from(sdkStatus.status)
    }

    // MARK: - Refresh Status (AC1, AC7)

    func refreshStatus() async {
        guard let bridge = agentBridge, bridge.isRunning else {
            serverStatuses = [:]
            return
        }
        serverStatuses = await bridge.mcpServerStatus()
    }

    // MARK: - Toggle Enable/Disable (AC3, AC4)

    func toggleServer(name: String, enabled: Bool) async {
        do {
            try await agentBridge?.toggleMcpServer(name: name, enabled: enabled)
        } catch {
            errorMessage = "切换失败: \(error.localizedDescription)"
        }
        await loadServers()
    }

    // MARK: - Delete (AC5)

    func deleteServer(name: String) async throws {
        let configs = try store.list()
        guard let config = configs.first(where: { $0.name == name }) else { return }
        try store.delete(config)
        if selectedServerName == name {
            selectedServerName = nil
        }
        // Hot-remove from running Agent's tool pool
        agentBridge?.updateMCPServers()
        await loadServers()
    }

    func confirmDelete(name: String) {
        serverToDelete = name
        showDeleteConfirmation = true
    }

    func performDelete() async {
        guard let name = serverToDelete else { return }
        showDeleteConfirmation = false
        do {
            try await deleteServer(name: name)
        } catch {
            errorMessage = error.localizedDescription
        }
        serverToDelete = nil
    }

    // MARK: - Reconnect (AC6)

    func reconnectServer(name: String) async {
        do {
            try await agentBridge?.reconnectMcpServer(name: name)
        } catch {
            errorMessage = "重连失败: \(error.localizedDescription)"
        }
        await refreshStatus()
    }

    // MARK: - Sheet Callbacks

    func onAddSheetDismiss() async {
        await loadServers()
        // Hot-add new MCP server to running Agent's tool pool
        agentBridge?.updateMCPServers()
    }

    func onEditSheetDismiss() async {
        await loadServers()
        // Hot-update MCP server config on running Agent
        agentBridge?.updateMCPServers()
    }
}
