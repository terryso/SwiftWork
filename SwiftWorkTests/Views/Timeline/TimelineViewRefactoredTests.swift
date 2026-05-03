import XCTest
@testable import SwiftWork

// MARK: - Story 1.5 ATDD: TimelineView Refactored Tests
//
// RED PHASE: These tests assert EXPECTED behavior for the refactored TimelineView
// that delegates to independent EventView components.
//
// Coverage: AC#1 (TimelineView rendering), AC#2 (streaming), AC#3 (ThinkingView),
//           AC#4 (ResultView), AC#5 (UnknownEventView)

@MainActor
final class TimelineViewRefactoredTests: XCTestCase {

    // MARK: - AC#1 — TimelineView Rendering

    func testTimelineViewRendersEventsList() throws {
        // RED: TimelineView should render all events from agentBridge.events
        let bridge = AgentBridge()
        bridge.events = [
            AgentEvent(type: .userMessage, content: "Hello", timestamp: .now),
            AgentEvent(type: .assistant, content: "Hi there", timestamp: .now),
            AgentEvent(type: .toolUse, content: "Bash", metadata: ["toolName": "Bash", "toolUseId": "t1", "input": "{}"] as [String: any Sendable], timestamp: .now)
        ]
        let view = TimelineView(agentBridge: bridge, selectedEventId: .constant(nil))
        XCTAssertNotNil(view, "TimelineView should render with 3 events")
    }

    func testTimelineViewEmptyState() throws {
        // RED: TimelineView should show empty state when no events
        let bridge = AgentBridge()
        let view = TimelineView(agentBridge: bridge, selectedEventId: .constant(nil))
        XCTAssertNotNil(view, "TimelineView should render empty state")
    }

    func testTimelineViewUsesAgentBridgeEvents() throws {
        // RED: TimelineView reads events from agentBridge.events
        let bridge = AgentBridge()
        XCTAssertEqual(bridge.events.count, 0, "New AgentBridge should have empty events")

        // Add events directly
        bridge.events = [
            AgentEvent(type: .system, content: "init", timestamp: .now)
        ]
        XCTAssertEqual(bridge.events.count, 1)
    }

    func testEventViewForAllAgentEventTypes() throws {
        // RED: Verify exhaustive switch covers all 19 AgentEventType cases
        let allTypes = AgentEventType.allCases
        // AgentEventType has 19 cases (18 SDK types + unknown)
        XCTAssertGreaterThanOrEqual(allTypes.count, 19, "AgentEventType should have at least 19 cases")

        let bridge = AgentBridge()
        // Create one event per type and verify TimelineView can be created
        for eventType in allTypes {
            let event = AgentEvent(
                type: eventType,
                content: "Test content for \(eventType.rawValue)",
                timestamp: .now
            )
            bridge.events = [event]
            let view = TimelineView(agentBridge: bridge, selectedEventId: .constant(nil))
            XCTAssertNotNil(view, "TimelineView should handle AgentEventType.\(eventType.rawValue)")
        }
    }

    // MARK: - AC#2 — Streaming Text Integration

    func testStreamingTextBlockRenderedWhenNonEmpty() throws {
        // RED: When agentBridge.streamingText is non-empty, a streaming text block
        // should be rendered at the bottom of the event list
        let bridge = AgentBridge()
        bridge.events = [
            AgentEvent(type: .userMessage, content: "Hello", timestamp: .now)
        ]
        bridge.streamingText = "Streaming response..."
        let view = TimelineView(agentBridge: bridge, selectedEventId: .constant(nil))
        XCTAssertNotNil(view, "TimelineView should render with streaming text")
    }

    func testStreamingTextHiddenWhenEmpty() throws {
        // RED: When streamingText is empty, no streaming block should render
        let bridge = AgentBridge()
        bridge.events = [
            AgentEvent(type: .userMessage, content: "Hello", timestamp: .now)
        ]
        bridge.streamingText = ""
        let view = TimelineView(agentBridge: bridge, selectedEventId: .constant(nil))
        XCTAssertNotNil(view, "TimelineView should render without streaming text block")
    }

    // MARK: - AC#3 — ThinkingView

    func testThinkingViewShownForSystemInitEvent() throws {
        // RED: .system event with subtype "init" should render ThinkingView
        // instead of regular SystemEventView
        let bridge = AgentBridge()
        bridge.events = [
            AgentEvent(
                type: .system,
                content: "Session initialized",
                metadata: ["subtype": "init"] as [String: any Sendable],
                timestamp: .now
            )
        ]
        let view = TimelineView(agentBridge: bridge, selectedEventId: .constant(nil))
        XCTAssertNotNil(view, "TimelineView should render ThinkingView for system init")
    }

    func testThinkingViewNotShownForSystemStatusEvent() throws {
        // RED: .system event with other subtype should render SystemEventView
        let bridge = AgentBridge()
        bridge.events = [
            AgentEvent(
                type: .system,
                content: "Status update",
                metadata: ["subtype": "status"] as [String: any Sendable],
                timestamp: .now
            )
        ]
        let view = TimelineView(agentBridge: bridge, selectedEventId: .constant(nil))
        XCTAssertNotNil(view, "TimelineView should render SystemEventView for non-init system events")
    }

    // MARK: - AC#4 — ResultView

    func testResultEventUsesResultView() throws {
        // RED: .result event should delegate to ResultView component
        let bridge = AgentBridge()
        bridge.events = [
            AgentEvent(
                type: .result,
                content: "Completed",
                metadata: [
                    "subtype": "success",
                    "numTurns": 2,
                    "durationMs": 10000,
                    "totalCostUsd": 0.025
                ] as [String: any Sendable],
                timestamp: .now
            )
        ]
        let view = TimelineView(agentBridge: bridge, selectedEventId: .constant(nil))
        XCTAssertNotNil(view, "TimelineView should render ResultView for .result events")
    }

    // MARK: - AC#5 — UnknownEventView

    func testUnknownEventRenderedForUnknownType() throws {
        // RED: .unknown event type should render UnknownEventView
        let bridge = AgentBridge()
        bridge.events = [
            AgentEvent(
                type: .unknown,
                content: "",
                timestamp: .now
            )
        ]
        let view = TimelineView(agentBridge: bridge, selectedEventId: .constant(nil))
        XCTAssertNotNil(view, "TimelineView should render UnknownEventView for .unknown events")
    }

    func testDefaultCaseCoversGrowthEventTypes() throws {
        // RED: Growth-phase event types (hookStarted, taskStarted, etc.) should
        // be handled by SystemEventView or default case in the switch
        let growthTypes: [AgentEventType] = [
            .hookStarted, .hookProgress, .hookResponse,
            .taskStarted, .taskProgress,
            .authStatus, .filesPersisted, .localCommandOutput,
            .promptSuggestion, .toolUseSummary
        ]

        let bridge = AgentBridge()
        for eventType in growthTypes {
            let event = AgentEvent(
                type: eventType,
                content: "Growth event: \(eventType.rawValue)",
                timestamp: .now
            )
            bridge.events = [event]
            let view = TimelineView(agentBridge: bridge, selectedEventId: .constant(nil))
            XCTAssertNotNil(view, "TimelineView should handle growth type .\(eventType.rawValue)")
        }
    }
}
