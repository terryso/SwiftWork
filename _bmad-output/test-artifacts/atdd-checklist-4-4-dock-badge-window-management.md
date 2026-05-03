---
stepsCompleted: ['step-01-preflight-and-context', 'step-02-generation-mode', 'step-03-test-strategy', 'step-04-generate-tests', 'step-04c-aggregate', 'step-05-validate-and-complete']
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-05-03'
storyId: '4.4'
storyKey: '4-4-dock-badge-window-management'
storyFile: '_bmad-output/implementation-artifacts/4-4-dock-badge-window-management.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-4-4-dock-badge-window-management.md'
generatedTestFiles:
  - 'SwiftWorkTests/App/DockBadgeTests.swift'
  - 'SwiftWorkTests/App/WindowStateTests.swift'
---

# ATDD Checklist: Story 4.4 -- Dock Badge 与窗口管理

## TDD Red Phase (Current)

Red-phase test scaffolds generated. All tests **fail to compile** until implementation is added (TDD red phase).

- **Unit/Integration Tests:** 22 tests across 2 files
- **Framework:** XCTest (Swift)
- **Stack:** Backend (Swift/macOS native app)

## Acceptance Criteria Coverage

| AC | Description | Test File | Test Count | Priority |
|----|-------------|-----------|------------|----------|
| AC#1 | Dock 图标显示未读会话数 badge | `DockBadgeTests.swift` | 11 | P0/P1/P2 |
| AC#2 | 窗口位置和大小在重启后恢复 | `WindowStateTests.swift` | 9 | P0/P1/P2 |
| AC#3 | 全屏/分屏/Stage Manager 兼容性 | `WindowStateTests.swift` | 3 | P2 |

### AC#1: Dock Badge 未读会话计数

| Test | Description | Priority |
|------|-------------|----------|
| `testDockBadgeSetWhenUnreadCountPositive` | unreadSessionCount > 0 时设置 badgeLabel | P0 |
| `testDockBadgeClearedWhenUnreadCountZero` | unreadSessionCount == 0 时清空 badgeLabel | P0 |
| `testDockBadgeClearedWhenUnreadCountNegative` | 负数 count 清空 badge（边界条件） | P0 |
| `testMarkSessionAsUnreadIncrementsCount` | 标记会话为未读时递增计数 | P0 |
| `testMarkSameSessionUnreadTwiceNoDoubleCount` | 同一会话重复标记不重复计数 | P0 |
| `testSelectSessionClearsUnread` | 选中会话清除未读标记并递减计数 | P0 |
| `testClearAllUnreadResetsCount` | 应用回到前台时清除所有未读 | P1 |
| `testUnreadCountChangeTriggersBadgeUpdate` | unreadSessionCount 变更自动触发 badge 更新 | P1 |
| `testAgentBridgeOnResultCallbackFires` | AgentBridge.onResult 回调正确触发 | P1 |
| `testUnreadMarkPersistsToSwiftData` | hasUnreadResult 持久化到 SwiftData | P2 |
| `testInitialStateUnreadCountIsZero` | 初始状态 unreadSessionCount 为 0 | P1 |
| `testSessionHasUnreadResultDefaultsFalse` | Session.hasUnreadResult 默认 false | P1 |

### AC#2: 窗口状态持久化

| Test | Description | Priority |
|------|-------------|----------|
| `testWindowFrameRoundTrip` | saveWindowFrame/loadAppState 往返正确 | P0 |
| `testRestoredFrameNotZero` | 恢复的 NSRect 非 zero rect | P0 |
| `testFullscreenFramePreserved` | 全屏尺寸帧正确保存恢复 | P0 |
| `testWindowFrameOverwrite` | 最近保存覆盖先前保存 | P1 |
| `testWindowFrameSaveDoesNotAffectOtherState` | 窗口帧保存不影响其他状态 | P1 |
| `testNoSavedFrameReturnsNil` | 无保存数据时返回 nil | P0 |
| `testSplitViewFramePreserved` | 分屏小窗口帧正确保存恢复 | P1 |
| `testUnusualWindowPositionPreserved` | 多显示器离屏位置正确保存 | P1 |
| `testAllWindowRelatedStatePersistsTogether` | 所有窗口相关状态一起持久化 | P1 |

