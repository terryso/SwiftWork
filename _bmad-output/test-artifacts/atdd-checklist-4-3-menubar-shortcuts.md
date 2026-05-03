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
workflowType: testarch-atdd
storyId: '4.3'
storyKey: 4-3-menubar-shortcuts
storyFile: _bmad-output/implementation-artifacts/4-3-menubar-shortcuts.md
atddChecklistPath: _bmad-output/test-artifacts/atdd-checklist-4-3-menubar-shortcuts.md
generatedTestFiles:
  - SwiftWorkTests/App/MenuBarCommandsTests.swift
  - SwiftWorkTests/App/AppStateIntegrationTests.swift
inputDocuments:
  - _bmad-output/project-context.md
  - _bmad-output/implementation-artifacts/4-3-menubar-shortcuts.md
  - SwiftWork/App/SwiftWorkApp.swift
  - SwiftWork/App/ContentView.swift
  - SwiftWork/ViewModels/SessionViewModel.swift
  - SwiftWork/ViewModels/SettingsViewModel.swift
  - SwiftWorkTests/App/AppEntryTests.swift
  - SwiftWorkTests/Support/TestDataFactory.swift
---

# ATDD Checklist - Epic 4, Story 3: macOS Menu Bar & Keyboard Shortcuts

**Date:** 2026-05-03
**Author:** Nick
**Primary Test Level:** Unit + Integration (Backend/Swift)

---

## Story Summary

为 SwiftWork 添加标准 macOS 菜单栏和键盘快捷键，覆盖 File/Edit/View/Window/Help 五个标准菜单。用户通过 Cmd+N 新建会话、Cmd+W 关闭窗口、Cmd+, 打开设置、Cmd+I 切换 Inspector、Cmd+Shift+D 切换 Debug Panel。

**As a** macOS 用户
**I want** 通过标准菜单栏和键盘快捷键操作应用
**So that** 我可以高效地使用 SwiftWork 的常用功能

---

## Acceptance Criteria

1. **AC#1** 应用运行时显示标准 macOS 菜单结构：File/Edit/View/Window/Help
2. **AC#2** Cmd+N 创建新会话并切换到该会话
3. **AC#3** Cmd+W 关闭当前窗口
4. **AC#4** Cmd+, 打开设置页面

---

## Story Integration Metadata

- **Story ID:** `4.3`
- **Story Key:** `4-3-menubar-shortcuts`
- **Story File:** `_bmad-output/implementation-artifacts/4-3-menubar-shortcuts.md`
- **Checklist Path:** `_bmad-output/test-artifacts/atdd-checklist-4-3-menubar-shortcuts.md`
- **Generated Test Files:**
  - `SwiftWorkTests/App/MenuBarCommandsTests.swift`
  - `SwiftWorkTests/App/AppStateIntegrationTests.swift`

---

## Red-Phase Test Scaffolds Created

### Unit Tests - MenuBarCommandsTests.swift (10 tests)

**File:** `SwiftWorkTests/App/MenuBarCommandsTests.swift` (~210 lines)

- [P0] **testCmdNCreatesNewSession** - RED - `cannot find 'AppState' in scope`
  - Verifies: AC#2 - Cmd+N invokes createSession() and sessions count increases

- [P0] **testCmdNSelectsNewlyCreatedSession** - RED - `cannot find 'AppState' in scope`
  - Verifies: AC#2 - Cmd+N auto-selects the newly created session

- [P0] **testCmdCommaOpensSettings** - RED - `cannot find 'AppState' in scope`
  - Verifies: AC#4 - Cmd+, sets isSettingsPresented to true

- [P0] **testSettingsCanBeDismissedAfterOpening** - RED - `cannot find 'AppState' in scope`
  - Verifies: AC#4 - Settings sheet can be dismissed after opening

- [P1] **testCmdITogglesInspectorVisible** - RED - `cannot find 'AppState' in scope`
  - Verifies: AC#1 - Cmd+I toggles isInspectorVisible from false to true

- [P1] **testCmdITogglesInspectorOff** - RED - `cannot find 'AppState' in scope`
  - Verifies: AC#1 - Cmd+I toggles isInspectorVisible back to false

- [P1] **testCmdShiftDTogglesDebugPanelVisible** - RED - `cannot find 'AppState' in scope`
  - Verifies: AC#1 - Cmd+Shift+D toggles isDebugPanelVisible from false to true

