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
storyId: '1.6'
storyKey: 1-6-app-state-restore
storyFile: '_bmad-output/implementation-artifacts/1-6-app-state-restore.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-1-6-app-state-restore.md'
generatedTestFiles:
  - SwiftWorkTests/Services/AppStateManagerTests.swift
  - SwiftWorkTests/App/AppStateRestoreIntegrationTests.swift
  - SwiftWorkTests/Utils/WindowAccessorTests.swift
inputDocuments:
  - '_bmad-output/implementation-artifacts/1-6-app-state-restore.md'
  - '_bmad-output/project-context.md'
  - '_bmad-output/implementation-artifacts/1-5-timeline-event-stream.md'
  - 'SwiftWork/ViewModels/SessionViewModel.swift'
  - 'SwiftWork/ViewModels/SettingsViewModel.swift'
  - 'SwiftWork/App/ContentView.swift'
  - 'SwiftWork/Models/SwiftData/AppConfiguration.swift'
---

# ATDD Checklist: Story 1.6 — 应用状态恢复

**Date:** 2026-05-01
**Author:** TEA Agent (Master Test Architect)
**Primary Test Level:** Unit + Integration (Service + ViewModel)
**Detected Stack:** backend (Swift/XCTest)

---

## Story Summary

**As a** 用户
**I want** 应用重启后恢复上次的会话状态和窗口布局
**So that** 我不需要每次重新选择会话和调整窗口

---

## Acceptance Criteria

1. **AC#1:** 用户正在使用某个会话时退出并重新打开应用，自动选中上次的活跃会话，Sidebar 高亮该会话（FR6），窗口位置、大小与上次关闭时一致（NFR21），Inspector Panel 的展开/折叠状态保持（NFR21）
2. **AC#2:** 应用异常退出后重新打开，恢复至最近的会话状态（NFR14），已持久化的事件历史完整保留

---

## Test Summary

| Category | File | Tests | Priority |
|----------|------|-------|----------|
| AppStateManager Unit Tests | `SwiftWorkTests/Services/AppStateManagerTests.swift` | 14 | P0-P1 |
| AppStateRestore Integration Tests | `SwiftWorkTests/App/AppStateRestoreIntegrationTests.swift` | 8 | P0 |
| WindowAccessor Unit Tests | `SwiftWorkTests/Utils/WindowAccessorTests.swift` | 4 | P0-P1 |
| **Total** | **3 files** | **26 tests** | |

---

## Acceptance Criteria Coverage

| AC | Description | Test Coverage | Priority |
|----|-------------|---------------|----------|
| #1 | 自动选中上次活跃会话 | `AppStateManagerTests.testSaveAndLoadLastActiveSessionID`, `AppStateManagerTests.testLoadAppStateReturnsSavedValues`, `AppStateRestoreIntegrationTests.testRestoreSelectedSessionAfterRestart`, `AppStateRestoreIntegrationTests.testSelectedSessionMatchesPersistedID` | P0 |
| #1 | 窗口位置和大小恢复 | `AppStateManagerTests.testSaveAndLoadWindowFrame`, `AppStateManagerTests.testNSRectSerializationRoundTrip`, `WindowAccessorTests.testNSRectFromStringRoundTrip`, `WindowAccessorTests.testNSStringFromRectProducesValidString` | P0 |
| #1 | Inspector Panel 状态保持 | `AppStateManagerTests.testSaveAndLoadInspectorVisibility`, `AppStateManagerTests.testInspectorVisibilityPersistedOnToggle` | P0 |
| #2 | 异常退出后恢复最近会话状态 | `AppStateRestoreIntegrationTests.testRestoreAfterSimulatedCrash`, `AppStateRestoreIntegrationTests.testEventsPreservedAfterCrash` | P0 |
| #2 | 已删除会话回退逻辑 | `AppStateManagerTests.testDeletedSessionFallbackToFirst`, `AppStateRestoreIntegrationTests.testFallbackToFirstSessionWhenSavedDeleted` | P0 |
| #1/#2 | 首次启动默认值 | `AppStateManagerTests.testLoadAppStateReturnsDefaultsWhenEmpty`, `AppStateManagerTests.testFirstLaunchReturnsNilSessionID` | P1 |
| #1 | 覆盖写入 | `AppStateManagerTests.testOverwriteExistingValue` | P1 |

---

## Test Levels

| Level | Count | Files |
|-------|-------|-------|
| Unit (Service) | 14 | AppStateManagerTests |
| Integration (App flow) | 8 | AppStateRestoreIntegrationTests |
| Unit (Utility) | 4 | WindowAccessorTests |

---

## Red-Phase Test Scaffolds Created

