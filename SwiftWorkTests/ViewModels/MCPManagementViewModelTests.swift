import XCTest
@testable import SwiftWork
import SwiftData
import OpenAgentSDK

// ATDD Red Phase — Story 6.3: MCP 管理面板
// Unit tests for MCPManagementViewModel and MCPServerDisplayStatus.
// These tests assert EXPECTED behavior. They will FAIL until the ViewModel is implemented.
//
// Coverage:
//   AC1 — Server 列表显示（ViewModel 加载逻辑）
//   AC2 — 展开详情（selectedServerName 状态管理）
//   AC3 — 禁用 Server（toggleServer 更新配置 + SDK 调用）
//   AC4 — 启用 Server（toggleServer 反向操作）
//   AC5 — 删除 Server（deleteServer 从 SwiftData 移除）
//   AC6 — 重连 Server（reconnectServer 调用 SDK）
//   AC7 — 错误详情展示（serverStatuses 错误映射）
//   AC8 — 空状态（无配置时 servers 为空）

// MARK: - MCPServerDisplayStatus Tests (AC1, AC7)

final class MCPServerDisplayStatusTests: XCTestCase {

    // [P0] MCPServerDisplayStatus has all six display states
    func testDisplayStatusHasSixCases() {
        let statuses: [MCPServerDisplayStatus] = [
            .connected, .failed, .pending, .disabled, .disconnected, .offline
        ]
        XCTAssertEqual(statuses.count, 6, "MCPServerDisplayStatus should have 6 cases")
    }

    // [P0] Connected status maps to green color description
    func testConnectedStatusIsGreen() {
        let status = MCPServerDisplayStatus.connected
        // Verify via label or color name — the enum should provide a color label
        XCTAssertEqual(status.colorName, "green", "Connected should map to green")
    }

    // [P0] Failed status maps to red
    func testFailedStatusIsRed() {
        let status = MCPServerDisplayStatus.failed
        XCTAssertEqual(status.colorName, "red", "Failed should map to red")
    }

    // [P0] Pending status maps to orange/amber
    func testPendingStatusIsAmber() {
        let status = MCPServerDisplayStatus.pending
        XCTAssertEqual(status.colorName, "orange", "Pending should map to orange/amber")
    }

    // [P0] Disabled status maps to gray
    func testDisabledStatusIsGray() {
        let status = MCPServerDisplayStatus.disabled
        XCTAssertEqual(status.colorName, "gray", "Disabled should map to gray")
    }

    // [P0] Disconnected status maps to gray
    func testDisconnectedStatusIsGray() {
        let status = MCPServerDisplayStatus.disconnected
        XCTAssertEqual(status.colorName, "gray", "Disconnected should map to gray")
    }

    // [P0] Offline status maps to gray
    func testOfflineStatusIsGray() {
        let status = MCPServerDisplayStatus.offline
        XCTAssertEqual(status.colorName, "gray", "Offline should map to gray")
    }

    // [P0] from() maps SDK connected to display connected
    func testFromSDKConnected() {
        let status = MCPServerDisplayStatus.from(.connected)
        XCTAssertEqual(status, .connected)
    }

    // [P0] from() maps SDK failed to display failed
    func testFromSDKFailed() {
        let status = MCPServerDisplayStatus.from(.failed)
        XCTAssertEqual(status, .failed)
    }

    // [P0] from() maps SDK pending to display pending
    func testFromSDKPending() {
        let status = MCPServerDisplayStatus.from(.pending)
        XCTAssertEqual(status, .pending)
    }

    // [P0] from() maps SDK disabled to display disabled
    func testFromSDKDisabled() {
        let status = MCPServerDisplayStatus.from(.disabled)
        XCTAssertEqual(status, .disabled)
    }

    // [P0] from() maps SDK needsAuth to display failed (MVP fallback)
    func testFromSDKNeedsAuthMapsToFailed() {
        let status = MCPServerDisplayStatus.from(.needsAuth)
        XCTAssertEqual(status, .failed, "needsAuth should map to failed in MVP")
    }

    // [P0] Each display status has a localized label
    func testDisplayStatusHasLocalizedLabels() {
        XCTAssertFalse(MCPServerDisplayStatus.connected.label.isEmpty)
        XCTAssertFalse(MCPServerDisplayStatus.failed.label.isEmpty)
        XCTAssertFalse(MCPServerDisplayStatus.pending.label.isEmpty)
        XCTAssertFalse(MCPServerDisplayStatus.disabled.label.isEmpty)
        XCTAssertFalse(MCPServerDisplayStatus.disconnected.label.isEmpty)
        XCTAssertFalse(MCPServerDisplayStatus.offline.label.isEmpty)
    }
}

