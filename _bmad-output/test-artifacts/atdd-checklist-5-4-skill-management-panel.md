---
stepsCompleted:
  - step-01-preflight-and-context
  - step-02-generation-mode
  - step-03-test-strategy
  - step-04-generate-tests
  - step-04c-aggregate
  - step-05-validate-and-complete
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-05-05'
storyId: '5.4'
storyKey: '5-4-skill-management-panel'
storyFile: '_bmad-output/implementation-artifacts/5-4-skill-management-panel.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-5-4-skill-management-panel.md'
generatedTestFiles:
  - SwiftWorkTests/Views/Settings/SkillSourceGroupingTests.swift
  - SwiftWorkTests/Views/Settings/SkillsSettingsViewTests.swift
---

# ATDD Checklist: Story 5.4 -- Skill Management Panel

## Story Summary

As a user, I want to view all discovered skills in the settings panel so that I can understand which skills are available, their sources, and descriptions.

## Acceptance Criteria Coverage

| AC | Description | Test Level | Priority | Test File | Status |
|----|-------------|------------|----------|-----------|--------|
| AC#1 | Settings new Skills tab (3 tabs: General/Permissions/Skills) | Integration | P0 | SkillsSettingsViewTests | RED |
| AC#2 | Skill list grouped by source (Built-in/Project/User) | Unit | P0 | SkillSourceGroupingTests, SkillsSettingsViewTests | RED |
| AC#3 | Skill detail expand/collapse | Component | P0 | SkillsSettingsViewTests | RED |
| AC#4 | Open in Finder button for filesystem skills | Component | P0 | SkillsSettingsViewTests | RED |

## Test Strategy

**Detected Stack:** Native macOS (SwiftUI + XCTest)

Since this is a Swift/SwiftUI native app (not a web frontend), the test strategy differs from the default Playwright-based ATDD:

