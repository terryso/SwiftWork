---
stepsCompleted: ['step-01-preflight-and-context', 'step-02-generation-mode', 'step-03-test-strategy', 'step-04-generate-tests', 'step-04c-aggregate', 'step-05-validate-and-complete']
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-05-05'
storyId: '5.2'
storyKey: '5-2-input-bar-slash-autocomplete'
storyFile: '_bmad-output/implementation-artifacts/5-2-input-bar-slash-autocomplete.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-5-2-input-bar-slash-autocomplete.md'
generatedTestFiles:
  - 'SwiftWorkTests/Views/Workspace/InputBar/SkillAutocompleteViewModelTests.swift'
inputDocuments:
  - '_bmad-output/implementation-artifacts/5-2-input-bar-slash-autocomplete.md'
  - '_bmad-output/project-context.md'
  - '_bmad/tea/config.yaml'
  - 'SwiftWork/Views/Workspace/InputBar/InputBarView.swift'
  - 'SwiftWork/Views/Workspace/InputBar/IMESafeTextView.swift'
  - 'SwiftWork/SDKIntegration/AgentBridge.swift'
  - 'SwiftWorkTests/Views/Workspace/InputBar/InputBarViewTests.swift'
  - 'SwiftWorkTests/SDKIntegration/AgentBridgeSkillTests.swift'
  - 'SwiftWorkTests/Support/TestDataFactory.swift'
---

# ATDD Checklist: Story 5.2 - Input Bar Slash Autocomplete

## TDD Red Phase (Current)

Red-phase test scaffolds generated.

- **Unit Tests:** 30 tests in `SkillAutocompleteViewModelTests.swift` (will compile-fail until `SkillAutocompleteViewModel` is implemented)
- **No E2E tests** (Swift/macOS XCTest project -- UI keyboard interactions tested via ViewModel logic)

## Acceptance Criteria Coverage

| AC | Description | Test Coverage | Priority |
|----|-------------|---------------|----------|
| AC#1 | Slash triggers autocomplete | `testEmptyInputDoesNotShowMenu`, `testSlashShowsAllSkills`, `testSlashWithNoSkillsDoesNotShowMenu`, `testMenuAppearsWithInitialSelection` | P0/P1 |
| AC#2 | Fuzzy filter | `testPrefixMatchFiltersSkills`, `testAliasMatchFiltersSkills`, `testNoMatchHidesMenu`, `testPrefixMatchesSortedFirst`, `testFilterIsCaseInsensitive`, `testAliasPrefixMatch` | P0/P1 |
| AC#3 | Keyboard select and confirm | `testSelectSkillReturnsSlashPrefixedName`, `testSelectSkillReturnsNilForOutOfBounds`, `testSelectSkillReturnsNilWhenMenuNotVisible`, `testSelectedIndexTracksHighlight`, `testMoveSelectionWrapsAtBoundary` | P0/P1 |
| AC#4 | Escape/click-outside dismiss | `testDismissHidesMenuAndResetsState`, `testDismissWhenNotVisibleIsNoOp` | P0/P1 |
| AC#5 | Non-matching text sent as plain text | `testNonMatchingSlashTextDoesNotTriggerAutocomplete`, `testNonMatchingTextHasEmptyFilteredSkills` | P0/P1 |
| AC#6 | Line-start only trigger | `testSlashAtNonStartDoesNotTrigger`, `testSlashAtStartWithLeadingWhitespaceTriggers`, `testNonSlashTextDoesNotTrigger`, `testSlashInMiddleOfWordDoesNotTrigger` | P0/P1 |
| Edge | State transitions and boundaries | `testUpdateFromMatchingToNonMatchingDismissesMenu`, `testUpdateFromNonSlashToSlashTriggersMenu`, `testEmptySkillsSourceShowsNoMenu`, `testSpecialCharacterSkillNames`, `testSelectSkillAfterFiltering` | P1 |

## Test Priority Breakdown

- **P0 (Must pass):** 16 tests -- critical path for all 6 ACs
- **P1 (Should pass):** 14 tests -- edge cases, boundary conditions, and deeper coverage

## Implementation Guidance

### New source files to create:

1. **`SwiftWork/Views/Workspace/InputBar/SkillAutocompleteViewModel.swift`**
   - `@Observable` class with properties: `filteredSkills`, `isVisible`, `selectedIndex`, `skillsSource`
   - Methods: `updateQuery(_:)`, `selectSkill(at:) -> String?`, `dismiss()`, `moveSelection(down:)`

2. **`SwiftWork/Views/Workspace/InputBar/SkillAutocompleteMenuView.swift`**
   - SwiftUI overlay/popup menu for skill list rendering
   - Not directly tested by unit tests (SwiftUI view), but required for visual behavior

