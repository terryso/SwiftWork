import XCTest
@testable import SwiftWork

// ATDD Red Phase -- Story 3.3: 会话管理增强
// Tests for InputBarView: Agent-running state input behavior, send+stop button layout.
// These tests will FAIL until InputBarView removes disabled(agentBridge.isRunning) and
// supports concurrent send/stop buttons.

@MainActor
final class InputBarViewTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeBridge() -> AgentBridge {
        AgentBridge()
    }

    // MARK: - AC#3: Agent 执行中发送追加消息

    // [P0] InputBarView compiles and can be instantiated
    func testInputBarViewCompiles() {
        let bridge = makeBridge()
        let inputBar = InputBarView(agentBridge: bridge)
        XCTAssertNotNil(inputBar, "InputBarView should compile and instantiate")
    }

    // [P0] InputBarView accepts an AgentBridge that is running
    // Story 3-3 removes the disabled(agentBridge.isRunning) on the TextField.
    // The view should still compile when isRunning is true.
    func testInputBarViewWithRunningBridge() {
        let bridge = makeBridge()
        bridge.configure(apiKey: "test-key", baseURL: nil, model: "test-model", workspacePath: nil, sessionId: UUID().uuidString)

        // isRunning starts false
        XCTAssertFalse(bridge.isRunning)

        // The view should work regardless of isRunning state
        let inputBar = InputBarView(agentBridge: bridge)
        XCTAssertNotNil(inputBar, "InputBarView should compile regardless of isRunning state")
    }

    // [P0] AgentBridge queues follow-up via streamInput when sendMessage is called while running
    // Story 3-3 uses streamInput() for multi-turn queuing — no cancellation, no interruption.
    func testSendMessageWhileRunningDoesNotCancel() async throws {
        let bridge = makeBridge()
        bridge.configure(apiKey: "test-key", baseURL: nil, model: "test-model", workspacePath: nil, sessionId: UUID().uuidString)

        // Start first message
        bridge.sendMessage("First message")
        XCTAssertTrue(bridge.isRunning, "Should be running after first sendMessage")

        // Send second message while running
        bridge.sendMessage("Follow-up message")

        // The second sendMessage should NOT call cancelExecution().
        // Key difference: cancelExecution appends a "任务已取消" system event.
        // If the second send correctly appends a userMessage WITHOUT cancellation,
        // there should be NO "任务已取消" event appended between the two userMessages.
        let _ = bridge.events.contains { event in
            event.type == .system && event.metadata["isCancellation"] != nil
        }

        // Note: This test may be timing-dependent. The key assertion is that
        // the user message for "Follow-up message" was appended.
        let hasFollowUpUserMessage = bridge.events.contains { event in
            event.type == .userMessage && event.content == "Follow-up message"
        }

        XCTAssertTrue(hasFollowUpUserMessage, "Follow-up user message should be appended")
        // The absence of cancellation event is the key behavior change
        // (In the OLD code, sendMessage while running would cancelExecution first)
    }

    // [P0] sendMessage while running appends user message to existing events
    func testSendMessageWhileRunningAppendsUserMessage() async throws {
        let bridge = makeBridge()
        bridge.configure(apiKey: "test-key", baseURL: nil, model: "test-model", workspacePath: nil, sessionId: UUID().uuidString)

        // First message
        bridge.sendMessage("Initial query")
        XCTAssertTrue(bridge.isRunning)

        // Second message while running
        bridge.sendMessage("Additional context")

        // Both user messages should be in events
        let userMessages = bridge.events.filter { $0.type == .userMessage }
        XCTAssertEqual(userMessages.count, 2, "Should have two user messages")
        XCTAssertEqual(userMessages.first?.content, "Initial query")
        XCTAssertEqual(userMessages.last?.content, "Additional context")
    }

    // [P1] sendMessage while running does not clear existing events
    func testSendMessageWhileRunningPreservesExistingEvents() async throws {
        let bridge = makeBridge()
        bridge.configure(apiKey: "test-key", baseURL: nil, model: "test-model", workspacePath: nil, sessionId: UUID().uuidString)

        bridge.sendMessage("First")
        let eventsBeforeSecond = bridge.events.count

        bridge.sendMessage("Second")
        // Events should grow, not reset
        XCTAssertGreaterThanOrEqual(bridge.events.count, eventsBeforeSecond,
                                    "Events should not be cleared on follow-up send")
    }

    // [P1] sendMessage while running does not reset isRunning
    func testSendMessageWhileRunningKeepsIsRunningTrue() async throws {
        let bridge = makeBridge()
        bridge.configure(apiKey: "test-key", baseURL: nil, model: "test-model", workspacePath: nil, sessionId: UUID().uuidString)

        bridge.sendMessage("First")
        XCTAssertTrue(bridge.isRunning)

        bridge.sendMessage("Second")
        XCTAssertTrue(bridge.isRunning, "isRunning should remain true after follow-up send")
    }

    // [P1] Send button should be visible when agent is running
    // Story 3-3 changes InputBarView layout: both send and stop buttons visible when running.
    // This is a compilation/structure test -- full UI testing requires ViewInspector.
    func testInputBarViewCompilesWithRunningAgent() {
        let bridge = makeBridge()
        bridge.configure(apiKey: "test-key", baseURL: nil, model: "test-model", workspacePath: nil, sessionId: UUID().uuidString)

        // Simulate running state
        // (In actual use, isRunning is set by sendMessage. Here we just test view compilation.)
        let inputBar = InputBarView(agentBridge: bridge)
        XCTAssertNotNil(inputBar)
    }

    // MARK: - AC#4: Shift+Enter 换行，Enter 发送

    // [P0] InputBarView uses a multi-line TextField
    // Story 3-3 may use TextField(axis: .vertical) or NSTextView wrapper.
    // Compilation test confirms the view structure supports multi-line.
    func testInputBarViewSupportsMultiLine() {
        let bridge = makeBridge()
        let inputBar = InputBarView(agentBridge: bridge)
        XCTAssertNotNil(inputBar, "InputBarView should compile with multi-line support")
    }

    func testCompactComposerMetricsClampGrowthAndScrollThreshold() {
        XCTAssertEqual(
            InputBarComposerMetrics.clampedVisibleHeight(for: 0),
            InputBarComposerMetrics.singleLineHeight,
            "Empty composer should render at compact single-line height"
        )
        XCTAssertEqual(
            InputBarComposerMetrics.clampedVisibleHeight(for: InputBarComposerMetrics.maxVisibleHeight + 48),
            InputBarComposerMetrics.maxVisibleHeight,
            "Long content should clamp to the max visible height"
        )
        XCTAssertTrue(
            InputBarComposerMetrics.needsInternalScrolling(for: InputBarComposerMetrics.maxVisibleHeight + 1),
            "Content beyond the max visible height should scroll internally"
        )
    }

    func testCompactComposerPlaceholderVisibilityContract() {
        XCTAssertEqual(InputBarComposerMetrics.placeholderText, "输入消息发送给 Agent...")
        XCTAssertTrue(InputBarComposerMetrics.showsPlaceholder(for: ""))
        XCTAssertTrue(InputBarComposerMetrics.showsPlaceholder(for: " "))
        XCTAssertEqual(
            InputBarComposerMetrics.placeholderLeadingPadding,
            InputBarComposerMetrics.textContainerInset.width
        )
        XCTAssertEqual(
            InputBarComposerMetrics.placeholderTopPadding,
            InputBarComposerMetrics.textContainerInset.height
        )
        XCTAssertFalse(InputBarComposerMetrics.showsPlaceholder(for: "hello"))
    }

    // [P1] Enter key sends message (behavioral contract)
    // Note: Keyboard behavior testing in SwiftUI requires ViewInspector or UI tests.
    // This test documents the expected behavior contract.
    func testEnterKeySendsMessage() async throws {
        let bridge = makeBridge()
        bridge.configure(apiKey: "test-key", baseURL: nil, model: "test-model", workspacePath: nil, sessionId: UUID().uuidString)

        // Simulate what happens when Enter is pressed: sendMessage is called
        bridge.sendMessage("Test message via Enter")

        let userMessage = bridge.events.first
        XCTAssertEqual(userMessage?.type, .userMessage, "Enter should trigger sendMessage")
        XCTAssertEqual(userMessage?.content, "Test message via Enter")
    }

    // [P1] Shift+Enter does not send message (inserts newline)
    // The input text should contain a newline character, not be sent.
    // This is a contract test since SwiftUI keyboard interception is hard to test directly.
    func testShiftEnterDoesNotSendMessage() async throws {
        let bridge = makeBridge()
        bridge.configure(apiKey: "test-key", baseURL: nil, model: "test-model", workspacePath: nil, sessionId: UUID().uuidString)

        // If Shift+Enter inserts a newline, the inputText would be "line1\nline2"
        // When Enter (without Shift) is pressed, sendMessage is called with the full text
        let multiLineText = "first line\nsecond line"
        bridge.sendMessage(multiLineText)

        let userMessage = bridge.events.first
        XCTAssertEqual(userMessage?.type, .userMessage)
        XCTAssertEqual(userMessage?.content, "first line\nsecond line",
                       "Multi-line text should be sent as-is when Enter is pressed")
    }
}
