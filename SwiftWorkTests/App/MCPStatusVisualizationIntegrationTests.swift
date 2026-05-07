import XCTest
@testable import SwiftWork
import SwiftData
import OpenAgentSDK

// ATDD Red Phase -- Story 6.5: MCP 状态可视化
// Integration tests for MCP status visualization end-to-end flows.
// These tests assert EXPECTED behavior. They will FAIL until Story 6-5 is implemented.
//
// Coverage:
//   AC1 -- MCP 连接数指标端到端流程
//   AC2 -- MCP 工具来源标识验证（已由 Story 6-4 实现，回归验证）
//   AC3 -- Inspector MCP 元数据端到端展示

@MainActor
final class MCPStatusVisualizationIntegrationTests: XCTestCase {

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
        MCPServerConfigStore(modelContext: context)
    }

    // MARK: - AC1: 端到端 — 配置服务器 → Agent 连接 → 状态显示

    // [P0] End-to-end: configure servers → load → status display
    func testEndToEndConfigureAndDisplayStatus() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        // Step 1: Configure MCP servers
        _ = try store.add(name: "weather-api", transportType: .sse, command: nil,
                          url: "http://localhost:3000/sse", args: nil, env: nil,
                          headers: nil, enabled: true, scope: .global, workspacePath: nil)
        _ = try store.add(name: "db-api", transportType: .stdio, command: "/usr/bin/db-mcp",
                          url: nil, args: nil, env: nil, headers: nil,
                          enabled: true, scope: .global, workspacePath: nil)

        // Step 2: Create ViewModel
        let bridge = AgentBridge()
        let viewModel = MCPStatusViewModel(store: store, agentBridge: bridge)

        // Step 3: Load configured servers
        await viewModel.loadConfiguredServers()
        XCTAssertEqual(viewModel.totalConfiguredCount, 2)

        // Step 4: Simulate Agent runtime statuses
        viewModel.serverStatuses = [
            "weather-api": McpServerStatus(name: "weather-api", status: .connected, error: nil,
                                           tools: ["get_forecast", "get_weather"]),
            "db-api": McpServerStatus(name: "db-api", status: .connected, error: nil,
                                      tools: ["query", "insert"])
        ]

        // Step 5: Verify computed properties
        XCTAssertEqual(viewModel.connectedCount, 2)
        XCTAssertEqual(viewModel.failedCount, 0)
        XCTAssertEqual(viewModel.pendingCount, 0)

        // Step 6: Verify summary text
        let summary = viewModel.statusSummaryText
        XCTAssertTrue(summary.contains("2") || summary.contains("MCP"))
    }

    // [P0] End-to-end: partial connection failure scenario
    func testEndToEndPartialConnectionFailure() async throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        _ = try store.add(name: "good-srv", transportType: .sse, command: nil,
                          url: "http://localhost:3000/sse", args: nil, env: nil,
                          headers: nil, enabled: true, scope: .global, workspacePath: nil)
        _ = try store.add(name: "bad-srv", transportType: .sse, command: nil,
                          url: "http://localhost:4000/sse", args: nil, env: nil,
                          headers: nil, enabled: true, scope: .global, workspacePath: nil)
        _ = try store.add(name: "pending-srv", transportType: .sse, command: nil,
                          url: "http://localhost:5000/sse", args: nil, env: nil,
                          headers: nil, enabled: true, scope: .global, workspacePath: nil)

        let bridge = AgentBridge()
        let viewModel = MCPStatusViewModel(store: store, agentBridge: bridge)
        await viewModel.loadConfiguredServers()

        viewModel.serverStatuses = [
            "good-srv": McpServerStatus(name: "good-srv", status: .connected, error: nil, tools: []),
            "bad-srv": McpServerStatus(name: "bad-srv", status: .failed, error: "ECONNREFUSED", tools: []),
            "pending-srv": McpServerStatus(name: "pending-srv", status: .pending, error: nil, tools: [])
        ]

        XCTAssertEqual(viewModel.connectedCount, 1)
        XCTAssertEqual(viewModel.failedCount, 1)
        XCTAssertEqual(viewModel.pendingCount, 1)
        XCTAssertEqual(viewModel.totalConfiguredCount, 3)
    }

    // MARK: - AC2: 回归验证 — MCP 工具来源标识

    // [P0] MCP tool event has correct metadata for Inspector display
    func testMCPToolEventMetadataForInspectorDisplay() {
        // Simulate EventMapper output for an MCP tool call
        let data = SDKMessage.ToolUseData(
            toolName: "mcp__weather__get_forecast",
            toolUseId: "tu-integration-001",
            input: "{\"city\": \"Tokyo\"}"
        )
        let message = SDKMessage.toolUse(data)
        let event = EventMapper.map(message)

        // Verify MCP metadata present
        XCTAssertEqual(event.metadata["isMCP"] as? Bool, true)
        XCTAssertEqual(event.metadata["serverName"] as? String, "weather")
        XCTAssertEqual(event.metadata["toolName"] as? String, "mcp__weather__get_forecast")

        // Verify Inspector can extract display values
        let toolName = event.metadata["toolName"] as? String ?? ""
        let parts = toolName.components(separatedBy: "__")
        if parts.count >= 3 {
            let mcpToolName = parts.dropFirst(2).joined(separator: "__")
            XCTAssertEqual(mcpToolName, "get_forecast")
        }

        // Verify ToolRendererRegistry returns MCPToolRenderer
        let registry = ToolRendererRegistry()
        let renderer = registry.renderer(for: toolName)
        XCTAssertNotNil(renderer, "Registry should return MCPToolRenderer for MCP tool")
    }

    // [P0] Non-MCP tool event does not have MCP metadata
    func testNonMCPToolEventNoMCPMetadataForInspector() {
        let data = SDKMessage.ToolUseData(
            toolName: "Bash",
            toolUseId: "tu-bash-001",
            input: "{\"command\": \"ls -la\"}"
        )
        let message = SDKMessage.toolUse(data)
        let event = EventMapper.map(message)

        XCTAssertNil(event.metadata["isMCP"])
        XCTAssertNil(event.metadata["serverName"])
    }

    // MARK: - AC3: 端到端 — MCP 元数据从 EventMapper 到 Inspector

    // [P0] MCP tool event metadata flows correctly for Inspector display
    func testMCPMetadataFlowsToInspector() {
        // 1. EventMapper produces event with MCP metadata
        let data = SDKMessage.ToolUseData(
            toolName: "mcp__database__query_select_rows",
            toolUseId: "tu-inspector-001",
            input: "{\"sql\": \"SELECT * FROM users\"}"
        )
        let message = SDKMessage.toolUse(data)
        let event = EventMapper.map(message)

        // 2. Inspector reads metadata for display
        guard let isMCP = event.metadata["isMCP"] as? Bool, isMCP else {
            XCTFail("Inspector should detect MCP tool via isMCP metadata")
            return
        }

        let serverName = event.metadata["serverName"] as? String
        XCTAssertEqual(serverName, "database", "Inspector should display server 'database'")

        let fullToolName = event.metadata["toolName"] as? String ?? ""
        let parts = fullToolName.components(separatedBy: "__")

        // 3. Inspector derives display values
        if parts.count >= 3 {
            // 命名空间全名
            XCTAssertEqual(fullToolName, "mcp__database__query_select_rows")

            // 服务器名
            XCTAssertEqual(parts[1], "database")

            // MCP 工具名（去掉前缀）
            let actualToolName = parts.dropFirst(2).joined(separator: "__")
            XCTAssertEqual(actualToolName, "query_select_rows")
        } else {
            XCTFail("Should have 3+ parts in MCP tool name")
        }
    }

    // [P0] MCP toolProgress event also flows MCP metadata
    func testMCPToolProgressMetadataFlowsToInspector() {
        let data = SDKMessage.ToolProgressData(
            toolUseId: "tu-progress-001",
            toolName: "mcp__weather__get_forecast",
            elapsedTimeSeconds: 3.5
        )
        let message = SDKMessage.toolProgress(data)
        let event = EventMapper.map(message)

        XCTAssertEqual(event.metadata["isMCP"] as? Bool, true)
        XCTAssertEqual(event.metadata["serverName"] as? String, "weather")
    }

    // [P1] MCP toolResult event does not have MCP metadata (toolResult doesn't carry toolName)
    func testMCPToolResultMetadataStatus() {
        let data = SDKMessage.ToolResultData(
            toolUseId: "tu-result-001",
            content: "{\"result\": \"sunny\"}",
            isError: false
        )
        let message = SDKMessage.toolResult(data)
        let event = EventMapper.map(message)

        // toolResult doesn't contain toolName, so MCP detection is not applicable
        // Inspector would need to cross-reference with toolUseId to find the corresponding toolUse event
        XCTAssertNil(event.metadata["isMCP"],
            "toolResult should not have isMCP metadata (no toolName available)")
    }

    // MARK: - AC2: MCPToolRenderer 回归验证

    // [P0] MCPToolRenderer summaryTitle matches Inspector tool name display
    func testMCPToolRendererSummaryTitleMatchesInspector() {
        let renderer = MCPToolRenderer()
        let content = ToolContent(
            toolName: "mcp__weather__get_forecast",
            toolUseId: "tu-renderer-001",
            input: "{}",
            output: nil,
            isError: false
        )

        let title = renderer.summaryTitle(content: content)
        XCTAssertEqual(title, "get_forecast")

        // Inspector should display the same name
        let parts = content.toolName.components(separatedBy: "__")
        if parts.count >= 3 {
            let inspectorToolName = parts.dropFirst(2).joined(separator: "__")
            XCTAssertEqual(title, inspectorToolName,
                "MCPToolRenderer and Inspector should display same tool name")
        }
    }

    // [P0] MCPToolRenderer subtitle shows server name
    func testMCPToolRendererSubtitleShowsServerName() {
        let renderer = MCPToolRenderer()
        let content = ToolContent(
            toolName: "mcp__weather__get_forecast",
            toolUseId: "tu-renderer-002",
            input: "{}",
            output: nil,
            isError: false
        )

        let subtitle = renderer.subtitle(content: content)
        XCTAssertEqual(subtitle, "via weather")
    }

    // MARK: - 回归验证：现有测试不应被破坏

    // [P0] Existing ToolRendererRegistry still works for non-MCP tools
    func testToolRendererRegistryStillWorksForNonMCPTools() {
        let registry = ToolRendererRegistry()
        // Bash is an exact match in the registry
        let renderer = registry.renderer(for: "Bash")
        XCTAssertNotNil(renderer, "Registry should still work for Bash")
    }

    // [P0] Existing EventMapper still maps non-MCP events correctly
    func testEventMapperStillMapsNonMCPEventsCorrectly() {
        let data = SDKMessage.ToolUseData(
            toolName: "Bash",
            toolUseId: "tu-regression-001",
            input: "{\"command\": \"echo hello\"}"
        )
        let message = SDKMessage.toolUse(data)
        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .toolUse)
        XCTAssertEqual(event.metadata["toolName"] as? String, "Bash")
        XCTAssertNil(event.metadata["isMCP"])
    }
}
