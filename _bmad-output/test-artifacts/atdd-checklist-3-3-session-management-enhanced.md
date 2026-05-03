---
stepsCompleted:
  - step-01-preflight-and-context
  - step-02-generation-mode
  - step-03-test-strategy
  - step-04-generate-tests
  - step-04c-aggregate
  - step-05-validate-and-complete
lastStep: step-05-validate-and-complete
lastSaved: '2026-05-03'
storyId: '3.3'
storyKey: '3-3-session-management-enhanced'
storyFile: '_bmad-output/implementation-artifacts/3-3-session-management-enhanced.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-3-3-session-management-enhanced.md'
generatedTestFiles:
  - SwiftWorkTests/Views/Sidebar/SidebarViewTests.swift
  - SwiftWorkTests/Views/Workspace/InputBar/InputBarViewTests.swift
  - SwiftWorkTests/SDKIntegration/AgentBridgeTests.swift
---

# ATDD Checklist: Story 3.3 - 会话管理增强

## TDD Red Phase (Current)

**Phase**: RED
**Total Tests**: 30 (17 new + 13 pre-existing that validate unchanged code)
**Execution Mode**: Sequential (backend/Swift native project)

## Acceptance Criteria Coverage

### AC#1: Sidebar 右键点击删除会话，确认后级联删除 (FR4)

| Test | Priority | File | Status |
|------|----------|------|--------|
| testSidebarViewCompiles | P0 | SidebarViewTests | RED |
| testSidebarViewAcceptsSessionToDeleteState | P0 | SidebarViewTests | RED |
| testDeleteConfirmationContainsSessionTitle | P0 | SidebarViewTests | RED |
| testDeleteSessionAfterConfirmationRemovesFromList | P0 | SidebarViewTests | RED |
| testDeleteConfirmationCancelPreservesSession | P1 | SidebarViewTests | RED |
| testDeleteLastSessionShowsEmptyState | P1 | SidebarViewTests | RED |
| testDeleteSessionCascadeRemovesEvents | P1 | SidebarViewTests | RED |

### AC#2: Sidebar 右键点击重命名，内联编辑模式 (FR5)

| Test | Priority | File | Status |
|------|----------|------|--------|
| testSessionRowViewCompiles | P0 | SidebarViewTests | RED |
| testRenameSessionUpdatesTitle | P0 | SidebarViewTests | RED |
| testRenameSessionBumpsToTop | P0 | SidebarViewTests | RED |
| testRenameCancelPreservesOriginalTitle | P1 | SidebarViewTests | RED |
| testRenameSessionPersistsToSwiftData | P1 | SidebarViewTests | RED |
| testRenameToEmptyStringUpdatesTitle | P1 | SidebarViewTests | RED |

### AC#3: Agent 执行中发送追加消息 (FR30)

| Test | Priority | File | Status |
|------|----------|------|--------|
| testInputBarViewCompiles | P0 | InputBarViewTests | RED |
| testInputBarViewWithRunningBridge | P0 | InputBarViewTests | RED |
| testSendMessageWhileRunningDoesNotCancel | P0 | InputBarViewTests | RED |
| testSendMessageWhileRunningAppendsUserMessage | P0 | InputBarViewTests | RED |
| testSendMessageWhileRunningPreservesExistingEvents | P1 | InputBarViewTests | RED |
| testSendMessageWhileRunningKeepsIsRunningTrue | P1 | InputBarViewTests | RED |
| testInputBarViewCompilesWithRunningAgent | P1 | InputBarViewTests | RED |
| testSendMessageWhileRunningDoesNotCancel (AgentBridge) | P0 | AgentBridgeTests | RED |
| testSendMessageWhileRunningNoCancellationEvent | P0 | AgentBridgeTests | RED |
| testFollowUpSendPreservesIsRunning | P0 | AgentBridgeTests | RED |
| testFollowUpSendDoesNotClearEvents | P1 | AgentBridgeTests | RED |
| testFollowUpSendAppendsNotReplaces | P1 | AgentBridgeTests | RED |
| testFollowUpSendDoesNotResetStreamingText | P1 | AgentBridgeTests | RED |

### AC#4: Shift+Enter 换行，Enter 发送 (FR32)

| Test | Priority | File | Status |
|------|----------|------|--------|
| testInputBarViewSupportsMultiLine | P0 | InputBarViewTests | RED |
| testEnterKeySendsMessage | P1 | InputBarViewTests | RED |
| testShiftEnterDoesNotSendMessage | P1 | InputBarViewTests | RED |

## Priority Distribution

| Priority | Count |
|----------|-------|
| P0 | 14 |
| P1 | 16 |
| P2 | 0 |
| **Total** | **30** |

## Test Files Created / Updated

