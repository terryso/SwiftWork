---
stepsCompleted: ['step-01-preflight-and-context', 'step-02-generation-mode', 'step-03-test-strategy', 'step-04-generate-tests', 'step-05-validate-and-complete']
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-05-03'
workflowType: 'testarch-atdd'
storyId: '3.4'
storyKey: '3-4-inspector-panel'
storyFile: '_bmad-output/implementation-artifacts/3-4-inspector-panel.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-3-4-inspector-panel.md'
generatedTestFiles:
  - 'SwiftWorkTests/Views/Workspace/Inspector/InspectorViewTests.swift'
inputDocuments:
  - '_bmad-output/implementation-artifacts/3-4-inspector-panel.md'
  - '_bmad-output/project-context.md'
  - '_bmad-output/planning-artifacts/epics.md'
  - '_bmad-output/planning-artifacts/architecture.md'
---

# ATDD Checklist - Epic 3, Story 3.4: Inspector Panel

**Date:** 2026-05-03
**Author:** Nick
**Primary Test Level:** Unit (XCTest, Swift backend)

---

## Story Summary

As a user, I want to view detailed information about a selected event in a right-side panel, so that I can deeply understand each step of the Agent's operation.

**As a** user
**I want** to view selected event details in a right-side Inspector Panel
**So that** I can deeply understand the complete data of each Agent operation step

---

## Acceptance Criteria

1. **AC#1:** Given user clicks any event in Timeline, When event is selected, Then Inspector Panel displays the event's full details: JSON format raw data, execution time, token usage (FR37)
2. **AC#2:** Given Inspector Panel is expanded, When user clicks Inspector toggle button, Then Panel collapses, Workspace area expands to full width (FR41)
3. **AC#3:** Given Inspector Panel is collapsed, When user clicks toggle button, Then Panel expands, restoring previous width

**Covered FRs:** FR37, FR41
**Covered ARCHs:** ARCH-8 (Observation framework), ARCH-12 (layer boundaries)
**Covered NFRs:** NFR21 (Inspector visibility persistence)

---

## Story Integration Metadata

- **Story ID:** `3.4`
- **Story Key:** `3-4-inspector-panel`
- **Story File:** `_bmad-output/implementation-artifacts/3-4-inspector-panel.md`
- **Checklist Path:** `_bmad-output/test-artifacts/atdd-checklist-3-4-inspector-panel.md`
- **Generated Test Files:** `SwiftWorkTests/Views/Workspace/Inspector/InspectorViewTests.swift`

---

## Test Strategy

### Detected Stack

- **Type:** Backend (Swift Package Manager, XCTest)
- **Framework:** XCTest (native Swift testing)
- **Test Runner:** `swift test`

### Test Level Selection

| Test Level | Usage | Rationale |
|---|---|---|
| Unit | Primary | View instantiation, event detail rendering, ToolContent pairing, metadata serialization -- all testable in isolation with XCTest |
| Integration | Supplement | WorkspaceView + InspectorView binding, event selection hoisting -- tests that multiple components interact correctly |

No E2E/Component tests (not a frontend/Playwright project). SwiftUI view body inspection uses `XCTAssertNotNil` pattern consistent with existing test suite (ToolCardViewTests, TimelineEventViewsTests).

---

## Red-Phase Test Scaffolds Created

### Unit Tests (26 tests)

**File:** `SwiftWorkTests/Views/Workspace/Inspector/InspectorViewTests.swift` (~320 lines)

#### AC#1: Inspector displays event details when selected (20 tests)

- [P0] `testInspectorViewEmptyStateWithNilEvent` -- InspectorView instantiates with nil selectedEvent (empty state)
- [P0] `testInspectorViewWithToolUseEvent` -- InspectorView instantiates with toolUse event and matching ToolContent
- [P0] `testInspectorViewWithResultEvent` -- InspectorView instantiates with result event (duration, cost, turns)
- [P0] `testInspectorViewWithAssistantEvent` -- InspectorView instantiates with assistant event (model, stopReason)
- [P0] `testInspectorViewWithSystemEvent` -- InspectorView instantiates with system event (subtype, sessionId)
- [P0] `testInspectorViewWithUserMessageEvent` -- InspectorView instantiates with userMessage event
- [P0] `testEventMetadataSerialization` -- Event metadata serializable to JSON for Inspector raw data display
- [P1] `testInspectorViewWithCompletedToolContent` -- Completed tool event shows output, status, elapsed time
- [P1] `testInspectorViewWithFailedToolContent` -- Failed tool event shows error output
- [P1] `testInspectorViewWithRunningToolContent` -- Running tool event shows progress indicator
- [P1] `testInspectorViewWithToolUseEventNoMatchingContent` -- ToolUse event without matching ToolContent handled
- [P1] `testInspectorViewWithResultEventAndUsage` -- Result event with usage and cost breakdown
- [P1] `testInspectorViewHandlesAllEventTypes` -- All 19 AgentEventType cases handled without crash
- [P1] `testEventWithEmptyMetadata` -- Event with empty metadata handled gracefully
- [P1] `testEventWithNestedMetadata` -- Nested metadata dictionaries (usage, costBreakdown) handled
- [P1] `testToolContentLookupByToolUseId` -- ToolContent retrieved by toolUseId from map
- [P1] `testToolContentElapsedTimeAccessible` -- Elapsed time accessible for Inspector display
- [P1] `testToolContentInputAccessible` -- Input JSON accessible for Inspector display
- [P1] `testEventTimestampAccessible` -- Timestamp accessible for formatting
- [P1] `testEventTypeRawValues` -- AgentEventType raw values available for display labels

