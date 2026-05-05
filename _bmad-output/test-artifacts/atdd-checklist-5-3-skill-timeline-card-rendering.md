---
stepsCompleted: ['step-01-preflight-and-context', 'step-02-generation-mode', 'step-03-test-strategy', 'step-04-generate-tests', 'step-04c-aggregate', 'step-05-validate-and-complete']
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-05-05'
storyId: '5.3'
storyKey: '5-3-skill-timeline-card-rendering'
storyFile: '_bmad-output/implementation-artifacts/5-3-skill-timeline-card-rendering.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-5-3-skill-timeline-card-rendering.md'
generatedTestFiles:
  - 'SwiftWorkTests/Views/Timeline/SkillToolRendererTests.swift'
inputDocuments:
  - '_bmad-output/implementation-artifacts/5-3-skill-timeline-card-rendering.md'
  - '_bmad-output/project-context.md'
  - 'SwiftWork/SDKIntegration/ToolRenderable.swift'
  - 'SwiftWork/SDKIntegration/ToolRendererRegistry.swift'
  - 'SwiftWork/Models/UI/ToolContent.swift'
  - 'SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/BashToolRenderer.swift'
  - 'SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/FileEditToolRenderer.swift'
  - 'SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/SearchToolRenderer.swift'
  - 'SwiftWorkTests/SDKIntegration/ToolRendererRegistryTests.swift'
  - 'SwiftWorkTests/Views/Timeline/ToolCardViewTests.swift'
  - '_bmad-output/implementation-artifacts/epic-5-skill-system.md'
---

# ATDD Checklist: Story 5.3 - Skill Timeline Card Rendering

## TDD Red Phase (Current)

Red-phase test scaffolds generated.

- **Unit Tests:** 40 tests in `SkillToolRendererTests.swift` (will compile-fail until `SkillToolRenderer` is implemented)
- **No E2E tests** (Swift/macOS XCTest project -- SwiftUI view rendering tested via protocol contract and data extraction)

## Acceptance Criteria Coverage

| AC | Description | Test Coverage | Priority |
|----|-------------|---------------|----------|
| AC#1 | Skill toolUse card identification and rendering | `testSkillToolRendererHasCorrectToolName`, `testSkillToolRendererHasPurpleAccentColor`, `testSkillToolRendererUsesSparklesIcon`, `testSkillToolRendererConformsToToolRenderable`, `testSummaryTitleExtractsSkillNameWithSlashPrefix`, `testSummaryTitleDifferentSkillNames`, `testSummaryTitleFallsBackForEmptyInput`, `testSummaryTitleFallsBackForInvalidJSON`, `testSummaryTitleFallsBackWhenNoSkillField`, `testSubtitleExtractsArgsFromInput`, `testSubtitleTruncatesLongArgs`, `testSubtitleReturnsNilForEmptyArgs`, `testSubtitleReturnsNilWhenNoArgsField`, `testSubtitleReturnsNilForEmptyInput`, `testSubtitleReturnsNilForInvalidJSON`, `testRegistryContainsSkillToolRendererAfterInit`, `testRegistryRendererSummaryTitleForSkillContent`, `testRegistryRendererSubtitleForSkillContent`, `testRegistryRendererBodyReturnsView` | P0/P1 |
| AC#2 | Skill toolResult completion status | `testBodyRendersCompletedStatusContent`, `testBodyRendersFailedStatusContent`, `testBodyRendersPendingStatusContent`, `testBodyHandlesNonJSONOutput`, `testBodyHandlesEmptyOutput` | P0/P1 |
| AC#3 | Expanded detail view | `testBodyParsesToolResultOutputJSON`, `testBodyDisplaysPromptTemplateSummary` | P0/P1 |
| AC#4 | Multiple Skill calls visual distinction | `testSkillIconDiffersFromBashToolRenderer`, `testSkillIconDiffersFromFileEditToolRenderer`, `testSkillIconDiffersFromSearchToolRenderer`, `testSkillToolNameIsUnique`, `testMultipleSkillCallsRenderIndependently`, `testMultipleSkillCallsWithDifferentStatuses` | P0/P1 |
| Edge | Boundary and input parsing | `testExtraJSONFieldsIgnored`, `testNonStringSkillFieldFallsBack`, `testNonStringArgsFieldReturnsNil`, `testArgsAtExactLimitNotTruncated`, `testArgsOverLimitByOneTruncated` | P1 |

## Test Priority Breakdown

- **P0 (Must pass):** 24 tests -- critical path for all 4 ACs
- **P1 (Should pass):** 16 tests -- edge cases, boundary conditions, and deeper coverage

## Implementation Guidance

### New source files to create:

1. **`SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/SkillToolRenderer.swift`**
   - `struct SkillToolRenderer: ToolRenderable`
   - `static let toolName = "Skill"`
   - `static let accentColor: Color = .purple`
   - `static let icon: String = "sparkles"`
   - `func summaryTitle(content:)` -- parse "skill" from input JSON, return `"/\(skillName)"`
   - `func subtitle(content:)` -- parse "args" from input JSON, truncate to 80 chars
   - `func body(content:)` -- return `SkillToolExpandedContent` view
   - Private helper `parseField(_:from:)` for JSON extraction

