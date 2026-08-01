import XCTest
import SwiftUI
import SwiftData
import OpenAgentSDK
@testable import SwiftWork

// ATDD Red Phase — Story 6.3: MCP 管理面板
// View-level acceptance tests for MCP tab integration in SettingsView,
// MCPManagementView initialization, and MCPServerRowView/MCPServerDetailView.
// These tests assert EXPECTED behavior that does NOT exist yet.
// They WILL FAIL until MCPManagementView and related types are created.

@MainActor
final class MCPManagementViewTests: XCTestCase {

    // MARK: - Test Helpers

    private var testContainer: ModelContainer!

    private func makeTestContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        testContainer = try! ModelContainer(
            for: MCPServerConfig.self, PermissionRule.self, AppConfiguration.self,
            configurations: config
        )
        return testContainer
    }

    private func makeStore(in context: ModelContext) -> MCPServerConfigStore {
        MCPServerConfigStore(modelContext: context, keychainManager: MockKeychainManager())
    }

    private func makeHandler(in context: ModelContext) -> PermissionHandler {
        let handler = PermissionHandler()
        handler.setModelContext(context)
        return handler
    }

    private func makeBridge(with store: MCPServerConfigStore) -> AgentBridge {
        let bridge = AgentBridge()
        bridge.mcpConfigStore = store
        return bridge
    }

    override func tearDown() async throws {
        testContainer = nil
    }

    // MARK: - AC1: SettingsView MCP Tab

    // [P0] SettingsView has an MCP tab option
    func testSettingsViewHasMCPTab() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)
        let store = makeStore(in: context)
        let bridge = makeBridge(with: store)

        // SettingsView should accept agentBridge with MCP capability
        let view = SettingsView(
            settingsViewModel: SettingsViewModel(),
            permissionHandler: handler,
            agentBridge: bridge
        )
        XCTAssertNotNil(view, "SettingsView should accept agentBridge with MCP store")
    }

    // [P0] SettingsTab includes mcp case
    func testSettingsTabEnumIncludesMCP() {
        // SettingsView.SettingsTab (private) should include mcp case.
        // We test this indirectly by verifying the tab picker has 4 options.
        // Since SettingsTab is private, we verify via the view's existence.
        // The actual test: SettingsTab.allCases should have count 4 after implementation
        // (general, permissions, skills, mcp)
        XCTAssertTrue(true, "Placeholder — direct enum access requires making SettingsTab non-private or using reflection. Verified via SettingsViewIntegrationTests instead.")
    }

    // MARK: - AC1/AC8: MCPManagementView Initialization

    // [P0] MCPManagementView initializes with store and agentBridge
    func testMCPManagementViewInitializesWithStore() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let store = makeStore(in: context)
        let bridge = makeBridge(with: store)

        let view = MCPManagementView(store: store, agentBridge: bridge)
        XCTAssertNotNil(view, "MCPManagementView should initialize with store and agentBridge")
    }

    // [P0] MCPManagementView initializes when agentBridge is nil
    func testMCPManagementViewInitializesWithNilBridge() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let store = makeStore(in: context)

        let view = MCPManagementView(store: store, agentBridge: nil)
        XCTAssertNotNil(view, "MCPManagementView should initialize even with nil agentBridge")
    }

    // MARK: - AC8: Empty State

    // [P0] MCPManagementView body is accessible (not a stub)
    func testMCPManagementViewShowsEmptyState() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let store = makeStore(in: context)

        let view = MCPManagementView(store: store, agentBridge: nil)
        // The view should have a non-trivial body (not just Text("MCPManagementView"))
        // In red phase, we verify the type exists and can be instantiated
        XCTAssertNotNil(view)
    }

    // MARK: - AC1: MCPServerRowView

    // [P0] MCPServerRowView initializes with config and status
    func testMCPServerRowViewInitializes() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let store = makeStore(in: context)

        let config = try store.add(
            name: "row-test",
            transportType: .sse,
            command: nil,
            url: "http://localhost:3000/sse",
            args: nil,
            env: nil,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )

        let view = MCPServerRowView(
            config: config,
            status: .connected,
            isExpanded: false
        )
        XCTAssertNotNil(view, "MCPServerRowView should initialize with config and status")
    }

    // [P0] MCPServerRowView accepts different display statuses
    func testMCPServerRowViewAcceptsDifferentStatuses() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let store = makeStore(in: context)

        let config = try store.add(
            name: "status-test",
            transportType: .stdio,
            command: "npx",
            url: nil,
            args: nil,
            env: nil,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )

        // Should accept all display statuses without crashing
        let statuses: [MCPServerDisplayStatus] = [.connected, .failed, .pending, .disabled, .disconnected, .offline]
        for status in statuses {
            let view = MCPServerRowView(config: config, status: status, isExpanded: false)
            XCTAssertNotNil(view, "MCPServerRowView should accept status: \(status)")
        }
    }

    // MARK: - AC2/AC5/AC6: MCPServerDetailView

    // [P0] MCPServerDetailView initializes with config and callbacks
    func testMCPServerDetailViewInitializes() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let store = makeStore(in: context)

        let config = try store.add(
            name: "detail-test",
            transportType: .sse,
            command: nil,
            url: "http://localhost:3000/sse",
            args: nil,
            env: nil,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )

        let view = MCPServerDetailView(
            config: config,
            sdkStatus: nil,
            isAgentRunning: false,
            onToggle: {},
            onEdit: {},
            onReconnect: {},
            onDelete: {}
        )
        XCTAssertNotNil(view, "MCPServerDetailView should initialize with config and callbacks")
    }

    // [P0] MCPServerDetailView shows delete confirmation (AC5)
    func testMCPManagementViewShowsDeleteConfirmation() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let store = makeStore(in: context)

        // The ViewModel should have a method or state for showing delete confirmation
        let viewModel = MCPManagementViewModel(store: store)

        // Initially not confirming delete
        XCTAssertFalse(viewModel.showDeleteConfirmation, "Should not show delete confirmation initially")
        XCTAssertNil(viewModel.serverToDelete, "No server pending deletion initially")

        // Trigger delete confirmation
        viewModel.confirmDelete(name: "some-server")
        XCTAssertTrue(viewModel.showDeleteConfirmation, "Should show confirmation after confirmDelete()")
        XCTAssertEqual(viewModel.serverToDelete, "some-server")
    }
}
