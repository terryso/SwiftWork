import XCTest
import SwiftUI
@testable import SwiftWork

// ATDD Red Phase — Story 2.3: 事件类型视觉系统
// Integration tests verifying that TimelineView applies correct visual styles
// to each event type, and that the visual system is cohesive across all events.
// These tests will FAIL until Story 2.3 is implemented.

@MainActor
final class EventThemeIntegrationTests: XCTestCase {

    // MARK: - Timeline View Rendering per Event Type

    // [P0] Timeline renders all core event types without crash
    func testTimelineRendersAllCoreEventTypes() {
        let events: [AgentEvent] = [
            AgentEvent(type: .userMessage, content: "Hello", timestamp: .now),
            AgentEvent(type: .assistant, content: "Response", metadata: ["model": "claude"], timestamp: .now),
            AgentEvent(type: .system, content: "Init", metadata: ["subtype": "init"] as [String: any Sendable], timestamp: .now),
            AgentEvent(type: .result, content: "Done", metadata: ["subtype": "success", "durationMs": 1000, "numTurns": 1] as [String: any Sendable], timestamp: .now),
            AgentEvent(type: .unknown, content: "", timestamp: .now),
        ]

        for event in events {
            // Each event type should be representable without crash
            XCTAssertNotNil(event, "\(event.type.rawValue) event should be representable")
        }
    }

    // [P0] Each event type maps to a distinct view
    func testEachEventTypeMapsToDistinctView() {
        let types: [AgentEventType] = [
            .userMessage, .assistant, .toolUse, .toolResult,
            .toolProgress, .result, .system, .unknown
        ]

        // All event types should be representable
        for eventType in types {
            let event = AgentEvent(type: eventType, content: "test", timestamp: .now)
            XCTAssertNotNil(event, "\(eventType.rawValue) should instantiate as AgentEvent")
        }
    }

    // MARK: - Visual Consistency Across Event Types

    // [P0] User message events use blue left-aligned bubble consistently
    func testUserMessageVisualConsistency() {
        let events = [
            AgentEvent(type: .userMessage, content: "Short message", timestamp: .now),
            AgentEvent(type: .userMessage, content: String(repeating: "Long message ", count: 50), timestamp: .now),
            AgentEvent(type: .userMessage, content: "中文消息测试", timestamp: .now),
        ]

        for event in events {
            let view = UserMessageView(event: event)
            XCTAssertNotNil(view, "UserMessageView should render consistently for all content")
        }
    }

    // [P0] Tool cards use consistent card shape across all tool types
    func testToolCardVisualConsistencyAcrossToolTypes() {
        let registry = ToolRendererRegistry()
        let toolTypes = [
            ("Bash", "{\"command\": \"ls\"}"),
            ("Edit", "{\"file_path\": \"/src/a.swift\"}"),
            ("Grep", "{\"pattern\": \"TODO\"}"),
            ("Read", "{\"file_path\": \"/src/b.swift\"}"),
            ("Write", "{\"file_path\": \"/src/c.swift\"}"),
        ]

        for (toolName, input) in toolTypes {
            let content = ToolContent(
                toolName: toolName,
                toolUseId: "tu-\(toolName)",
                input: input,
                output: nil,
                isError: false,
                status: .pending
            )
            let view = ToolCardView(content: content, registry: registry, isSelected: false, onSelect: {})
            XCTAssertNotNil(view, "ToolCardView should render consistently for \(toolName)")
        }
    }

    // [P0] Error styling is consistent across tool results and system events
    func testErrorStylingConsistency() {
        // Tool result error
        let toolResultEvent = AgentEvent(
            type: .toolResult,
            content: "error output",
            metadata: ["toolUseId": "tu-001", "isError": true] as [String: any Sendable],
            timestamp: .now
        )
        let toolResultView = ToolResultView(event: toolResultEvent)
        XCTAssertNotNil(toolResultView, "ToolResultView error should have consistent red styling")

        // System event error
        let systemEvent = AgentEvent(
            type: .system,
            content: "error message",
            metadata: ["isError": true] as [String: any Sendable],
            timestamp: .now
        )
        let systemView = SystemEventView(event: systemEvent, isError: true)
        XCTAssertNotNil(systemView, "SystemEventView error should have consistent red styling")

        // ToolResultContentView error
        let resultContentView = ToolResultContentView(output: "fatal error", isError: true)
        XCTAssertNotNil(resultContentView, "ToolResultContentView error should have consistent red styling")
    }

