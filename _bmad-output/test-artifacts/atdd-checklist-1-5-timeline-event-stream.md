---
stepsCompleted:
  - step-01-preflight-and-context
  - step-02-generation-mode
  - step-03-test-strategy
  - step-04-generate-tests
  - step-04c-aggregate
  - step-05-validate-and-complete
lastStep: step-05-validate-and-complete
lastSaved: '2026-05-01'
storyId: '1.5'
storyKey: 1-5-timeline-event-stream
storyFile: '_bmad-output/implementation-artifacts/1-5-timeline-event-stream.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-1-5-timeline-event-stream.md'
generatedTestFiles:
  - SwiftWorkTests/Views/Timeline/TimelineEventViewsTests.swift
  - SwiftWorkTests/Views/Timeline/StreamingTextViewTests.swift
  - SwiftWorkTests/Views/Timeline/TimelineViewRefactoredTests.swift
inputDocuments:
  - '_bmad-output/implementation-artifacts/1-5-timeline-event-stream.md'
  - '_bmad-output/project-context.md'
  - '_bmad-output/implementation-artifacts/1-4-message-input-agent-execution.md'
---

# ATDD Checklist: Story 1.5 — Timeline 事件流渲染

**Date:** 2026-05-01
**Author:** TEA Agent (Master Test Architect)
**Primary Test Level:** Unit + Component (View)

---

## Story Summary

**As a** 用户
**I want** 看到 Agent 的实时事件流以文本形式渲染在 Timeline 中
**So that** 我可以实时观察 Agent 的思考和执行过程

---

## Acceptance Criteria

1. **AC#1:** 用户发送消息后 Agent 开始响应，SDK 产生各类 SDKMessage 事件时，EventMapper 将每个 SDKMessage 映射为 AgentEvent，TimelineView 实时渲染（FR7），事件渲染延迟不超过 100ms（NFR2）
2. **AC#2:** Agent 正在生成文本响应时，接收到 `.partialMessage` 事件后，文本以逐字方式流式显示，无可见卡顿（FR8, NFR3）
3. **AC#3:** Agent 正在处理请求时，接收到思考相关事件后，显示 Thinking 动画指示器（旋转动画 + "思考中..." 文本）（FR9）
4. **AC#4:** Agent 完成任务时，接收到 `.result` 事件后，Timeline 底部显示结果摘要卡片，包含状态（成功/失败）、耗时、Token 用量（FR10）
5. **AC#5:** 接收到未知的 SDKMessage 类型时，`@unknown default` 触发后，渲染为"未知事件"占位卡片，应用不崩溃

---

## Test Summary

| Category | File | Tests | Priority |
|----------|------|-------|----------|
| EventView Tests (Unit) | `SwiftWorkTests/Views/Timeline/TimelineEventViewsTests.swift` | 18 | P0-P1 |
| StreamingTextView Tests | `SwiftWorkTests/Views/Timeline/StreamingTextViewTests.swift` | 6 | P0 |
| TimelineView Refactored Tests | `SwiftWorkTests/Views/Timeline/TimelineViewRefactoredTests.swift` | 12 | P0-P1 |
| **Total** | **3 files** | **36 tests** | |

---

## Acceptance Criteria Coverage

| AC | Description | Test Coverage | Priority |
|----|-------------|---------------|----------|
| #1 | EventMapper 映射 + TimelineView 实时渲染 | `TimelineViewRefactoredTests.testEventViewForAllAgentEventTypes`, `TimelineViewRefactoredTests.testTimelineViewRendersEventsList`, `TimelineViewRefactoredTests.testTimelineViewEmptyState`, `TimelineEventViewsTests.testUserMessageViewInstantiation`, `TimelineEventViewsTests.testAssistantMessageViewInstantiation`, `TimelineEventViewsTests.testToolCallViewInstantiation`, `TimelineEventViewsTests.testToolResultViewInstantiation`, `TimelineEventViewsTests.testSystemEventViewInstantiation`, `TimelineEventViewsTests.testToolProgressViewInstantiation` | P0 |
| #2 | 流式文本逐字显示 | `StreamingTextViewTests.testStreamingTextViewRendersNonEmptyText`, `StreamingTextViewTests.testStreamingTextViewEmptyNotRendered`, `StreamingTextViewTests.testStreamingTextAccumulation`, `TimelineViewRefactoredTests.testStreamingTextBlockRenderedWhenNonEmpty`, `TimelineViewRefactoredTests.testStreamingTextHiddenWhenEmpty` | P0 |
| #3 | Thinking 动画指示器 | `TimelineEventViewsTests.testThinkingViewInstantiation`, `TimelineViewRefactoredTests.testThinkingViewShownForSystemInitEvent`, `TimelineViewRefactoredTests.testThinkingViewNotShownForSystemStatusEvent` | P0 |
| #4 | 结果摘要卡片 | `TimelineEventViewsTests.testResultViewInstantiation`, `TimelineEventViewsTests.testResultViewDisplaysSubtype`, `TimelineEventViewsTests.testResultViewDisplaysDurationAndCost`, `TimelineEventViewsTests.testResultViewDisplaysNumTurns` | P0 |
| #5 | 未知事件占位卡片 | `TimelineEventViewsTests.testUnknownEventViewInstantiation`, `TimelineViewRefactoredTests.testUnknownEventRenderedForUnknownType` | P0 |

