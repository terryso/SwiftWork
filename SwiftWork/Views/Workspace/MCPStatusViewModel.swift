import Foundation
import OpenAgentSDK

/// ViewModel for the WorkspaceStatusBar MCP connection status display.
/// Provides computed properties for MCP server connection counts and status summary text.
/// Refreshes runtime status from AgentBridge when the agent is running.
@MainActor
@Observable
final class MCPStatusViewModel {

    // MARK: - Public State

    /// Runtime MCP server statuses from the SDK (keyed by server name).
    var serverStatuses: [String: McpServerStatus] = [:]

    // MARK: - Computed Properties (AC1)

    /// Number of currently connected MCP servers.
    var connectedCount: Int {
        serverStatuses.values.filter { $0.status == .connected }.count
    }

    /// Number of failed MCP servers (includes .failed and .needsAuth).
    var failedCount: Int {
        serverStatuses.values.filter {
            $0.status == .failed || $0.status == .needsAuth
        }.count
    }

    /// Number of MCP servers currently connecting (pending).
    var pendingCount: Int {
        serverStatuses.values.filter { $0.status == .pending }.count
    }

    /// Total number of configured MCP servers from SwiftData.
    var totalConfiguredCount: Int {
        configuredServers.count
    }

    /// Human-readable status summary text for the status bar.
    var statusSummaryText: String {
        if totalConfiguredCount == 0 && serverStatuses.isEmpty {
            return "就绪"
        }

        if pendingCount > 0 {
            return "正在连接..."
        }

        if connectedCount > 0 && failedCount > 0 {
            return "\(connectedCount) MCP 已连接，\(failedCount) 个连接失败"
        }

        if failedCount > 0 {
            return "\(failedCount) 个 MCP 连接失败"
        }

        if connectedCount > 0 {
            return "\(connectedCount) MCP 已连接"
        }

        // Configured but not running — show configured count
        if totalConfiguredCount > 0 {
            return "\(totalConfiguredCount) MCP 已配置"
        }

        return "就绪"
    }

    /// Whether the status bar should show a warning indicator.
    var showsWarning: Bool {
        failedCount > 0
    }

    /// Whether the status bar should show a loading/pending indicator.
    var showsPending: Bool {
        pendingCount > 0
    }

    /// Whether there are any active connections.
    var hasConnections: Bool {
        connectedCount > 0
    }

    // MARK: - Dependencies

    private let store: MCPServerConfigStore
    private weak var agentBridge: AgentBridge?

    private var configuredServers: [MCPServerConfig] = []

    @ObservationIgnored
    private var refreshTask: _Concurrency.Task<Void, Never>?

    init(store: MCPServerConfigStore, agentBridge: AgentBridge? = nil) {
        self.store = store
        self.agentBridge = agentBridge
    }

    // MARK: - Data Loading

    /// Loads configured MCP server list from SwiftData store.
    func loadConfiguredServers() async {
        do {
            configuredServers = try store.list()
        } catch {
            configuredServers = []
        }
    }

    /// Refreshes runtime MCP server statuses from the running Agent.
    func refreshStatus() async {
        guard let bridge = agentBridge, bridge.isRunning else {
            serverStatuses = [:]
            return
        }
        serverStatuses = await bridge.mcpServerStatus()
    }

    // MARK: - Agent Lifecycle

    /// Called when the Agent running state changes.
    /// Triggers status refresh and starts/stops periodic updates.
    func onAgentRunningChanged(isRunning: Bool) async {
        if isRunning {
            await refreshStatus()
            await loadConfiguredServers()
        } else {
            serverStatuses = [:]
            await loadConfiguredServers()
        }
    }

    // MARK: - Periodic Refresh

    /// Starts periodic status refresh (every 5 seconds) while the Agent is running.
    func startPeriodicRefresh() {
        stopPeriodicRefresh()
        refreshTask = _Concurrency.Task { [weak self] in
            while !_Concurrency.Task.isCancelled {
                try? await _Concurrency.Task.sleep(nanoseconds: 5_000_000_000)
                guard !_Concurrency.Task.isCancelled else { return }
                await self?.refreshStatus()
            }
        }
    }

    /// Stops the periodic refresh timer.
    func stopPeriodicRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}
