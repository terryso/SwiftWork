---
stepsCompleted:
  - step-01-preflight-and-context
  - step-02-generation-mode
  - step-03-test-strategy
  - step-04-generate-tests
  - step-04c-aggregate
  - step-05-validate-and-complete
lastStep: step-05-validate-and-complete
lastSaved: '2026-05-02'
workflowType: testarch-atdd
storyId: '2.5'
storyKey: 2-5-timeline-performance
storyFile: _bmad-output/implementation-artifacts/2-5-timeline-performance.md
atddChecklistPath: _bmad-output/test-artifacts/atdd-checklist-2-5-timeline-performance.md
generatedTestFiles:
  - SwiftWorkTests/Views/Timeline/TimelinePerformanceTests.swift
  - SwiftWorkTests/Support/PerformanceTestStubs.swift
inputDocuments:
  - _bmad-output/implementation-artifacts/2-5-timeline-performance.md
  - _bmad-output/project-context.md
  - SwiftWork/SDKIntegration/AgentBridge.swift
  - SwiftWork/Services/EventStore.swift
  - SwiftWork/Views/Workspace/Timeline/TimelineView.swift
  - SwiftWorkTests/Support/TestDataFactory.swift
  - SwiftWorkTests/SDKIntegration/AgentBridgeTests.swift
  - SwiftWorkTests/Services/EventStoreTests.swift
  - SwiftWorkTests/Views/Timeline/TimelineViewRefactoredTests.swift
---

# ATDD Checklist - Epic 2, Story 5: Timeline 性能优化

**Date:** 2026-05-02
**Author:** Nick
**Primary Test Level:** Unit + Integration

---

## Story Summary

Timeline 在长时间会话中保持流畅滚动性能，通过分页加载、虚拟化窗口和智能滚动三大策略确保 1000+ 事件时 UI 不冻结、8 小时运行无内存泄漏。

**As a** 用户
**I want** 在长时间会话中 Timeline 依然保持流畅滚动
**So that** 我不会因为事件数量增多而体验到卡顿

---

## Acceptance Criteria

1. **AC#1 (500+ 事件流畅滚动):** Given 会话包含 500+ 个事件 When 用户滚动 Timeline Then 使用 LazyVStack 懒加载渲染，滚动帧率不低于 60fps，空闲内存不超过 100MB，活跃内存不超过 300MB
2. **AC#2 (1000+ 事件分页加载):** Given 会话包含 1000+ 个事件 When 加载会话 Then 通过分页加载策略，UI 不冻结，仅渲染可视区域及 buffer 范围内的事件
3. **AC#3 (长时间运行无泄漏):** Given 长时间运行会话（8小时+） When 持续使用 Then 无内存泄漏，内存占用增长不超过 20%

---

## Story Integration Metadata

- **Story ID:** `2.5`
- **Story Key:** `2-5-timeline-performance`
- **Story File:** `_bmad-output/implementation-artifacts/2-5-timeline-performance.md`
- **Checklist Path:** `_bmad-output/test-artifacts/atdd-checklist-2-5-timeline-performance.md`
- **Generated Test Files:**
  - `SwiftWorkTests/Views/Timeline/TimelinePerformanceTests.swift`
  - `SwiftWorkTests/Support/PerformanceTestStubs.swift`

---

## Stack Detection

- **Detected Stack:** Backend (Swift Package Manager, XCTest)
- **Test Framework:** XCTest (built-in Swift testing)
- **No browser/E2E testing** applicable — this is a native macOS SwiftUI app
- All tests are **unit** and **integration** level

---

## Generation Mode

- **Mode:** AI Generation
- **Reason:** Acceptance criteria are clear; scenarios are standard (pagination, virtualization, scroll state, memory trimming). No browser recording needed.

---

## Test Strategy

### Acceptance Criteria to Test Mapping

| AC | Test Scenarios | Level | Priority |
|----|---------------|-------|----------|
| AC#1 (500+ 事件流畅) | Virtualization window computes correct subset | Unit | P0 |
| AC#1 (500+ 事件流畅) | Virtualization clamps at array boundaries | Unit | P0 |
| AC#1 (500+ 事件流畅) | Virtualization state tracks visible indices | Unit | P0 |
| AC#1 (500+ 事件流畅) | ScrollMode defaults to followLatest | Unit | P0 |
| AC#1 (500+ 事件流畅) | Scroll up >16px switches to manualBrowse | Unit | P0 |
| AC#1 (500+ 事件流畅) | Scroll near bottom (<96px) switches to followLatest | Unit | P0 |
| AC#1 (500+ 事件流畅) | Virtualization performance benchmark | Unit | P1 |
| AC#2 (1000+ 分页) | SwiftDataEventStore fetch with offset/limit | Integration | P0 |
| AC#2 (1000+ 分页) | fetchEvents offset beyond range returns empty | Integration | P0 |
| AC#2 (1000+ 分页) | loadInitialPage loads only first page | Integration | P0 |
| AC#2 (1000+ 分页) | loadMoreEvents appends next page | Integration | P0 |
| AC#2 (1000+ 分页) | hasMoreEvents flag tracks correctly | Integration | P0 |
| AC#2 (1000+ 分页) | Small sessions load all events | Integration | P1 |
| AC#2 (1000+ 分页) | Paginated fetch performance benchmark | Integration | P0 |
| AC#3 (内存优化) | trimOldEvents removes beyond threshold | Unit | P0 |
| AC#3 (内存优化) | trimOldEvents no-op when under threshold | Unit | P0 |
| AC#3 (内存优化) | trimOldEvents preserves boundary exactly | Unit | P0 |
| AC#3 (内存优化) | trimOldEvents performance benchmark | Unit | P1 |

