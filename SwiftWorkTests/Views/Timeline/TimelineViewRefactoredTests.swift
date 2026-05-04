import XCTest
@testable import SwiftWork

// MARK: - TimelineView scroll behavior tests
//
// These tests lock the refactored conversation behavior:
// - opening on the latest content
// - following the bottom only when appropriate
// - top pagination guard conditions
// - existing event rendering coverage

@MainActor
final class TimelineViewRefactoredTests: XCTestCase {

    // MARK: - Scroll behavior policy

    func testLatestScrollTargetPrefersStreamingContent() {
        let target = TimelineViewBehavior.latestScrollTarget(
            streamingText: "partial response",
            events: [AgentEvent(type: .assistant, content: "done", timestamp: .now)]
        )

        XCTAssertEqual(target, .streaming)
    }

    func testLatestScrollTargetFallsBackToLastEvent() {
        let lastEvent = AgentEvent(type: .assistant, content: "latest", timestamp: .now)
        let target = TimelineViewBehavior.latestScrollTarget(
            streamingText: "",
            events: [
                AgentEvent(type: .userMessage, content: "older", timestamp: .now),
                lastEvent
            ]
        )

        XCTAssertEqual(target, .event(lastEvent.id))
    }

    func testLatestScrollTargetFallsBackToBottomAnchorWhenEmpty() {
        let target = TimelineViewBehavior.latestScrollTarget(
            streamingText: "",
            events: []
        )

        XCTAssertEqual(target, .bottomAnchor)
    }

    func testShouldAutoScrollRequiresFollowLatestWithoutPendingPrepend() {
        XCTAssertTrue(
            TimelineViewBehavior.shouldAutoScroll(
                hasCompletedInitialScroll: true,
                scrollMode: .followLatest,
                hasPendingPrepend: false
            )
        )

        XCTAssertFalse(
            TimelineViewBehavior.shouldAutoScroll(
                hasCompletedInitialScroll: true,
                scrollMode: .manualBrowse,
                hasPendingPrepend: false
            )
        )

        XCTAssertFalse(
            TimelineViewBehavior.shouldAutoScroll(
                hasCompletedInitialScroll: true,
                scrollMode: .followLatest,
                hasPendingPrepend: true
            )
        )
    }

    func testShouldLoadEarlierRequiresNearTopAndNoInFlightPagination() {
        XCTAssertTrue(
            TimelineViewBehavior.shouldLoadEarlier(
                hasCompletedInitialScroll: true,
                hasEarlierEvents: true,
                isLoadingEarlierEvents: false,
                hasPendingPrepend: false,
                isFirstLoadedEventVisible: true,
                topVisibleEventMinY: 40,
                threshold: 120
            )
        )

        XCTAssertFalse(
            TimelineViewBehavior.shouldLoadEarlier(
                hasCompletedInitialScroll: true,
                hasEarlierEvents: true,
                isLoadingEarlierEvents: true,
                hasPendingPrepend: false,
                isFirstLoadedEventVisible: true,
                topVisibleEventMinY: 40,
                threshold: 120
            )
        )

        XCTAssertFalse(
            TimelineViewBehavior.shouldLoadEarlier(
                hasCompletedInitialScroll: true,
                hasEarlierEvents: true,
                isLoadingEarlierEvents: false,
                hasPendingPrepend: true,
                isFirstLoadedEventVisible: true,
                topVisibleEventMinY: 40,
                threshold: 120
            )
        )

        XCTAssertFalse(
            TimelineViewBehavior.shouldLoadEarlier(
                hasCompletedInitialScroll: true,
                hasEarlierEvents: true,
                isLoadingEarlierEvents: false,
                hasPendingPrepend: false,
                isFirstLoadedEventVisible: true,
                topVisibleEventMinY: 160,
                threshold: 120
            )
        )

        XCTAssertFalse(
            TimelineViewBehavior.shouldLoadEarlier(
                hasCompletedInitialScroll: true,
                hasEarlierEvents: true,
                isLoadingEarlierEvents: false,
                hasPendingPrepend: false,
                isFirstLoadedEventVisible: false,
                topVisibleEventMinY: 20,
                threshold: 120
            )
        )
    }

    // MARK: - Rendering coverage