### AppStateManagerTests (14 tests)

**File:** `SwiftWorkTests/Services/AppStateManagerTests.swift`

**AC#1 — Last Active Session ID:**
- `testSaveAndLoadLastActiveSessionID` [P0] — save session UUID then load returns same value
- `testLoadAppStateReturnsSavedValues` [P0] — loadAppState populates all cached properties
- `testSaveLastActiveSessionIDNil` [P1] — saving nil clears the stored value

**AC#1 — Window Frame:**
- `testSaveAndLoadWindowFrame` [P0] — save NSRect then load returns same rect
- `testNSRectSerializationRoundTrip` [P0] — NSStringFromRect/NSRectFromString round-trip preserves origin and size
- `testWindowFrameDefaultValue` [P1] — no saved frame returns nil

**AC#1 — Inspector Visibility:**
- `testSaveAndLoadInspectorVisibility` [P0] — save true then load returns true
- `testInspectorVisibilityPersistedOnToggle` [P0] — toggle from false to true persists
- `testInspectorVisibilityDefaultValue` [P1] — no saved value returns false

**AC#2 — Edge Cases:**
- `testLoadAppStateReturnsDefaultsWhenEmpty` [P1] — fresh install returns nil/false defaults
- `testFirstLaunchReturnsNilSessionID` [P1] — no saved session ID returns nil
- `testDeletedSessionFallbackToFirst` [P0] — saved ID references deleted session, restore falls back
- `testOverwriteExistingValue` [P1] — second save overwrites first value

**Configuration:**
- `testConfigureSetsModelContext` [P0] — configure stores modelContext for subsequent operations

### AppStateRestoreIntegrationTests (8 tests)

**File:** `SwiftWorkTests/App/AppStateRestoreIntegrationTests.swift`

**AC#1 — Full Restore Flow:**
- `testRestoreSelectedSessionAfterRestart` [P0] — simulate app restart: save state -> reload -> session selected
- `testSelectedSessionMatchesPersistedID` [P0] — selected session ID matches lastActiveSessionID
- `testRestoreWindowFrameAfterRestart` [P0] — window frame persisted and restored correctly
- `testRestoreInspectorStateAfterRestart` [P0] — inspector visibility persisted and restored

**AC#2 — Crash Recovery:**
- `testRestoreAfterSimulatedCrash` [P0] — crash mid-session, restart restores to last saved state
- `testEventsPreservedAfterCrash` [P0] — events persisted before crash survive restart

**AC#2 — Fallback:**
- `testFallbackToFirstSessionWhenSavedDeleted` [P0] — saved session was deleted, falls back to sessions.first
- `testEmptySessionsNoCrashOnRestore` [P0] — no sessions exist, restore does not crash

### WindowAccessorTests (4 tests)

**File:** `SwiftWorkTests/Utils/WindowAccessorTests.swift`

**AC#1 — NSRect Serialization:**
- `testNSRectFromStringRoundTrip` [P0] — NSStringFromRect -> NSRectFromString preserves values
- `testNSStringFromRectProducesValidString` [P0] — serialized string is non-empty and parseable
- `testNSRectFromStringHandlesEmptyString` [P1] — empty string returns zero rect
- `testNSRectSerializationPreservesOriginAndSize` [P0] — origin.x, origin.y, width, height all preserved

---

## Implementation Checklist

### Task 1: Create AppStateManager Service

**File:** `SwiftWork/Services/AppStateManager.swift` (NEW)

**Activate:** `AppStateManagerTests` (14 tests)

**Tasks to make tests pass:**

- [ ] Create `AppState` struct or inline properties on AppStateManager
- [ ] Implement `@MainActor @Observable final class AppStateManager`
- [ ] Define key constants: `appState.lastActiveSessionID`, `appState.windowFrame`, `appState.inspectorVisible`
- [ ] Implement `configure(modelContext:)` to store ModelContext
- [ ] Implement `loadAppState()` — read all 3 keys from AppConfiguration
- [ ] Implement `saveLastActiveSessionID(_:)` — write UUID to AppConfiguration
- [ ] Implement `saveWindowFrame(_:)` — serialize NSRect to String, write to AppConfiguration
- [ ] Implement `saveInspectorVisibility(_:)` — write Bool to AppConfiguration
- [ ] Implement `saveValue(_:forKey:)` and `loadValue(forKey:)` — generic AppConfiguration CRUD
- [ ] Implement UUID/Data helpers: `loadUUID(key:)`, `loadBool(key:)`, `loadNSRect(key:)`
- [ ] Run tests: `swift test --filter AppStateManagerTests`

### Task 2: Integrate AppStateManager into SessionViewModel