### Existing source files to modify:

1. **`SwiftWork/Views/Workspace/InputBar/InputBarView.swift`**
   - Add `@State private var autocompleteVM = SkillAutocompleteViewModel()`
   - Add `.onChange(of: inputText)` to call `autocompleteVM.updateQuery(inputText)`
   - Inject `agentBridge.discoveredSkills` into `autocompleteVM.skillsSource`
   - Show `SkillAutocompleteMenuView` as overlay when `autocompleteVM.isVisible`

2. **`SwiftWork/Views/Workspace/InputBar/IMESafeTextView.swift`**
   - Add keyboard callbacks to `SendTextView`: `onEscape`, `onArrowUp`, `onArrowDown`, `onEnterWithAutocomplete`
   - Wire these callbacks in `InputBarView`'s `updateNSView`

### Required changes to make tests pass:

1. **Create `SkillAutocompleteViewModel` class:**
   ```swift
   @MainActor
   @Observable
   final class SkillAutocompleteViewModel {
       var filteredSkills: [Skill] = []
       var isVisible: Bool = false
       var selectedIndex: Int? = nil
       var skillsSource: [Skill] = []

       func updateQuery(_ text: String) { /* see Story Dev Notes */ }
       func selectSkill(at index: Int) -> String? { /* return "/skillName" */ }
       func dismiss() { /* reset state */ }
       func moveSelection(down: Bool) { /* navigate +/- with wrap */ }
   }
   ```

2. **Key filtering logic** (from Story Dev Notes):
   - Trim whitespace, check `hasPrefix("/")`
   - Extract query after `/`, lowercase
   - Filter: name prefix match > name contains match > alias prefix match
   - Sort: prefix matches first, then alphabetical

3. **Line-start trigger** (AC#6):
   - `text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("/")`
   - Non-starting slash (e.g., "hello /") must not trigger

## Test Design Notes

### Why ViewModel-only unit tests?

`SkillAutocompleteViewModel` encapsulates all autocomplete logic (filtering, selection, visibility). The SwiftUI view layer (`SkillAutocompleteMenuView`, `InputBarView` overlay) is thin presentation code that:
- Cannot be easily unit-tested in XCTest without ViewInspector
- Is covered implicitly by the ViewModel tests (if the ViewModel logic is correct and the View binds correctly, the behavior is correct)

### Why no mock AgentBridge needed?

`skillsSource` is a simple `[Skill]` array injected into the ViewModel. Tests directly construct skill arrays using `makeSkill()` helper, avoiding the need for mock AgentBridge. This follows the project's testing pattern (see `AgentBridgeSkillTests.swift`).

### Test data design

The `sampleSkills` property provides 5 skills matching the BuiltInSkills set, ensuring tests are realistic. The `makeSkill()` helper creates `Skill` instances with customizable name, aliases, description, and argumentHint.

## Red-Green-Refactor Workflow

### RED Phase (Current)
- All 30 tests in `SkillAutocompleteViewModelTests.swift` are generated
- Tests will **fail to compile** until `SkillAutocompleteViewModel` is implemented
- This is intentional -- TDD red phase

### GREEN Phase (During Implementation)
For each task in the story:

1. Implement the corresponding method in `SkillAutocompleteViewModel`
2. Run: `xcodebuild test -scheme SwiftWork -destination 'platform=macOS' -only-testing:SwiftWorkTests/SkillAutocompleteViewModelTests`
3. Verify previously failing tests now pass
4. If any test still fails, fix implementation (not the test)

### REFACTOR Phase (After GREEN)
- Review code for clarity, performance, and adherence to project rules
- Ensure no 300-line View limit violations
- Ensure `@Observable` used (not `ObservableObject`)
- Ensure `@MainActor` on all ViewModel properties and methods

## Execution Commands

```bash
# Run all SkillAutocompleteViewModel tests
xcodebuild test -scheme SwiftWork -destination 'platform=macOS' \
  -only-testing:SwiftWorkTests/SkillAutocompleteViewModelTests

# Run specific test
xcodebuild test -scheme SwiftWork -destination 'platform=macOS' \
  -only-testing:SwiftWorkTests/SkillAutocompleteViewModelTests/testSlashShowsAllSkills

# Run all project tests (regression check)
swift test
```

## Next Steps

1. Implement `SkillAutocompleteViewModel` (Task 1 in Story)
2. Implement `SkillAutocompleteMenuView` (Task 2 in Story)
3. Integrate into `InputBarView` (Task 3 in Story)
4. Run ATDD tests to verify GREEN phase
5. Run full regression suite (`swift test`) to confirm no breakage
6. Commit passing tests and implementation
