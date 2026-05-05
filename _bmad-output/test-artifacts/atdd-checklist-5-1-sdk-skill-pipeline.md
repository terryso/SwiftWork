---
stepsCompleted: ['step-01-preflight-and-context', 'step-02-generation-mode', 'step-03-test-strategy', 'step-04-generate-tests', 'step-04c-aggregate']
lastStep: 'step-04c-aggregate'
lastSaved: '2026-05-05'
storyId: '5.1'
storyKey: '5-1-sdk-skill-pipeline'
storyFile: '_bmad-output/implementation-artifacts/5-1-sdk-skill-pipeline.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-5-1-sdk-skill-pipeline.md'
generatedTestFiles:
  - 'SwiftWorkTests/SDKIntegration/AgentBridgeSkillTests.swift'
inputDocuments:
  - '_bmad-output/implementation-artifacts/5-1-sdk-skill-pipeline.md'
  - '_bmad-output/project-context.md'
  - '_bmad/tea/config.yaml'
  - '.build/checkouts/open-agent-sdk-swift/Sources/OpenAgentSDK/Tools/SkillRegistry.swift'
  - '.build/checkouts/open-agent-sdk-swift/Sources/OpenAgentSDK/Types/SkillTypes.swift'
  - '.build/checkouts/open-agent-sdk-swift/Sources/OpenAgentSDK/Tools/Advanced/SkillTool.swift'
  - '.build/checkouts/open-agent-sdk-swift/Sources/OpenAgentSDK/Skills/SkillLoader.swift'
  - '.build/checkouts/open-agent-sdk-swift/Sources/OpenAgentSDK/Types/AgentTypes.swift'
  - 'SwiftWork/SDKIntegration/AgentBridge.swift'
  - 'SwiftWorkTests/SDKIntegration/AgentBridgeTests.swift'
---

# ATDD Checklist: Story 5.1 - SDK Skill Pipeline

## TDD Red Phase (Current)

Red-phase test scaffolds generated.

- Unit/Integration Tests: 22 tests (will compile-fail until `discoveredSkills` property is added to `AgentBridge`)
- No E2E tests (backend Swift/XCTest project -- not applicable)

## Acceptance Criteria Coverage

| AC | Description | Test Coverage | Priority |
|----|-------------|---------------|----------|
| AC#1 | AgentOptions enables Skill discovery | `testConfigureCreatesSkillRegistry`, `testConfigureTriggersSkillDirectorySetup` | P0 |
| AC#2 | Filesystem Skill discovery | `testConfigureDiscoversFilesystemSkills` | P1 |
| AC#3 | Skill list injected into system prompt | `testSkillRegistryFormatsSkillsForPrompt`, `testFormatSkillsForPromptEmptyWhenNoSkills` | P1 |
| AC#4 | SkillTool execution success path | `testSkillRegistryFindsRegisteredSkill`, `testSkillRegistryFindsSkillByAlias`, `testRegisteredSkillHasToolRestrictions` | P0 |
| AC#5 | SkillTool execution failure path | `testSkillRegistryReturnsNilForNonExistentSkill`, `testSkillRegistryHasReturnsFalseForMissingSkill`, `testSkillRegistryHandlesEmptyRegistry` | P0 |
| AC#6 | BuiltInSkills coexistence | `testAllBuiltInSkillsRegistered`, `testBuiltInSkillsAreUserInvocable`, `testBuiltInSkillsDirectUserInvocable`, `testCustomSkillCoexistsWithBuiltInSkills` | P0 |
| AC#7 | UI-layer skill list exposure | `testAgentBridgeExposesDiscoveredSkills`, `testDiscoveredSkillsReflectsCurrentState`, `testDiscoveredSkillsFiltersToUserInvocable` | P0 |
| Regression | Existing AgentBridge behavior preserved | `testConfigureWithSkillsDoesNotBreakEventHandling`, `testClearEventsDoesNotRemoveSkillRegistry`, `testReconfigureRefreshesSkillRegistry` | P0/P1 |

## Test Priority Breakdown

- **P0 (Must pass):** 16 tests -- critical path for all ACs
- **P1 (Should pass):** 6 tests -- edge cases and deeper coverage

## Implementation Guidance

### Source file to modify:
- `SwiftWork/SDKIntegration/AgentBridge.swift` (the ONLY source file that needs changes)

### Required changes to make tests pass:

1. **Add `skillRegistry` property to `AgentBridge`:**
   ```swift
   @ObservationIgnored
   private var skillRegistry: SkillRegistry?
   ```

2. **Add `discoveredSkills` computed property:**
   ```swift
   var discoveredSkills: [Skill] {
       skillRegistry?.userInvocableSkills ?? []
   }
   ```

3. **Modify `configure()` to create and populate SkillRegistry:**
   ```swift
   let registry = SkillRegistry()
   registry.register(BuiltInSkills.commit)
   registry.register(BuiltInSkills.review)
   registry.register(BuiltInSkills.simplify)
   registry.register(BuiltInSkills.debug)
   registry.register(BuiltInSkills.test)
   self.skillRegistry = registry
   ```

4. **Pass skillRegistry and skillDirectories to AgentOptions:**
   ```swift
   var options = AgentOptions(
       apiKey: apiKey,
       model: model,
       // ... other params
   )
   options.skillRegistry = registry
   options.skillDirectories = [] // non-nil triggers autoDiscoverSkills
   ```

### Test activation sequence (during dev-story):

1. Add the `discoveredSkills` property first -- this fixes compilation
2. Run tests -- they will compile but fail (assertions not met)
3. Implement `configure()` changes to register BuiltInSkills
4. Run tests -- P0 tests should start passing
5. Verify all 22 tests pass
6. Run full suite to verify 765+ existing tests still pass

## Next Steps (Task-by-Task Activation)

During implementation of each task:

1. Implement the `discoveredSkills` property (fixes compilation)
2. Run tests: `xcodebuild test` or `swift test`
3. Verify activated tests fail first, then pass after implementation (green phase)
4. If any activated tests still fail unexpectedly:
   - Either fix implementation (feature bug)
   - Or fix test (test bug)
5. Commit passing tests

## TDD Phase Status

- Phase: RED (test scaffolds generated)
- Total tests: 22
- All tests assert EXPECTED behavior (not placeholders)
- Tests will NOT compile until `discoveredSkills` is added to `AgentBridge`
- After compilation fix, tests will FAIL until feature is implemented
- This is INTENTIONAL (TDD red phase)