- [P1] **testCmdShiftDTogglesDebugPanelOff** - RED - `cannot find 'AppState' in scope`
  - Verifies: AC#1 - Cmd+Shift+D toggles isDebugPanelVisible back to false

- [P2] **testSwiftWorkAppUsesWindowGroup** - RED - (compiles, runtime check)
  - Verifies: AC#3 - SwiftWorkApp uses WindowGroup for Cmd+W support

- [P1] **testAppStateExposesRequiredMenuCommandState** - RED - `cannot find 'AppState' in scope`
  - Verifies: AC#1 - AppState exposes all required shared state for menu commands

- [P1] **testAppStateDefaultValues** - RED - `cannot find 'AppState' in scope`
  - Verifies: AC#1 - AppState initial values are correct for menu commands

### Integration Tests - AppStateIntegrationTests.swift (8 tests)

**File:** `SwiftWorkTests/App/AppStateIntegrationTests.swift` (~175 lines)

- [P0] **testAppStateConfigurationWithModelContext** - RED - `cannot find 'AppState' in scope`
  - Verifies: AppState can be created and configured with ModelContext

- [P0] **testSharedStateConsistencyAcrossReaders** - RED - `cannot find 'AppState' in scope`
  - Verifies: Multiple components reading from same AppState see consistent state

- [P0] **testMenuCommandStateChangesAreObservable** - RED - `cannot find 'AppState' in scope`
  - Verifies: Menu command state changes are observable by SwiftUI views

- [P1] **testInspectorVisibilityPersistedViaAppStateManager** - RED - `cannot find 'AppState' in scope`
  - Verifies: Inspector visibility state can be persisted via AppStateManager

- [P1] **testDebugPanelVisibilityPersistedViaAppStateManager** - RED - `cannot find 'AppState' in scope`
  - Verifies: Debug Panel visibility state can be persisted via AppStateManager

- [P1] **testAppStateProvidesContentViewEquivalentState** - RED - `cannot find 'AppState' in scope`
  - Verifies: AppState holds the same state types that ContentView previously held

- [P1] **testCreateSessionAndPersistSelection** - RED - `cannot find 'AppState' in scope`
  - Verifies: AppState can be used to create session and persist selection

---

## Acceptance Criteria Coverage

| AC | Description | Tests | Status |
|---|---|---|---|
| AC#1 | Standard macOS menu structure | testAppStateExposesRequiredMenuCommandState, testAppStateDefaultValues, testCmdIToggles*, testCmdShiftDToggles* | RED |
| AC#2 | Cmd+N creates new session | testCmdNCreatesNewSession, testCmdNSelectsNewlyCreatedSession, testSharedStateConsistencyAcrossReaders, testCreateSessionAndPersistSelection | RED |
| AC#3 | Cmd+W closes window | testSwiftWorkAppUsesWindowGroup | RED |
| AC#4 | Cmd+, opens settings | testCmdCommaOpensSettings, testSettingsCanBeDismissedAfterOpening | RED |

---

## Implementation Checklist

### Task 1: Create AppState.swift (makes most tests pass)

**File:** `SwiftWork/App/AppState.swift`

**Tasks to make tests pass:**

- [ ] Create `@MainActor @Observable final class AppState`
- [ ] Add `let sessionViewModel = SessionViewModel()`
- [ ] Add `let settingsViewModel = SettingsViewModel()`
- [ ] Add `var isSettingsPresented = false`
- [ ] Add `var isInspectorVisible = false`
- [ ] Add `var isDebugPanelVisible = false`
- [ ] Run tests: `xcodebuild test -project SwiftWork.xcodeproj -scheme SwiftWork -destination 'platform=macOS' -only-testing:SwiftWorkTests/MenuBarCommandsTests -only-testing:SwiftWorkTests/AppStateIntegrationTests`

### Task 2: Update SwiftWorkApp.swift (menu commands)

**File:** `SwiftWork/App/SwiftWorkApp.swift`

**Tasks:**

- [ ] Add `@State private var appState = AppState()`
- [ ] Add `.commands { ... }` modifier with CommandGroup registrations
- [ ] Add Cmd+N binding to `appState.sessionViewModel.createSession()`
- [ ] Add Cmd+, binding to `appState.isSettingsPresented = true`
- [ ] Add Cmd+I binding to `appState.isInspectorVisible.toggle()`
- [ ] Add Cmd+Shift+D binding to `appState.isDebugPanelVisible.toggle()`

