---
stepsCompleted:
  - step-01-preflight-and-context
  - step-02-generation-mode
  - step-03-test-strategy
  - step-04-generate-tests
  - step-04c-aggregate
lastStep: step-04c-aggregate
lastSaved: '2026-05-01'
storyId: '1.3'
storyKey: 1-3-session-management-sidebar
storyFile: '_bmad-output/implementation-artifacts/1-3-session-management-sidebar.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-1-3-session-management-sidebar.md'
generatedTestFiles:
  - SwiftWorkTests/ViewModels/SessionViewModelTests.swift
  - SwiftWorkTests/App/SessionManagementIntegrationTests.swift
inputDocuments:
  - '_bmad-output/implementation-artifacts/1-3-session-management-sidebar.md'
  - '_bmad-output/project-context.md'
---

# ATDD Checklist: Story 1.3 — 会话管理与 Sidebar

**Date:** 2026-05-01
**Author:** TEA Agent
**Primary Test Level:** Unit + Integration

---

## Story Summary

**As a** 用户
**I want** 在左侧 Sidebar 中创建、查看和切换会话
**So that** 我可以管理多个任务会话并在它们之间快速切换

---

## Acceptance Criteria

1. **AC#1:** 用户打开应用 → Sidebar 显示所有历史会话列表，按 updatedAt 降序排列（FR2）
2. **AC#2:** 用户点击 "+" 按钮 → 创建新会话（标题为"新会话"），Sidebar 列表立即更新，SwiftData 持久化（FR1, NFR19）
3. **AC#3:** 用户点击某个会话 → 主工作区切换到该会话，显示其事件历史，会话切换加载不超过 500ms（FR3, NFR5）

---

## Test Summary

| Category | File | Tests | Priority |
|----------|------|-------|----------|
| SessionViewModel (Unit) | `SwiftWorkTests/ViewModels/SessionViewModelTests.swift` | 22 | P0-P1 |
| Session Management (Integration) | `SwiftWorkTests/App/SessionManagementIntegrationTests.swift` | 10 | P0-P1 |
| **Total** | **2 files** | **32 tests** | |

---

## Acceptance Criteria Coverage

| AC | Description | Test Coverage | Priority |
|----|-------------|---------------|----------|
| #1 | Sidebar 显示所有会话，按 updatedAt 降序 | `SessionViewModelTests.testFetchSessionsSortedByUpdatedAt`, `SessionViewModelTests.testFetchSessionsEmpty`, `SessionManagementIntegrationTests.testSidebarViewInstantiation`, `SessionManagementIntegrationTests.testSessionRowViewInstantiation`, `SessionManagementIntegrationTests.testSessionOrderingAfterCRUDOperations` | P0-P1 |
| #2 | 创建新会话，Sidebar 更新，SwiftData 持久化 | `SessionViewModelTests.testCreateSessionAddsToList`, `SessionViewModelTests.testCreateSessionAutoSelects`, `SessionViewModelTests.testCreateSessionInsertsAtHead`, `SessionViewModelTests.testCreateSessionPersistsToSwiftData`, `SessionViewModelTests.testCreateSessionDefaultTitle`, `SessionManagementIntegrationTests.testSessionCreationEndToEnd`, `SessionManagementIntegrationTests.testMultipleSessionCreation` | P0-P1 |
| #3 | 切换会话，显示事件历史，< 500ms | `SessionViewModelTests.testSelectSessionUpdatesSelection`, `SessionViewModelTests.testSelectSessionDoesNotReloadList`, `SessionManagementIntegrationTests.testSessionSwitchingPreservesData`, `SessionManagementIntegrationTests.testContentViewHasSessionViewModel` | P0-P1 |
| Extra | 删除会话（级联删除、自动选中逻辑） | `SessionViewModelTests.testDeleteSessionRemovesFromList`, `SessionViewModelTests.testDeleteSessionCascadesEvents`, `SessionViewModelTests.testDeleteSelectedSessionAutoSelectsNearest`, `SessionViewModelTests.testDeleteLastSessionSetsSelectionNil`, `SessionViewModelTests.testDeleteNonSelectedSessionKeepsSelection`, `SessionManagementIntegrationTests.testCascadeDeleteRemovesAllEvents`, `SessionManagementIntegrationTests.testDeleteSessionDoesNotAffectOtherSessionEvents` | P0-P1 |
| Extra | 更新会话标题 + 重排序 | `SessionViewModelTests.testUpdateSessionTitle`, `SessionViewModelTests.testUpdateSessionTitleUpdatesTimestamp`, `SessionViewModelTests.testUpdateSessionTitleReSortsList`, `SessionViewModelTests.testUpdateSessionTitlePersistsToSwiftData` | P0-P1 |
| Extra | 未配置状态安全 + @Observable | `SessionViewModelTests.testUnconfiguredStateDoesNotCrash`, `SessionViewModelTests.testInitialState`, `SessionViewModelTests.testSessionViewModelIsObservable`, `SessionViewModelTests.testConfigureCallsFetchSessions` | P0-P1 |

