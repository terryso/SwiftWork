import XCTest
import SwiftUI
@testable import SwiftWork
import SwiftData
import OpenAgentSDK

// ATDD Red Phase -- Story 6.5: MCP 状态可视化
// Unit tests for WorkspaceStatusBar view rendering logic.
// These tests assert EXPECTED behavior. They will FAIL until Story 6-5 is implemented.
//
// Coverage:
//   AC1 -- Status Bar 显示 MCP 连接数指标
//   AC1 -- 无 MCP 连接时显示 "就绪"
//   AC1 -- 有连接失败时显示警告
//   AC1 -- pending 状态显示加载指示器

@MainActor
final class WorkspaceStatusBarTests: XCTestCase {

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

    // MARK: - AC1: WorkspaceStatusBar 视图创建

    // [P0] WorkspaceStatusBar can be created with MCPStatusViewModel
    func testWorkspaceStatusBarCanBeCreated() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = MCPStatusViewModel(store: store)

        let statusBar = WorkspaceStatusBar(viewModel: viewModel)
        XCTAssertNotNil(statusBar, "WorkspaceStatusBar should be created without crash")
    }

    // [P0] WorkspaceStatusBar renders with empty state
    func testWorkspaceStatusBarRendersWithEmptyState() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = MCPStatusViewModel(store: store)

        // No configs, no connections
        let statusBar = WorkspaceStatusBar(viewModel: viewModel)
        XCTAssertNotNil(statusBar)
    }

    // MARK: - AC1: WorkspaceStatusBar 集成到 WorkspaceView

    // [P0] WorkspaceView has a WorkspaceStatusBar
    func testWorkspaceViewHasWorkspaceStatusBar() throws {
        // This test verifies WorkspaceStatusBar is integrated into WorkspaceView
        // The integration happens in WorkspaceView.swift
        // For red phase, we verify the type exists and can be instantiated
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = MCPStatusViewModel(store: store)
        let _ = WorkspaceStatusBar(viewModel: viewModel)
        // Type exists and can be instantiated
    }

    // MARK: - AC1: 状态显示格式

    // [P0] MCPStatusViewModel statusSummaryText for single connected server
    func testStatusSummaryForSingleConnectedServer() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try store.add(
            name: "single-srv",
            transportType: .sse,
            command: nil,
            url: "http://localhost:3000/sse",
            args: nil, env: nil, headers: nil,
            enabled: true, scope: .global, workspacePath: nil
        )

        let bridge = AgentBridge()
        let viewModel = MCPStatusViewModel(store: store, agentBridge: bridge)
        viewModel.serverStatuses = [
            "single-srv": McpServerStatus(
                name: "single-srv", status: .connected, error: nil, tools: []
            )
        ]

        let text = viewModel.statusSummaryText
        XCTAssertTrue(text.contains("1") || text.contains("MCP"),
            "Single connected server summary should contain count and 'MCP'")
    }

    // [P0] Status summary shows "就绪" when nothing configured
    func testStatusSummaryShowsReadyWhenNothingConfigured() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = MCPStatusViewModel(store: store, agentBridge: nil)

        XCTAssertEqual(viewModel.statusSummaryText, "就绪",
            "Should show '就绪' when no MCP servers configured")
    }

    // [P0] Status summary shows failure indicator
    func testStatusSummaryShowsFailureIndicator() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try store.add(
            name: "fail-srv",
            transportType: .sse,
            command: nil,
            url: "http://localhost:3000/sse",
            args: nil, env: nil, headers: nil,
            enabled: true, scope: .global, workspacePath: nil
        )

        let bridge = AgentBridge()
        let viewModel = MCPStatusViewModel(store: store, agentBridge: bridge)
        viewModel.serverStatuses = [
            "fail-srv": McpServerStatus(
                name: "fail-srv", status: .failed, error: "Connection refused", tools: []
            )
        ]

        let text = viewModel.statusSummaryText
        // Should indicate failure
        let indicatesFailure = text.contains("失败") || text.contains("fail") || text.contains("连接失败")
        XCTAssertTrue(indicatesFailure,
            "Status should indicate failure when server is failed")
    }

    // [P0] Status summary shows connecting indicator for pending
    func testStatusSummaryShowsConnectingForPending() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try store.add(
            name: "pending-srv",
            transportType: .sse,
            command: nil,
            url: "http://localhost:3000/sse",
            args: nil, env: nil, headers: nil,
            enabled: true, scope: .global, workspacePath: nil
        )

        let bridge = AgentBridge()
        let viewModel = MCPStatusViewModel(store: store, agentBridge: bridge)
        viewModel.serverStatuses = [
            "pending-srv": McpServerStatus(
                name: "pending-srv", status: .pending, error: nil, tools: []
            )
        ]

        let text = viewModel.statusSummaryText
        let indicatesPending = text.contains("连接") || text.contains("pending") || text.contains("...")
        XCTAssertTrue(indicatesPending,
            "Status should indicate pending/connecting state")
    }

    // MARK: - AC1: 混合状态显示

    // [P1] Mixed status with connected and failed shows both
    func testMixedStatusShowsBothConnectedAndFailed() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        _ = try store.add(name: "ok-srv", transportType: .sse, command: nil,
                          url: "http://localhost:3000/sse", args: nil, env: nil,
                          headers: nil, enabled: true, scope: .global, workspacePath: nil)
        _ = try store.add(name: "fail-srv", transportType: .sse, command: nil,
                          url: "http://localhost:4000/sse", args: nil, env: nil,
                          headers: nil, enabled: true, scope: .global, workspacePath: nil)

        let bridge = AgentBridge()
        let viewModel = MCPStatusViewModel(store: store, agentBridge: bridge)
        viewModel.serverStatuses = [
            "ok-srv": McpServerStatus(name: "ok-srv", status: .connected, error: nil, tools: []),
            "fail-srv": McpServerStatus(name: "fail-srv", status: .failed, error: "err", tools: [])
        ]

        XCTAssertEqual(viewModel.connectedCount, 1)
        XCTAssertEqual(viewModel.failedCount, 1)
    }
}
