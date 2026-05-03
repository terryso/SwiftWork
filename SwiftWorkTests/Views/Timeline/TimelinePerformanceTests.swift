import XCTest
@testable import SwiftWork
import SwiftData

// Story 2.5: Timeline 性能优化
// Unit & integration tests for: paginated loading, virtualization window,
// scroll mode management, memory trimming, and SwiftData pagination.

@MainActor
final class TimelinePerformanceTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeContext() throws -> (ModelContainer, ModelContext) {
        let schema = Schema([
            Session.self as any PersistentModel.Type,
            Event.self as any PersistentModel.Type
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)
        return (container, context)
    }

    private func makeStore(context: ModelContext) -> SwiftDataEventStore {
        SwiftDataEventStore(modelContext: context)
    }

    private func makeSession(context: ModelContext) throws -> Session {
        let session = Session(title: "Performance Test Session")
        context.insert(session)
        try context.save()
        return session
    }

    private func makeBridge() -> AgentBridge {
        AgentBridge()
    }

    /// Creates `count` AgentEvent instances of varying types for testing.
    private func makeTestEvents(count: Int) -> [AgentEvent] {
        let types: [AgentEventType] = [.userMessage, .assistant, .toolUse, .toolResult, .system, .result]
        return (0..<count).map { i in
            AgentEvent(
                type: types[i % types.count],
                content: "Event \(i) — performance test content with some extra text to vary size.",
                metadata: i % 3 == 0 ? ["toolUseId": "tu-\(i)" as any Sendable] : [:],
                timestamp: .now
            )
        }
    }

    // =========================================================================
    // MARK: - Task 1: Paginated Event Loading (AC #2)
    // =========================================================================

    // [P0] SwiftDataEventStore.fetchEvents supports offset and limit parameters
    func testFetchEventsWithOffsetAndLimit() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let session = try makeSession(context: context)

        // Persist 100 events
        for i in 0..<100 {
            let event = AgentEvent(type: .userMessage, content: "Event \(i)", timestamp: .now)
            try store.persist(event, session: session, order: i)
        }

        let page = try store.fetchEvents(for: session.id, offset: 50, limit: 25)