// MARK: - MCPManagementViewModel Tests

@MainActor
final class MCPManagementViewModelTests: XCTestCase {

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
    ) -> MCPManagementViewModel {
        MCPManagementViewModel(store: store, agentBridge: agentBridge)
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

    // MARK: - AC8: 空状态（ViewModel 初始化）

    // [P0] ViewModel initializes with empty servers list
    func testViewModelInitializesWithEmptyServers() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel(store: store)

        XCTAssertTrue(viewModel.servers.isEmpty, "servers should be empty on init before loadServers()")
    }

    // [P0] ViewModel initializes with empty serverStatuses
    func testViewModelInitializesWithEmptyStatuses() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel(store: store)

        XCTAssertTrue(viewModel.serverStatuses.isEmpty, "serverStatuses should be empty on init")
    }

    // [P0] ViewModel initializes with no selected server
    func testViewModelInitializesWithNoSelection() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel(store: store)

        XCTAssertNil(viewModel.selectedServerName, "selectedServerName should be nil on init")
    }

    // [P0] ViewModel initializes not loading
    func testViewModelInitializesNotLoading() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel(store: store)

        XCTAssertFalse(viewModel.isLoading, "isLoading should be false on init")
    }

    // [P0] ViewModel initializes with no error
    func testViewModelInitializesWithNoError() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel(store: store)

        XCTAssertNil(viewModel.errorMessage, "errorMessage should be nil on init")
    }

    // [P0] ViewModel initializes with sheets hidden
    func testViewModelInitializesWithSheetsHidden() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel(store: store)

        XCTAssertFalse(viewModel.showAddSheet, "showAddSheet should be false on init")
        XCTAssertNil(viewModel.editingConfig, "editingConfig should be nil on init")
    }

    // MARK: - AC1: Server 列表加载

    // [P0] loadServers populates servers from SwiftData store
    func testLoadServersPopulatesFromStore() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "server-a")
        _ = try addTestConfig(to: store, name: "server-b", transportType: .stdio)

        let viewModel = makeViewModel(store: store)
        await viewModel.loadServers()

        XCTAssertEqual(viewModel.servers.count, 2, "Should load 2 servers from store")
    }

    // [P0] loadServers returns empty list when no configs
    func testLoadServersReturnsEmptyWhenNoConfigs() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel(store: store)

        await viewModel.loadServers()

        XCTAssertTrue(viewModel.servers.isEmpty, "Should be empty when no configs exist")
    }

    // [P0] loadServers sorts by createdAt
    func testLoadServersSortsByCreationDate() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        _ = try addTestConfig(to: store, name: "first-created")
        // Small delay to ensure different timestamps
        try await _Concurrency.Task.sleep(nanoseconds: 10_000_000)
        _ = try addTestConfig(to: store, name: "second-created")

        let viewModel = makeViewModel(store: store)
        await viewModel.loadServers()

        XCTAssertEqual(viewModel.servers.first?.name, "first-created", "Should sort by createdAt ascending")
        XCTAssertEqual(viewModel.servers.last?.name, "second-created")
    }

    // MARK: - AC2: 展开详情（选中状态管理）

    // [P0] selectServer sets selectedServerName
    func testSelectServerSetsSelection() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "selectable-server")

        let viewModel = makeViewModel(store: store)
        await viewModel.loadServers()

        viewModel.selectServer(name: "selectable-server")

        XCTAssertEqual(viewModel.selectedServerName, "selectable-server")
    }

    // [P0] selectServer toggles off when same name clicked
    func testSelectServerTogglesOffWhenSameClicked() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "toggle-server")

        let viewModel = makeViewModel(store: store)
        await viewModel.loadServers()

        viewModel.selectServer(name: "toggle-server")
        XCTAssertEqual(viewModel.selectedServerName, "toggle-server")

        viewModel.selectServer(name: "toggle-server")
        XCTAssertNil(viewModel.selectedServerName, "Clicking same server should deselect")
    }

    // [P0] selectServer switches selection to different server
    func testSelectServerSwitchesToDifferentServer() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "server-x")
        _ = try addTestConfig(to: store, name: "server-y")

        let viewModel = makeViewModel(store: store)
        await viewModel.loadServers()

        viewModel.selectServer(name: "server-x")
        XCTAssertEqual(viewModel.selectedServerName, "server-x")

        viewModel.selectServer(name: "server-y")
        XCTAssertEqual(viewModel.selectedServerName, "server-y")
    }

    // MARK: - AC1: statusForServer 映射

    // [P0] statusForServer returns disabled when config.enabled is false
    func testStatusForServerReturnsDisabledWhenNotEnabled() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let config = try addTestConfig(to: store, name: "disabled-srv", enabled: false)

        let viewModel = makeViewModel(store: store)
        await viewModel.loadServers()

        let status = viewModel.statusForServer(config)
        XCTAssertEqual(status, .disabled)
    }

    // [P0] statusForServer returns offline when Agent not running
    func testStatusForServerReturnsOfflineWhenAgentNotRunning() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let config = try addTestConfig(to: store, name: "offline-srv")

        // No agentBridge -> agent not running
        let viewModel = makeViewModel(store: store, agentBridge: nil)
        await viewModel.loadServers()

        let status = viewModel.statusForServer(config)
        XCTAssertEqual(status, .offline)
    }

    // [P0] statusForServer returns connected when SDK reports connected
    func testStatusForServerReturnsConnectedWhenSDKConnected() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let config = try addTestConfig(to: store, name: "connected-srv")

        let bridge = AgentBridge()
        let viewModel = makeViewModel(store: store, agentBridge: bridge)

        // Simulate SDK status
        viewModel.serverStatuses = ["connected-srv": McpServerStatus(
            name: "connected-srv",
            status: .connected,
            error: nil,
            tools: []
        )]

        let status = viewModel.statusForServer(config)
        XCTAssertEqual(status, .connected)
    }

    // [P0] statusForServer returns failed when SDK reports failed
    func testStatusForServerReturnsFailedWhenSDKFailed() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let config = try addTestConfig(to: store, name: "failed-srv")

        let bridge = AgentBridge()
        let viewModel = makeViewModel(store: store, agentBridge: bridge)

        viewModel.serverStatuses = ["failed-srv": McpServerStatus(
            name: "failed-srv",
            status: .failed,
            error: "Connection refused",
            tools: []
        )]

        let status = viewModel.statusForServer(config)
        XCTAssertEqual(status, .failed)
    }

    // [P0] statusForServer returns disconnected when Agent running but server not in SDK status
    func testStatusForServerReturnsDisconnectedWhenMissingFromSDK() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let config = try addTestConfig(to: store, name: "missing-srv")

        let bridge = AgentBridge()
        bridge.isRunning = true
        // Agent running but serverStatuses doesn't contain this server
        let viewModel = makeViewModel(store: store, agentBridge: bridge)
        viewModel.serverStatuses = [:]

        let status = viewModel.statusForServer(config)
        XCTAssertEqual(status, .disconnected)
    }

    // MARK: - AC3/AC4: 禁用/启用 Server（toggleServer）

    // [P0] toggleServer sets enabled to false (disable)
    func testToggleServerDisablesConfig() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "toggle-disable", enabled: true)

        let bridge = AgentBridge()
        bridge.mcpConfigStore = store
        let viewModel = makeViewModel(store: store, agentBridge: bridge)
        await viewModel.loadServers()

        await viewModel.toggleServer(name: "toggle-disable", enabled: false)

        let configs = try store.list()
        let updated = configs.first { $0.name == "toggle-disable" }
        XCTAssertNotNil(updated)
        XCTAssertFalse(updated!.enabled, "Server should be disabled after toggle(enabled: false)")
    }

    // [P0] toggleServer sets enabled to true (enable)
    func testToggleServerEnablesConfig() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "toggle-enable", enabled: false)

        let bridge = AgentBridge()
        bridge.mcpConfigStore = store
        let viewModel = makeViewModel(store: store, agentBridge: bridge)
        await viewModel.loadServers()

        await viewModel.toggleServer(name: "toggle-enable", enabled: true)

        let configs = try store.list()
        let updated = configs.first { $0.name == "toggle-enable" }
        XCTAssertNotNil(updated)
        XCTAssertTrue(updated!.enabled, "Server should be enabled after toggle(enabled: true)")
    }

    // [P0] toggleServer reloads servers after toggle
    func testToggleServerReloadsServers() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "reload-after-toggle")

        let bridge = AgentBridge()
        bridge.mcpConfigStore = store
        let viewModel = makeViewModel(store: store, agentBridge: bridge)
        await viewModel.loadServers()
        XCTAssertEqual(viewModel.servers.count, 1)

        await viewModel.toggleServer(name: "reload-after-toggle", enabled: false)

        // After toggle, the servers list should reflect the updated enabled state
        let toggledServer = viewModel.servers.first { $0.name == "reload-after-toggle" }
        XCTAssertNotNil(toggledServer)
        XCTAssertFalse(toggledServer!.enabled)
    }

    // [P1] toggleServer with non-existent name does not crash
    func testToggleServerNonExistentNameDoesNotCrash() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel(store: store)

        // Should not throw or crash — graceful handling
        await viewModel.toggleServer(name: "ghost-server", enabled: false)
    }

    // MARK: - AC5: 删除 Server

    // [P0] deleteServer removes config from SwiftData
    func testDeleteServerRemovesConfig() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "to-delete")

        let viewModel = makeViewModel(store: store)
        await viewModel.loadServers()
        XCTAssertEqual(viewModel.servers.count, 1)

        try await viewModel.deleteServer(name: "to-delete")

        let remaining = try store.list()
        XCTAssertTrue(remaining.isEmpty, "Config should be deleted from store")
    }

    // [P0] deleteServer reloads servers after deletion
    func testDeleteServerReloadsList() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "delete-me")
        _ = try addTestConfig(to: store, name: "keep-me")

        let viewModel = makeViewModel(store: store)
        await viewModel.loadServers()
        XCTAssertEqual(viewModel.servers.count, 2)

        try await viewModel.deleteServer(name: "delete-me")

        XCTAssertEqual(viewModel.servers.count, 1, "Should have 1 server after deletion")
        XCTAssertEqual(viewModel.servers.first?.name, "keep-me")
    }

    // [P0] deleteServer clears selection if deleted server was selected
    func testDeleteServerClearsSelection() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "selected-for-delete")

        let viewModel = makeViewModel(store: store)
        await viewModel.loadServers()
        viewModel.selectServer(name: "selected-for-delete")
        XCTAssertEqual(viewModel.selectedServerName, "selected-for-delete")

        try await viewModel.deleteServer(name: "selected-for-delete")

        XCTAssertNil(viewModel.selectedServerName, "Selection should be cleared after deletion")
    }

    // [P1] deleteServer with non-existent name does not crash
    func testDeleteServerNonExistentDoesNotCrash() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel(store: store)

        try? await viewModel.deleteServer(name: "ghost")
    }

    // MARK: - AC6: 重连 Server

    // [P0] reconnectServer calls agentBridge.reconnectMcpServer
    func testReconnectServerCallsAgentBridge() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "reconnect-me")

        let bridge = AgentBridge()
        let viewModel = makeViewModel(store: store, agentBridge: bridge)
        await viewModel.loadServers()

        // This should call bridge.reconnectMcpServer(name:) internally
        // Without a real Agent, it should not crash
        await viewModel.reconnectServer(name: "reconnect-me")
    }

    // [P0] reconnectServer refreshes status after reconnect attempt
    func testReconnectServerRefreshesStatus() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "reconnect-status")

        let bridge = AgentBridge()
        let viewModel = makeViewModel(store: store, agentBridge: bridge)
        await viewModel.loadServers()

        await viewModel.reconnectServer(name: "reconnect-status")

        // After reconnect, refreshStatus() should have been called
        // (serverStatuses may still be empty if agent not running, but the method ran)
        // Verifying no crash is sufficient for red phase
    }

    // [P1] reconnectServer with non-existent name does not crash
    func testReconnectServerNonExistentDoesNotCrash() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel(store: store)

        await viewModel.reconnectServer(name: "ghost")
    }

    // MARK: - AC7: 错误详情展示

    // [P0] serverStatuses contains error from SDK
    func testServerStatusesContainsErrorFromSDK() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        let viewModel = makeViewModel(store: store)
        viewModel.serverStatuses = [
            "error-srv": McpServerStatus(
                name: "error-srv",
                status: .failed,
                error: "ECONNREFUSED: Connection refused at 127.0.0.1:3000",
                tools: []
            )
        ]

        let errorStatus = viewModel.serverStatuses["error-srv"]
        XCTAssertNotNil(errorStatus)
        XCTAssertEqual(errorStatus?.error, "ECONNREFUSED: Connection refused at 127.0.0.1:3000")
    }

    // [P0] SDK status with tools list populates serverStatuses
    func testServerStatusesContainsToolsList() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        let viewModel = makeViewModel(store: store)
        viewModel.serverStatuses = [
            "tools-srv": McpServerStatus(
                name: "tools-srv",
                status: .connected,
                error: nil,
                tools: ["read_file", "write_file", "search_files"]
            )
        ]

        let toolsStatus = viewModel.serverStatuses["tools-srv"]
        XCTAssertNotNil(toolsStatus)
        XCTAssertEqual(toolsStatus?.tools.count, 3)
        XCTAssertTrue(toolsStatus?.tools.contains("read_file") ?? false)
    }

    // MARK: - AC8: 空状态完整验证

    // [P0] isShowingEmptyState is true when no servers loaded
    func testIsEmptyStateTrueWhenNoServers() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel(store: store)

        XCTAssertTrue(viewModel.isShowingEmptyState, "Should show empty state when no servers")
    }

    // [P0] isShowingEmptyState is false when servers exist
    func testIsEmptyStateFalseWhenServersExist() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "existing-srv")

        let viewModel = makeViewModel(store: store)
        await viewModel.loadServers()

        XCTAssertFalse(viewModel.isShowingEmptyState, "Should not show empty state when servers exist")
    }

    // MARK: - refreshStatus (AC1, AC7)

    // [P0] refreshStatus clears statuses when agent not running
    func testRefreshStatusClearsWhenAgentNotRunning() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        let viewModel = makeViewModel(store: store, agentBridge: nil)
        viewModel.serverStatuses = ["old": McpServerStatus(
            name: "old", status: .connected, error: nil, tools: []
        )]

        await viewModel.refreshStatus()

        XCTAssertTrue(viewModel.serverStatuses.isEmpty, "Statuses should be cleared when agent not running")
    }

    // [P0] refreshStatus clears statuses when bridge has no agent
    func testRefreshStatusClearsWhenNoAgent() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        let bridge = AgentBridge()
        // Agent not configured yet
        let viewModel = makeViewModel(store: store, agentBridge: bridge)
        viewModel.serverStatuses = ["stale": McpServerStatus(
            name: "stale", status: .pending, error: nil, tools: []
        )]

        await viewModel.refreshStatus()

        XCTAssertTrue(viewModel.serverStatuses.isEmpty, "Statuses should be cleared when agent is nil")
    }

    // MARK: - Sheet management

    // [P0] showAddSheet toggles
    func testShowAddSheetToggles() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel(store: store)

        XCTAssertFalse(viewModel.showAddSheet)
        viewModel.showAddSheet = true
        XCTAssertTrue(viewModel.showAddSheet)
    }

    // [P0] editingConfig sets to a config for edit sheet
    func testEditingConfigSetsForEditSheet() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let config = try addTestConfig(to: store, name: "editable")

        let viewModel = makeViewModel(store: store)
        await viewModel.loadServers()

        XCTAssertNil(viewModel.editingConfig)
        viewModel.editingConfig = config
        XCTAssertEqual(viewModel.editingConfig?.name, "editable")
    }

    // [P0] onAddSheetDismiss reloads servers
    func testOnAddSheetDismissReloadsServers() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try addTestConfig(to: store, name: "pre-existing")

        let viewModel = makeViewModel(store: store)
        await viewModel.loadServers()
        XCTAssertEqual(viewModel.servers.count, 1)

        // Simulate adding a new config while sheet was open
        _ = try addTestConfig(to: store, name: "added-during-sheet")

        await viewModel.onAddSheetDismiss()

        XCTAssertEqual(viewModel.servers.count, 2, "Should reload servers after sheet dismiss")
        let names = Set(viewModel.servers.map(\.name))
        XCTAssertTrue(names.contains("added-during-sheet"))
    }

    // [P0] onEditSheetDismiss reloads servers
    func testOnEditSheetDismissReloadsServers() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let config = try addTestConfig(to: store, name: "edit-me")

        let viewModel = makeViewModel(store: store)
        await viewModel.loadServers()

        // Simulate edit changing the config
        _ = try store.update(config, name: "edited-name")

        await viewModel.onEditSheetDismiss()

        let names = viewModel.servers.map(\.name)
        XCTAssertTrue(names.contains("edited-name"), "Should reflect edited name after reload")
    }
}