**File:** `SwiftWork/ViewModels/SessionViewModel.swift` (MODIFY)

**Activate:** `AppStateRestoreIntegrationTests` (partial)

**Tasks to make tests pass:**

- [ ] Add `appStateManager` property to SessionViewModel
- [ ] In `configure(modelContext:)`, call `appStateManager.loadAppState()` and restore `selectedSession`
- [ ] In `selectSession(_:)`, call `appStateManager.saveLastActiveSessionID(session.id)`
- [ ] Handle deleted session fallback: if `lastActiveSessionID` not in sessions, use `sessions.first`
- [ ] Run tests: `swift test --filter AppStateRestoreIntegrationTests`

### Task 3: Create WindowAccessor Utility

**File:** `SwiftWork/Utils/WindowAccessor.swift` (NEW)

**Activate:** `WindowAccessorTests` (4 tests)

**Tasks to make tests pass:**

- [ ] Create `WindowAccessor: NSViewRepresentable` struct
- [ ] Implement `makeNSView` and `updateNSView` with `onWindowUpdate` callback
- [ ] Verify NSRect serialization functions work correctly
- [ ] Run tests: `swift test --filter WindowAccessorTests`

### Task 4: Integrate into ContentView and SwiftWorkApp

**Files:** `SwiftWork/App/ContentView.swift` (MODIFY), `SwiftWork/App/SwiftWorkApp.swift` (MODIFY)

**Activate:** `AppStateRestoreIntegrationTests` (remaining)

**Tasks to make tests pass:**

- [ ] Add `@State private var appStateManager = AppStateManager()` to ContentView
- [ ] In `.task`, configure appStateManager and load app state
- [ ] Restore window frame via NSWindow.setFrame after load
- [ ] Restore inspector visibility state
- [ ] Add `.defaultSize(width: 1200, height: 800)` to SwiftWorkApp WindowGroup
- [ ] Monitor window move/resize notifications with throttle
- [ ] Monitor NSApplication.willTerminateNotification for final state save
- [ ] Run tests: `swift test --filter AppStateRestoreIntegrationTests`

### Task 5: Update Constants

**File:** `SwiftWork/Utils/Constants.swift` (MODIFY)

**Tasks:**

- [ ] Add AppState key constants to Constants enum
- [ ] Run: `swift test`

---

## Running Tests

```bash
# Run all tests for this story
swift test --filter AppStateManagerTests
swift test --filter AppStateRestoreIntegrationTests
swift test --filter WindowAccessorTests

# Run all project tests
swift test

# Run specific test
swift test --filter AppStateManagerTests/testSaveAndLoadLastActiveSessionID
```

---

## Red-Green-Refactor Workflow

### RED Phase (Complete)

- All 26 tests written as red-phase scaffolds asserting EXPECTED behavior
- Tests will fail until:
  - AppStateManager service created with AppConfiguration KV CRUD
  - SessionViewModel enhanced with state restore on configure
  - WindowAccessor NSViewRepresentable utility created
  - ContentView integrates AppStateManager lifecycle
  - SwiftWorkApp defaultSize set

### GREEN Phase (DEV Team - Next Steps)

1. Implement Task 1 (AppStateManager) — makes 14 unit tests pass
2. Implement Task 2 (SessionViewModel integration) — makes partial integration tests pass
3. Implement Task 3 (WindowAccessor) — makes 4 utility tests pass
4. Implement Task 4 (ContentView + SwiftWorkApp integration) — makes remaining integration tests pass
5. Implement Task 5 (Constants) — supporting changes
6. Run `swift test` to verify all tests pass

### REFACTOR Phase

- Review AppStateManager for single-responsibility (state persistence only, no UI logic)
- Ensure no regression in existing tests
- Verify AppStateManager conforms to project architecture (Services layer, no View dependencies)

---

## Notes

- This is a Swift/SwiftUI/macOS project using XCTest. No Playwright/Jest/browser testing.
- AppStateManager uses AppConfiguration KV model (already proven in SettingsViewModel) for persistence
- NSRect serialization uses native `NSStringFromRect`/`NSRectFromString` — stable macOS API
- WindowAccessor uses NSViewRepresentable to bridge AppKit NSWindow access in SwiftUI
- Story 1-6 is the final story in Epic 1, completing the SDK->UI closed loop
- Window frame persistence uses throttled saves (500ms) to avoid frequent SwiftData writes
- Inspector state is persisted even though Inspector content is not yet implemented (Story 3-4)
- The `@Observable` pattern (not ObservableObject) must be followed for AppStateManager

---

**Generated by BMad TEA Agent** — 2026-05-01