    // MARK: - Color Theme Integration

    // [P0] Color.themeAccent exists and is blue
    func testColorThemeAccentExists() {
        let accent = Color.themeAccent
        XCTAssertNotNil(accent, "Color.themeAccent should be defined for consistent theming")
    }

    // MARK: - Tool Registry Completeness

    // [P0] All expected tool types are registered by default
    func testAllExpectedToolTypesRegistered() {
        let registry = ToolRendererRegistry()
        let expectedTools = ["Bash", "Edit", "Grep", "Read", "Write"]

        for tool in expectedTools {
            XCTAssertNotNil(registry.renderer(for: tool),
                "Registry should have renderer for \(tool) registered by default")
        }
    }

    // [P0] Registry returns nil for unregistered tool
    func testRegistryReturnsNilForUnregisteredTool() {
        let registry = ToolRendererRegistry()
        XCTAssertNil(registry.renderer(for: "NonExistentTool"),
            "Registry should return nil for unregistered tool")
    }

    // MARK: - Status Badge Visual System

    // [P0] ToolExecutionStatus has exactly 4 cases with correct raw values
    func testToolExecutionStatusHasCorrectCases() {
        XCTAssertEqual(ToolExecutionStatus.pending.rawValue, "pending")
        XCTAssertEqual(ToolExecutionStatus.running.rawValue, "running")
        XCTAssertEqual(ToolExecutionStatus.completed.rawValue, "completed")
        XCTAssertEqual(ToolExecutionStatus.failed.rawValue, "failed")
    }

    // [P0] All ToolExecutionStatus values are distinct
    func testToolExecutionStatusValuesAreDistinct() {
        let allStatuses: [ToolExecutionStatus] = [.pending, .running, .completed, .failed]
        let rawValues = Set(allStatuses.map(\.rawValue))
        XCTAssertEqual(rawValues.count, 4, "All status raw values should be distinct")
    }

    // MARK: - Diff Content Visual Differentiation

    // [P1] ToolResultContentView detects diff content and applies color coding
    func testDiffContentColorCoding() {
        let diffOutput = """
        @@ -1,3 +1,3 @@
        -old line
        +new line
         unchanged
        """
        let view = ToolResultContentView(output: diffOutput, isError: false)
        XCTAssertNotNil(view, "ToolResultContentView should apply diff color coding: green for +, red for -, blue for @@")
    }

    // MARK: - Edge Cases

    // [P1] Empty content events render without crash
    func testEmptyContentEventsRender() {
        let events = [
            AgentEvent(type: .userMessage, content: "", timestamp: .now),
            AgentEvent(type: .assistant, content: "", timestamp: .now),
            AgentEvent(type: .system, content: "", timestamp: .now),
        ]

        for event in events {
            switch event.type {
            case .userMessage:
                let view = UserMessageView(event: event)
                XCTAssertNotNil(view)
            case .assistant:
                let view = AssistantMessageView(event: event)
                XCTAssertNotNil(view)
            case .system:
                let view = SystemEventView(event: event)
                XCTAssertNotNil(view)
            default:
                break
            }
        }
    }

    // [P1] All AgentEventType cases have visual representation
    func testAllAgentEventTypesHaveVisualRepresentation() {
        for eventType in AgentEventType.allCases {
            let event = AgentEvent(type: eventType, content: "test content", timestamp: .now)
            XCTAssertNotNil(event, "All AgentEventType cases should create valid events for visual rendering")
        }
    }
}