---

## Test Levels

| Level | Count | Files |
|-------|-------|-------|
| Unit | 22 | SessionViewModelTests |
| Integration | 10 | SessionManagementIntegrationTests (SwiftData ModelContext, View instantiation) |

---

## Red-Phase Test Scaffolds Created

### SessionViewModelTests (22 tests)

**File:** `SwiftWorkTests/ViewModels/SessionViewModelTests.swift`

**AC#1 - Session List (Fetch + Sort):**
- `testFetchSessionsSortedByUpdatedAt` [P0] — sessions returned by updatedAt descending
- `testFetchSessionsEmpty` [P0] — empty store returns empty array

**AC#2 - Create Session:**
- `testCreateSessionAddsToList` [P0] — new session appears in sessions array
- `testCreateSessionAutoSelects` [P0] — new session is auto-selected
- `testCreateSessionInsertsAtHead` [P0] — inserted at index 0
- `testCreateSessionPersistsToSwiftData` [P0] — survives in SwiftData
- `testCreateSessionDefaultTitle` [P1] — title defaults to "新会话"

**AC#3 - Select Session:**
- `testSelectSessionUpdatesSelection` [P0] — selectedSession tracks selection
- `testSelectSessionDoesNotReloadList` [P1] — list count unchanged on select

**Delete Session:**
- `testDeleteSessionRemovesFromList` [P0] — removed from array
- `testDeleteSessionCascadesEvents` [P0] — associated Events deleted
- `testDeleteSelectedSessionAutoSelectsNearest` [P0] — auto-selects nearest
- `testDeleteLastSessionSetsSelectionNil` [P1] — nil when no sessions left
- `testDeleteNonSelectedSessionKeepsSelection` [P1] — selection unchanged

**Update Title:**
- `testUpdateSessionTitle` [P0] — title changed
- `testUpdateSessionTitleUpdatesTimestamp` [P0] — updatedAt refreshed
- `testUpdateSessionTitleReSortsList` [P0] — re-sorted by updatedAt
- `testUpdateSessionTitlePersistsToSwiftData` [P1] — persisted

**Configure & Safety:**
- `testConfigureCallsFetchSessions` [P0] — configure triggers fetch
- `testUnconfiguredStateDoesNotCrash` [P0] — nil modelContext safe
- `testInitialState` [P1] — clean initial state
- `testSessionViewModelIsObservable` [P0] — @Observable conformance
- `testFetchSessionsSetsErrorOnFailure` [P1] — error path exists

### SessionManagementIntegrationTests (10 tests)

**File:** `SwiftWorkTests/App/SessionManagementIntegrationTests.swift`

**View Instantiation:**
- `testSidebarViewInstantiation` [P0] — SidebarView(sessionViewModel:) compiles
- `testSessionRowViewInstantiation` [P0] — SessionRowView(session:) compiles
- `testContentViewHasSessionViewModel` [P1] — ContentView instantiable

**End-to-End Flow:**
- `testSessionCreationEndToEnd` [P0] — session persists across context recreation
- `testMultipleSessionCreation` [P1] — 3 sessions created and tracked
- `testSessionSwitchingPreservesData` [P0] — events survive session switching

**Cascade Delete:**
- `testCascadeDeleteRemovesAllEvents` [P0] — 5 events deleted with session
- `testDeleteSessionDoesNotAffectOtherSessionEvents` [P1] — sibling session untouched

**Ordering:**
- `testSessionOrderingAfterCRUDOperations` [P0] — correct order after create/update/delete

---

## Required data-testid Attributes

> Note: This is a SwiftUI/macOS project, not a web app. There are no `data-testid` attributes. View testing uses SwiftUI's `@testable` import and View instantiation verification.

---

## Implementation Checklist

### Task 1: Implement SessionViewModel

**File:** `SwiftWork/ViewModels/SessionViewModel.swift`

**Activate:** `SessionViewModelTests` (22 tests)

**Tasks to make tests pass:**

- [ ] Replace placeholder `struct SessionViewModel` with `@MainActor @Observable final class SessionViewModel`
- [ ] Add properties: `sessions: [Session]`, `selectedSession: Session?`, `isLoading: Bool`, `errorMessage: String?`
- [ ] Add private `modelContext: ModelContext?` stored property
- [ ] Implement `configure(modelContext:)` — stores context, calls `fetchSessions()`
- [ ] Implement `fetchSessions()` — `FetchDescriptor<Session>` sorted by `updatedAt` descending
- [ ] Implement `createSession()` — insert into SwiftData, prepend to array, auto-select
- [ ] Implement `selectSession(_:)` — update `selectedSession`
- [ ] Implement `deleteSession(_:)` — delete from SwiftData, remove from array, handle auto-selection
- [ ] Implement `updateSessionTitle(_:title:)` — update title + updatedAt, re-sort array
- [ ] Wrap SwiftData ops in `do/catch`, set `errorMessage` on failure
- [ ] Guard all operations with `guard let modelContext else { return }`
- [ ] Run tests: `swift test --filter SessionViewModelTests`
- [ ] All 22 tests pass (green phase)

