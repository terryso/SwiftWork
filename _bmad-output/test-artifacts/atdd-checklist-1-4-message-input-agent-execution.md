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
storyId: '1.4'
storyKey: 1-4-message-input-agent-execution
storyFile: '_bmad-output/implementation-artifacts/1-4-message-input-agent-execution.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-1-4-message-input-agent-execution.md'
generatedTestFiles:
  - SwiftWorkTests/SDKIntegration/EventMapperTests.swift
  - SwiftWorkTests/SDKIntegration/AgentBridgeTests.swift
  - SwiftWorkTests/App/MessageInputAgentExecutionIntegrationTests.swift
inputDocuments:
  - '_bmad-output/implementation-artifacts/1-4-message-input-agent-execution.md'
  - '_bmad-output/project-context.md'
---

# ATDD Checklist: Story 1.4 — 消息输入与 Agent 执行

**Date:** 2026-05-01
**Author:** TEA Agent
**Primary Test Level:** Unit + Integration

---

## Story Summary

**As a** 用户
**I want** 在输入框中输入消息并发送给 Agent，以及中断正在执行的任务
**So that** 我可以与 Agent 交互并控制执行过程

---

## Acceptance Criteria

1. **AC#1:** 用户在 InputBarView 中输入消息，按 Enter 键发送给 Agent，InputBar 清空，Timeline 开始显示事件流（FR29），消息作为 `.userMessage` 事件渲染在 Timeline 顶部
2. **AC#2:** Agent 正在执行任务时，用户点击停止按钮，Agent 任务被取消（FR31），AsyncStream 正确清理，Timeline 显示"任务已取消"状态提示
3. **AC#3:** Agent 执行过程中发生错误时，应用不崩溃，Timeline 显示友好错误提示（NFR11），用户可以重新发送消息

---

## Test Summary

| Category | File | Tests | Priority |
|----------|------|-------|----------|
| EventMapper (Unit) | `SwiftWorkTests/SDKIntegration/EventMapperTests.swift` | 28 | P0-P1 |
| AgentBridge (Unit) | `SwiftWorkTests/SDKIntegration/AgentBridgeTests.swift` | 15 | P0-P1 |
| Integration | `SwiftWorkTests/App/MessageInputAgentExecutionIntegrationTests.swift` | 12 | P0-P1 |
| **Total** | **3 files** | **55 tests** | |

---

## Acceptance Criteria Coverage

| AC | Description | Test Coverage | Priority |
|----|-------------|---------------|----------|
| #1 | 发送消息给 Agent，显示事件流 | `EventMapperTests` (28 tests: all SDKMessage types), `AgentBridgeTests.testSendMessageAppendsUserMessage`, `AgentBridgeTests.testSendMessageEmptyTextDoesNothing`, `AgentBridgeTests.testSendMessageSetsIsRunning`, `AgentBridgeTests.testUserMessageOrdering`, `MessageInputAgentExecutionIntegrationTests.testInputBarViewInstantiation`, `MessageInputAgentExecutionIntegrationTests.testTimelineViewInstantiation`, `MessageInputAgentExecutionIntegrationTests.testWorkspaceViewInstantiation`, `MessageInputAgentExecutionIntegrationTests.testMultipleMessagesSequentially`, `MessageInputAgentExecutionIntegrationTests.testEventMapperCoversAllSDKMessageTypes` | P0-P1 |
| #2 | 中断 Agent 任务，显示取消提示 | `AgentBridgeTests.testCancelExecutionSetsIsRunningFalse`, `AgentBridgeTests.testCancelExecutionAppendsCancellationEvent`, `AgentBridgeTests.testCancelExecutionEventContainsCancellationText`, `AgentBridgeTests.testCancelExecutionWhenNotRunning`, `EventMapperTests.testMapResultCancelled`, `MessageInputAgentExecutionIntegrationTests.testCancelPreservesExistingEvents` | P0-P1 |
| #3 | 错误处理不崩溃，可重发消息 | `AgentBridgeTests.testSendMessageWithoutConfigureDoesNotCrash`, `AgentBridgeTests.testAgentBridgeNeverCrashes`, `AgentBridgeTests.testConfigureDoesNotCrash`, `AgentBridgeTests.testConfigureWithNilOptionals`, `MessageInputAgentExecutionIntegrationTests.testErrorRecoveryAllowsResend`, `MessageInputAgentExecutionIntegrationTests.testFreshStartAfterError` | P0-P1 |

---

## Test Levels