### Existing files to modify:

1. **`SwiftWork/SDKIntegration/ToolRendererRegistry.swift`**
   - Add `register(SkillToolRenderer())` to `init()` method (one line)
   - This makes the registry return `SkillToolRenderer` for `"Skill"` toolName

### Files that do NOT need modification:

- EventMapper.swift -- Skill toolUse already goes through generic `.toolUse` branch
- ToolContent.swift -- `fromToolUseEvent()`/`fromToolResultEvent()` already handle Skill calls
- ToolCardView.swift -- Already uses registry lookup for rendering
- TimelineView.swift -- Already uses toolContentMap pairing mechanism
- AgentBridge.swift -- toolContentMap logic already covers Skill tool

### Key implementation pattern:

Follow the existing renderer pattern from `BashToolRenderer` and `SearchToolRenderer`:
- Static properties for toolName, accentColor, icon
- `summaryTitle` parses input JSON for display name
- `subtitle` parses input JSON for secondary info
- `body` returns a SwiftUI view for expanded content

## Risk Areas

1. **JSON Parsing** -- Input is a JSON String (not Dictionary). Must use `JSONSerialization` or `JSONDecoder`, not direct cast.
2. **Truncation** -- Args must be truncated to exactly 80 characters using `String.prefix(80)`.
3. **Fallback behavior** -- Empty/invalid input must fall back gracefully to "Skill" title and nil subtitle.
4. **Color comparison** -- SwiftUI `Color` values cannot be directly compared with `==`. Tests verify accessibility of the property; visual verification done in manual acceptance testing.

## Acceptance Test Traceability

| Test ID | AC | Test Method | Priority |
|---------|-----|-------------|----------|
| T01 | AC1 | testSkillToolRendererHasCorrectToolName | P0 |
| T02 | AC1 | testSkillToolRendererHasPurpleAccentColor | P0 |
| T03 | AC1 | testSkillToolRendererUsesSparklesIcon | P0 |
| T04 | AC1 | testSkillToolRendererConformsToToolRenderable | P0 |
| T05 | AC1 | testSummaryTitleExtractsSkillNameWithSlashPrefix | P0 |
| T06 | AC1 | testSummaryTitleDifferentSkillNames | P0 |
| T07 | AC1 | testSummaryTitleFallsBackForEmptyInput | P0 |
| T08 | AC1 | testSummaryTitleFallsBackForInvalidJSON | P1 |
| T09 | AC1 | testSummaryTitleFallsBackWhenNoSkillField | P1 |
| T10 | AC1 | testSubtitleExtractsArgsFromInput | P0 |
| T11 | AC1 | testSubtitleTruncatesLongArgs | P0 |
| T12 | AC1 | testSubtitleReturnsNilForEmptyArgs | P0 |
| T13 | AC1 | testSubtitleReturnsNilWhenNoArgsField | P1 |
| T14 | AC1 | testSubtitleReturnsNilForEmptyInput | P1 |
| T15 | AC1 | testSubtitleReturnsNilForInvalidJSON | P1 |
| T16 | AC2 | testBodyRendersCompletedStatusContent | P0 |
| T17 | AC2 | testBodyRendersFailedStatusContent | P0 |
| T18 | AC2 | testBodyRendersPendingStatusContent | P0 |
| T19 | AC3 | testBodyParsesToolResultOutputJSON | P0 |
| T20 | AC3 | testBodyDisplaysPromptTemplateSummary | P1 |
| T21 | AC4 | testSkillIconDiffersFromBashToolRenderer | P0 |
| T22 | AC4 | testSkillIconDiffersFromFileEditToolRenderer | P0 |
| T23 | AC4 | testSkillIconDiffersFromSearchToolRenderer | P0 |
| T24 | AC4 | testSkillToolNameIsUnique | P1 |
| T25 | AC1 | testRegistryContainsSkillToolRendererAfterInit | P0 |
| T26 | AC1 | testRegistryRendererSummaryTitleForSkillContent | P0 |
| T27 | AC1 | testRegistryRendererSubtitleForSkillContent | P0 |
| T28 | AC1 | testRegistryRendererBodyReturnsView | P1 |
| T29 | AC4 | testMultipleSkillCallsRenderIndependently | P0 |
| T30 | AC4 | testMultipleSkillCallsWithDifferentStatuses | P1 |
| T31 | AC2 | testBodyHandlesNonJSONOutput | P1 |
| T32 | AC2 | testBodyHandlesEmptyOutput | P1 |
| T33 | Edge | testExtraJSONFieldsIgnored | P1 |
| T34 | Edge | testNonStringSkillFieldFallsBack | P1 |
| T35 | Edge | testNonStringArgsFieldReturnsNil | P1 |
| T36 | Edge | testArgsAtExactLimitNotTruncated | P1 |
| T37 | Edge | testArgsOverLimitByOneTruncated | P1 |