### Task 2: Implement SidebarView

**File:** `SwiftWork/Views/Sidebar/SidebarView.swift`

**Activate:** `SessionManagementIntegrationTests.testSidebarViewInstantiation`

**Tasks to make tests pass:**

- [ ] Replace placeholder with `SidebarView(sessionViewModel:)` taking `SessionViewModel`
- [ ] Use `List(selection:)` bound to `sessionViewModel.selectedSession`
- [ ] ForEach over `sessionViewModel.sessions` with `SessionRowView`
- [ ] Add toolbar "+" button calling `sessionViewModel.createSession()`
- [ ] Add empty state view
- [ ] Run tests: `swift test --filter SessionManagementIntegrationTests`
- [ ] All integration tests pass (green phase)

### Task 3: Implement SessionRowView

**File:** `SwiftWork/Views/Sidebar/SessionRowView.swift`

**Activate:** `SessionManagementIntegrationTests.testSessionRowViewInstantiation`

**Tasks to make tests pass:**

- [ ] Replace placeholder with `SessionRowView(session:)` taking `Session`
- [ ] VStack: title (`.lineLimit(1)`) + relative time
- [ ] System colors for dark/light mode
- [ ] Run tests: `swift test --filter SessionManagementIntegrationTests`

### Task 4: Integrate into ContentView

**File:** `SwiftWork/App/ContentView.swift`

**Activate:** `SessionManagementIntegrationTests.testContentViewHasSessionViewModel`

**Tasks to make tests pass:**

- [ ] Add `@State private var sessionViewModel = SessionViewModel()`
- [ ] Replace `Text("Sidebar")` with `SidebarView(sessionViewModel: sessionViewModel)`
- [ ] Detail: show workspace or "选择或创建一个会话" placeholder
- [ ] Call `sessionViewModel.configure(modelContext:)` on onboarding completion
- [ ] Run tests: `swift test --filter SessionManagementIntegrationTests`

### Task 5: Add Date+Formatting extension

**File:** `SwiftWork/Utils/Extensions/Date+Formatting.swift` (NEW)

**Tasks:**

- [ ] Create extension with `relativeFormatted` computed property
- [ ] Use `RelativeDateTimeFormatter` with cached static instance

---

## Running Tests

```bash
# Run all tests for this story
swift test --filter SessionViewModelTests
swift test --filter SessionManagementIntegrationTests

# Run all project tests
swift test

# Run specific test
swift test --filter SessionViewModelTests.testCreateSessionAutoSelects
```

---

## Mock Strategy

- **SwiftData**: In-memory `ModelContainer` (`isStoredInMemoryOnly: true`) — no file I/O
- **No external dependencies**: SessionViewModel only depends on SwiftData `ModelContext`
- **Existing `TestDataFactory`**: Can be extended with session-related factories if needed

---

## Red-Green-Refactor Workflow

### RED Phase (Complete)

- All 32 tests written as red-phase scaffolds asserting EXPECTED behavior
- Tests will fail until SessionViewModel is implemented as `@MainActor @Observable final class`
- Integration tests will fail until SidebarView/SessionRowView accept correct parameters

### GREEN Phase (DEV Team - Next Steps)

1. Implement Task 1 (SessionViewModel) — makes 22 unit tests pass
2. Implement Task 2 (SidebarView) — makes integration tests pass
3. Implement Task 3 (SessionRowView) — makes integration tests pass
4. Implement Task 4 (ContentView integration) — makes integration tests pass
5. Implement Task 5 (Date+Formatting) — enables relative time display
6. Run `swift test` to verify all pass

### REFACTOR Phase

- Review for code quality, DRY, performance
- Ensure tests still pass after each refactor

---

## Notes

- This is a Swift/macOS project using XCTest (not Playwright/Jest). Test patterns follow XCTest conventions with `@testable import`.
- `Session` is a SwiftData `@Model` class with `@Relationship(deleteRule: .cascade)` already configured in Story 1-1.
- SessionViewModel must be `@MainActor @Observable final class` (not `ObservableObject`) per project rules.
- SidebarView uses `List(selection:)` with `Binding<Session.ID?>` pattern for macOS selection.
- NFR5 (session switch < 500ms) is not automated — verified via Instruments profiling.
- The `SidebarView(sessionViewModel:)` initializer signature is required by integration tests.
- The `SessionRowView(session:)` initializer signature is required by integration tests.

---

**Generated by BMad TEA Agent** — 2026-05-01