---

## Test Levels

| Level | Count | Files |
|-------|-------|-------|
| Unit (EventView) | 18 | TimelineEventViewsTests |
| Unit (StreamingText) | 6 | StreamingTextViewTests |
| Component (View) | 12 | TimelineViewRefactoredTests |

---

## Red-Phase Test Scaffolds Created

### TimelineEventViewsTests (18 tests)

**File:** `SwiftWorkTests/Views/Timeline/TimelineEventViewsTests.swift`

**AC#1 — EventView Instantiation:**
- `testUserMessageViewInstantiation` [P0] — UserMessageView(event:) compiles and creates
- `testUserMessageViewDisplaysContent` [P0] — renders event.content
- `testAssistantMessageViewInstantiation` [P0] — AssistantMessageView(event:) compiles
- `testToolCallViewInstantiation` [P0] — ToolCallView(event:) compiles
- `testToolCallViewDisplaysToolName` [P0] — renders tool name from event.content
- `testToolCallViewDisplaysInputSummary` [P1] — renders truncated input from metadata
- `testToolResultViewInstantiation` [P0] — ToolResultView(event:) compiles
- `testToolResultViewSuccessStyle` [P0] — isError=false uses green background
- `testToolResultViewErrorStyle` [P0] — isError=true uses red background
- `testToolProgressViewInstantiation` [P0] — ToolProgressView(event:) compiles
- `testToolProgressViewDisplaysElapsedTime` [P1] — renders elapsedTimeSeconds from metadata
- `testSystemEventViewInstantiation` [P0] — SystemEventView(event:) compiles
- `testSystemEventViewDisplaysContent` [P1] — renders event.content

**AC#3 — ThinkingView:**
- `testThinkingViewInstantiation` [P0] — ThinkingView() compiles

**AC#4 — ResultView:**
- `testResultViewInstantiation` [P0] — ResultView(event:) compiles
- `testResultViewDisplaysSubtype` [P0] — renders subtype metadata
- `testResultViewDisplaysDurationAndCost` [P0] — renders durationMs + totalCostUsd
- `testResultViewDisplaysNumTurns` [P1] — renders numTurns metadata

**AC#5 — UnknownEventView:**
- `testUnknownEventViewInstantiation` [P0] — UnknownEventView(event:) compiles

### StreamingTextViewTests (6 tests)

**File:** `SwiftWorkTests/Views/Timeline/StreamingTextViewTests.swift`

**AC#2 — Streaming Text:**
- `testStreamingTextViewRendersNonEmptyText` [P0] — renders provided text
- `testStreamingTextViewEmptyNotRendered` [P0] — empty text does not render
- `testStreamingTextAccumulation` [P0] — streamingText accumulates from partialMessage events
- `testStreamingTextClearedOnAssistantEvent` [P0] — streamingText cleared when .assistant arrives
- `testStreamingTextPreservesOrder` [P0] — text order matches event order
- `testStreamingTextSupportsUnicode` [P1] — CJK and emoji content rendered

### TimelineViewRefactoredTests (12 tests)

**File:** `SwiftWorkTests/Views/Timeline/TimelineViewRefactoredTests.swift`

**AC#1 — TimelineView Rendering:**
- `testTimelineViewRendersEventsList` [P0] — renders all events from agentBridge.events
- `testTimelineViewEmptyState` [P0] — empty events shows placeholder
- `testTimelineViewUsesAgentBridgeEvents` [P0] — reads from agentBridge.events
- `testEventViewForAllAgentEventTypes` [P0] — exhaustive switch covers all 19 AgentEventType cases

**AC#2 — Streaming Text Integration:**
- `testStreamingTextBlockRenderedWhenNonEmpty` [P0] — streamingText block visible
- `testStreamingTextHiddenWhenEmpty` [P0] — no streaming block when streamingText == ""

**AC#3 — Thinking:**
- `testThinkingViewShownForSystemInitEvent` [P0] — .system with subtype "init" shows ThinkingView
- `testThinkingViewNotShownForSystemStatusEvent` [P1] — .system with other subtype shows SystemEventView

**AC#4 — Result Card:**
- `testResultEventUsesResultView` [P0] — .result event delegates to ResultView