#### AC#2 & AC#3: Inspector visibility toggle (2 tests)

- [P0] `testWorkspaceViewAcceptsInspectorVisibility` -- WorkspaceView accepts isInspectorVisible binding (collapsed)
- [P0] `testWorkspaceViewWithInspectorVisible` -- WorkspaceView accepts isInspectorVisible=true (expanded)

#### AC#1: Event selection state (2 tests)

- [P0] `testEventSelectionLookupById` -- AgentEvent found by ID in event list (selection lookup)
- [P0] `testEventIdUniqueness` -- Each AgentEvent has unique ID for selection

#### Integration (2 tests)

- [P1] `testSelectedEventChangesOnDifferentEvent` -- InspectorView renders correctly when selection changes
- [P1] `testInspectorViewWithToolProgressEvent` -- InspectorView handles toolProgress event

---

## Required InspectorView API Contract

The tests define the following API contract that the implementation must satisfy:

### InspectorView.init parameters:

```swift
InspectorView(
    selectedEvent: AgentEvent?,        // nil = empty state, non-nil = show details
    toolContentMap: [String: ToolContent]  // toolUseId -> paired ToolContent
)
```

### WorkspaceView.init additional parameter:

```swift
WorkspaceView(
    agentBridge: AgentBridge,
    eventStore: (any EventStoring)?,
    session: Session,
    settingsViewModel: SettingsViewModel,
    sessionViewModel: SessionViewModel,
    isInspectorVisible: Binding<Bool>   // NEW: toggle from ContentView
)
```

---

## Implementation Checklist

### Task 1: InspectorView Rewrite (AC#1)

**Test file:** `SwiftWorkTests/Views/Workspace/Inspector/InspectorViewTests.swift`

**Tasks to make AC#1 tests pass:**

- [ ] Rewrite `InspectorView.swift` to accept `selectedEvent: AgentEvent?` and `toolContentMap: [String: ToolContent]`
- [ ] Implement empty state view (nil selectedEvent): "选择一个事件以查看详情" + icon
- [ ] Implement event type label with color differentiation
- [ ] Implement timestamp formatting display
- [ ] Implement content summary text display
- [ ] Implement type-specific detail sections using `@ViewBuilder` + switch on `event.type`:
  - toolUse/toolResult/toolProgress: show ToolContent details from toolContentMap
  - result: show status, durationMs, totalCostUsd, numTurns, usage
  - assistant: show model, stopReason
  - system: show subtype, sessionId
  - Other types: generic metadata display
- [ ] Implement JSON raw data section (collapsible) with CopyButton
- [ ] Keep InspectorView under 300 lines -- split into ToolEventInspector.swift if needed
- [ ] Run: `swift test --filter InspectorViewTests`
- [ ] Verify: `testInspectorViewHandlesAllEventTypes` passes (exhaustive switch)

**Estimated Effort:** 4 hours

### Task 2: Inspector Panel Toggle (AC#2, AC#3)

**Test file:** `SwiftWorkTests/Views/Workspace/Inspector/InspectorViewTests.swift`

**Tasks to make AC#2/AC#3 tests pass:**

- [ ] Add `isInspectorVisible: Binding<Bool>` parameter to WorkspaceView
- [ ] Modify `ContentView.swift` to pass `isInspectorVisible` binding to WorkspaceView
- [ ] Modify `WorkspaceView.swift` layout: wrap in HStack with Timeline (flexible) + InspectorView (fixed width)
- [ ] Add toggle button in WorkspaceView toolbar area (sidebar.right icon)
- [ ] Implement animated width transition with `withAnimation(.easeInOut(duration: 0.25))`
- [ ] Visibility persistence already handled by AppStateManager -- no changes needed there
- [ ] Run: `swift test --filter InspectorViewTests`

