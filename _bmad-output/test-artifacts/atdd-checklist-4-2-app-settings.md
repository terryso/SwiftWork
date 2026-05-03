---
stepsCompleted: ['step-01-preflight-and-context', 'step-02-generation-mode', 'step-03-test-strategy', 'step-04-generate-tests', 'step-04c-aggregate']
lastStep: 'step-04c-aggregate'
lastSaved: '2026-05-03'
storyId: '4.2'
storyKey: '4-2-app-settings'
storyFile: '_bmad-output/implementation-artifacts/4-2-app-settings.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-4-2-app-settings.md'
generatedTestFiles:
  - 'SwiftWorkTests/ViewModels/SettingsViewModel4_2Tests.swift'
  - 'SwiftWorkTests/Views/Settings/APIKeySettingsViewTests.swift'
  - 'SwiftWorkTests/Views/Settings/ModelPickerViewTests.swift'
  - 'SwiftWorkTests/Views/Settings/SettingsViewIntegrationTests.swift'
inputDocuments:
  - '_bmad-output/implementation-artifacts/4-2-app-settings.md'
  - '_bmad-output/project-context.md'
  - 'SwiftWork/ViewModels/SettingsViewModel.swift'
  - 'SwiftWork/Views/Settings/SettingsView.swift'
  - 'SwiftWork/App/ContentView.swift'
  - 'SwiftWork/Utils/Constants.swift'
  - 'SwiftWorkTests/Support/TestDataFactory.swift'
---

# ATDD Checklist -- Story 4.2: Application Settings Page

## Summary

| Item | Value |
|------|-------|
| Story | 4.2 Application Settings Page |
| Stack | Backend (SwiftUI + XCTest) |
| Generation Mode | AI Generation (native Swift project, no browser automation) |
| Execution Mode | Sequential |
| Test Framework | XCTest |
| Test Files | 4 (3 new + 1 updated) |
| Total Test Cases | 37 |

## Acceptance Criteria Mapping

### AC#1: SettingsView contains API Key management, model selection, and permission configuration (FR48)

> Given user opens settings via menu bar or keyboard shortcut, When SettingsView is displayed, Then it contains API Key management area (show/hide/update Key), model selection dropdown, and permission configuration entry.

| ID | Test Case | Level | Priority | File |
|----|-----------|-------|----------|------|
| AC1-01 | SettingsView accepts both SettingsViewModel and PermissionHandler | Integration | P0 | SettingsViewIntegrationTests |
| AC1-02 | SettingsView contains three tabs: General, Permissions, Advanced | Integration | P0 | SettingsViewIntegrationTests |
| AC1-03 | APIKeySettingsView compiles and accepts SettingsViewModel | Component | P0 | APIKeySettingsViewTests |
| AC1-04 | APIKeySettingsView renders unconfigured state | Component | P0 | APIKeySettingsViewTests |
| AC1-05 | ModelPickerView compiles and accepts SettingsViewModel | Component | P0 | ModelPickerViewTests |
| AC1-06 | ModelPickerView shows available models from Constants | Component | P0 | ModelPickerViewTests |
| AC1-07 | ModelPickerView reflects current selected model | Component | P0 | ModelPickerViewTests |
| AC1-08 | SettingsView passes SettingsViewModel to APIKeySettingsView | Integration | P1 | SettingsViewIntegrationTests |
| AC1-09 | SettingsView passes SettingsViewModel to ModelPickerView | Integration | P1 | SettingsViewIntegrationTests |
| AC1-10 | SettingsView preserves PermissionRulesView in permissions tab | Integration | P1 | SettingsViewIntegrationTests |
| AC1-11 | APIKeySettingsView renders configured state with masked key | Component | P1 | APIKeySettingsViewTests |
| AC1-12 | APIKeySettingsView has apiKey property for input | Component | P1 | APIKeySettingsViewTests |
| AC1-13 | ModelPickerView selection updates ViewModel | Component | P1 | ModelPickerViewTests |
| AC1-14 | APIKeySettingsView base URL input binds to viewModel | Component | P2 | APIKeySettingsViewTests |
| AC1-15 | SettingsView backwards compatibility -- permissionHandler only | Integration | P2 | SettingsViewIntegrationTests |
| AC1-16 | SettingsViewModel is shared between ContentView and SettingsView | Integration | P2 | SettingsViewIntegrationTests |

### AC#2: API Key update via KeychainManager (NFR6)

> Given user updates API Key in settings, When clicking save, Then the new Key is updated in Keychain via KeychainManager and takes effect on next Agent call.

| ID | Test Case | Level | Priority | File |
|----|-----------|-------|----------|------|
| AC2-01 | updateAPIKey saves new key to Keychain | Unit | P0 | SettingsViewModel4_2Tests |
| AC2-02 | updateAPIKey updates isAPIKeyConfigured to true | Unit | P0 | SettingsViewModel4_2Tests |
| AC2-03 | updateAPIKey clears errorMessage on success | Unit | P0 | SettingsViewModel4_2Tests |
| AC2-04 | updateAPIKey rejects empty key | Unit | P1 | SettingsViewModel4_2Tests |
| AC2-05 | updateAPIKey rejects whitespace-only key | Unit | P1 | SettingsViewModel4_2Tests |
| AC2-06 | updateAPIKey replaces existing key | Unit | P2 | SettingsViewModel4_2Tests |