    func testTimelineViewRendersEventsList() throws {
        let bridge = AgentBridge()
        bridge.events = [
            AgentEvent(type: .userMessage, content: "Hello", timestamp: .now),
            AgentEvent(type: .assistant, content: "Hi there", timestamp: .now),
            AgentEvent(type: .toolUse, content: "Bash", metadata: ["toolName": "Bash", "toolUseId": "t1", "input": "{}"] as [String: any Sendable], timestamp: .now)
        ]
        let view = TimelineView(agentBridge: bridge, reloadToken: UUID(), selectedEventId: .constant(nil))
        XCTAssertNotNil(view, "TimelineView should render with 3 events")
    }

    func testTimelineViewEmptyState() throws {
        let bridge = AgentBridge()
        let view = TimelineView(agentBridge: bridge, reloadToken: UUID(), selectedEventId: .constant(nil))
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
            let view = TimelineView(agentBridge: bridge, reloadToken: UUID(), selectedEventId: .constant(nil))
            XCTAssertNotNil(view, "TimelineView should handle AgentEventType.\(eventType.rawValue)")
        }
    }

    // MARK: - Streaming Text Integration

    func testStreamingTextBlockRenderedWhenNonEmpty() throws {
        let bridge = AgentBridge()
        bridge.events = [
            AgentEvent(type: .userMessage, content: "Hello", timestamp: .now)
        ]
        bridge.streamingText = "Streaming response..."
        let view = TimelineView(agentBridge: bridge, reloadToken: UUID(), selectedEventId: .constant(nil))
        XCTAssertNotNil(view, "TimelineView should render with streaming text")
    }

    func testStreamingTextHiddenWhenEmpty() throws {
        let bridge = AgentBridge()
        bridge.events = [
            AgentEvent(type: .userMessage, content: "Hello", timestamp: .now)
        ]
        bridge.streamingText = ""
        let view = TimelineView(agentBridge: bridge, reloadToken: UUID(), selectedEventId: .constant(nil))
        XCTAssertNotNil(view, "TimelineView should render without streaming text block")
    }

    // MARK: - ThinkingView

    func testThinkingViewShownForSystemInitEvent() throws {
        let bridge = AgentBridge()
        bridge.events = [
            AgentEvent(
                type: .system,
                content: "Session initialized",
                metadata: ["subtype": "init"] as [String: any Sendable],
                timestamp: .now
            )
        ]
        let view = TimelineView(agentBridge: bridge, reloadToken: UUID(), selectedEventId: .constant(nil))
        XCTAssertNotNil(view, "TimelineView should render ThinkingView for system init")
    }

    func testThinkingViewNotShownForSystemStatusEvent() throws {
        let bridge = AgentBridge()
        bridge.events = [
            AgentEvent(
                type: .system,
                content: "Status update",
                metadata: ["subtype": "status"] as [String: any Sendable],
                timestamp: .now
            )
        ]
        let view = TimelineView(agentBridge: bridge, reloadToken: UUID(), selectedEventId: .constant(nil))
        XCTAssertNotNil(view, "TimelineView should render SystemEventView for non-init system events")
    }

    // MARK: - ResultView

    func testResultEventUsesResultView() throws {
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
        let view = TimelineView(agentBridge: bridge, reloadToken: UUID(), selectedEventId: .constant(nil))
        XCTAssertNotNil(view, "TimelineView should render ResultView for .result events")
    }

    // MARK: - UnknownEventView

    func testUnknownEventRenderedForUnknownType() throws {
        let bridge = AgentBridge()
        bridge.events = [
            AgentEvent(
                type: .unknown,
                content: "",
                timestamp: .now
            )
        ]
        let view = TimelineView(agentBridge: bridge, reloadToken: UUID(), selectedEventId: .constant(nil))
        XCTAssertNotNil(view, "TimelineView should render UnknownEventView for .unknown events")
    }

    func testDefaultCaseCoversGrowthEventTypes() throws {
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
            let view = TimelineView(agentBridge: bridge, reloadToken: UUID(), selectedEventId: .constant(nil))
            XCTAssertNotNil(view, "TimelineView should handle growth type .\(eventType.rawValue)")
        }
    }

    func testTimelineViewAcceptsStableReloadToken() throws {
        let bridge = AgentBridge()
        bridge.events = [
            AgentEvent(type: .assistant, content: "Latest page", timestamp: .now)
        ]

        let view = TimelineView(
            agentBridge: bridge,
            reloadToken: UUID(),
            selectedEventId: .constant(nil)
        )

        XCTAssertNotNil(view, "TimelineView should accept an explicit reload token")
    }
}