### Task 3: Update ContentView.swift (state migration)

**File:** `SwiftWork/App/ContentView.swift`

**Tasks:**

- [ ] Add `@Environment(AppState.self) private var appState`
- [ ] Remove `@State` for shared properties, read from `appState`
- [ ] Keep `@State` for local UI state (hasCompletedOnboarding, mainWindow, etc.)

### Task 4: Update AppEntryTests.swift

**File:** `SwiftWorkTests/App/AppEntryTests.swift`

**Tasks:**

- [ ] Add test verifying SwiftWorkApp body contains `Commands` builder

---

## Running Tests

```bash
# Run all ATDD tests for this story
xcodebuild test -project SwiftWork.xcodeproj -scheme SwiftWork -destination 'platform=macOS' \
  -only-testing:SwiftWorkTests/MenuBarCommandsTests \
  -only-testing:SwiftWorkTests/AppStateIntegrationTests

# Run all tests (verify no regression)
xcodebuild test -project SwiftWork.xcodeproj -scheme SwiftWork -destination 'platform=macOS'

# Run specific test class
xcodebuild test -project SwiftWork.xcodeproj -scheme SwiftWork -destination 'platform=macOS' \
  -only-testing:SwiftWorkTests/MenuBarCommandsTests/testCmdNCreatesNewSession
```

---

## Red-Green-Refactor Workflow

### RED Phase (Complete)

**TEA Agent Responsibilities:**

- [x] All tests written as red-phase scaffolds
- [x] Tests fail at compile time with `cannot find 'AppState' in scope`
- [x] 18 total test cases covering all 4 acceptance criteria
- [x] Priority assignments: P0 (6), P1 (10), P2 (1), gap (1)
- [x] Implementation checklist created
- [x] Xcode project updated with new test file references

**Verification:**

- All generated tests fail to compile (expected -- `AppState` class does not exist yet)
- Build command: `xcodebuild build-for-testing` produces 16 compilation errors
- All errors are `cannot find 'AppState' in scope` -- the exact type to be implemented

### GREEN Phase (DEV Team - Next Steps)

1. Create `SwiftWork/App/AppState.swift` with `@MainActor @Observable final class AppState`
2. Run tests to verify they now compile and pass
3. Update `SwiftWorkApp.swift` to register menu commands using AppState
4. Update `ContentView.swift` to read shared state from AppState via `@Environment`
5. Run full test suite to verify no regression (currently 723+ tests)

### REFACTOR Phase

1. Verify all tests pass
2. Ensure ContentView state migration is complete
3. Clean up any unused `@State` declarations
4. Run full test suite again

---

## Test Execution Evidence

### RED Verification

**Command:** `xcodebuild build-for-testing -project SwiftWork.xcodeproj -scheme SwiftWork -destination 'platform=macOS'`

**Results:**

```
SwiftWorkTests/App/MenuBarCommandsTests.swift:24:24: error: cannot find 'AppState' in scope
SwiftWorkTests/App/MenuBarCommandsTests.swift:48:24: error: cannot find 'AppState' in scope
... (16 errors total across 2 files)
** TEST BUILD FAILED **
```

**Summary:**

- Total tests: 18 (across 2 test classes)
- Compilation errors: 16 (all `cannot find 'AppState' in scope`)
- Status: RED-phase scaffolds verified -- all tests fail because `AppState` type doesn't exist

**Expected Failure Messages:**
- All failures: `cannot find 'AppState' in scope` -- implementation of `AppState` class is the prerequisite for all tests

---

## Pre-existing Issues Fixed

- Removed duplicate `SettingsViewModel4_2Tests.swift` reference from `SwiftWorkTests/Views/Settings/` group in Xcode project (file lives in `SwiftWorkTests/ViewModels/`)

---

## Notes

- Tests verify the **behavior** of menu commands through the shared `AppState` object, not through SwiftUI's Command system directly (which is not testable via XCTest)
- `Cmd+W` is auto-provided by SwiftUI WindowGroup and only has a structural verification test
- The `AppState` class is the key architectural change -- tests verify its API contract before implementation
- All tests use in-memory `ModelContainer` for SwiftData isolation

---

**Generated by BMad TEA Agent** - 2026-05-03