---

## Red-Phase Test Scaffolds Created

### Unit + Integration Tests (33 tests)

**File:** `SwiftWorkTests/Views/Timeline/TimelinePerformanceTests.swift` (~730 lines)

**Support File:** `SwiftWorkTests/Support/PerformanceTestStubs.swift` (~55 lines)

#### Task 1: Paginated Event Loading (7 tests)

- [P0] `testFetchEventsWithOffsetAndLimit` -- RED: returns wrong count (protocol stub returns empty)
- [P0] `testFetchEventsWithLimitNearEnd` -- RED: returns wrong count
- [P0] `testFetchEventsOffsetBeyondRange` -- RED: returns wrong count
- [P0] `testEventStoringProtocolHasPaginatedFetch` -- Passes (compile-time check)
- [P0] `testLoadInitialPageLoadsOnlyFirstPage` -- RED: stub no-ops, events stay empty
- [P0] `testLoadMoreEventsAppendsNextPage` -- RED: stub no-ops
- [P0] `testHasMoreEventsFlag` -- RED: stub always returns false
- [P1] `testLoadInitialPageSmallSessionLoadsAll` -- RED: stub no-ops

#### Task 2: Virtualization Window (6 tests)

- [P0] `testVirtualizationManagerReturnsVisibleSubset` -- RED: stub returns empty array
- [P0] `testVirtualizationClampsAtStart` -- Passes (empty return is valid for empty range)
- [P0] `testVirtualizationClampsAtEnd` -- Passes (empty return is valid)
- [P0] `testVirtualizationStateTracksIndices` -- Passes (struct exists in stubs)
- [P1] `testVirtualizationBufferDefault` -- Passes (hardcoded in stub)
- [P1] `testVirtualizationWithEmptyEvents` -- Passes (empty in = empty out)

#### Task 3: Scroll Mode Management (7 tests)

- [P0] `testScrollModeHasFollowLatestAndManualBrowse` -- Passes (enum exists in stubs)
- [P0] `testScrollModeManagerDefaultsToFollowLatest` -- Passes (hardcoded in stub)
- [P0] `testScrollUpSwitchesToManualBrowse` -- RED: stub handleScrollChange is no-op
- [P0] `testSmallScrollUpStaysFollowLatest` -- Passes (no-op leaves default)
- [P0] `testScrollNearBottomSwitchesToFollowLatest` -- RED: stub no-op
- [P1] `testShowReturnToBottomButton` -- Passes (computed from state)
- [P1] `testReturnToBottomResetsMode` -- RED: stub no-op

#### Task 4: Memory Optimization (5 tests)

- [P0] `testTrimOldEventsRemovesOldest` -- RED: stub no-op, events.count stays 600
- [P0] `testTrimOldEventsDoesNothingWhenUnderThreshold` -- Passes (no-op is correct under 500)
- [P0] `testTrimOldEventsAtExactThreshold` -- Passes (no-op is correct at 500)
- [P1] `testAgentEventMetadataNoClosures` -- Passes (compile-time Sendable check)
- [P1] `testTrimOldEventsCalledDuringAppend` -- RED: stub no-op

#### Task 5: Performance Benchmarks (5 tests)

- [P0] `testPaginatedFetchPerformance` -- RED: stub returns empty
- [P0] `testVirtualizationWindowPerformance` -- Passes (measures stub)
- [P1] `testLegacyLoadEventsPerformance` -- Passes (uses existing method)
- [P1] `testTrimOldEventsPerformance` -- Passes (measures stub)
- [P1] `testSwiftDataPaginatedQueryOrdering` -- RED: stub returns empty

#### Integration (2 tests)

- [P0] `testLargeSessionLoadUsesPagination` -- RED: stub no-ops
- [P1] `testLoadMorePreservesOrder` -- RED: stub no-ops

---

## Implementation Checklist

### Task 1: Implement Paginated Event Loading

**Files to modify:**
- `SwiftWork/Services/EventStore.swift` -- Add `fetchEvents(for:offset:limit:)` to protocol and implementation
- `SwiftWork/SDKIntegration/AgentBridge.swift` -- Add `loadInitialPage`, `loadMoreEvents`, `hasMoreEvents`, `pageSize`

