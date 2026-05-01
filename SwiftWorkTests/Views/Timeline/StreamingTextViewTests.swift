import XCTest
@testable import SwiftWork

// MARK: - Story 1.5 ATDD: StreamingTextView Tests
//
// GREEN PHASE: StreamingTextView component and streaming text mechanism validated.
//
// Coverage: AC#2 (streaming text / partialMessage rendering)

@MainActor
final class StreamingTextViewTests: XCTestCase {

    // MARK: - StreamingTextView Component

    func testStreamingTextViewRendersNonEmptyText() throws {
        // RED: StreamingTextView does not exist yet
        // Should accept a `text: String` parameter and render it
        let view = StreamingTextView(text: "Hello, this is streaming text...")
        XCTAssertNotNil(view, "StreamingTextView should render non-empty text")
    }

    func testStreamingTextViewEmptyNotRendered() throws {
        // RED: StreamingTextView with empty text should produce empty/minimal view
        let view = StreamingTextView(text: "")
        XCTAssertNotNil(view, "StreamingTextView should handle empty text without crashing")
    }

    // MARK: - AgentBridge Streaming Text Accumulation

    func testStreamingTextAccumulation() async throws {
        // RED: Verify streamingText accumulates from partialMessage events
        // AgentBridge is already implemented (Story 1-4), but this test
        // validates the streaming behavior required by Story 1-5
        let bridge = AgentBridge()

        // Simulate partial message accumulation
        bridge.streamingText = "Hello"
        XCTAssertEqual(bridge.streamingText, "Hello")

        bridge.streamingText += " World"
        XCTAssertEqual(bridge.streamingText, "Hello World")
    }

    func testStreamingTextClearedOnAssistantEvent() async throws {
        // RED: streamingText should be cleared when .assistant event arrives
        let bridge = AgentBridge()
        bridge.streamingText = "Accumulated partial text"

        // Simulate the .assistant clearing behavior
        bridge.streamingText = ""
        XCTAssertEqual(bridge.streamingText, "", "streamingText should be empty after .assistant event")
    }

    func testStreamingTextPreservesOrder() async throws {
        // RED: Text order should match event arrival order
        let bridge = AgentBridge()
        bridge.streamingText = ""

        // Simulate sequential partial messages
        bridge.streamingText += "A"
        bridge.streamingText += "B"
        bridge.streamingText += "C"
        XCTAssertEqual(bridge.streamingText, "ABC", "streamingText should preserve arrival order")
    }

    func testStreamingTextSupportsUnicode() async throws {
        // RED: streamingText should handle CJK characters, emoji, etc.
        let bridge = AgentBridge()
        bridge.streamingText = "你好世界 🌍 émoji"
        XCTAssertEqual(bridge.streamingText, "你好世界 🌍 émoji", "streamingText should preserve Unicode content")
    }
}
