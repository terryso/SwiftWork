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
storyId: '3.2'
storyKey: '3-2-permission-config-rules'
storyFile: '_bmad-output/implementation-artifacts/3-2-permission-config-rules.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-3-2-permission-config-rules.md'
generatedTestFiles:
  - SwiftWorkTests/SDKIntegration/PermissionHandlerConfigTests.swift
  - SwiftWorkTests/Views/Permission/PermissionRulesViewTests.swift
  - SwiftWorkTests/Views/Settings/SettingsViewIntegrationTests.swift
---

# ATDD Checklist: Story 3.2 - 权限配置与规则管理

## TDD Red Phase (Current)

**Phase**: RED
**Total Tests**: 24 (all will fail until implementation is complete)
**Execution Mode**: Sequential (backend/Swift project)

## Acceptance Criteria Coverage

### AC#1: PermissionRulesView 显示权限规则列表 (FR25)

| Test | Priority | File | Status |
|------|----------|------|--------|
| testPermissionRulesViewCompiles | P0 | PermissionRulesViewTests | RED |
| testPermissionRulesViewShowsRulesWhenNotEmpty | P0 | PermissionRulesViewTests | RED |
| testPermissionRulesViewEmptyState | P1 | PermissionRulesViewTests | RED |
| testRuleRowDisplaysCorrectInformation | P1 | PermissionRulesViewTests | RED |
| testToolTypeLabelMappings | P1 | PermissionRulesViewTests | RED |
| testRulesSortedByCreatedAtDescending | P1 | PermissionRulesViewTests | RED |
| testSettingsViewAcceptsPermissionHandler | P0 | SettingsViewIntegrationTests | RED |
| testSettingsViewIsNotStub | P0 | SettingsViewIntegrationTests | RED |

### AC#2: 规则删除，后续同类操作重新要求审批

| Test | Priority | File | Status |
|------|----------|------|--------|
| testDeleteRuleRemovesFromCacheAndContext | P0 | PermissionHandlerConfigTests | RED |
| testDeleteRuleBatchRemoval | P0 | PermissionHandlerConfigTests | RED |
| testDeleteRuleOnEmptyListDoesNotCrash | P1 | PermissionHandlerConfigTests | RED |
| testDeletedRuleRequiresReApproval | P1 | PermissionHandlerConfigTests | RED |
| testDeleteAllRulesLeavesHandlerFunctional | P2 | PermissionHandlerConfigTests | RED |
| testDeleteRuleRemovesFromSwiftData | P0 | PermissionRulesViewTests | RED |
| testBatchDeletionViaIndexSet | P0 | PermissionRulesViewTests | RED |

### AC#3: 全局权限模式切换，立即生效 (FR26)

| Test | Priority | File | Status |
|------|----------|------|--------|
| testGlobalModePersistedToAppConfiguration | P0 | PermissionHandlerConfigTests | RED |
| testGlobalModeRestoredOnSetModelContext | P0 | PermissionHandlerConfigTests | RED |
| testMultipleGlobalModeChangesPersistLatest | P1 | PermissionHandlerConfigTests | RED |
| testGlobalModeDoesNotPersistBeforeModelContextSet | P1 | PermissionHandlerConfigTests | RED |
| testPersistAutoApproveModeRestoresCorrectly | P1 | PermissionHandlerConfigTests | RED |
| testGlobalModeSwitchAffectsEvaluation | P0 | PermissionRulesViewTests | RED |
| testAllGlobalPermissionModesExist | P0 | PermissionRulesViewTests | RED |
| testGlobalModeSurvivesHandlerRecreation | P1 | PermissionRulesViewTests | RED |
| testGlobalModeChangeImmediateEffect | P2 | PermissionRulesViewTests | RED |
| testSettingsViewGlobalModeBinding | P1 | SettingsViewIntegrationTests | RED |
| testPermissionHandlerAccessibleFromContentView | P1 | SettingsViewIntegrationTests | RED |
| testSettingsViewDoesNotInterruptAgentExecution | P2 | SettingsViewIntegrationTests | RED |

## Priority Distribution

| Priority | Count |
|----------|-------|
| P0 | 12 |
| P1 | 9 |
| P2 | 3 |
| **Total** | **24** |