- **Unit tests**: `SkillSource.from(_:)` pure-function grouping logic (AC#2)
- **Integration tests**: SettingsView constructor acceptance, tab structure, AgentBridge data flow (AC#1, AC#2, AC#4)
- **Component tests**: SkillListItemView rendering states (AC#3, AC#4)
- **Manual verification**: Tab switching, expand/collapse interaction, Open in Finder button behavior

### Why XCTest instead of Playwright

This project uses SwiftUI with XCTest -- there is no web frontend or Playwright configuration. Tests use `@testable import SwiftWork` and direct Swift type assertions. SwiftUI View tests verify compilability and constructor signatures rather than DOM rendering.

## Red-Phase Test Scaffolds

### Unit Tests (SkillSourceGroupingTests.swift)

| # | Test | AC | Priority | Expected Failure |
|---|------|----|----------|-----------------|
| 1 | testSkillSourceBuiltInWhenBaseDirIsNil | AC#2 | P0 | SkillSource type does not exist yet |
| 2 | testSkillSourceProjectWhenBaseDirUnderCWD | AC#2 | P0 | SkillSource type does not exist yet |
| 3 | testSkillSourceUserWhenBaseDirOutsideCWD | AC#2 | P0 | SkillSource type does not exist yet |
| 4 | testSkillSourceUserWhenBaseDirInHomeDirectory | AC#2 | P1 | SkillSource type does not exist yet |
| 5 | testAllBuiltInSkillsClassifiedAsBuiltIn | AC#2 | P1 | SkillSource type does not exist yet |
| 6 | testGroupingMixedSkills | AC#2 | P1 | SkillSource type does not exist yet |
| 7 | testSkillSourceWhenBaseDirEqualsCWD | AC#2 | P2 | SkillSource type does not exist yet |
| 8 | testSkillSourceWhenBaseDirHasSimilarPrefixButDifferentPath | AC#2 | P2 | SkillSource type does not exist yet |

**Total: 8 unit tests**

### Integration/Component Tests (SkillsSettingsViewTests.swift)

| # | Test | AC | Priority | Expected Failure |
|---|------|----|----------|-----------------|
| 1 | testSettingsViewAcceptsAgentBridge | AC#1 | P0 | SettingsView.init(...) does not have agentBridge param |
| 2 | testSettingsViewHasThreeTabs | AC#1 | P0 | SettingsView.init(...) does not have agentBridge param |
| 3 | testSettingsViewBackwardCompatTwoParamInit | AC#1 | P1 | Compile (should pass -- regression guard) |
| 4 | testSettingsViewBackwardCompatSingleParamInit | AC#1 | P1 | Compile (should pass -- regression guard) |
| 5 | testSkillsListViewAcceptsSkills | AC#2 | P0 | SkillsListView type does not exist yet |
| 6 | testSkillsListViewHandlesEmptySkills | AC#2 | P0 | SkillsListView type does not exist yet |
| 7 | testSkillsListViewGroupingBySource | AC#2 | P1 | SkillSource type does not exist yet |
| 8 | testSkillListItemViewAcceptsSkill | AC#3 | P0 | SkillListItemView type does not exist yet |
| 9 | testSkillListItemViewExpandedState | AC#3 | P0 | SkillListItemView type does not exist yet |
| 10 | testSkillListItemViewWithNoAliases | AC#3 | P1 | SkillListItemView type does not exist yet |
| 11 | testSkillListItemViewWithMinimalSkill | AC#3 | P1 | SkillListItemView type does not exist yet |
| 12 | testSkillWithBaseDirHasValidURL | AC#4 | P0 | Compile (may pass -- uses existing Skill.baseDir) |
| 13 | testBuiltInSkillHasNoBaseDir | AC#4 | P0 | Compile (should pass -- BuiltInSkills.commit.baseDir is nil) |
| 14 | testBuiltInSkillsDoNotShowOpenInFinder | AC#4 | P1 | SkillSource type does not exist yet |
| 15 | testAgentBridgeExposesAllRegisteredSkills | AC#2 | P0 | AgentBridge.allRegisteredSkills does not exist yet |
| 16 | testAllRegisteredSkillsIncludesNonUserInvocable | AC#2 | P1 | AgentBridge.allRegisteredSkills does not exist yet |
| 17 | testGeneralTabStillWorksAfterSkillsTab | Regression | P0 | Compile (should pass if SettingsView init unchanged) |
| 18 | testPermissionsTabStillWorksAfterSkillsTab | Regression | P0 | Compile (should pass if SettingsView init unchanged) |

**Total: 18 integration/component tests**

## Summary

| Metric | Value |
|--------|-------|
| TDD Phase | RED |
| Total Tests | 26 |
| Unit Tests | 8 |
| Integration/Component Tests | 18 |
| Expected Compile Failures | ~16 (new types not yet implemented) |
| Expected Runtime Failures | ~0 (pure logic tests only fail if logic is wrong) |
| Acceptance Criteria Covered | AC#1, AC#2, AC#3, AC#4 (all 4) |
| Priority P0 Tests | 12 |
| Priority P1 Tests | 10 |
| Priority P2 Tests | 2 |
| Regression Tests | 2 |

## Implementation Tasks (Red-Green-Refactor)

### Task 1: Create SkillSource enum (enables AC#2 tests)

```swift
// In SwiftWork/Views/Settings/SkillsListView.swift or Models/UI/SkillSource.swift
enum SkillSource: Equatable {
    case builtIn
    case project
    case user

    static func from(_ skill: Skill) -> SkillSource {
        guard let baseDir = skill.baseDir else { return .builtIn }
        let cwd = FileManager.default.currentDirectoryPath
        return baseDir.hasPrefix(cwd + "/") || baseDir == cwd ? .project : .user
    }
}
```

### Task 2: Add allRegisteredSkills to AgentBridge (enables AC#2 data access)

```swift
// In AgentBridge.swift, add after discoveredSkills:
var allRegisteredSkills: [Skill] {
    skillRegistry?.allSkills ?? []
}
```

### Task 3: Update SettingsView (enables AC#1 tests)

- Add `SettingsTab.skills` case
- Add `agentBridge` parameter to init
- Add `case .skills` branch in `activeTabContent`
- Update ContentView.swift to pass agentBridge

### Task 4: Create SkillsListView (enables AC#2, #3, #4 tests)

- Accept `[Skill]` parameter
- Group by `SkillSource`
- Render Section per group
- Create SkillListItemView for expand/collapse

### Task 5: Regression verification

- Run all existing tests to confirm no breakage
- Verify backward-compatible SettingsView inits still work

## Red-Green-Refactor Workflow

1. **RED** (current): All 26 tests written, most will fail at compile-time because types don't exist
2. **GREEN**: Implement tasks 1-4, activate tests progressively:
   - Implement Task 1 -> SkillSourceGroupingTests compile and pass
   - Implement Task 2 -> allRegisteredSkills tests compile and pass
   - Implement Task 3 -> SettingsView tests compile and pass
   - Implement Task 4 -> SkillsListView/SkillListItemView tests compile and pass
3. **REFACTOR**: Clean up, extract SkillSource to proper location, verify all 629+ tests pass

## Key Risks & Assumptions

1. **SkillSource path matching**: The `hasPrefix` approach may have edge cases (see P2 test for similar-prefix scenario). Implementation should use `hasPrefix(cwd + "/")` or `baseDir == cwd` to avoid false matches.
2. **CWD vs workspacePath**: Settings panel is global, not session-scoped. Using `FileManager.default.currentDirectoryPath` for project detection, which may differ from the active session's workspacePath.
3. **SwiftUI View testability**: SwiftUI Views are tested for compilability (constructor acceptance) rather than rendered output. Visual behavior (expand/collapse, Finder open) requires manual verification.
4. **allRegisteredSkills vs discoveredSkills**: The story requires showing ALL skills in settings, not just userInvocable ones. A new `allRegisteredSkills` property is needed on AgentBridge.

## Manual Verification Checklist

- [ ] Settings panel shows three tabs: General / Permissions / Skills
- [ ] Skills tab lists all skills grouped by source (Built-in / Project / User)
- [ ] Clicking a skill row expands to show full details
- [ ] Expanded detail shows: name, description, aliases, whenToUse, argumentHint, toolRestrictions, baseDir, supportingFiles
- [ ] "Open in Finder" button appears only for skills with baseDir != nil
- [ ] "Open in Finder" opens Finder to the correct directory
- [ ] Built-in skills (commit, review, simplify, debug, test) appear in Built-in group
- [ ] Skills tab does not break General or Permissions tabs

## Next Steps

1. Run `swift build` to verify compile failures are expected (types missing)
2. Implement Story 5-4 following tasks 1-4 above
3. Run `swift test` after each task to verify progressive green
4. Complete manual verification checklist
5. Link ATDD artifacts into story file

## Execution Command

```bash
# Build (verify expected compile failures)
swift build

# Run all tests (verify expected failures + existing tests still pass)
swift test

# Run specific test file
swift test --filter SkillSourceGroupingTests
swift test --filter SkillsSettingsViewTests
```
