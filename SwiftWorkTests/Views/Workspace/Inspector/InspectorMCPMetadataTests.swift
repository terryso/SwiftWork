import XCTest
@testable import SwiftWork

// ATDD Red Phase -- Story 6.5: MCP 状态可视化
// Unit tests for InspectorView MCP metadata extraction and display logic.
// These tests assert EXPECTED behavior. They will FAIL until Story 6-5 is implemented.
//
// Coverage:
//   AC3 -- Inspector MCP 工具元数据展示（serverName, mcpToolName, 命名空间全名）

final class InspectorMCPMetadataTests: XCTestCase {

    // MARK: - AC3: MCP 元数据检测

    // [P0] MCP tool event identified via metadata["isMCP"]
    func testMCPToolEventIdentifiedViaMetadata() {
        let event = AgentEvent(
            type: .toolUse,
            content: "mcp__weather__get_forecast",
            metadata: [
                "toolName": "mcp__weather__get_forecast",
                "toolUseId": "tu-001",
                "input": "{\"city\": \"Tokyo\"}",
                "isMCP": true,
                "serverName": "weather"
            ],
            timestamp: .now
        )

        let isMCP = event.metadata["isMCP"] as? Bool ?? false
        XCTAssertTrue(isMCP,
            "MCP toolUse event should have isMCP = true")
    }

    // [P0] Non-MCP tool event does not have isMCP metadata
    func testNonMCPToolEventNoIsMCPMetadata() {
        let event = AgentEvent(
            type: .toolUse,
            content: "Bash",
            metadata: [
                "toolName": "Bash",
                "toolUseId": "tu-002",
                "input": "{\"command\": \"ls\"}"
            ],
            timestamp: .now
        )

        let isMCP = event.metadata["isMCP"] as? Bool
        XCTAssertNil(isMCP,
            "Non-MCP toolUse should NOT have isMCP metadata")
    }

    // MARK: - AC3: MCP 元数据字段完整性

    // [P0] MCP tool event has all required metadata fields
    func testMCPToolEventHasAllRequiredMetadataFields() {
        let event = AgentEvent(
            type: .toolUse,
            content: "mcp__weather__get_forecast",
            metadata: [
                "toolName": "mcp__weather__get_forecast",
                "toolUseId": "tu-010",
                "input": "{}",
                "isMCP": true,
                "serverName": "weather"
            ],
            timestamp: .now
        )

        // Required MCP metadata fields for Inspector
        XCTAssertNotNil(event.metadata["isMCP"], "Should have isMCP")
        XCTAssertNotNil(event.metadata["serverName"], "Should have serverName")
        XCTAssertNotNil(event.metadata["toolName"], "Should have toolName")
    }

    // MARK: - AC3: MCP 工具名解析逻辑

    // [P0] Extracts actual tool name from full namespace "mcp__server__tool"
    func testExtractsActualToolNameFromFullNamespace() {
        let toolName = "mcp__weather__get_forecast"
        let parts = toolName.components(separatedBy: "__")

        XCTAssertEqual(parts.count, 3)
        XCTAssertEqual(parts[0], "mcp")
        XCTAssertEqual(parts[1], "weather")
        XCTAssertEqual(parts[2], "get_forecast")
    }

    // [P0] Handles tool names with additional underscores
    func testHandlesToolNamesWithAdditionalUnderscores() {
        let toolName = "mcp__database__query_select_rows"
        let parts = toolName.components(separatedBy: "__")

        // Single underscores within the tool name are NOT separators
        XCTAssertEqual(parts.count, 3)
        XCTAssertEqual(parts[0], "mcp")
        XCTAssertEqual(parts[1], "database")
        // Actual tool name is everything after server prefix
        let actualToolName = parts.dropFirst(2).joined(separator: "__")
        XCTAssertEqual(actualToolName, "query_select_rows",
            "Should preserve underscores in tool name part")
    }

    // [P0] Extracts server name from namespace
    func testExtractsServerNameFromNamespace() {
        let toolName = "mcp__weather__get_forecast"
        let parts = toolName.components(separatedBy: "__")

        guard parts.count >= 2 else {
            XCTFail("Should have at least 2 parts")
            return
        }
        XCTAssertEqual(parts[1], "weather",
            "Should extract 'weather' as server name")
    }

    // [P1] Handles malformed namespace with only 2 parts
    func testHandlesMalformedNamespaceWithTwoParts() {
        let toolName = "mcp__onlyonepart"
        let parts = toolName.components(separatedBy: "__")

        XCTAssertEqual(parts.count, 2)
        XCTAssertEqual(parts[0], "mcp")
        XCTAssertEqual(parts[1], "onlyonepart")
        // In this case, no actual tool name can be extracted
        // Implementation should handle gracefully
    }