## Test Files Created

### 1. SwiftWorkTests/SDKIntegration/PermissionHandlerConfigTests.swift
- **Tests**: 10
- **Focus**: `deleteRule()`, `deleteRule(at:)`, `globalMode` persistence via AppConfiguration
- **Dependencies**: SwiftData in-memory container (PermissionRule + AppConfiguration)
- **Key methods tested**: `deleteRule(_:)`, `deleteRule(at:)`, `persistGlobalMode()` (via didSet), `setModelContext()` restore

### 2. SwiftWorkTests/Views/Permission/PermissionRulesViewTests.swift
- **Tests**: 11
- **Focus**: PermissionRulesView compilation, rule display, deletion, global mode picker
- **Dependencies**: SwiftData in-memory container, PermissionHandler
- **Key behaviors tested**: View instantiation, @Query rule fetching, empty state, sorting, tool type labels, mode switching

### 3. SwiftWorkTests/Views/Settings/SettingsViewIntegrationTests.swift
- **Tests**: 4
- **Focus**: SettingsView integration with PermissionHandler, ContentView flow
- **Dependencies**: SwiftData in-memory container, AgentBridge
- **Key behaviors tested**: SettingsView accepts PermissionHandler, agent execution not interrupted

## Implementation Requirements (for GREEN phase)

### PermissionHandler.swift additions:
1. **`deleteRule(_ rule: PermissionRule)`** -- Remove from cachedRules, delete from ModelContext, save
2. **`deleteRule(at indexSet: IndexSet)`** -- Batch deletion for SwiftUI List `onDelete`
3. **`persistGlobalMode()`** -- Private method: upsert AppConfiguration key "globalPermissionMode"
4. **`globalMode didSet`** -- Call `persistGlobalMode()` when modelContext is set
5. **`setModelContext()` update** -- Restore globalMode from AppConfiguration after reloadRules()

### New View files:
1. **PermissionRulesView.swift** -- `@Query` rules list + global mode Picker + delete callback
2. **SettingsView.swift** -- Rewrite from stub; embed PermissionRulesView + permission section

### Updated files:
1. **ContentView.swift** -- Add SettingsView opening mechanism (button or Cmd+,)

## Red-Green-Refactor Workflow

### RED (complete):
- Test scaffolds generated with assertions for expected behavior
- Tests will fail to compile until PermissionHandler methods and Views are implemented

### GREEN (next):
1. Add `deleteRule()` methods to PermissionHandler
2. Add `persistGlobalMode()` and `globalMode` didSet to PermissionHandler
3. Update `setModelContext()` to restore persisted globalMode
4. Create PermissionRulesView.swift
5. Rewrite SettingsView.swift with permissionHandler parameter
6. Update ContentView.swift to pass permissionHandler to SettingsView
7. Run `swift test` -- tests should now compile and pass

### REFACTOR:
- Extract SettingsPermissionSection if SettingsView exceeds 300 lines
- Ensure consistent error handling in deleteRule methods
- Verify no force unwraps in new code

## Execution Commands

```bash
# Run all story 3-2 tests
swift test --filter PermissionHandlerConfigTests
swift test --filter PermissionRulesViewTests
swift test --filter SettingsViewIntegrationTests

# Run all tests (check for regressions)
swift test

# Build only (verify compilation)
swift build
```

## Key Risks & Assumptions

1. **Assumption**: `PermissionRule` and `AppConfiguration` SwiftData models are unchanged from Story 3-1
2. **Assumption**: `PermissionHandler.toolTypeLabel()` static method already exists (verified in source)
3. **Risk**: SwiftData in-memory container behavior may differ slightly from persistent container for `@Query`
4. **Risk**: SettingsView init with `permissionHandler` parameter may require Observable pattern adjustments
5. **Assumption**: `AgentBridge.permissionHandler` is a public property (verified in source)

## Next Steps

1. Run `dev-story` workflow with story file `_bmad-output/implementation-artifacts/3-2-permission-config-rules.md`
2. Implement tasks 1-5 in the story
3. After each task, activate corresponding tests (remove skip/fix compilation)
4. Verify RED -> GREEN for each test batch
5. Run `swift test` to verify all 24 tests pass with no regressions
