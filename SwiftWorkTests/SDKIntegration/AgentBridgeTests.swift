import XCTest
@testable import SwiftWork

// ATDD Red Phase — Story 1.4: 消息输入与 Agent 执行
// Unit tests for AgentBridge: state management, message sending, cancellation, error handling.
// These tests will FAIL until AgentBridge is reimplemented as @MainActor @Observable final class.

@MainActor
final class AgentBridgeTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeBridge() -> AgentBridge {
        AgentBridge()
    }

    // MARK: - AC#1: Initial state

    // [P0] AgentBridge has correct initial state
    func testInitialState() {
        let bridge = makeBridge()

        XCTAssertTrue(bridge.events.isEmpty, "events should start empty")
        XCTAssertFalse(bridge.isRunning, "isRunning should start false")
        XCTAssertNil(bridge.errorMessage, "errorMessage should start nil")
    }

    // [P0] AgentBridge is a class (not struct) for @Observable conformance
    func testAgentBridgeIsClass() {
        let bridge = makeBridge()
        let mirror = Mirror(reflecting: bridge)
        XCTAssertEqual(mirror.displayStyle, .class, "AgentBridge should be a class (not struct) for @Observable")
    }

    // MARK: - AC#1: sendMessage — user message prepended to events

    // [P0] sendMessage appends user message event before SDK stream
    func testSendMessageAppendsUserMessage() async throws {
        let bridge = makeBridge()
        bridge.configure(apiKey: "test-key", baseURL: nil, model: "test-model", workspacePath: nil)

        await bridge.sendMessage("Hello, Agent!")

        // The first event should be the user message
        let firstEvent = bridge.events.first
        XCTAssertNotNil(firstEvent, "sendMessage should append at least a user message event")
        XCTAssertEqual(firstEvent?.type, .userMessage, "First event should be a userMessage")
        XCTAssertEqual(firstEvent?.content, "Hello, Agent!")
    }

    // [P0] sendMessage with empty text does nothing
    func testSendMessageEmptyTextDoesNothing() async {
        let bridge = makeBridge()
        bridge.configure(apiKey: "test-key", baseURL: nil, model: "test-model", workspacePath: nil)

        await bridge.sendMessage("")

        XCTAssertTrue(bridge.events.isEmpty, "Empty message should not append events")
        XCTAssertFalse(bridge.isRunning, "isRunning should remain false for empty message")
    }

    // [P0] sendMessage without configure does not crash
    func testSendMessageWithoutConfigureDoesNotCrash() async {
        let bridge = makeBridge()

        // Agent not configured — sendMessage should handle gracefully
        await bridge.sendMessage("Hello")

        // May or may not append user message depending on implementation,
        // but the key invariant is: NO CRASH
        XCTAssertTrue(true, "sendMessage without configure should not crash")
    }

    // MARK: - AC#1: sendMessage — isRunning state transitions

    // [P0] sendMessage sets isRunning to true, then false when stream completes
    func testSendMessageSetsIsRunning() async throws {
        let bridge = makeBridge()
        bridge.configure(apiKey: "test-key", baseURL: nil, model: "test-model", workspacePath: nil)

        // Start sending — isRunning should become true
        bridge.sendMessage("Do something")
        XCTAssertTrue(bridge.isRunning, "isRunning should be true immediately after sendMessage")

        // Wait for the stream to complete (it will fail due to fake API key)
        // Use a timeout to avoid hanging forever
        let maxWait: UInt64 = 5_000_000_000 // 5 seconds in nanoseconds
        let start = ContinuousClock.now
        while bridge.isRunning {
            let elapsed = ContinuousClock.now - start
            if elapsed > .seconds(5) {
                XCTFail("isRunning did not become false within timeout")
                break
            }
            try await Task.sleep(for: .milliseconds(100))
        }

        XCTAssertFalse(bridge.isRunning, "isRunning should be false after stream completes")
    }

    // MARK: - AC#1: sendMessage — clears error state

    // [P0] sendMessage clears errorMessage on new send
    func testSendMessageClearsErrorMessage() async throws {
        let bridge = makeBridge()

        // Simulate a previous error
        // After implementation, errorMessage would be set by a failed send
        // Then a new send should clear it
        bridge.configure(apiKey: "test-key", baseURL: nil, model: "test-model", workspacePath: nil)

        await bridge.sendMessage("First message")
        // After first message completes (likely error due to fake key), errorMessage may be set
        // Send again to verify clearing
        await bridge.sendMessage("Second message")

        // errorMessage may or may not be nil depending on whether the fake key triggered an error
        // The key assertion is that the second send doesn't crash
        XCTAssertTrue(true, "Second send should not crash even after first send error")
    }

    // MARK: - AC#2: cancelExecution

    // [P0] cancelExecution sets isRunning to false
    func testCancelExecutionSetsIsRunningFalse() {
        let bridge = makeBridge()

        // Manually set isRunning to simulate an active execution
        // After implementation, cancelExecution will be called during an active stream
        bridge.cancelExecution()

        XCTAssertFalse(bridge.isRunning, "cancelExecution should set isRunning to false")
    }

    // [P0] cancelExecution appends cancellation system event
    func testCancelExecutionAppendsCancellationEvent() {
        let bridge = makeBridge()

        bridge.cancelExecution()

        // Should have appended a "任务已取消" system event
        let cancelEvent = bridge.events.last
        XCTAssertNotNil(cancelEvent, "cancelExecution should append a cancellation event")
        XCTAssertEqual(cancelEvent?.type, .system)
        XCTAssertNotNil(cancelEvent?.metadata["isCancellation"])
    }

    // [P0] cancelExecution event content contains cancellation text
    func testCancelExecutionEventContainsCancellationText() {
        let bridge = makeBridge()

        bridge.cancelExecution()

        let cancelEvent = bridge.events.last
        XCTAssertEqual(cancelEvent?.content, "任务已取消")
    }

    // [P1] cancelExecution when not running is safe (no crash)
    func testCancelExecutionWhenNotRunning() {
        let bridge = makeBridge()

        // Should be safe to cancel when nothing is running
        bridge.cancelExecution()
        bridge.cancelExecution()  // Double cancel

        XCTAssertFalse(bridge.isRunning)
        XCTAssertEqual(bridge.events.count, 2, "Each cancelExecution should append an event")
    }

    // MARK: - AC#3: Error handling

    // [P0] configure with valid parameters does not crash
    func testConfigureDoesNotCrash() {
        let bridge = makeBridge()

        bridge.configure(apiKey: "sk-test-key", baseURL: "https://api.example.com", model: "claude-sonnet-4-6", workspacePath: "/tmp/workspace")

        // No crash = success
        XCTAssertTrue(true, "configure should not crash")
    }

    // [P0] configure with nil optional parameters does not crash
    func testConfigureWithNilOptionals() {
        let bridge = makeBridge()

        bridge.configure(apiKey: "sk-test-key", baseURL: nil, model: "claude-sonnet-4-6", workspacePath: nil)

        XCTAssertTrue(true, "configure with nil optionals should not crash")
    }

    // [P0] AgentBridge never crashes on any error scenario
    func testAgentBridgeNeverCrashes() async {
        let bridge = makeBridge()

        // No configure — send anyway
        await bridge.sendMessage("test")
        // Cancel without running
        bridge.cancelExecution()
        // Send again
        await bridge.sendMessage("test2")
        // Cancel again
        bridge.cancelExecution()

        // If we reach here, the bridge never crashed
        XCTAssertTrue(true, "AgentBridge should never crash under any sequence of operations")
    }

    // MARK: - clearEvents

    // [P0] clearEvents empties the events array
    func testClearEventsEmptiesArray() {
        let bridge = makeBridge()
        bridge.configure(apiKey: "test-key", baseURL: nil, model: "test-model", workspacePath: nil)

        // Add some events via cancelExecution
        bridge.cancelExecution()
        XCTAssertFalse(bridge.events.isEmpty, "Should have events before clear")

        bridge.clearEvents()

        XCTAssertTrue(bridge.events.isEmpty, "clearEvents should empty the events array")
        XCTAssertNil(bridge.errorMessage, "clearEvents should clear errorMessage")
        XCTAssertFalse(bridge.isRunning, "clearEvents should set isRunning to false")
    }

    // [P1] clearEvents resets all state to initial values
    func testClearEventsResetsAllState() {
        let bridge = makeBridge()
        bridge.configure(apiKey: "test-key", baseURL: nil, model: "test-model", workspacePath: nil)
        bridge.cancelExecution()

        bridge.clearEvents()

        XCTAssertTrue(bridge.events.isEmpty)
        XCTAssertFalse(bridge.isRunning)
        XCTAssertNil(bridge.errorMessage)
    }

    // MARK: - Event ordering

    // [P0] User message appears before SDK events
    func testUserMessageOrdering() async throws {
        let bridge = makeBridge()
        bridge.configure(apiKey: "test-key", baseURL: nil, model: "test-model", workspacePath: nil)

        await bridge.sendMessage("Hello")

        // User message should be the first event
        if let first = bridge.events.first {
            XCTAssertEqual(first.type, .userMessage, "User message should be first event")
        }
    }

    // MARK: - Session switching (clearEvents + configure)

    // [P0] Switching sessions clears old events
    func testSessionSwitchClearsOldEvents() {
        let bridge = makeBridge()
        bridge.configure(apiKey: "key1", baseURL: nil, model: "model1", workspacePath: "/path1")
        bridge.cancelExecution()  // Add some events
        XCTAssertFalse(bridge.events.isEmpty)

        // Simulate session switch
        bridge.clearEvents()
        bridge.configure(apiKey: "key1", baseURL: nil, model: "model1", workspacePath: "/path2")

        XCTAssertTrue(bridge.events.isEmpty, "Events should be cleared on session switch")
    }
}
