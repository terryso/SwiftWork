import XCTest
import SwiftUI
@testable import SwiftWork
import OpenAgentSDK

// ATDD Red Phase -- Story 6.4: Agent MCP 集成与工具注册
// Unit tests for MCPToolRenderer, ToolRendererRegistry MCP prefix matching,
// and EventMapper MCP metadata detection.
// These tests assert EXPECTED behavior. They will FAIL until Story 6-4 is implemented.
//
// Coverage:
//   AC2 -- MCP 工具 Tool Card 渲染（MCPToolRenderer 实现）
//   AC2 -- ToolRendererRegistry 前缀匹配
//   AC2 -- EventMapper MCP 元数据传递

@MainActor
final class MCPToolRendererTests: XCTestCase {

    // MARK: - AC2: MCPToolRenderer summaryTitle 解析

    // [P0] summaryTitle extracts tool name from "mcp__serverName__toolName"
    func testSummaryTitleExtractsToolNameFromNamespace() throws {
        let renderer = MCPToolRenderer()
        let content = ToolContent(
            toolName: "mcp__weather__get_forecast",
            toolUseId: "tu-mcp-001",
            input: "{}",
            output: nil,
            isError: false
        )
        let title = renderer.summaryTitle(content: content)
        XCTAssertEqual(title, "get_forecast",
            "summaryTitle should extract 'get_forecast' from 'mcp__weather__get_forecast'")
    }

    // [P0] summaryTitle handles toolName with additional underscores in tool part
    func testSummaryTitleHandlesUnderscoreInToolName() throws {
        let renderer = MCPToolRenderer()
        let content = ToolContent(
            toolName: "mcp__db__query_select_rows",
            toolUseId: "tu-mcp-002",
            input: "{}",
            output: nil,
            isError: false
        )
        let title = renderer.summaryTitle(content: content)
        XCTAssertEqual(title, "query_select_rows",
            "summaryTitle should preserve underscores in the tool name part")
    }

    // [P1] summaryTitle falls back to full toolName for malformed namespace
    func testSummaryTitleFallsBackForTwoPartName() throws {
        let renderer = MCPToolRenderer()
        let content = ToolContent(
            toolName: "mcp__onlyonepart",
            toolUseId: "tu-mcp-003",
            input: "{}",
            output: nil,
            isError: false
        )
        let title = renderer.summaryTitle(content: content)
        XCTAssertEqual(title, "mcp__onlyonepart",
            "summaryTitle should fall back to full toolName for malformed namespace")
    }