### 1. SwiftWorkTests/Views/Sidebar/SidebarViewTests.swift (NEW)
- **Tests**: 13
- **Focus**: SidebarView context menu, delete confirmation alert, SessionRowView inline rename
- **Dependencies**: SwiftData in-memory container, SessionViewModel
- **Key behaviors tested**: View compilation, delete flow via ViewModel, rename via ViewModel, cascade delete, empty state

### 2. SwiftWorkTests/Views/Workspace/InputBar/InputBarViewTests.swift (NEW)
- **Tests**: 10
- **Focus**: InputBarView compilation, running-state behavior, multi-line support
- **Dependencies**: AgentBridge
- **Key behaviors tested**: View compiles with running bridge, concurrent send/stop layout contract, multi-line TextField

### 3. SwiftWorkTests/SDKIntegration/AgentBridgeTests.swift (EXTENDED)
- **New Tests**: 7
- **Focus**: sendMessage behavior when isRunning == true (follow-up message support)
- **Dependencies**: AgentBridge, MockEventStore
- **Key behaviors tested**: No cancellation on follow-up send, event preservation, user message appending, isRunning state

## Implementation Requirements (for GREEN phase)

### SidebarView.swift additions:
1. **`@State private var sessionToDelete: Session?`** -- Tracks which session is pending deletion
2. **`.contextMenu` modifier** on SessionRowView rows -- "删除" and "重命名" menu items
3. **`.alert` modifier** -- Delete confirmation dialog bound to `sessionToDelete`
4. **`@State private var renamingSessionID: UUID?`** -- Tracks which session is in rename mode
5. **`@State private var renameText: String`** -- Holds the text during rename editing

### SessionRowView.swift additions:
1. **`isRenaming: Bool` parameter** -- Controls inline TextField vs Text display
2. **`renameText: Binding<String>` parameter** -- Two-way binding for rename text
3. **Conditional view**: TextField when renaming, Text when not
4. **`.onSubmit`** on TextField to confirm rename

### InputBarView.swift changes:
1. **Remove `.disabled(agentBridge.isRunning)`** from TextField
2. **Layout change**: Show both send and stop buttons when running (not mutually exclusive)
3. **`onKeyPress(.return)` interceptor** -- Enter sends, Shift+Enter inserts newline

### AgentBridge.swift changes:
1. **Remove `if isRunning { cancelExecution() }`** from `sendMessage()`
2. **Append user message and start new stream turn** without resetting state
3. **Do not clear events or reset isRunning** on follow-up sends

## Red-Green-Refactor Workflow

### RED (complete):
- Test scaffolds generated with assertions for expected behavior
- Tests exercise both ViewModel logic (verifiable) and View compilation (smoke tests)
- AgentBridge tests verify the core behavior change (no cancellation on follow-up)

### GREEN (next):
1. Update SidebarView.swift: add context menu, delete alert, rename state management
2. Update SessionRowView.swift: add isRenaming parameter, conditional TextField
3. Update InputBarView.swift: remove disabled, add concurrent buttons, onKeyPress
4. Update AgentBridge.swift: remove cancel-on-send, implement append-without-reset
5. Run `swift test` -- tests should now compile and pass

### REFACTOR:
- Extract SidebarView editing state into a helper struct if view exceeds 300 lines
- Ensure InputBarView keyboard handling is reliable (fallback to NSTextView if needed)
- Verify no force unwraps in new code
- Verify strict concurrency compliance

## Execution Commands

```bash
# Run story 3-3 specific tests
swift test --filter SidebarViewTests
swift test --filter InputBarViewTests
swift test --filter AgentBridgeTests

# Run all tests (check for regressions)
swift test

# Build only (verify compilation)
swift build
```

## Key Risks & Assumptions

1. **Assumption**: SessionViewModel.deleteSession and updateSessionTitle are already fully implemented (verified in source). Story 3-3 only adds UI to call them.
2. **Assumption**: Session cascade delete rule is already configured in Session.swift (verified: `@Relationship(deleteRule: .cascade)`).
3. **Risk**: SwiftUI `.contextMenu` and `.alert` behavior requires ViewInspector or UI tests for full coverage. Compilation tests are the baseline.
4. **Risk**: `onKeyPress(.return)` for Enter/Shift+Enter differentiation may not work reliably on all macOS versions. Fallback: NSTextView Representable wrapper.
5. **Risk**: AgentBridge.sendMessage changes require careful task generation management -- the `activeTaskGeneration` mechanism must handle concurrent streams.
6. **Assumption**: SDK `agent.stream()` supports multiple sequential calls on the same Agent instance without creating a new Agent (verified in SDK docs).
7. **Learning from Story 3-2**: Store ModelContainer as instance variable (not tuple destructuring) to prevent premature release in tests.

## Next Steps

1. Run `dev-story` workflow with story file `_bmad-output/implementation-artifacts/3-3-session-management-enhanced.md`
2. Implement Tasks 1-5 in the story
3. After each task, activate corresponding tests
4. Verify RED -> GREEN for each test batch
5. Run `swift test` to verify all tests pass with no regressions