### AC#3: Model switch takes effect on next message

> Given user switches model in settings, When selecting a new model, Then next message uses the new model, and currently executing session is unaffected.

| ID | Test Case | Level | Priority | File |
|----|-----------|-------|----------|------|
| AC3-01 | updateModel persists selected model to AppConfiguration | Unit | P0 | SettingsViewModel4_2Tests |
| AC3-02 | updateModel updates selectedModel property on ViewModel | Unit | P0 | SettingsViewModel4_2Tests |
| AC3-03 | ModelPickerView model change persists via updateModel | Component | P1 | ModelPickerViewTests |
| AC3-04 | updateModel replaces existing model preference | Unit | P1 | SettingsViewModel4_2Tests |
| AC3-05 | updateModel with same model is idempotent | Unit | P2 | SettingsViewModel4_2Tests |
| AC3-06 | ModelPickerView displays default model on first launch | Component | P2 | ModelPickerViewTests |

### Cross-Cutting: maskedAPIKey display

| ID | Test Case | Level | Priority | File |
|----|-----------|-------|----------|------|
| CC-01 | maskedAPIKey returns empty string when no key configured | Unit | P0 | SettingsViewModel4_2Tests |
| CC-02 | maskedAPIKey shows first 8 and last 4 characters for long keys | Unit | P0 | SettingsViewModel4_2Tests |
| CC-03 | maskedAPIKey handles short keys (< 12 characters) | Unit | P1 | SettingsViewModel4_2Tests |
| CC-04 | maskedAPIKey handles exactly 12-character key | Unit | P2 | SettingsViewModel4_2Tests |

### Cross-Cutting: loadCurrentConfig() refresh

| ID | Test Case | Level | Priority | File |
|----|-----------|-------|----------|------|
| CC-05 | loadCurrentConfig refreshes isAPIKeyConfigured from Keychain | Unit | P0 | SettingsViewModel4_2Tests |
| CC-06 | loadCurrentConfig refreshes selectedModel from AppConfiguration | Unit | P0 | SettingsViewModel4_2Tests |
| CC-07 | loadCurrentConfig loads base URL from Keychain | Unit | P1 | SettingsViewModel4_2Tests |
| CC-08 | loadCurrentConfig handles missing base URL gracefully | Unit | P1 | SettingsViewModel4_2Tests |
| CC-09 | loadCurrentConfig updates maskedAPIKey after key change | Unit | P2 | SettingsViewModel4_2Tests |

## Priority Distribution

| Priority | Count | Description |
|----------|-------|-------------|
| P0 | 14 | Must-pass for story acceptance |
| P1 | 13 | Important but not blocking |
| P2 | 7 | Nice-to-have edge case |
| P3 | 0 | Future consideration |

## Test Level Distribution

| Level | Count |
|-------|-------|
| Unit (SettingsViewModel) | 15 |
| Component (APIKeySettingsView + ModelPickerView) | 9 |
| Integration (SettingsView + ContentView) | 8 |

## TDD Red Phase Status

- All new tests are designed to **FAIL** until implementation is complete
- Tests exercise types and APIs that do not yet exist:
  - `SettingsViewModel.updateAPIKey(_:)`
  - `SettingsViewModel.updateModel(_:)`
  - `SettingsViewModel.loadCurrentConfig()`
  - `SettingsViewModel.maskedAPIKey` (computed property)
  - `APIKeySettingsView` (new View type)
  - `ModelPickerView` (new View type)
  - `SettingsView` multi-tab initializer with `settingsViewModel` parameter
- Tests follow existing project conventions: `@MainActor`, `XCTestCase`, `@testable import SwiftWork`
- Tests use `MockKeychainManager` from `TestDataFactory.swift` for deterministic Keychain behavior
- Tests use in-memory `ModelContainer` for SwiftData isolation

## Implementation Guidance

### SettingsViewModel methods to add:

1. `updateAPIKey(_ key: String) throws` -- Validate non-empty, save to Keychain, update isAPIKeyConfigured
2. `updateModel(_ model: String) throws` -- Save to AppConfiguration, update selectedModel property
3. `loadCurrentConfig()` -- Refresh isAPIKeyConfigured, selectedModel, baseURL, maskedAPIKey from persisted sources
4. `maskedAPIKey: String` (computed property) -- Return masked version of stored API Key (first 8 + **** + last 4)

### Views to create:

1. `APIKeySettingsView` -- API Key management subpage (SecureField + show/hide toggle + save)
2. `ModelPickerView` -- Model selection subpage (current model + dropdown)

### Views to update:

1. `SettingsView` -- Refactor from single PermissionRulesView to TabView with 3 tabs
2. `ContentView` -- Pass settingsViewModel to SettingsView in sheet

## Next Steps (Task-by-Task Activation)

During implementation of each task:

1. Implement the required method/View for the current task
2. Run tests: `swift test`
3. Verify that previously failing tests now pass (green phase)
4. If any tests still fail unexpectedly:
   - Either fix implementation (feature bug)
   - Or fix test (test bug)
5. Commit passing tests