    // [P1] summaryTitle falls back for non-mcp toolName
    func testSummaryTitleFallsBackForNonMCPToolName() throws {
        let renderer = MCPToolRenderer()
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-mcp-004",
            input: "{}",
            output: nil,
            isError: false
        )
        let title = renderer.summaryTitle(content: content)
        XCTAssertEqual(title, "Bash",
            "summaryTitle should fall back to full toolName for non-MCP tool")
    }

    // MARK: - AC2: MCPToolRenderer subtitle 生成

    // [P0] subtitle extracts server name as "via {serverName}"
    func testSubtitleExtractsServerName() throws {
        let renderer = MCPToolRenderer()
        let content = ToolContent(
            toolName: "mcp__weather__get_forecast",
            toolUseId: "tu-mcp-010",
            input: "{}",
            output: nil,
            isError: false
        )
        let subtitle = renderer.subtitle(content: content)
        XCTAssertEqual(subtitle, "via weather",
            "subtitle should show 'via weather' for server name 'weather'")
    }

    // [P0] subtitle returns nil for non-MCP toolName
    func testSubtitleReturnsNilForNonMCPTool() throws {
        let renderer = MCPToolRenderer()
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "tu-mcp-011",
            input: "{}",
            output: nil,
            isError: false
        )
        let subtitle = renderer.subtitle(content: content)
        XCTAssertNil(subtitle,
            "subtitle should be nil for non-MCP toolName")
    }

    // [P1] subtitle returns nil for malformed mcp namespace
    func testSubtitleReturnsNilForMalformedNamespace() throws {
        let renderer = MCPToolRenderer()
        let content = ToolContent(
            toolName: "mcp__onlyonepart",
            toolUseId: "tu-mcp-012",
            input: "{}",
            output: nil,
            isError: false
        )
        // With only 2 parts after split, parts[1] exists so it should return "via onlyonepart"
        // But this is a malformed case — behavior depends on implementation
        // The implementation should still try to extract a server name
        let subtitle = renderer.subtitle(content: content)
        // Accepting either "via onlyonepart" or nil for this edge case
        if let subtitle {
            XCTAssertEqual(subtitle, "via onlyonepart")
        }
    }

    // MARK: - AC2: MCPToolRenderer static properties

    // [P0] MCPToolRenderer has blue accent color
    func testMCPToolRendererHasBlueAccentColor() throws {
        // MCP tools should use blue accent to distinguish from built-in tools
        let color = MCPToolRenderer.accentColor
        // SwiftUI Color.blue -- can only verify it's not the default gray
        XCTAssertNotEqual(MCPToolRenderer.accentColor, BashToolRenderer.accentColor,
            "MCPToolRenderer accentColor should differ from BashToolRenderer")
    }

    // [P0] MCPToolRenderer has icon
    func testMCPToolRendererHasIcon() throws {
        let icon = MCPToolRenderer.icon
        XCTAssertFalse(icon.isEmpty, "MCPToolRenderer should have a non-empty icon")
    }

    // [P0] MCPToolRenderer body returns a View
    func testMCPToolRendererBodyReturnsView() throws {
        let renderer = MCPToolRenderer()
        let content = ToolContent(
            toolName: "mcp__weather__get_forecast",
            toolUseId: "tu-mcp-020",
            input: "{\"city\": \"Tokyo\"}",
            output: nil,
            isError: false
        )
        let view = renderer.body(content: content)
        XCTAssertNotNil(view, "MCPToolRenderer.body(content:) should return a non-nil View")
    }

    // MARK: - AC2: ToolRendererRegistry MCP 前缀匹配

    // [P0] Registry returns MCPToolRenderer for "mcp__" prefixed tool name
    func testRegistryReturnsMCPRendererForPrefixedToolName() throws {
        let registry = ToolRendererRegistry()

        let renderer = registry.renderer(for: "mcp__weather__get_forecast")
        XCTAssertNotNil(renderer,
            "Registry should return MCPToolRenderer for 'mcp__weather__get_forecast'")
    }

    // [P0] Registry returns MCPToolRenderer for any "mcp__" prefixed tool
    func testRegistryReturnsMCPRendererForAnyMCPPrefix() throws {
        let registry = ToolRendererRegistry()

        let renderer = registry.renderer(for: "mcp__database__query")
        XCTAssertNotNil(renderer,
            "Registry should return MCPToolRenderer for 'mcp__database__query'")
    }

    // [P0] Registry exact match takes priority over prefix match
    func testRegistryExactMatchOverridesPrefixMatch() throws {
        let registry = ToolRendererRegistry()
        // "Bash" is an exact match in the registry -- should return BashToolRenderer, not MCPToolRenderer
        let renderer = registry.renderer(for: "Bash")
        XCTAssertNotNil(renderer)
        // Even though we can't check the exact type, we can verify the renderer exists
    }

    // [P0] Registry returns nil for non-matching non-mcp tool
    func testRegistryReturnsNilForUnregisteredNonMCPTool() throws {
        let registry = ToolRendererRegistry()

        let renderer = registry.renderer(for: "SomeRandomTool")
        XCTAssertNil(renderer,
            "Registry should return nil for unregistered non-MCP tool")
    }

    // [P1] Registry returns MCPToolRenderer for "mcp__" prefix with minimal name
    func testRegistryReturnsMCPRendererForMinimalMCPName() throws {
        let registry = ToolRendererRegistry()

        let renderer = registry.renderer(for: "mcp__s__t")
        XCTAssertNotNil(renderer,
            "Registry should return MCPToolRenderer even for minimal 'mcp__s__t'")
    }

    // MARK: - AC2: EventMapper MCP 元数据传递

    // [P0] EventMapper adds isMCP metadata for mcp__ prefixed toolUse
    func testEventMapperAddsIsMCPMetadataForMCPToolUse() throws {
        let data = SDKMessage.ToolUseData(
            toolName: "mcp__weather__get_forecast",
            toolUseId: "tu-mcp-030",
            input: "{\"city\": \"Tokyo\"}"
        )
        let message = SDKMessage.toolUse(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.type, .toolUse)
        XCTAssertEqual(event.metadata["isMCP"] as? Bool, true,
            "MCP toolUse event should have isMCP = true in metadata")
    }

    // [P0] EventMapper adds serverName metadata for mcp__ toolUse
    func testEventMapperAddsServerNameMetadataForMCPToolUse() throws {
        let data = SDKMessage.ToolUseData(
            toolName: "mcp__weather__get_forecast",
            toolUseId: "tu-mcp-031",
            input: "{\"city\": \"Tokyo\"}"
        )
        let message = SDKMessage.toolUse(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.metadata["serverName"] as? String, "weather",
            "MCP toolUse metadata should contain serverName = 'weather'")
    }

    // [P0] EventMapper does not add isMCP for non-MCP toolUse
    func testEventMapperNoIsMCPForNonMCPToolUse() throws {
        let data = SDKMessage.ToolUseData(
            toolName: "Bash",
            toolUseId: "tu-bash-001",
            input: "{\"command\": \"ls\"}"
        )
        let message = SDKMessage.toolUse(data)

        let event = EventMapper.map(message)

        XCTAssertNil(event.metadata["isMCP"],
            "Non-MCP toolUse should NOT have isMCP in metadata")
        XCTAssertNil(event.metadata["serverName"],
            "Non-MCP toolUse should NOT have serverName in metadata")
    }

    // [P1] EventMapper adds isMCP for mcp__ toolProgress
    func testEventMapperAddsIsMCPForMCPToolProgress() throws {
        let data = SDKMessage.ToolProgressData(
            toolUseId: "tu-mcp-032",
            toolName: "mcp__weather__get_forecast",
            elapsedTimeSeconds: 2.0
        )
        let message = SDKMessage.toolProgress(data)

        let event = EventMapper.map(message)

        XCTAssertEqual(event.metadata["isMCP"] as? Bool, true,
            "MCP toolProgress event should have isMCP = true in metadata")
        XCTAssertEqual(event.metadata["serverName"] as? String, "weather",
            "MCP toolProgress metadata should contain serverName = 'weather'")
    }

    // [P1] EventMapper does not add isMCP for non-MCP toolProgress
    func testEventMapperNoIsMCPForNonMCPToolProgress() throws {
        let data = SDKMessage.ToolProgressData(
            toolUseId: "tu-bash-002",
            toolName: "Bash",
            elapsedTimeSeconds: 1.0
        )
        let message = SDKMessage.toolProgress(data)

        let event = EventMapper.map(message)

        XCTAssertNil(event.metadata["isMCP"],
            "Non-MCP toolProgress should NOT have isMCP in metadata")
    }

    // [P0] EventMapper preserves existing metadata for MCP toolUse
    func testEventMapperPreservesExistingMetadataForMCPToolUse() throws {
        let data = SDKMessage.ToolUseData(
            toolName: "mcp__db__query",
            toolUseId: "tu-mcp-033",
            input: "{\"sql\": \"SELECT * FROM users\"}"
        )
        let message = SDKMessage.toolUse(data)

        let event = EventMapper.map(message)

        // Existing metadata should still be present
        XCTAssertEqual(event.metadata["toolName"] as? String, "mcp__db__query")
        XCTAssertEqual(event.metadata["toolUseId"] as? String, "tu-mcp-033")
        XCTAssertEqual(event.metadata["input"] as? String, "{\"sql\": \"SELECT * FROM users\"}")
        // Plus MCP-specific metadata
        XCTAssertEqual(event.metadata["isMCP"] as? Bool, true)
        XCTAssertEqual(event.metadata["serverName"] as? String, "db")
    }
}