### AC#3: 全屏/分屏/Stage Manager 兼容性

| Test | Description | Priority |
|------|-------------|----------|
| `testInspectorVisibilityForLayoutAdaptation` | Inspector 可见性可切换以适配布局 | P2 |
| `testDebugPanelVisibilityForLayoutAdaptation` | Debug Panel 可见性可切换以适配布局 | P2 |

## Red Phase Verification

- [x] All tests reference unimplemented properties/methods (`unreadSessionCount`, `updateDockBadge()`, `markSessionAsUnread()`, `clearUnreadForSession()`, `clearAllUnread()`, `hasUnreadResult`)
- [x] Tests fail to compile without implementation (confirmed via `swift test`)
- [x] No placeholder assertions -- all tests assert specific expected behavior
- [x] All tests follow Given-When-Then format with clear comments
- [x] Tests are isolated -- each creates its own test data
- [x] Tests are deterministic -- no timing dependencies

## Implementation Tasks (GREEN Phase)

### Task 1: Dock Badge 未读会话计数

Files to modify:

1. **`SwiftWork/Models/SwiftData/Session.swift`**
   - Add `var hasUnreadResult: Bool = false`

2. **`SwiftWork/App/AppState.swift`**
   - Add `var unreadSessionCount: Int = 0`
   - Add `func updateDockBadge()` -- set `NSApplication.shared.dockTile.badgeLabel`
   - Add `func markSessionAsUnread(_ session: Session)` -- set `hasUnreadResult`, increment count
   - Add `func clearUnreadForSession(_ session: Session)` -- clear `hasUnreadResult`, decrement count
   - Add `func clearAllUnread()` -- clear all sessions' unread marks, reset count
   - Wire `unreadSessionCount` change to auto-call `updateDockBadge()`

3. **`SwiftWork/SDKIntegration/AgentBridge.swift`**
   - Wire `onResult` callback in ContentView to trigger `appState.markSessionAsUnread()`

4. **`SwiftWork/App/ContentView.swift`**
   - Connect AgentBridge `onResult` to AppState unread logic
   - Listen for `NSApplication.didBecomeActiveNotification` to clear all unread

5. **`SwiftWork/ViewModels/SessionViewModel.swift`**
   - In `selectSession()`, call `appState.clearUnreadForSession()`

### Task 2: 窗口状态持久化验证

- Already implemented in Story 4-3 via `AppStateManager`
- WindowStateTests verify the existing implementation

### Task 3: 全屏/分屏兼容性

- NavigationSplitView auto-handles fullscreen/split view
- If issues found, convert fixed `.frame(width:)` to responsive `min(300, availableWidth * 0.25)`

## Execution Commands

```bash
# Build only
swift build

# Run all tests
swift test

# Run specific test file
swift test --filter DockBadgeTests
swift test --filter WindowStateTests

# Run single test
swift test --filter testDockBadgeSetWhenUnreadCountPositive
```

## Generated Files

| File | Tests | Purpose |
|------|-------|---------|
| `SwiftWorkTests/App/DockBadgeTests.swift` | 12 | Dock Badge 未读计数 + onResult 集成 |
| `SwiftWorkTests/App/WindowStateTests.swift` | 10 | 窗口帧持久化 + 布局适配 |

## Knowledge Base References

- `data-factories.md` -- test data creation via `makeModelContext()` helper
- `test-quality.md` -- isolated, deterministic, atomic test design
- `test-levels-framework.md` -- unit + integration test level selection
- `test-healing-patterns.md` -- robust test patterns
- `test-priorities-matrix.md` -- P0/P1/P2 prioritization

## Next Steps

1. Implement `hasUnreadResult` on Session model
2. Extend AppState with dock badge methods
3. Wire AgentBridge onResult to AppState
4. Add foreground notification listener
5. Update selectSession to clear unread
6. Run `swift test` -- all 22 tests should pass
7. Verify no regression in existing 567+ tests