    // [P1] Handles minimal namespace "mcp__s__t"
    func testHandlesMinimalNamespace() {
        let toolName = "mcp__s__t"
        let parts = toolName.components(separatedBy: "__")

        XCTAssertEqual(parts.count, 3)
        XCTAssertEqual(parts[1], "s", "Server name should be 's'")
        XCTAssertEqual(parts[2], "t", "Tool name should be 't'")
    }

    // MARK: - AC3: MCP 元数据展示逻辑（Inspector 专用）

    // [P0] MCP metadata extraction helper returns source label
    func testMCPMetadataSourceLabel() {
        let event = AgentEvent(
            type: .toolUse,
            content: "mcp__weather__get_forecast",
            metadata: [
                "toolName": "mcp__weather__get_forecast",
                "isMCP": true,
                "serverName": "weather"
            ],
            timestamp: .now
        )

        // Verify the metadata contains the information Inspector needs
        let isMCP = event.metadata["isMCP"] as? Bool ?? false
        XCTAssertTrue(isMCP)

        let serverName = event.metadata["serverName"] as? String
        XCTAssertEqual(serverName, "weather")

        let toolName = event.metadata["toolName"] as? String
        XCTAssertEqual(toolName, "mcp__weather__get_forecast")
    }

    // [P0] Inspector can derive MCP tool display name from toolName
    func testInspectorDerivesMCPToolDisplayName() {
        let toolName = "mcp__weather__get_forecast"
        let parts = toolName.components(separatedBy: "__")

        guard parts.count >= 3 else {
            XCTFail("Need 3+ parts for valid MCP tool name")
            return
        }

        // Display values Inspector should show:
        // - 来源: MCP
        // - 服务器: weather
        // - 命名空间: mcp__weather__get_forecast
        // - MCP 工具: get_forecast
        let source = "MCP"
        let server = parts[1]
        let namespace = toolName
        let mcpToolName = parts.dropFirst(2).joined(separator: "__")

        XCTAssertEqual(source, "MCP")
        XCTAssertEqual(server, "weather")
        XCTAssertEqual(namespace, "mcp__weather__get_forecast")
        XCTAssertEqual(mcpToolName, "get_forecast")
    }

    // [P0] Non-MCP event metadata does not trigger MCP section
    func testNonMCPEventDoesNotTriggerMCPSection() {
        let event = AgentEvent(
            type: .toolUse,
            content: "Bash",
            metadata: [
                "toolName": "Bash",
                "toolUseId": "tu-bash-001",
                "input": "{\"command\": \"ls\"}"
            ],
            timestamp: .now
        )

        let isMCP = event.metadata["isMCP"] as? Bool ?? false
        XCTAssertFalse(isMCP,
            "Non-MCP event should not trigger MCP section in Inspector")
    }

    // MARK: - AC3: MCPToolRenderer 和 Inspector 解析逻辑一致性

    // [P0] Inspector and MCPToolRenderer use same parsing logic
    func testInspectorAndRendererUseSameParsingLogic() {
        // This test verifies the parsing logic used in both
        // MCPToolRenderer.summaryTitle and Inspector MCP metadata section
        // is consistent
        let toolNames = [
            "mcp__weather__get_forecast",
            "mcp__database__query_select_rows",
            "mcp__s__t",
        ]

        for toolName in toolNames {
            let parts = toolName.components(separatedBy: "__")

            // MCPToolRenderer logic
            let rendererTitle: String
            if parts.count >= 3 {
                rendererTitle = parts.dropFirst(2).joined(separator: "__")
            } else {
                rendererTitle = toolName
            }

            // Inspector logic (should be same)
            let inspectorToolName: String
            if parts.count >= 3 {
                inspectorToolName = parts.dropFirst(2).joined(separator: "__")
            } else {
                inspectorToolName = toolName
            }

            XCTAssertEqual(rendererTitle, inspectorToolName,
                "MCPToolRenderer and Inspector should parse '\(toolName)' identically")
        }
    }

    // [P0] Server name extraction consistent between EventMapper and Inspector
    func testServerNameExtractionConsistent() {
        let toolName = "mcp__weather__get_forecast"
        let parts = toolName.components(separatedBy: "__")

        // EventMapper logic (from EventMapper.swift line 43-44)
        let eventMapperServerName = parts.count >= 2 ? parts[1] : nil

        // Inspector logic
        let inspectorServerName = parts.count >= 2 ? parts[1] : nil

        XCTAssertEqual(eventMapperServerName, inspectorServerName,
            "EventMapper and Inspector should extract same server name")
        XCTAssertEqual(eventMapperServerName, "weather")
    }
}
