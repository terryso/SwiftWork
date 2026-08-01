import XCTest
@testable import SwiftWork
import SwiftData
import OpenAgentSDK

// ATDD Red Phase -- Story 6.5: MCP 状态可视化
// Unit tests for MCPStatusViewModel (computed properties, status refresh, offline mode).
// These tests assert EXPECTED behavior. They will FAIL until Story 6-5 is implemented.
//
// Coverage:
//   AC1 -- Status Bar MCP 连接数指标（ViewModel 计算属性）
//   AC1 -- Agent 未运行时的离线状态展示
//   AC1 -- Agent 运行时定时刷新机制

@MainActor
final class MCPStatusViewModelTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeContext() throws -> (ModelContainer, ModelContext) {
        let schema = Schema([
            MCPServerConfig.self as any PersistentModel.Type
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)
        return (container, context)
    }

    private func makeStore(context: ModelContext) -> MCPServerConfigStore {
        MCPServerConfigStore(modelContext: context, keychainManager: MockKeychainManager())
    }

    private func makeViewModel(
        store: MCPServerConfigStore,
        agentBridge: AgentBridge? = nil
    ) -> MCPStatusViewModel {
        MCPStatusViewModel(store: store, agentBridge: agentBridge)
    }

    private func addTestConfig(
        to store: MCPServerConfigStore,
        name: String = "test-server",
        transportType: TransportType = .sse,
        enabled: Bool = true
    ) throws -> MCPServerConfig {
        try store.add(
            name: name,
            transportType: transportType,
            command: nil,
            url: transportType == .stdio ? nil : "http://localhost:3000/sse",
            args: nil,
            env: nil,
            headers: nil,
            enabled: enabled,
            scope: .global,
            workspacePath: nil
        )
    }

    // MARK: - AC1: 初始状态

    // [P0] ViewModel initializes with zero connectedCount
    func testViewModelInitializesWithZeroConnectedCount() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel(store: store)