**Estimated Effort:** 2 hours

### Task 3: Event Selection State Hoisting (AC#1)

**Test file:** `SwiftWorkTests/Views/Workspace/Inspector/InspectorViewTests.swift`

**Tasks to make selection tests pass:**

- [ ] Add `@State private var selectedEventId: UUID?` to WorkspaceView
- [ ] Change TimelineView `selectedEventId` from `@State` to `@Binding`
- [ ] Add `.contentShape(Rectangle())` + `.onTapGesture` to all event views (not just ToolCardView)
- [ ] Add selection highlight (blue border) for non-tool events
- [ ] Pass selectedEvent and toolContentMap from WorkspaceView to InspectorView
- [ ] Run: `swift test --filter InspectorViewTests`

**Estimated Effort:** 2 hours

### Task 4: Existing Tests -- No Regression

- [ ] Run full test suite: `swift test`
- [ ] Verify all existing tests pass with WorkspaceView API changes
- [ ] Check that TimelineView @Binding change doesn't break TimelineViewRefactoredTests

**Estimated Effort:** 0.5 hours

---

## Running Tests

```bash
# Run all Inspector tests
swift test --filter InspectorViewTests

# Run specific test
swift test --filter InspectorViewTests/testInspectorViewEmptyStateWithNilEvent

# Run full test suite (regression check)
swift test

# Build only (fast check for compilation errors)
swift build
```

---

## Red-Green-Refactor Workflow

### RED Phase (Complete)

**TEA Agent Responsibilities:**

- All 26 tests written as red-phase scaffolds
- API contract defined for InspectorView and WorkspaceView changes
- Implementation tasks mapped to test coverage
- Test structure follows existing project patterns (ToolCardViewTests, TimelineEventViewsTests)

**Expected Failure Reasons:**

- `InspectorView(selectedEvent:toolContentMap:)` -- init does not accept these parameters yet (current InspectorView is a placeholder with no parameters)
- `WorkspaceView(... isInspectorVisible:)` -- init does not accept isInspectorVisible binding yet
- All P0 tests will fail at compilation due to missing init parameters

### GREEN Phase (DEV Team - Next Steps)

1. Start with Task 3 (event selection state hoisting) -- fundamental data flow change
2. Then Task 1 (InspectorView rewrite) -- core display logic
3. Then Task 2 (toggle mechanism) -- wiring
4. Finally Task 4 (regression check) -- safety net

### REFACTOR Phase (After All Tests Pass)

- Extract ToolEventInspector.swift if InspectorView exceeds 300 lines
- Ensure CopyButton is reused from ToolCardView (no duplication)
- Verify @ViewBuilder switch is exhaustive for all 19 event types

---

## Knowledge Base References Applied

- **data-factories.md** -- Factory pattern with overrides applied to `makeToolContent()`, `makeToolUseEvent()`, etc.
- **test-quality.md** -- Tests under 300 lines, explicit assertions, deterministic, isolated
- **test-healing-patterns.md** -- Avoided hardcoded values; used factory functions for test data
- **test-levels-framework.md** -- Unit tests for pure view logic and data mapping; integration tests for component binding

---

## File Change Impact

### Files Being Tested (will be modified in implementation)

| File | Change Type | Risk |
|---|---|---|
| `SwiftWork/Views/Workspace/Inspector/InspectorView.swift` | REWRITE (placeholder -> full panel) | High |
| `SwiftWork/Views/Workspace/WorkspaceView.swift` | UPDATE (add isInspectorVisible, selectedEventId, HStack layout) | High |
| `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` | UPDATE (selectedEventId @State -> @Binding) | Medium |
| `SwiftWork/App/ContentView.swift` | UPDATE (pass isInspectorVisible to WorkspaceView) | Low |

### Files NOT Modified (zero regression risk)

- `SwiftWork/Services/AppStateManager.swift` -- persistence already complete
- `SwiftWork/Models/UI/AgentEvent.swift` -- no changes needed
- `SwiftWork/Models/UI/ToolContent.swift` -- no changes needed
- `SwiftWork/SDKIntegration/AgentBridge.swift` -- no changes needed

---

## Notes

- InspectorView persistence (NFR21) is already implemented in AppStateManager. Tests do not need to cover persistence directly -- it is tested in AppStateManagerTests.
- The `@Binding` pattern for selectedEventId follows the same hoisting pattern used in Story 3-3 (SidebarView -> SessionRowView renaming state).
- OpenWork reference: `debug-panel.tsx` provides the UI interaction model, but SwiftWork's implementation is native SwiftUI.
- CopyButton can be reused from ToolCardView.swift -- do not duplicate.

---

**Generated by BMad TEA Agent** - 2026-05-03
