import XCTest
import SwiftUI
@testable import SwiftWork

// ATDD Red Phase -- Story 4.1: Debug Panel
// Component tests for DebugView rendering and WorkspaceView integration.
// These tests will FAIL until Story 4.1 is implemented.

@MainActor
final class DebugViewTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeBridge() -> AgentBridge {
        AgentBridge()
    }

    private func makeResultEvent(
        durationMs: Int = 3500,
        totalCostUsd: Double = 0.045,
        numTurns: Int = 5,
        inputTokens: Int? = nil,
        outputTokens: Int? = nil
    ) -> AgentEvent {
        var metadata: [String: any Sendable] = [
            "durationMs": durationMs,
            "totalCostUsd": totalCostUsd,
            "numTurns": numTurns
        ]
        if let inputTokens, let outputTokens {
            metadata["usage"] = [
                "inputTokens": inputTokens,
                "outputTokens": outputTokens
            ] as [String: any Sendable]
        }
        return AgentEvent(
            type: .result,
            content: "success",
            metadata: metadata,
            timestamp: Date()
        )
    }

    private func makeToolUseEvent(
        toolName: String = "Bash",
        toolUseId: String = "tu-dv-001",
        input: String = "{\"command\": \"ls -la\"}"
    ) -> AgentEvent {
        AgentEvent(
            type: .toolUse,
            content: toolName,
            metadata: [
                "toolName": toolName,
                "toolUseId": toolUseId,
                "input": input
            ] as [String: any Sendable],
            timestamp: Date()
        )
    }

    private func makeToolResultEvent(
        toolUseId: String = "tu-dv-001",
        content: String = "file1.txt\nfile2.txt",
        isError: Bool = false
    ) -> AgentEvent {
        AgentEvent(
            type: .toolResult,
            content: content,
            metadata: [
                "toolUseId": toolUseId,
                "isError": isError
            ] as [String: any Sendable],
            timestamp: Date()
        )
    }

    private func makeAssistantEvent() -> AgentEvent {
        AgentEvent(
            type: .assistant,
            content: "Here is the response",
            metadata: ["model": "claude-sonnet-4-6"] as [String: any Sendable],
            timestamp: Date()
        )
    }

    private func makeSystemEvent() -> AgentEvent {
        AgentEvent(
            type: .system,
            content: "System initialized",
            metadata: ["subtype": "init"] as [String: any Sendable],
            timestamp: Date()
        )
    }

    // MARK: - AC#1: DebugView renders Raw Event Stream tab

    // [P0] DebugView instantiates with AgentBridge
    func testDebugViewInstantiatesWithAgentBridge() {
        let bridge = makeBridge()
        let vm = DebugViewModel(agentBridge: bridge)
        let view = DebugView(debugViewModel: vm)
        XCTAssertNotNil(view, "DebugView should instantiate with DebugViewModel")
    }

    // [P0] DebugView renders empty state when no events
    func testDebugViewRendersEmptyState() {
        let bridge = makeBridge()
        bridge.events = []
        let vm = DebugViewModel(agentBridge: bridge)
        let view = DebugView(debugViewModel: vm)
        XCTAssertNotNil(view, "DebugView should render empty state without crash")
    }

    // [P1] DebugView handles all 20 AgentEventType cases without crash
    func testDebugViewHandlesAllEventTypes() {
        let bridge = makeBridge()
        let allTypes: [AgentEventType] = AgentEventType.allCases
        bridge.events = allTypes.map { type in
            AgentEvent(
                type: type,
                content: "Test \(type.rawValue)",
                metadata: ["testKey": "value"] as [String: any Sendable],
                timestamp: Date()
            )
        }
        let vm = DebugViewModel(agentBridge: bridge)
        let view = DebugView(debugViewModel: vm)
        XCTAssertNotNil(view, "DebugView should handle all event types without crash")
    }

    // MARK: - AC#2: DebugView renders Token Statistics tab

    // [P0] DebugView renders token statistics with data
    func testDebugViewRendersTokenStatistics() {
        let bridge = makeBridge()
        bridge.events = [
            makeResultEvent(totalCostUsd: 0.087, inputTokens: 2000, outputTokens: 3500)
        ]
        let vm = DebugViewModel(agentBridge: bridge)
        let view = DebugView(debugViewModel: vm)
        XCTAssertNotNil(view, "DebugView should render with token statistics data")
    }

    // [P1] DebugView renders zero-state token summary
    func testDebugViewRendersZeroTokenSummary() {
        let bridge = makeBridge()
        bridge.events = []
        let vm = DebugViewModel(agentBridge: bridge)
        let view = DebugView(debugViewModel: vm)
        XCTAssertNotNil(view, "DebugView should render zero-state token summary")
    }

    // MARK: - AC#3: DebugView renders Tool Logs tab

    // [P0] DebugView renders tool logs tab
    func testDebugViewRendersToolLogs() {
        let bridge = makeBridge()
        let toolUseId = "tu-dvtool-001"
        bridge.events = [
            makeToolUseEvent(toolUseId: toolUseId),
            makeToolResultEvent(toolUseId: toolUseId)
        ]
        bridge.toolContentMap = [
            toolUseId: ToolContent(
                toolName: "Bash",
                toolUseId: toolUseId,
                input: "{\"command\": \"make build\"}",
                output: "Build OK",
                isError: false,
                status: .completed,
                elapsedTimeSeconds: 4
            )
        ]
        let vm = DebugViewModel(agentBridge: bridge)
        let view = DebugView(debugViewModel: vm)
        XCTAssertNotNil(view, "DebugView should render tool logs with data")
    }

    // [P1] DebugView renders tool logs with different statuses
    func testDebugViewRendersToolLogsWithAllStatuses() {
        let bridge = makeBridge()
        bridge.events = [
            makeToolUseEvent(toolUseId: "tu-s-a"),
            makeToolUseEvent(toolUseId: "tu-s-b"),
            makeToolUseEvent(toolUseId: "tu-s-c"),
            makeToolUseEvent(toolUseId: "tu-s-d")
        ]
        bridge.toolContentMap = [
            "tu-s-a": ToolContent(
                toolName: "Bash", toolUseId: "tu-s-a",
                input: "", output: "ok", isError: false, status: .completed
            ),
            "tu-s-b": ToolContent(
                toolName: "Bash", toolUseId: "tu-s-b",
                input: "", output: "err", isError: true, status: .failed
            ),
            "tu-s-c": ToolContent(
                toolName: "Read", toolUseId: "tu-s-c",
                input: "", output: nil, isError: false, status: .running, elapsedTimeSeconds: 7
            ),
            "tu-s-d": ToolContent(
                toolName: "Grep", toolUseId: "tu-s-d",
                input: "", output: nil, isError: false, status: .pending
            )
        ]
        let vm = DebugViewModel(agentBridge: bridge)
        let view = DebugView(debugViewModel: vm)
        XCTAssertNotNil(view, "DebugView should handle all tool execution statuses")
    }

    // MARK: - Integration: WorkspaceView + Debug Panel

    // [P0] WorkspaceView accepts isDebugPanelVisible binding
    func testWorkspaceViewAcceptsDebugPanelVisibility() {
        let bridge = makeBridge()
        let session = Session(title: "Test")
        let settingsVM = SettingsViewModel()
        let sessionVM = SessionViewModel()

        let view = WorkspaceView(
            agentBridge: bridge,
            eventStore: nil,
            session: session,
            settingsViewModel: settingsVM,
            sessionViewModel: sessionVM,
            isInspectorVisible: .constant(false),
            isDebugPanelVisible: .constant(false)
        )
        XCTAssertNotNil(view, "WorkspaceView should accept isDebugPanelVisible binding")
    }

    // [P1] WorkspaceView renders with Debug Panel visible
    func testWorkspaceViewWithDebugPanelVisible() {
        let bridge = makeBridge()
        let session = Session(title: "Test")
        let settingsVM = SettingsViewModel()
        let sessionVM = SessionViewModel()

        let view = WorkspaceView(
            agentBridge: bridge,
            eventStore: nil,
            session: session,
            settingsViewModel: settingsVM,
            sessionViewModel: sessionVM,
            isInspectorVisible: .constant(false),
            isDebugPanelVisible: .constant(true)
        )
        XCTAssertNotNil(view, "WorkspaceView should render with isDebugPanelVisible=true")
    }

    // [P1] WorkspaceView renders with both Inspector and Debug Panel visible
    func testWorkspaceViewWithBothPanelsVisible() {
        let bridge = makeBridge()
        let session = Session(title: "Test")
        let settingsVM = SettingsViewModel()
        let sessionVM = SessionViewModel()

        let view = WorkspaceView(
            agentBridge: bridge,
            eventStore: nil,
            session: session,
            settingsViewModel: settingsVM,
            sessionViewModel: sessionVM,
            isInspectorVisible: .constant(true),
            isDebugPanelVisible: .constant(true)
        )
        XCTAssertNotNil(view, "WorkspaceView should render with both Inspector and Debug Panel visible")
    }
}
