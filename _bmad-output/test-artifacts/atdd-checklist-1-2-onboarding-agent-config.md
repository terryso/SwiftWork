---
stepsCompleted:
  - step-01-preflight-and-context
  - step-02-generation-mode
  - step-03-test-strategy
  - step-04-generate-tests
  - step-04c-aggregate
lastStep: step-04c-aggregate
lastSaved: '2026-05-01'
storyId: '1.2'
storyKey: 1-2-onboarding-agent-config
storyFile: '_bmad-output/implementation-artifacts/1-2-onboarding-agent-config.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-1-2-onboarding-agent-config.md'
generatedTestFiles:
  - SwiftWorkTests/Services/KeychainManagerTests.swift
  - SwiftWorkTests/ViewModels/SettingsViewModelTests.swift
  - SwiftWorkTests/App/OnboardingFlowTests.swift
  - SwiftWorkTests/Utils/ConstantsTests.swift
inputDocuments:
  - '_bmad-output/implementation-artifacts/1-2-onboarding-agent-config.md'
  - '_bmad-output/project-context.md'
  - '.claude/skills/bmad-testarch-atdd/resources/knowledge/data-factories.md'
  - '.claude/skills/bmad-testarch-atdd/resources/knowledge/test-quality.md'
  - '.claude/skills/bmad-testarch-atdd/resources/knowledge/test-healing-patterns.md'
---

# ATDD Checklist: Story 1.2 — 首次启动引导与 Agent 配置

## TDD Red Phase (Current)

Red-phase test scaffolds generated. All tests assert EXPECTED behavior and will FAIL until implementation is complete.

## Test Summary

| Category | File | Tests | Priority |
|----------|------|-------|----------|
| KeychainManager (Service) | `SwiftWorkTests/Services/KeychainManagerTests.swift` | 9 | P0-P1 |
| SettingsViewModel (ViewModel) | `SwiftWorkTests/ViewModels/SettingsViewModelTests.swift` | 15 | P0-P1 |
| Onboarding Flow (App) | `SwiftWorkTests/App/OnboardingFlowTests.swift` | 6 | P0-P2 |
| Constants (Utils) | `SwiftWorkTests/Utils/ConstantsTests.swift` | 5 | P0-P1 |
| **Total** | **4 files** | **35 tests** | |

## Acceptance Criteria Coverage

| AC | Description | Test Coverage | Priority |
|----|-------------|---------------|----------|
| #1 | 首次启动显示 WelcomeView 引导页面 | `OnboardingFlowTests.testFirstLaunchShowsOnboarding`, `OnboardingFlowTests.testContentViewInstantiation`, `OnboardingFlowTests.testWelcomeViewInstantiation`, `SettingsViewModelTests.testInitialFirstLaunchState`, `SettingsViewModelTests.testInitialAPIKeyNotConfigured` | P0 |
| #2 | API Key 通过 KeychainManager 存入 Keychain | `KeychainManagerTests.testSaveAndLoadRoundTrip`, `KeychainManagerTests.testSaveAPIKeyConvenienceMethods`, `KeychainManagerTests.testSaveDuplicateKeyUpdates`, `KeychainManagerTests.testDeleteThenLoadReturnsNil`, `SettingsViewModelTests.testSaveAPIKeySetsConfigured`, `SettingsViewModelTests.testSaveAPIKeyStoresInKeychain` | P0 |
| #3 | 用户可选择 Agent 模型 | `ConstantsTests.testAvailableModelsContainsAllModels`, `SettingsViewModelTests.testDefaultModel`, `SettingsViewModelTests.testAvailableModels`, `SettingsViewModelTests.testChangeSelectedModel` | P0-P1 |
| #4 | 配置完成后自动跳转到主界面 | `SettingsViewModelTests.testCompleteSetupSetsFirstLaunchFalse`, `SettingsViewModelTests.testCompleteSetupPersistsOnboardingFlag` | P0 |
| #5 | 非首次启动跳过引导 | `OnboardingFlowTests.testNonFirstLaunchSkipsOnboarding`, `SettingsViewModelTests.testCheckExistingConfigDetectsCompletedOnboarding` | P0-P1 |
| #6 | 启动时自动从 Keychain 读取 API Key | `SettingsViewModelTests.testCheckExistingConfigDetectsExistingKey`, `SettingsViewModelTests.testCheckExistingConfigLoadsModelPreference`, `OnboardingFlowTests.testAppReadsExistingKeyOnStartup`, `OnboardingFlowTests.testKeyExistsButNoOnboardingFlag` | P0-P2 |
| #7 | 启动到可交互不超过 2 秒 (NFR1) | No automated test (performance NFR, verified via Instruments) | N/A |

## Test Levels

| Level | Count | Files |
|-------|-------|-------|
| Unit | 33 | KeychainManagerTests, SettingsViewModelTests, ConstantsTests |
| Integration | 2 | OnboardingFlowTests (SwiftData ModelContext) |

## Implementation Map

### Files to Implement (Red Phase Activation Order)

1. **Constants.swift** — Add `KeychainConstants` enum and `Constants.availableModels`
   - Activate: `ConstantsTests` (5 tests)
   - Green when: `KeychainConstants.service`, `KeychainConstants.apiKeyAccount`, `Constants.availableModels` exist

2. **KeychainManager.swift** — Replace placeholder with full implementation
   - Activate: `KeychainManagerTests` (9 tests)
   - Requires: `KeychainManaging` protocol, `save`/`load`/`delete` methods, convenience methods
   - Green when: CRUD operations pass with mock and real Keychain

3. **SettingsViewModel.swift** — New file, `@Observable final class`
   - Activate: `SettingsViewModelTests` (15 tests)
   - Requires: `apiKey`, `selectedModel`, `isAPIKeyConfigured`, `isFirstLaunch`, `isValidAPIKey`, `errorMessage`, `availableModels` properties; `saveAPIKey()`, `completeSetup()`, `checkExistingConfig()`, `configure(modelContext:)` methods
   - Green when: State management and Keychain/SwiftData integration pass

4. **WelcomeView.swift** — Replace placeholder with onboarding UI
   - Verify: `OnboardingFlowTests.testWelcomeViewInstantiation` passes
   - Requires: SecureField for API Key, Picker for model, "Get Started" button

5. **ContentView.swift** — Add onboarding conditional rendering
   - Activate: `OnboardingFlowTests` (6 tests)
   - Requires: `@State hasCompletedOnboarding`, conditional WelcomeView/NavigationSplitView rendering
   - Green when: All onboarding flow tests pass

## Next Steps (Task-by-Task Activation)

During implementation of each task:

1. Implement the corresponding source file
2. Run tests: `swift test`
3. Verify activated tests transition from RED to GREEN
4. If tests fail after implementation:
   - Check implementation for bugs (feature bug)
   - Check test assumptions (test bug)
5. Commit passing tests alongside implementation

## Mock Strategy

- **MockKeychainManager**: In-memory dictionary implementing `KeychainManaging` protocol
- **SwiftData**: In-memory `ModelContainer` (`isStoredInMemoryOnly: true`)
- No real Keychain or file system access in unit tests

## Notes

- `ErrorDomain.security` case will need to be added to `AppError.swift` for Keychain error mapping
- `KeychainConstants` enum and `Constants.availableModels` static property are new additions
- NFR1 (2-second startup) is not automated — verified via Instruments profiling
- All tests follow existing project patterns: `@testable import SwiftWork`, XCTest framework, `TestDataFactory`-style factories
