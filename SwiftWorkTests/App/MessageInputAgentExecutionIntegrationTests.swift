import XCTest
@testable import SwiftWork
import SwiftData
import OpenAgentSDK

// ATDD Red Phase — Story 1.4: 消息输入与 Agent 执行
// Integration tests for WorkspaceView, InputBarView, TimelineView instantiation
// and ContentView integration with AgentBridge.
// These tests will FAIL until views are implemented.

@MainActor
final class MessageInputAgentExecutionIntegrationTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeModelContext() throws -> ModelContext {
        let schema = Schema([Session.self, Event.self, AppConfiguration.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    // MARK: - AC#1: View instantiation

    // [P0] InputBarView can be instantiated (placeholder → real view)
    func testInputBarViewInstantiation() {
        let bridge = AgentBridge()
        let inputBar = InputBarView(agentBridge: bridge)
        XCTAssertNotNil(inputBar, "InputBarView should be instantiable with AgentBridge")
    }

    // [P0] TimelineView can be instantiated (placeholder → real view)
    func testTimelineViewInstantiation() {
        let bridge = AgentBridge()
        let timeline = TimelineView(agentBridge: bridge)
        XCTAssertNotNil(timeline, "TimelineView should be instantiable with AgentBridge")
    }

    // [P0] WorkspaceView can be instantiated (new file)
    func testWorkspaceViewInstantiation() {
        let bridge = AgentBridge()
        let session = Session(title: "Test")
        let settingsVM = SettingsViewModel()
        let workspace = WorkspaceView(
            agentBridge: bridge,
            eventStore: nil,
            session: session,
            settingsViewModel: settingsVM,
            sessionViewModel: SessionViewModel()
        )
        XCTAssertNotNil(workspace, "WorkspaceView should be instantiable")
    }

    // [P1] ContentView integrates AgentBridge (instantiation check)
    func testContentViewIntegratesAgentBridge() {
        let contentView = ContentView()
        XCTAssertNotNil(contentView, "ContentView should be instantiable with AgentBridge integration")
    }

    // MARK: - AC#1: AgentBridge + SwiftData integration

    // [P0] AgentBridge can be configured with session data
    func testAgentBridgeConfigureWithSession() throws {
        let bridge = AgentBridge()
        let session = Session(title: "Test Session", workspacePath: "/tmp/test")

        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "claude-sonnet-4-6",
            workspacePath: session.workspacePath,
            sessionId: session.id.uuidString
        )

        // No crash = success
        XCTAssertTrue(true, "AgentBridge configure with session data should not crash")
    }

    // [P0] Multiple messages can be sent sequentially
    func testMultipleMessagesSequentially() async throws {
        let bridge = AgentBridge()
        bridge.configure(apiKey: "test-key", baseURL: nil, model: "test-model", workspacePath: nil, sessionId: UUID().uuidString)

        await bridge.sendMessage("First message")
        await bridge.sendMessage("Second message")
        await bridge.sendMessage("Third message")

        // Each send should append a user message
        let userMessages = bridge.events.filter { $0.type == .userMessage }
        XCTAssertEqual(userMessages.count, 3, "Should have 3 user message events")
        XCTAssertEqual(userMessages[0].content, "First message")
        XCTAssertEqual(userMessages[1].content, "Second message")
        XCTAssertEqual(userMessages[2].content, "Third message")
    }

    // MARK: - AC#2: Cancel during execution (integration)

    // [P0] Cancel adds system event and preserves existing events
    func testCancelPreservesExistingEvents() async throws {
        let bridge = AgentBridge()
        bridge.configure(apiKey: "test-key", baseURL: nil, model: "test-model", workspacePath: nil, sessionId: UUID().uuidString)

        await bridge.sendMessage("Hello")
        let preCancelCount = bridge.events.count

        bridge.cancelExecution()

        // Cancel should append event, not remove existing ones
        XCTAssertGreaterThanOrEqual(bridge.events.count, preCancelCount, "Cancel should not remove existing events")

        let cancelEvent = bridge.events.last
        XCTAssertEqual(cancelEvent?.content, "任务已取消")
    }

    // MARK: - AC#3: Error recovery (integration)

    // [P0] After error, user can send a new message
    func testErrorRecoveryAllowsResend() async throws {
        let bridge = AgentBridge()
        bridge.configure(apiKey: "invalid-key", baseURL: nil, model: "test-model", workspacePath: nil, sessionId: UUID().uuidString)

        // First send with invalid key (will likely fail)
        await bridge.sendMessage("First")

        // Second send should still work (no crash, no stuck state)
        await bridge.sendMessage("Second")

        let userMessages = bridge.events.filter { $0.type == .userMessage }
        XCTAssertEqual(userMessages.count, 2, "Both messages should be recorded")
    }

    // [P0] clearEvents + reconfigure allows fresh start after error
    func testFreshStartAfterError() async throws {
        let bridge = AgentBridge()
        bridge.configure(apiKey: "key", baseURL: nil, model: "model", workspacePath: nil, sessionId: UUID().uuidString)

        await bridge.sendMessage("error-causing message")
        bridge.cancelExecution()

        // Fresh start
        bridge.clearEvents()
        bridge.configure(apiKey: "new-key", baseURL: nil, model: "new-model", workspacePath: "/new", sessionId: UUID().uuidString)

        XCTAssertTrue(bridge.events.isEmpty, "Fresh start should clear all events")
        XCTAssertFalse(bridge.isRunning)
        XCTAssertNil(bridge.errorMessage)
    }

    // MARK: - AC#1: EventMapper integration (round-trip)

    // [P0] EventMapper produces events with correct types for all 18 SDKMessage cases
    func testEventMapperCoversAllSDKMessageTypes() {
        let messages: [SDKMessage] = [
            .partialMessage(SDKMessage.PartialData(text: "a")),
            .assistant(SDKMessage.AssistantData(text: "b", model: "m", stopReason: "end_turn")),
            .toolUse(SDKMessage.ToolUseData(toolName: "T", toolUseId: "1", input: "{}")),
            .toolResult(SDKMessage.ToolResultData(toolUseId: "1", content: "c", isError: false)),
            .toolProgress(SDKMessage.ToolProgressData(toolUseId: "1", toolName: "T")),
            .result(SDKMessage.ResultData(subtype: .success, text: "d", usage: nil, numTurns: 1, durationMs: 100)),
            .system(SDKMessage.SystemData(subtype: .`init`, message: "e")),
            .userMessage(SDKMessage.UserMessageData(message: "f")),
            .hookStarted(SDKMessage.HookStartedData(hookId: "h", hookName: "H", hookEvent: "e")),
            .hookProgress(SDKMessage.HookProgressData(hookId: "h", hookName: "H", hookEvent: "e")),
            .hookResponse(SDKMessage.HookResponseData(hookId: "h", hookName: "H", hookEvent: "e")),
            .taskStarted(SDKMessage.TaskStartedData(taskId: "t", taskType: "sub", description: "desc")),
            .taskProgress(SDKMessage.TaskProgressData(taskId: "t", taskType: "sub")),
            .authStatus(SDKMessage.AuthStatusData(status: "ok", message: "auth")),
            .filesPersisted(SDKMessage.FilesPersistedData(filePaths: ["/a"])),
            .localCommandOutput(SDKMessage.LocalCommandOutputData(output: "out", command: "cmd")),
            .promptSuggestion(SDKMessage.PromptSuggestionData(suggestions: ["s"])),
            .toolUseSummary(SDKMessage.ToolUseSummaryData(toolUseCount: 1, tools: ["T"])),
        ]

        XCTAssertEqual(messages.count, 18, "Should test all 18 SDKMessage cases")

        for message in messages {
            let event = EventMapper.map(message)
            XCTAssertNotEqual(event.type, AgentEventType.unknown, "EventMapper should map all 18 SDKMessage cases to a known type")
            XCTAssertFalse(event.content.isEmpty, "Each mapped event should have non-empty content")
        }
    }
}