**Tests to activate (remove stubs, make green):**
- [ ] `testFetchEventsWithOffsetAndLimit`
- [ ] `testFetchEventsWithLimitNearEnd`
- [ ] `testFetchEventsOffsetBeyondRange`
- [ ] `testLoadInitialPageLoadsOnlyFirstPage`
- [ ] `testLoadMoreEventsAppendsNextPage`
- [ ] `testHasMoreEventsFlag`
- [ ] `testLoadInitialPageSmallSessionLoadsAll`

**Estimated Effort:** 3 hours

---

### Task 2: Implement Virtualization Window

**Files to create/modify:**
- `SwiftWork/Views/Workspace/Timeline/TimelineVirtualizationManager.swift` -- NEW
- `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` -- Integrate virtualization

**Tests to activate:**
- [ ] `testVirtualizationManagerReturnsVisibleSubset`
- [ ] `testVirtualizationClampsAtStart`
- [ ] `testVirtualizationClampsAtEnd`
- [ ] `testVirtualizationWindowPerformance`

**Estimated Effort:** 3 hours

---

### Task 3: Implement Smart Scroll Behavior

**Files to create/modify:**
- `SwiftWork/Views/Workspace/Timeline/ScrollModeManager.swift` -- NEW
- `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` -- Integrate scroll mode

**Tests to activate:**
- [ ] `testScrollUpSwitchesToManualBrowse`
- [ ] `testScrollNearBottomSwitchesToFollowLatest`
- [ ] `testReturnToBottomResetsMode`

**Estimated Effort:** 2 hours

---

### Task 4: Memory Optimization

**Files to modify:**
- `SwiftWork/SDKIntegration/AgentBridge.swift` -- Add `trimOldEvents()`, `maxInMemory`
- `SwiftWork/Views/Workspace/Timeline/EventViews/MarkdownContentView.swift` -- Add `@State` cache

**Tests to activate:**
- [ ] `testTrimOldEventsRemovesOldest`
- [ ] `testTrimOldEventsCalledDuringAppend`
- [ ] `testTrimOldEventsPerformance`

**Estimated Effort:** 2 hours

---

### Task 5: Clean Up Stubs

**After all tests pass:**
- [ ] Delete `SwiftWorkTests/Support/PerformanceTestStubs.swift`
- [ ] Remove protocol extension in test file
- [ ] Remove AgentBridge extension stubs in test file
- [ ] Move real types from stubs to production code
- [ ] Run `swift test --filter TimelinePerformanceTests` -- all 33 pass

**Estimated Effort:** 1 hour

---

## Running Tests

```bash
# Run all Story 2-5 tests
swift test --filter TimelinePerformanceTests

# Run specific test
swift test --filter TimelinePerformanceTests/testTrimOldEventsRemovesOldest

# Run with verbose output
swift test --filter TimelinePerformanceTests -v

# Build tests without running
swift build --build-tests
```

---

## Red-Green-Refactor Workflow

### RED Phase (Complete)

- 33 acceptance test scaffolds created in `TimelinePerformanceTests.swift`
- 23 tests fail (expected) -- stubs return empty/no-op
- 10 tests pass (structural checks and boundary cases)
- Support stubs in `PerformanceTestStubs.swift` allow compilation
- Test run result: `Executed 33 tests, with 23 failures (0 unexpected)`

### GREEN Phase (Next Steps)

1. Implement `fetchEvents(for:offset:limit:)` on `EventStoring` protocol and `SwiftDataEventStore`
2. Add `loadInitialPage`, `loadMoreEvents`, `hasMoreEvents` to `AgentBridge`
3. Create `TimelineVirtualizationManager.swift` with real window computation
4. Create `ScrollModeManager.swift` with real scroll state tracking
5. Add `trimOldEvents()` to `AgentBridge`
6. Replace stubs with real implementations
7. Delete `PerformanceTestStubs.swift`
8. Run tests after each task to verify green

### REFACTOR Phase

1. Review all new code for quality
2. Ensure no file exceeds 300 lines
3. Verify `@ObservationIgnored` on internal caches
4. Check for retain cycles in closures
5. Run Instruments for actual performance validation

---

## Test Execution Evidence

### RED Verification

**Command:** `swift test --filter TimelinePerformanceTests`

**Results:**
```
Executed 33 tests, with 23 failures (0 unexpected) in 8.059 seconds
```

**Summary:**
- Total tests: 33
- Failing (expected RED): 23
- Passing (structural): 10
- Status: RED-phase scaffolds verified

---

## Notes

- This project uses Swift/XCTest (not Playwright/TypeScript). The ATDD workflow was adapted to the native Swift testing framework.
- `PerformanceTestStubs.swift` provides minimal type stubs (`ScrollMode`, `ScrollModeManager`, `VirtualizationState`, `TimelineVirtualizationManager`) so tests compile. These should be deleted once real implementations are in place.
- The protocol extension on `EventStoring` provides a default paginated fetch that returns empty. The real implementation will use SwiftData `FetchDescriptor` with `.limit()` and `.offset()`.
- Performance benchmarks (`measure {}` blocks) will establish baselines during green phase.
- NFR tests (60fps, memory limits) require Instruments and are not automated in XCTest. The unit tests verify the logic that enables those NFRs.

---

**Generated by BMad TEA Agent** - 2026-05-02