| Level | Count | Files |
|-------|-------|-------|
| Unit | 43 | EventMapperTests (28), AgentBridgeTests (15) |
| Integration | 12 | MessageInputAgentExecutionIntegrationTests (View instantiation, SwiftData, round-trip) |

---

## Red-Phase Test Scaffolds Created

### EventMapperTests (28 tests)

**File:** `SwiftWorkTests/SDKIntegration/EventMapperTests.swift`

**AC#1 — MVP Event Types:**
- `testMapPartialMessage` [P0] — .partialMessage → type.partialMessage, content preserved
- `testMapPartialMessageWithParentToolUseId` [P0] — partial message with parent context
- `testMapAssistant` [P0] — .assistant → type.assistant, model/stopReason in metadata
- `testMapAssistantWithToolUseStopReason` [P1] — stopReason == "tool_use"
- `testMapToolUse` [P0] — .toolUse → type.toolUse, toolName/toolUseId/input in metadata
- `testMapToolUseWithComplexInput` [P1] — complex JSON string input
- `testMapToolResultSuccess` [P0] — .toolResult with isError=false
- `testMapToolResultError` [P0] — .toolResult with isError=true
- `testMapToolProgress` [P0] — .toolProgress → type.toolProgress
- `testMapToolProgressWithNilElapsedTime` [P1] — nil elapsedTime handling
- `testMapResultSuccess` [P0] — .result → type.result, subtype/numTurns/durationMs/totalCostUsd
- `testMapResultCancelled` [P0] — .result with cancelled subtype (AC#2)
- `testMapResultErrorDuringExecution` [P1] — .result with error subtype
- `testMapSystem` [P0] — .system → type.system, subtype in metadata
- `testMapSystemStatus` [P1] — .system with status subtype
- `testMapUserMessage` [P0] — .userMessage → type.userMessage

**MVP — Hook/Task/Auth Mappings (→ system):**
- `testMapHookStarted` [P1] — .hookStarted → type.system
- `testMapHookProgress` [P1] — .hookProgress → type.system
- `testMapHookResponse` [P1] — .hookResponse → type.system
- `testMapTaskStarted` [P1] — .taskStarted → type.system
- `testMapTaskProgress` [P1] — .taskProgress → type.system
- `testMapAuthStatus` [P1] — .authStatus → type.system
- `testMapFilesPersisted` [P1] — .filesPersisted → type.system
- `testMapLocalCommandOutput` [P1] — .localCommandOutput → type.system
- `testMapPromptSuggestion` [P1] — .promptSuggestion → type.system
- `testMapToolUseSummary` [P1] — .toolUseSummary → type.system

**Event Properties:**
- `testMappedEventsHaveUniqueIDs` [P0] — unique UUID per event
- `testMappedEventsHaveRecentTimestamps` [P0] — timestamp ≈ Date.now

### AgentBridgeTests (15 tests)

**File:** `SwiftWorkTests/SDKIntegration/AgentBridgeTests.swift`

**AC#1 — Initial State:**
- `testInitialState` [P0] — events empty, isRunning false, errorMessage nil
- `testAgentBridgeIsClass` [P0] — class type for @Observable conformance

**AC#1 — sendMessage:**
- `testSendMessageAppendsUserMessage` [P0] — user message prepended before SDK stream
- `testSendMessageEmptyTextDoesNothing` [P0] — empty text no-op
- `testSendMessageWithoutConfigureDoesNotCrash` [P0] — nil agent doesn't crash
- `testSendMessageSetsIsRunning` [P0] — isRunning state transition
- `testSendMessageClearsErrorMessage` [P0] — error cleared on new send

**AC#2 — cancelExecution:**
- `testCancelExecutionSetsIsRunningFalse` [P0] — sets isRunning false
- `testCancelExecutionAppendsCancellationEvent` [P0] — appends system event with isCancellation
- `testCancelExecutionEventContainsCancellationText` [P0] — content == "任务已取消"
- `testCancelExecutionWhenNotRunning` [P1] — safe to cancel when idle

**AC#3 — Error Handling:**
- `testConfigureDoesNotCrash` [P0] — valid config safe
- `testConfigureWithNilOptionals` [P0] — nil optionals safe
- `testAgentBridgeNeverCrashes` [P0] — arbitrary operation sequence never crashes

**clearEvents:**
- `testClearEventsEmptiesArray` [P0] — resets all state
- `testClearEventsResetsAllState` [P1] — full reset verification

**Session Switching:**
- `testSessionSwitchClearsOldEvents` [P0] — clearEvents + reconfigure

### MessageInputAgentExecutionIntegrationTests (12 tests)

**File:** `SwiftWorkTests/App/MessageInputAgentExecutionIntegrationTests.swift`

**AC#1 — View Instantiation:**
- `testInputBarViewInstantiation` [P0] — InputBarView(agentBridge:) compiles
- `testTimelineViewInstantiation` [P0] — TimelineView(agentBridge:) compiles
- `testWorkspaceViewInstantiation` [P0] — WorkspaceView(...) compiles
- `testContentViewIntegratesAgentBridge` [P1] — ContentView with AgentBridge

**AC#1 — AgentBridge + SwiftData:**
- `testAgentBridgeConfigureWithSession` [P0] — configure with session data
- `testMultipleMessagesSequentially` [P0] — 3 messages produce 3 userMessage events

**AC#2 — Cancel Integration:**
- `testCancelPreservesExistingEvents` [P0] — cancel appends, doesn't remove

**AC#3 — Error Recovery:**
- `testErrorRecoveryAllowsResend` [P0] — resend after error
- `testFreshStartAfterError` [P0] — clearEvents + reconfigure

**AC#1 — EventMapper Round-Trip:**
- `testEventMapperCoversAllSDKMessageTypes` [P0] — all 18 SDKMessage cases produce known types

---

## Required data-testid Attributes

> Note: This is a SwiftUI/macOS project, not a web app. There are no `data-testid` attributes. View testing uses SwiftUI's `@testable` import and View instantiation verification.

---

## Implementation Checklist

### Task 1: Implement EventMapper

**File:** `SwiftWork/SDKIntegration/EventMapper.swift` (NEW)

**Activate:** `EventMapperTests` (28 tests)

**Tasks to make tests pass:**

- [ ] Create `EventMapper.swift` with `struct EventMapper`
- [ ] Implement `static func map(_ message: SDKMessage) -> AgentEvent`
- [ ] Exhaustive switch covering all 18 SDKMessage cases
- [ ] Map MVP types directly: .partialMessage, .assistant, .toolUse, .toolResult, .toolProgress, .result, .system, .userMessage
- [ ] Map Growth types to .system: .hookStarted, .hookProgress, .hookResponse, .taskStarted, .taskProgress, .authStatus, .filesPersisted, .localCommandOutput, .promptSuggestion, .toolUseSummary
- [ ] Extract associated data into content and metadata fields
- [ ] Run tests: `swift test --filter EventMapperTests`
- [ ] All 28 tests pass (green phase)

### Task 2: Implement AgentBridge

**File:** `SwiftWork/SDKIntegration/AgentBridge.swift` (REPLACE placeholder)

**Activate:** `AgentBridgeTests` (15 tests)

**Tasks to make tests pass:**

- [ ] Replace placeholder `struct AgentBridge` with `@MainActor @Observable final class AgentBridge`
- [ ] Add properties: `events: [AgentEvent]`, `isRunning: Bool`, `errorMessage: String?`, `agent: Agent?`, `currentTask: Task<Void, Never>?`
- [ ] Implement `configure(apiKey:baseURL:model:workspacePath:)` — create Agent via `createAgent(options:)`
- [ ] Implement `sendMessage(_ text: String)` — async, prepend userMessage, start SDK stream
- [ ] Implement `cancelExecution()` — interrupt agent, cancel task, append cancel event
- [ ] Implement `clearEvents()` — reset all state
- [ ] All SDK calls wrapped in do/catch
- [ ] Guard against nil agent in sendMessage
- [ ] Run tests: `swift test --filter AgentBridgeTests`
- [ ] All 15 tests pass (green phase)

### Task 3: Implement InputBarView

**File:** `SwiftWork/Views/Workspace/InputBar/InputBarView.swift` (REPLACE placeholder)

**Activate:** `MessageInputAgentExecutionIntegrationTests.testInputBarViewInstantiation`

**Tasks to make tests pass:**

- [ ] Replace placeholder with `InputBarView(agentBridge: AgentBridge)` accepting AgentBridge
- [ ] TextField/TextEditor bound to `@State private var inputText`
- [ ] Enter sends, clears inputText
- [ ] Send button when idle, stop button when running
- [ ] Disabled input when isRunning
- [ ] Run tests: `swift test --filter MessageInputAgentExecutionIntegrationTests`

### Task 4: Implement TimelineView

**File:** `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` (REPLACE placeholder)

**Activate:** `MessageInputAgentExecutionIntegrationTests.testTimelineViewInstantiation`

**Tasks to make tests pass:**

- [ ] Replace placeholder with `TimelineView(agentBridge: AgentBridge)` accepting AgentBridge
- [ ] ScrollView + LazyVStack rendering agentBridge.events
- [ ] @ViewBuilder exhaustive switch on event.type
- [ ] Auto-scroll on new events (ScrollViewReader + onChange)
- [ ] Empty state placeholder
- [ ] Run tests: `swift test --filter MessageInputAgentExecutionIntegrationTests`

### Task 5: Create WorkspaceView

**File:** `SwiftWork/Views/Workspace/WorkspaceView.swift` (NEW)

**Activate:** `MessageInputAgentExecutionIntegrationTests.testWorkspaceViewInstantiation`

**Tasks to make tests pass:**

- [ ] Create WorkspaceView with agentBridge, session, timelineView, inputBarView parameters
- [ ] VStack(spacing: 0): TimelineView (flex) + Divider + InputBarView (fixed)
- [ ] .task modifier to configure AgentBridge on appear
- [ ] Run tests: `swift test --filter MessageInputAgentExecutionIntegrationTests`

### Task 6: Integrate into ContentView

**File:** `SwiftWork/App/ContentView.swift` (MODIFY)

**Activate:** `MessageInputAgentExecutionIntegrationTests.testContentViewIntegratesAgentBridge`

**Tasks to make tests pass:**

- [ ] Add `@State private var agentBridge = AgentBridge()`
- [ ] Replace detail placeholder with WorkspaceView
- [ ] Configure agentBridge on session change
- [ ] Run tests: `swift test --filter MessageInputAgentExecutionIntegrationTests`

---

## Running Tests

```bash
# Run all tests for this story
swift test --filter EventMapperTests
swift test --filter AgentBridgeTests
swift test --filter MessageInputAgentExecutionIntegrationTests

# Run all project tests
swift test

# Run specific test
swift test --filter EventMapperTests/testMapToolUse
```

---

## Mock Strategy

- **AgentBridge**: Uses real AgentBridge instance with fake API key — no real API calls expected in CI (agent.stream() will fail fast with invalid key)
- **EventMapper**: Direct SDKMessage construction using public initializers — no mocking needed
- **SwiftData**: In-memory ModelContainer (`isStoredInMemoryOnly: true`) for integration tests
- **Existing `TestDataFactory`**: Extended if needed, but most tests create SDK data types directly

---

## Red-Green-Refactor Workflow

### RED Phase (Complete)

- All 55 tests written as red-phase scaffolds asserting EXPECTED behavior
- Tests will fail until:
  - `EventMapper` is created with exhaustive SDKMessage mapping
  - `AgentBridge` is reimplemented as `@MainActor @Observable final class`
  - `InputBarView`, `TimelineView`, `WorkspaceView` accept AgentBridge parameter
  - `ContentView` integrates AgentBridge

### GREEN Phase (DEV Team - Next Steps)

1. Implement Task 1 (EventMapper) — makes 28 unit tests pass
2. Implement Task 2 (AgentBridge) — makes 15 unit tests pass
3. Implement Task 3 (InputBarView) — makes integration tests pass
4. Implement Task 4 (TimelineView) — makes integration tests pass
5. Implement Task 5 (WorkspaceView) — makes integration tests pass
6. Implement Task 6 (ContentView integration) — makes integration tests pass
7. Run `swift test` to verify all pass

### REFACTOR Phase

- Review for code quality, DRY, performance
- Ensure tests still pass after each refactor

---

## Notes

- This is a Swift/macOS project using XCTest (not Playwright/Jest). Test patterns follow XCTest conventions with `@testable import`.
- AgentBridge must be `@MainActor @Observable final class` per project rules.
- EventMapper is a stateless struct with a pure static function — fully deterministic, no mock needed.
- SDK `SDKMessage` has 18 cases; all are tested in EventMapperTests.
- AgentBridge tests that call `sendMessage` use fake API keys; the SDK will fail fast without making real network calls. Tests verify structural behavior (user message appended, state transitions, no crash), not SDK correctness.
- NFR11 (no crash on SDK errors) is tested via `testAgentBridgeNeverCrashes` and `testSendMessageWithoutConfigureDoesNotCrash`.
- FR29 (message sending) covered by `testSendMessageAppendsUserMessage` + `testUserMessageOrdering`.
- FR31 (cancel execution) covered by `testCancelExecutionSetsIsRunningFalse` + `testCancelExecutionAppendsCancellationEvent`.
- The `InputBarView(agentBridge:)` and `TimelineView(agentBridge:)` initializer signatures are required by integration tests.
- The `WorkspaceView(agentBridge:session:timelineView:inputBarView:)` initializer signature is required by integration tests (final signature may vary during implementation).

---

**Generated by BMad TEA Agent** — 2026-05-01