        XCTAssertEqual(viewModel.connectedCount, 0,
            "connectedCount should be 0 on init")
    }

    // [P0] ViewModel initializes with zero failedCount
    func testViewModelInitializesWithZeroFailedCount() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel(store: store)

        XCTAssertEqual(viewModel.failedCount, 0,
            "failedCount should be 0 on init")
    }

    // [P0] ViewModel initializes with zero pendingCount
    func testViewModelInitializesWithZeroPendingCount() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel(store: store)

        XCTAssertEqual(viewModel.pendingCount, 0,
            "pendingCount should be 0 on init")
    }

    // [P0] ViewModel initializes with zero totalConfiguredCount when no configs
    func testViewModelInitializesWithZeroTotalConfiguredCount() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel(store: store)

        XCTAssertEqual(viewModel.totalConfiguredCount, 0,
            "totalConfiguredCount should be 0 when no configs exist")
    }

    // MARK: - AC1: connectedCount 计算属性

    // [P0] connectedCount returns count of connected servers from SDK status
    func testConnectedCountReturnsConnectedServerCount() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "connected-a")
        _ = try addTestConfig(to: store, name: "connected-b")
        _ = try addTestConfig(to: store, name: "failed-one")

        let bridge = AgentBridge()
        let viewModel = makeViewModel(store: store, agentBridge: bridge)

        // Simulate SDK statuses
        viewModel.serverStatuses = [
            "connected-a": McpServerStatus(
                name: "connected-a", status: .connected, error: nil, tools: []
            ),
            "connected-b": McpServerStatus(
                name: "connected-b", status: .connected, error: nil, tools: []
            ),
            "failed-one": McpServerStatus(
                name: "failed-one", status: .failed, error: "timeout", tools: []
            )
        ]

        XCTAssertEqual(viewModel.connectedCount, 2,
            "connectedCount should return 2 for two connected servers")
    }

    // [P0] connectedCount returns 0 when all servers failed
    func testConnectedCountReturnsZeroWhenAllFailed() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "fail-a")
        _ = try addTestConfig(to: store, name: "fail-b")

        let bridge = AgentBridge()
        let viewModel = makeViewModel(store: store, agentBridge: bridge)

        viewModel.serverStatuses = [
            "fail-a": McpServerStatus(
                name: "fail-a", status: .failed, error: "refused", tools: []
            ),
            "fail-b": McpServerStatus(
                name: "fail-b", status: .failed, error: "timeout", tools: []
            )
        ]

        XCTAssertEqual(viewModel.connectedCount, 0,
            "connectedCount should be 0 when all servers failed")
    }

    // MARK: - AC1: failedCount 计算属性

    // [P0] failedCount counts .failed and .needsAuth statuses
    func testFailedCountCountsFailedAndNeedsAuth() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "ok")
        _ = try addTestConfig(to: store, name: "fail-srv")
        _ = try addTestConfig(to: store, name: "auth-srv")

        let bridge = AgentBridge()
        let viewModel = makeViewModel(store: store, agentBridge: bridge)

        viewModel.serverStatuses = [
            "ok": McpServerStatus(
                name: "ok", status: .connected, error: nil, tools: []
            ),
            "fail-srv": McpServerStatus(
                name: "fail-srv", status: .failed, error: "error", tools: []
            ),
            "auth-srv": McpServerStatus(
                name: "auth-srv", status: .needsAuth, error: nil, tools: []
            )
        ]

        XCTAssertEqual(viewModel.failedCount, 2,
            "failedCount should count both .failed and .needsAuth statuses")
    }

    // [P0] failedCount returns 0 when no failures
    func testFailedCountReturnsZeroWhenAllConnected() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "good-srv")

        let bridge = AgentBridge()
        let viewModel = makeViewModel(store: store, agentBridge: bridge)

        viewModel.serverStatuses = [
            "good-srv": McpServerStatus(
                name: "good-srv", status: .connected, error: nil, tools: []
            )
        ]

        XCTAssertEqual(viewModel.failedCount, 0,
            "failedCount should be 0 when all servers are connected")
    }

    // MARK: - AC1: pendingCount 计算属性

    // [P0] pendingCount counts servers with .pending status
    func testPendingCountCountsPendingServers() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "pending-a")
        _ = try addTestConfig(to: store, name: "pending-b")
        _ = try addTestConfig(to: store, name: "connected-a")

        let bridge = AgentBridge()
        let viewModel = makeViewModel(store: store, agentBridge: bridge)

        viewModel.serverStatuses = [
            "pending-a": McpServerStatus(
                name: "pending-a", status: .pending, error: nil, tools: []
            ),
            "pending-b": McpServerStatus(
                name: "pending-b", status: .pending, error: nil, tools: []
            ),
            "connected-a": McpServerStatus(
                name: "connected-a", status: .connected, error: nil, tools: []
            )
        ]

        XCTAssertEqual(viewModel.pendingCount, 2,
            "pendingCount should count 2 pending servers")
    }

    // MARK: - AC1: totalConfiguredCount 从配置列表计算

    // [P0] totalConfiguredCount reflects number of configs in SwiftData store
    func testTotalConfiguredCountReflectsStoreConfigs() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "srv-a")
        _ = try addTestConfig(to: store, name: "srv-b")
        _ = try addTestConfig(to: store, name: "srv-c")

        let viewModel = makeViewModel(store: store)
        await viewModel.loadConfiguredServers()

        XCTAssertEqual(viewModel.totalConfiguredCount, 3,
            "totalConfiguredCount should reflect 3 configured servers")
    }

    // [P0] totalConfiguredCount includes both enabled and disabled configs
    func testTotalConfiguredCountIncludesDisabledConfigs() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "enabled-srv", enabled: true)
        _ = try addTestConfig(to: store, name: "disabled-srv", enabled: false)

        let viewModel = makeViewModel(store: store)
        await viewModel.loadConfiguredServers()

        XCTAssertEqual(viewModel.totalConfiguredCount, 2,
            "totalConfiguredCount should include both enabled and disabled configs")
    }

    // MARK: - AC1: 离线状态（Agent 未运行）

    // [P0] Offline mode: connectedCount is 0 when no agentBridge
    func testOfflineModeConnectedCountIsZero() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel(store: store, agentBridge: nil)

        XCTAssertEqual(viewModel.connectedCount, 0,
            "In offline mode, connectedCount should be 0")
    }

    // [P0] Offline mode: totalConfiguredCount still shows configured count
    func testOfflineModeShowsConfiguredCount() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "offline-srv")

        let viewModel = makeViewModel(store: store, agentBridge: nil)
        await viewModel.loadConfiguredServers()

        XCTAssertEqual(viewModel.totalConfiguredCount, 1,
            "Offline mode should still show configured count from store")
    }

    // [P0] Offline mode: serverStatuses is empty
    func testOfflineModeServerStatusesIsEmpty() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel(store: store, agentBridge: nil)

        await viewModel.refreshStatus()

        XCTAssertTrue(viewModel.serverStatuses.isEmpty,
            "In offline mode, serverStatuses should be empty after refresh")
    }

    // MARK: - AC1: refreshStatus 刷新机制

    // [P0] refreshStatus clears old statuses when agent not running
    func testRefreshStatusClearsWhenAgentNotRunning() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        let viewModel = makeViewModel(store: store, agentBridge: nil)
        viewModel.serverStatuses = ["stale": McpServerStatus(
            name: "stale", status: .connected, error: nil, tools: []
        )]

        await viewModel.refreshStatus()

        XCTAssertTrue(viewModel.serverStatuses.isEmpty,
            "refreshStatus should clear stale statuses when agent not running")
    }

    // [P0] refreshStatus populates statuses when agent is running
    func testRefreshStatusPopulatesWhenAgentRunning() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "active-srv")

        let bridge = AgentBridge()
        let viewModel = makeViewModel(store: store, agentBridge: bridge)

        await viewModel.refreshStatus()

        // Without a real agent, statuses should be empty or populated based on bridge state
        // The key test is that the method runs without crash
        // When bridge has an agent, it would call agent.mcpServerStatus()
    }

    // [P0] refreshStatus with bridge but no agent clears statuses
    func testRefreshStatusClearsWhenBridgeHasNoAgent() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        let bridge = AgentBridge()
        let viewModel = makeViewModel(store: store, agentBridge: bridge)
        viewModel.serverStatuses = ["old": McpServerStatus(
            name: "old", status: .pending, error: nil, tools: []
        )]

        await viewModel.refreshStatus()

        XCTAssertTrue(viewModel.serverStatuses.isEmpty,
            "refreshStatus should clear when bridge has no active agent")
    }

    // MARK: - AC1: loadConfiguredServers 从 SwiftData 加载

    // [P0] loadConfiguredServers loads from store
    func testLoadConfiguredServersLoadsFromStore() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "config-a")
        _ = try addTestConfig(to: store, name: "config-b")

        let viewModel = makeViewModel(store: store)
        await viewModel.loadConfiguredServers()

        XCTAssertEqual(viewModel.totalConfiguredCount, 2)
    }

    // [P0] loadConfiguredServers handles empty store
    func testLoadConfiguredServersHandlesEmptyStore() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel(store: store)

        await viewModel.loadConfiguredServers()

        XCTAssertEqual(viewModel.totalConfiguredCount, 0)
    }

    // MARK: - AC1: 状态摘要文本

    // [P0] statusSummaryText returns "就绪" when no configs and not connected
    func testStatusSummaryTextReturnsReadyWhenNoConfigs() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel(store: store)

        XCTAssertEqual(viewModel.statusSummaryText, "就绪",
            "Should show '就绪' when no MCP servers configured and no connections")
    }

    // [P0] statusSummaryText returns connected count text when servers connected
    func testStatusSummaryTextReturnsConnectedCount() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "srv-a")
        _ = try addTestConfig(to: store, name: "srv-b")
        _ = try addTestConfig(to: store, name: "srv-c")

        let bridge = AgentBridge()
        let viewModel = makeViewModel(store: store, agentBridge: bridge)

        viewModel.serverStatuses = [
            "srv-a": McpServerStatus(name: "srv-a", status: .connected, error: nil, tools: []),
            "srv-b": McpServerStatus(name: "srv-b", status: .connected, error: nil, tools: []),
            "srv-c": McpServerStatus(name: "srv-c", status: .connected, error: nil, tools: [])
        ]

        XCTAssertTrue(viewModel.statusSummaryText.contains("3"),
            "Summary should contain count '3'")
        XCTAssertTrue(viewModel.statusSummaryText.contains("MCP"),
            "Summary should contain 'MCP'")
    }

    // [P0] statusSummaryText includes failure warning when servers failed
    func testStatusSummaryTextIncludesFailureWarning() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "ok-srv")
        _ = try addTestConfig(to: store, name: "fail-srv")

        let bridge = AgentBridge()
        let viewModel = makeViewModel(store: store, agentBridge: bridge)

        viewModel.serverStatuses = [
            "ok-srv": McpServerStatus(name: "ok-srv", status: .connected, error: nil, tools: []),
            "fail-srv": McpServerStatus(name: "fail-srv", status: .failed, error: "err", tools: [])
        ]

        let text = viewModel.statusSummaryText
        XCTAssertTrue(text.contains("MCP"),
            "Summary should mention MCP")
        // Should indicate some connection issue
        XCTAssertTrue(text.contains("失败") || text.contains("1"),
            "Summary should indicate failure count")
    }

    // [P0] statusSummaryText shows pending indicator when servers connecting
    func testStatusSummaryTextShowsPendingIndicator() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "pending-srv")

        let bridge = AgentBridge()
        let viewModel = makeViewModel(store: store, agentBridge: bridge)

        viewModel.serverStatuses = [
            "pending-srv": McpServerStatus(name: "pending-srv", status: .pending, error: nil, tools: [])
        ]

        XCTAssertTrue(viewModel.statusSummaryText.contains("连接") || viewModel.statusSummaryText.contains("pending"),
            "Summary should indicate pending/connecting status")
    }

    // MARK: - AC1: Agent 启动/停止自动更新

    // [P0] Agent running state change triggers status refresh
    func testAgentRunningStateChangeTriggersRefresh() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "auto-srv")

        let bridge = AgentBridge()
        let viewModel = makeViewModel(store: store, agentBridge: bridge)

        // Simulate agent starting -- isRunning changes to true
        // The ViewModel should observe this and trigger refreshStatus
        // In test we manually call the method that would be triggered
        await viewModel.onAgentRunningChanged(isRunning: true)

        // After agent starts, refreshStatus should have been called
        // (no crash is the main assertion here)
    }

    // [P0] Agent stopping clears runtime statuses but keeps configured count
    func testAgentStoppingClearsRuntimeStatuses() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "stop-srv")

        let bridge = AgentBridge()
        let viewModel = makeViewModel(store: store, agentBridge: bridge)

        viewModel.serverStatuses = [
            "stop-srv": McpServerStatus(name: "stop-srv", status: .connected, error: nil, tools: [])
        ]
        await viewModel.loadConfiguredServers()
        XCTAssertEqual(viewModel.totalConfiguredCount, 1)
        XCTAssertEqual(viewModel.connectedCount, 1)

        await viewModel.onAgentRunningChanged(isRunning: false)

        XCTAssertEqual(viewModel.connectedCount, 0,
            "After agent stops, connectedCount should be 0")
        XCTAssertEqual(viewModel.totalConfiguredCount, 1,
            "After agent stops, totalConfiguredCount should still reflect store configs")
    }

    // MARK: - AC1: 定时刷新

    // [P1] startPeriodicRefresh does not crash
    func testStartPeriodicRefreshDoesNotCrash() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "refresh-srv")

        let bridge = AgentBridge()
        let viewModel = makeViewModel(store: store, agentBridge: bridge)

        viewModel.startPeriodicRefresh()
        // Give it a moment
        try await _Concurrency.Task.sleep(nanoseconds: 100_000_000)
        viewModel.stopPeriodicRefresh()
        // Should not crash
    }

    // [P1] stopPeriodicRefresh cancels timer cleanly
    func testStopPeriodicRefreshCancelsTimer() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel(store: store)

        viewModel.startPeriodicRefresh()
        viewModel.stopPeriodicRefresh()
        // Should not crash, timer should be cancelled
    }

    // MARK: - Edge Cases

    // [P1] Empty serverStatuses with configured servers shows offline state
    func testEmptyStatusesWithConfigsShowsOfflineState() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "configured-only")

        let viewModel = makeViewModel(store: store, agentBridge: nil)
        await viewModel.loadConfiguredServers()

        XCTAssertEqual(viewModel.totalConfiguredCount, 1)
        XCTAssertEqual(viewModel.connectedCount, 0)
        XCTAssertEqual(viewModel.failedCount, 0)
        XCTAssertEqual(viewModel.pendingCount, 0)
    }

    // [P1] Server status with disabled config does not count as connected
    func testDisabledConfigDoesNotCountAsConnected() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "disabled-srv", enabled: false)

        let bridge = AgentBridge()
        let viewModel = makeViewModel(store: store, agentBridge: bridge)

        // SDK would not return status for disabled servers
        viewModel.serverStatuses = [:]

        await viewModel.loadConfiguredServers()

        XCTAssertEqual(viewModel.connectedCount, 0)
        XCTAssertEqual(viewModel.totalConfiguredCount, 1)
    }

    // [P1] Multiple rapid refresh calls do not crash
    func testMultipleRapidRefreshCallsDoNotCrash() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "rapid-srv")

        let bridge = AgentBridge()
        let viewModel = makeViewModel(store: store, agentBridge: bridge)

        // Rapid fire refresh calls
        await viewModel.refreshStatus()
        await viewModel.refreshStatus()
        await viewModel.refreshStatus()
        // Should not crash
    }
}