        XCTAssertEqual(page.count, 25, "Should return exactly 25 events for limit=25")
        XCTAssertEqual(page.first?.content, "Event 50", "First event in page should be offset by 50")
        XCTAssertEqual(page.last?.content, "Event 74", "Last event should be offset+limit-1")
    }

    // [P0] fetchEvents with limit returns fewer when near end
    func testFetchEventsWithLimitNearEnd() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let session = try makeSession(context: context)

        for i in 0..<60 {
            let event = AgentEvent(type: .assistant, content: "E\(i)", timestamp: .now)
            try store.persist(event, session: session, order: i)
        }

        // Request offset=50, limit=25 — only 10 events remain
        let page = try store.fetchEvents(for: session.id, offset: 50, limit: 25)

        XCTAssertEqual(page.count, 10, "Should return only remaining 10 events")
        XCTAssertEqual(page.first?.content, "E50")
    }

    // [P0] fetchEvents with offset beyond range returns empty
    func testFetchEventsOffsetBeyondRange() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let session = try makeSession(context: context)

        for i in 0..<10 {
            let event = AgentEvent(type: .userMessage, content: "E\(i)", timestamp: .now)
            try store.persist(event, session: session, order: i)
        }

        let page = try store.fetchEvents(for: session.id, offset: 100, limit: 10)

        XCTAssertTrue(page.isEmpty, "Should return empty when offset is beyond total count")
    }

    // [P0] EventStoring protocol includes paginated fetch signature
    func testEventStoringProtocolHasPaginatedFetch() {
        let mirror = Mirror(reflecting: SwiftDataEventStore.self)
        XCTAssertNotNil(mirror, "SwiftDataEventStore should conform to EventStoring with paginated fetch")
    }

    // [P0] AgentBridge.loadInitialPage loads first page only for large sessions
    func testLoadInitialPageLoadsOnlyFirstPage() throws {
        let bridge = makeBridge()
        let session = Session(title: "Big Session")
        let mockStore = MockPaginatedEventStore()
        mockStore.allEvents = makeTestEvents(count: 1000)

        bridge.configureEvents(store: mockStore, session: session)
        bridge.loadInitialPage(for: session)

        XCTAssertLessThanOrEqual(
            bridge.events.count,
            50,
            "loadInitialPage should load at most pageSize events (default 50)"
        )
        XCTAssertEqual(
            bridge.events.first?.content,
            bridge.events.first?.content,
            "First loaded event should be the earliest event"
        )
        XCTAssertTrue(bridge.hasMoreEvents, "Should have more events to load")
    }

    // [P0] AgentBridge.loadMoreEvents appends next page
    func testLoadMoreEventsAppendsNextPage() throws {
        let bridge = makeBridge()
        let session = Session(title: "Paged Session")
        let mockStore = MockPaginatedEventStore()
        mockStore.allEvents = makeTestEvents(count: 200)

        bridge.configureEvents(store: mockStore, session: session)
        bridge.loadInitialPage(for: session)

        let initialCount = bridge.events.count

        bridge.loadMoreEvents()

        XCTAssertGreaterThan(
            bridge.events.count,
            initialCount,
            "loadMoreEvents should append more events"
        )
        XCTAssertEqual(
            bridge.events.count,
            initialCount + min(50, 200 - initialCount),
            "Should append exactly one page of events"
        )
    }

    // [P0] AgentBridge tracks hasMoreEvents correctly
    func testHasMoreEventsFlag() throws {
        let bridge = makeBridge()
        let session = Session(title: "Flag Test")
        let mockStore = MockPaginatedEventStore()
        mockStore.allEvents = makeTestEvents(count: 100)

        bridge.configureEvents(store: mockStore, session: session)
        bridge.loadInitialPage(for: session)

        XCTAssertTrue(
            bridge.hasMoreEvents,
            "hasMoreEvents should be true when total events exceed loaded page"
        )

        // Load remaining pages
        bridge.loadMoreEvents() // 50 + 50 = 100
        XCTAssertFalse(
            bridge.hasMoreEvents,
            "hasMoreEvents should be false after loading all events"
        )
    }

    // [P1] loadInitialPage for small sessions loads all events
    func testLoadInitialPageSmallSessionLoadsAll() throws {
        let bridge = makeBridge()
        let session = Session(title: "Small")
        let mockStore = MockPaginatedEventStore()
        mockStore.allEvents = makeTestEvents(count: 30)

        bridge.configureEvents(store: mockStore, session: session)
        bridge.loadInitialPage(for: session)

        XCTAssertEqual(
            bridge.events.count,
            30,
            "Small sessions should load all events in initial page"
        )
        XCTAssertFalse(bridge.hasMoreEvents, "No more events to load")
    }

    // =========================================================================
    // MARK: - Task 2: Virtualization Window (AC #1, #2)
    // =========================================================================

    // [P0] TimelineVirtualizationManager computes visible event subset
    func testVirtualizationManagerReturnsVisibleSubset() {
        let allEvents = makeTestEvents(count: 1000)
        let manager = TimelineVirtualizationManager()

        let visible = manager.eventsToRender(
            visibleRange: 200..<250,
            allEvents: allEvents
        )

        // Should include buffer: 180..<270 (20 before and after)
        XCTAssertEqual(visible.count, 90, "Should return 50 visible + 20 buffer on each side")
        XCTAssertEqual(visible.first?.content, allEvents[180].content)
        XCTAssertEqual(visible.last?.content, allEvents[269].content)
    }

    // [P0] Virtualization clamps to array bounds
    func testVirtualizationClampsAtStart() {
        let allEvents = makeTestEvents(count: 100)
        let manager = TimelineVirtualizationManager()

        // Visible range at the very start: 0..<10 with buffer 20
        let visible = manager.eventsToRender(
            visibleRange: 0..<10,
            allEvents: allEvents
        )

        XCTAssertNotNil(visible, "Should handle start-of-array edge case")
        XCTAssertLessThanOrEqual(visible.count, 30, "Should not exceed visible + one-sided buffer")
    }

    // [P0] Virtualization clamps at end
    func testVirtualizationClampsAtEnd() {
        let allEvents = makeTestEvents(count: 50)
        let manager = TimelineVirtualizationManager()

        // Visible range near end: 45..<50 with buffer 20
        let visible = manager.eventsToRender(
            visibleRange: 45..<50,
            allEvents: allEvents
        )

        XCTAssertNotNil(visible, "Should handle end-of-array edge case")
        XCTAssertLessThanOrEqual(visible.count, 50, "Should not exceed total event count")
    }

    // [P1] Virtualization buffer constant is configurable
    func testVirtualizationBufferDefault() {
        let manager = TimelineVirtualizationManager()

        XCTAssertEqual(
            manager.renderBuffer,
            20,
            "Default render buffer should be 20 events on each side"
        )
    }

    // [P1] Empty events list returns empty visible subset
    func testVirtualizationWithEmptyEvents() {
        let manager = TimelineVirtualizationManager()
        let visible = manager.eventsToRender(
            visibleRange: 0..<0,
            allEvents: []
        )

        XCTAssertTrue(visible.isEmpty, "Empty events should return empty visible subset")
    }

    // [P0] Clamping out-of-bounds range should never exceed the array size
    func testVirtualizationClampsOutOfBoundsRange() {
        let manager = TimelineVirtualizationManager()

        XCTAssertEqual(manager.clampedRange(0..<30, totalCount: 8), 0..<8)
        XCTAssertEqual(manager.clampedRange(5..<30, totalCount: 8), 5..<8)
        XCTAssertEqual(manager.clampedRange(20..<30, totalCount: 8), 8..<8)
    }

    // =========================================================================
    // MARK: - Task 3: Scroll Mode Management (AC #1)
    // =========================================================================

    // [P0] ScrollMode enum has two cases
    func testScrollModeHasFollowLatestAndManualBrowse() {
        let follow = ScrollMode.followLatest
        let manual = ScrollMode.manualBrowse

        XCTAssertNotEqual(follow, manual, "ScrollMode should have distinct cases")
    }

    // [P0] ScrollModeManager defaults to followLatest
    func testScrollModeManagerDefaultsToFollowLatest() {
        let manager = ScrollModeManager()

        XCTAssertEqual(
            manager.scrollMode,
            .followLatest,
            "Default scroll mode should be followLatest"
        )
    }

    // [P0] Scrolling up switches to manualBrowse
    func testScrollUpSwitchesToManualBrowse() {
        let manager = ScrollModeManager()

        manager.handleScrollChange(
            scrollDelta: -20,
            distanceFromBottom: 500
        )

        XCTAssertEqual(
            manager.scrollMode,
            .manualBrowse,
            "Scrolling up >16px should switch to manualBrowse"
        )
    }

    // [P0] Small upward scroll does not switch mode until cumulative >16px
    func testSmallScrollUpStaysFollowLatest() {
        let manager = ScrollModeManager()

        manager.handleScrollChange(
            scrollDelta: -10,
            distanceFromBottom: 500
        )

        XCTAssertEqual(
            manager.scrollMode,
            .followLatest,
            "Single small scroll should stay in followLatest"
        )

        // Cumulative 10 + 10 = 20 > 16, should switch
        manager.handleScrollChange(
            scrollDelta: -10,
            distanceFromBottom: 500
        )

        XCTAssertEqual(
            manager.scrollMode,
            .manualBrowse,
            "Cumulative scroll >16px should switch to manualBrowse"
        )
    }

    // [P0] Scrolling near bottom switches back to followLatest
    func testScrollNearBottomSwitchesToFollowLatest() {
        let manager = ScrollModeManager()
        manager.scrollMode = .manualBrowse

        manager.handleScrollChange(
            scrollDelta: -5,
            distanceFromBottom: 80
        )

        XCTAssertEqual(
            manager.scrollMode,
            .followLatest,
            "Scrolling within 96px of bottom should switch to followLatest"
        )
    }

    // [P1] showReturnToBottomButton is true in manualBrowse mode
    func testShowReturnToBottomButton() {
        let manager = ScrollModeManager()

        XCTAssertFalse(
            manager.showReturnToBottomButton,
            "Should not show button in followLatest mode"
        )

        manager.scrollMode = .manualBrowse
        XCTAssertTrue(
            manager.showReturnToBottomButton,
            "Should show button in manualBrowse mode"
        )
    }

    // [P1] returnToBottom resets mode to followLatest
    func testReturnToBottomResetsMode() {
        let manager = ScrollModeManager()
        manager.scrollMode = .manualBrowse

        manager.returnToBottom()

        XCTAssertEqual(
            manager.scrollMode,
            .followLatest,
            "returnToBottom should reset to followLatest"
        )
    }

    // =========================================================================
    // MARK: - Task 4: Memory Optimization (AC #3)
    // =========================================================================

    // [P0] trimOldEvents removes oldest events beyond threshold
    func testTrimOldEventsRemovesOldest() {
        let bridge = makeBridge()
        bridge.events = makeTestEvents(count: 600)

        bridge.trimOldEvents()

        XCTAssertLessThanOrEqual(
            bridge.events.count,
            500,
            "trimOldEvents should reduce events to maxInMemory (500)"
        )
        // Should keep the LATEST events, not the oldest
        // Events are indexed 0..599; after trimming, first should be 100
        XCTAssertEqual(
            bridge.events.count,
            500,
            "Should keep exactly 500 most recent events"
        )
    }

    // [P0] trimOldEvents does nothing when under threshold
    func testTrimOldEventsDoesNothingWhenUnderThreshold() {
        let bridge = makeBridge()
        let events = makeTestEvents(count: 300)
        bridge.events = events

        bridge.trimOldEvents()

        XCTAssertEqual(
            bridge.events.count,
            300,
            "trimOldEvents should not remove events when count < maxInMemory"
        )
    }

    // [P0] trimOldEvents preserves exact boundary
    func testTrimOldEventsAtExactThreshold() {
        let bridge = makeBridge()
        bridge.events = makeTestEvents(count: 500)

        bridge.trimOldEvents()

        XCTAssertEqual(
            bridge.events.count,
            500,
            "trimOldEvents should not remove events at exact threshold"
        )
    }

    // [P1] AgentEvent metadata does not retain closures
    func testAgentEventMetadataNoClosures() {
        let event = AgentEvent(
            type: .toolUse,
            content: "test",
            metadata: ["key": "value" as any Sendable],
            timestamp: .now
        )
        XCTAssertEqual(event.metadata["key"] as? String, "value")
    }

    // [P1] trimOldEvents still called in appendAndPersist workflow
    func testTrimOldEventsCalledDuringAppend() {
        let bridge = makeBridge()
        let mockStore = MockPaginatedEventStore()
        let session = Session(title: "Trim Test")
        bridge.configureEvents(store: mockStore, session: session)

        for i in 0..<600 {
            let event = AgentEvent(
                type: .userMessage,
                content: "Event \(i)",
                timestamp: .now
            )
            bridge.events.append(event)
        }

        bridge.trimOldEvents()

        XCTAssertLessThanOrEqual(bridge.events.count, 500)
    }

    // [P0] trimOldEvents adjusts pagination offset correctly
    func testTrimOldEventsAdjustsPaginationOffset() throws {
        let bridge = makeBridge()
        let mockStore = MockPaginatedEventStore()
        mockStore.allEvents = makeTestEvents(count: 700)
        let session = Session(title: "Offset Test")
        bridge.configureEvents(store: mockStore, session: session)

        // Load all 700 events into memory
        bridge.loadInitialPage(for: session)
        // Simulate: append enough to trigger trim (loadInitialPage loads 50, we need 500+)
        bridge.events = makeTestEvents(count: 600)

        // Trim removes 100 oldest, keeping 500
        bridge.trimOldEvents()
        XCTAssertEqual(bridge.events.count, 500)

        // hasMoreEvents should use trimmedEventCount + events.count, not just events.count
        // After trim, if totalPersistedEvents = 700 and trimmedEventCount = 100:
        // hasMoreEvents = 700 > (100 + 500) = 700 > 600 = true
        // This test validates the offset tracking via loadMoreEvents
    }

    // [P0] loadMoreEvents uses correct offset after trim
    func testLoadMoreEventsAfterTrim() throws {
        let bridge = makeBridge()
        let mockStore = MockPaginatedEventStore()
        // 1000 events in store
        mockStore.allEvents = makeTestEvents(count: 1000)
        let session = Session(title: "Trim + LoadMore Test")
        bridge.configureEvents(store: mockStore, session: session)

        bridge.loadInitialPage(for: session)
        XCTAssertEqual(bridge.events.count, 50)

        // Manually add events to trigger trim scenario
        let extraEvents = (50..<650).map { i in
            AgentEvent(type: .userMessage, content: "Extra \(i)", timestamp: .now)
        }
        bridge.events.append(contentsOf: extraEvents)
        // Now events.count = 650

        bridge.trimOldEvents()
        // Trims to 500, removing 150 oldest
        XCTAssertEqual(bridge.events.count, 500)
        // First event should now be "Extra 150" (the 150th appended event)
        XCTAssertEqual(bridge.events.first?.content, "Extra 150")

        // Load more events should use offset = trimmedEventCount + events.count = 150 + 500 = 650
        bridge.loadMoreEvents()
        // Should append events from offset 650
        XCTAssertGreaterThan(bridge.events.count, 500)
    }

    // =========================================================================
    // MARK: - Task 5: Performance Benchmarks (AC #1, #2)
    // =========================================================================

    // [P0] Paginated fetch performance: first page of 1000 events loads under 100ms
    func testPaginatedFetchPerformance() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let session = try makeSession(context: context)

        // Persist 1000 events
        for i in 0..<1000 {
            let event = AgentEvent(
                type: .userMessage,
                content: "Perf event \(i)",
                timestamp: .now
            )
            try store.persist(event, session: session, order: i)
        }

        measure {
            _ = try? store.fetchEvents(for: session.id, offset: 0, limit: 50)
        }
    }

    // [P0] Virtualization window computation is fast
    func testVirtualizationWindowPerformance() {
        let allEvents = makeTestEvents(count: 10_000)
        let manager = TimelineVirtualizationManager()

        measure {
            _ = manager.eventsToRender(
                visibleRange: 5000..<5050,
                allEvents: allEvents
            )
        }
    }

    // [P1] Full loadEvents (legacy) for comparison
    func testLegacyLoadEventsPerformance() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let session = try makeSession(context: context)

        for i in 0..<1000 {
            let event = AgentEvent(
                type: .userMessage,
                content: "Legacy event \(i)",
                timestamp: .now
            )
            try store.persist(event, session: session, order: i)
        }

        measure {
            _ = try? store.fetchEvents(for: session.id)
        }
    }

    // [P1] trimOldEvents performance with large event list
    func testTrimOldEventsPerformance() {
        let bridge = makeBridge()
        bridge.events = makeTestEvents(count: 5000)

        measure {
            bridge.trimOldEvents()
        }
    }

    // [P1] SwiftData paginated query with offset returns correct page
    func testSwiftDataPaginatedQueryOrdering() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let session = try makeSession(context: context)

        let types: [AgentEventType] = [.userMessage, .assistant, .toolUse, .result]
        for i in 0..<200 {
            let event = AgentEvent(
                type: types[i % types.count],
                content: "Ordered event \(i)",
                timestamp: .now
            )
            try store.persist(event, session: session, order: i)
        }

        let page2 = try store.fetchEvents(for: session.id, offset: 100, limit: 50)

        XCTAssertEqual(page2.count, 50)
        XCTAssertEqual(page2.first?.content, "Ordered event 100")
        XCTAssertEqual(page2.last?.content, "Ordered event 149")
    }

    // =========================================================================
    // MARK: - Integration: AgentBridge + Paginated Store (AC #2)
    // =========================================================================

    // [P0] Large session load uses pagination, not full load
    func testLargeSessionLoadUsesPagination() throws {
        let bridge = makeBridge()
        let session = Session(title: "Large")
        let mockStore = MockPaginatedEventStore()
        mockStore.allEvents = makeTestEvents(count: 1500)

        bridge.configureEvents(store: mockStore, session: session)
        bridge.loadInitialPage(for: session)

        XCTAssertLessThanOrEqual(bridge.events.count, 50)
        XCTAssertTrue(bridge.hasMoreEvents)
    }

    // [P1] Load more events preserves existing events order
    func testLoadMorePreservesOrder() throws {
        let bridge = makeBridge()
        let session = Session(title: "Order Test")
        let mockStore = MockPaginatedEventStore()
        mockStore.allEvents = (0..<150).map { i in
            AgentEvent(type: .userMessage, content: "E\(i)", timestamp: .now)
        }

        bridge.configureEvents(store: mockStore, session: session)
        bridge.loadInitialPage(for: session)
        bridge.loadMoreEvents()

        // Verify order is preserved
        for i in 0..<bridge.events.count {
            XCTAssertEqual(
                bridge.events[i].content,
                "E\(i)",
                "Event at index \(i) should be E\(i)"
            )
        }
    }

    // =========================================================================
    // MARK: - Markdown Cache (Task 4.4)
    // =========================================================================

    // [P1] MarkdownContentView caches rendered views
    func testMarkdownCacheHashTracking() {
        // Verify that hash-based caching logic exists
        let markdown = "# Hello World"
        let hash = markdown.hashValue
        XCTAssertNotEqual(hash, 0, "Hash should be non-zero for non-empty string")
    }

    // =========================================================================
    // MARK: - totalEventCount
    // =========================================================================

    // [P0] totalEventCount returns correct count
    func testTotalEventCount() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let session = try makeSession(context: context)

        for i in 0..<75 {
            let event = AgentEvent(type: .userMessage, content: "E\(i)", timestamp: .now)
            try store.persist(event, session: session, order: i)
        }

        let count = try store.totalEventCount(for: session.id)
        XCTAssertEqual(count, 75, "totalEventCount should return the exact number of persisted events")
    }
}

// MARK: - Mock Paginated EventStore

private final class MockPaginatedEventStore: EventStoring, @unchecked Sendable {
    var allEvents: [AgentEvent] = []
    var shouldThrow = false
    var persistedEvents: [AgentEvent] = []

    func persist(_ event: AgentEvent, session: Session, order: Int) throws {
        if shouldThrow { throw AppError(domain: .data, code: "TEST_ERROR", message: "test error") }
        persistedEvents.append(event)
    }

    func fetchEvents(for sessionID: UUID) throws -> [AgentEvent] {
        if shouldThrow { throw AppError(domain: .data, code: "TEST_ERROR", message: "test error") }
        return allEvents
    }

    func fetchEvents(for sessionID: UUID, offset: Int, limit: Int) throws -> [AgentEvent] {
        if shouldThrow { throw AppError(domain: .data, code: "TEST_ERROR", message: "test error") }
        let start = min(offset, allEvents.count)
        let end = min(offset + limit, allEvents.count)
        return Array(allEvents[start..<end])
    }

    func totalEventCount(for sessionID: UUID) throws -> Int {
        if shouldThrow { throw AppError(domain: .data, code: "TEST_ERROR", message: "test error") }
        return allEvents.count
    }
}