**AC#5 — Unknown:**
- `testUnknownEventRenderedForUnknownType` [P0] — .unknown type shows UnknownEventView
- `testDefaultCaseCoversGrowthEventTypes` [P1] — hookStarted, taskStarted, etc. rendered as SystemEventView

---

## Implementation Checklist

### Task 1: Create EventViews subdirectory and extract views

**Files:** 10 new files in `SwiftWork/Views/Workspace/Timeline/EventViews/`

**Activate:** `TimelineEventViewsTests` (18 tests)

**Tasks to make tests pass:**

- [ ] Create `EventViews/` directory
- [ ] Create `UserMessageView.swift` — extract from TimelineView.userMessageView, accept `AgentEvent`
- [ ] Create `AssistantMessageView.swift` — extract assistantView, accept `AgentEvent`
- [ ] Create `StreamingTextView.swift` — new component for `text: String` parameter
- [ ] Create `ThinkingView.swift` — new animated thinking indicator (RotationEffect)
- [ ] Create `ToolCallView.swift` — extract toolUseView, accept `AgentEvent`
- [ ] Create `ToolResultView.swift` — extract toolResultView, accept `AgentEvent`
- [ ] Create `ToolProgressView.swift` — new progress view with elapsedTimeSeconds
- [ ] Create `ResultView.swift` — extract resultView, display subtype/duration/cost/numTurns
- [ ] Create `SystemEventView.swift` — extract systemView, accept `AgentEvent` + optional `isError`
- [ ] Create `UnknownEventView.swift` — extract unknownView, accept `AgentEvent`
- [ ] Run tests: `swift test --filter TimelineEventViewsTests`

### Task 2: Refactor TimelineView to use EventViews

**File:** `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` (MODIFY)

**Activate:** `TimelineViewRefactoredTests` (12 tests)

**Tasks to make tests pass:**

- [ ] Update `eventView(for:)` to call new independent EventView components
- [ ] Make switch exhaustive over all 19 `AgentEventType` cases
- [ ] Add ThinkingView for `.system` with `subtype == "init"`
- [ ] Use StreamingTextView component instead of inline Text
- [ ] Keep TimelineView under 300 lines
- [ ] Run tests: `swift test --filter TimelineViewRefactoredTests`

### Task 3: Verify streaming text behavior

**File:** Tests verify existing AgentBridge.streamingText behavior

**Activate:** `StreamingTextViewTests` (6 tests)

**Tasks to make tests pass:**

- [ ] Create `StreamingTextView.swift` accepting `text: String`
- [ ] Verify AgentBridge streamingText accumulation logic (existing)
- [ ] Verify streamingText cleared on .assistant (existing)
- [ ] Run tests: `swift test --filter StreamingTextViewTests`

---

## Running Tests

```bash
# Run all tests for this story
swift test --filter TimelineEventViewsTests
swift test --filter StreamingTextViewTests
swift test --filter TimelineViewRefactoredTests

# Run all project tests
swift test

# Run specific test
swift test --filter TimelineEventViewsTests/testThinkingViewInstantiation
```

---

## Red-Green-Refactor Workflow

### RED Phase (Complete)

- All 36 tests written as red-phase scaffolds asserting EXPECTED behavior
- Tests will fail until:
  - EventView subdirectory created with independent View components
  - ThinkingView with RotationEffect animation implemented
  - StreamingTextView component extracted
  - TimelineView refactored to use extracted components
  - Exhaustive switch covers all 19 AgentEventType cases

### GREEN Phase (DEV Team - Next Steps)

1. Implement Task 1 (EventViews extraction) — makes 18 unit tests pass
2. Implement Task 2 (TimelineView refactor) — makes 12 component tests pass
3. Implement Task 3 (StreamingText verification) — makes 6 tests pass
4. Run `swift test` to verify all 251+ tests pass

### REFACTOR Phase

- Review TimelineView for line count (under 300)
- Ensure all EventView files follow single-type-per-file rule
- Verify no regression in existing 215 tests

---

## Notes

- This is a Swift/SwiftUI/macOS project using XCTest. No Playwright/Jest/browser testing.
- View tests verify instantiation and type existence — SwiftUI view hierarchy testing is limited in XCTest.
- AgentEventType has 19 cases (18 SDK types + unknown). The exhaustive switch must cover all.
- Story 1-4 already implemented TimelineView with inline views (231 lines). This story extracts to independent files.
- AgentBridge.streamingText accumulation is already implemented — Story 1-5 tests verify behavior, not reimplement.
- ThinkingView requires `RotationEffect` animation — test only verifies instantiation (animation is visual).
- ResultView must display: subtype (success/cancelled/error), durationMs, totalCostUsd, numTurns from metadata.
- Growth-phase event types (hookStarted, taskStarted, etc.) map to SystemEventView — not separate views.

---

**Generated by BMad TEA Agent** — 2026-05-01
