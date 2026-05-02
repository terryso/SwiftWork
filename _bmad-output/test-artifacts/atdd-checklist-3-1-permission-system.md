---
stepsCompleted: ['step-01-preflight-and-context', 'step-02-generation-mode', 'step-03-test-strategy', 'step-04-generate-tests', 'step-04c-aggregate']
lastStep: 'step-04c-aggregate'
lastSaved: '2026-05-02'
storyId: '3.1'
storyKey: '3-1-permission-system'
storyFile: '_bmad-output/implementation-artifacts/3-1-permission-system.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-3-1-permission-system.md'
generatedTestFiles:
  - 'SwiftWorkTests/SDKIntegration/PermissionHandlerTests.swift'
  - 'SwiftWorkTests/Models/UI/PendingPermissionRequestTests.swift'
inputDocuments:
  - '_bmad-output/implementation-artifacts/3-1-permission-system.md'
  - '_bmad-output/project-context.md'
  - 'SwiftWork/Models/UI/PermissionDecision.swift'
  - 'SwiftWork/Models/SwiftData/PermissionRule.swift'
  - 'SwiftWork/SDKIntegration/AgentBridge.swift'
  - 'SwiftWork/Views/Permission/PermissionDialogView.swift'
  - 'SwiftWorkTests/Support/TestDataFactory.swift'
---

# ATDD Checklist: Story 3.1 权限系统实现

## TDD Red Phase (Current)

Red-phase test scaffolds generated. All tests use `XCTSkip()` to mark as pending at runtime.

### Swift ATDD Red Phase Note

In TypeScript/JavaScript, `test.skip()` prevents test execution while keeping the file compilable. In Swift, `XCTSkip()` is a **runtime** throw -- the code must compile first. Therefore:

- **The test files will NOT compile** until the implementation types (`PermissionHandler`, `GlobalPermissionMode`, `PendingPermissionRequest`, `PermissionDialogResult`, `PermissionAuditEntry`) are created.
- **This compile failure IS the red phase signal.** It clearly shows what types need to exist.
- **Activation process**: Create the minimal type stubs first (empty class/struct/enum with correct signatures), then the tests compile and are skipped at runtime via `XCTSkip()`. Remove `XCTSkip()` lines one-by-one during green phase.

### Summary

- Unit Tests (PermissionHandler): 16 test methods
- Unit Tests (PendingPermissionRequest): 10 test methods
- **Total: 26 test scaffolds (all skipped)**

## Acceptance Criteria Coverage

### AC#1: PermissionHandler evaluates tool calls, shows Sheet dialog when requiresApproval
| Test File | Test Method | Priority | Status |
|-----------|------------|----------|--------|
| PermissionHandlerTests | testAutoApproveReturnsApproved | P0 | Skipped (Red) |
| PermissionHandlerTests | testDenyAllReturnsDenied | P0 | Skipped (Red) |
| PermissionHandlerTests | testManualReviewNoRulesReturnsRequiresApproval | P0 | Skipped (Red) |
| PermissionHandlerTests | testManualReviewMatchesPersistentAllowRule | P0 | Skipped (Red) |
| PermissionHandlerTests | testManualReviewMatchesPersistentDenyRule | P0 | Skipped (Red) |
| PermissionHandlerTests | testManualReviewPersistentRuleOverridesSessionOverride | P1 | Skipped (Red) |

### AC#2: Allow Once authorizes current call, next similar operation still needs approval
| Test File | Test Method | Priority | Status |
|-----------|------------|----------|--------|
| PermissionHandlerTests | testAddSessionOverrideAllowsToolForSession | P0 | Skipped (Red) |
| PermissionHandlerTests | testSessionOverrideIsSessionScoped | P1 | Skipped (Red) |

### AC#3: Always Allow persists PermissionRule, future auto-passes
| Test File | Test Method | Priority | Status |
|-----------|------------|----------|--------|
| PermissionHandlerTests | testAddPersistentRuleCreatesPermissionRule | P0 | Skipped (Red) |
| PermissionHandlerTests | testPersistentRuleMatchesByToolName | P1 | Skipped (Red) |

### AC#4: Deny rejects tool call, Agent receives rejection feedback
| Test File | Test Method | Priority | Status |
|-----------|------------|----------|--------|
| PermissionHandlerTests | testDenyAllDeniesAllTools | P0 | Skipped (Red) |
| PermissionHandlerTests | testManualReviewDenyRuleReturnsDenied | P0 | Skipped (Red) |

### AC#5: Audit log records all permission decisions
| Test File | Test Method | Priority | Status |
|-----------|------------|----------|--------|
| PermissionHandlerTests | testAuditLogRecordsEveryDecision | P0 | Skipped (Red) |
| PermissionHandlerTests | testAuditLogEntryContainsCorrectFields | P0 | Skipped (Red) |
| PermissionHandlerTests | testAuditLogRecordsSessionOverrideDecisions | P1 | Skipped (Red) |

### Data Models & Integration
| Test File | Test Method | Priority | Status |
|-----------|------------|----------|--------|
| PendingPermissionRequestTests | testPendingPermissionRequestStoresMetadata | P0 | Skipped (Red) |
| PendingPermissionRequestTests | testPendingPermissionRequestIsIdentifiable | P0 | Skipped (Red) |
| PendingPermissionRequestTests | testPendingPermissionRequestIdentity | P0 | Skipped (Red) |
| PendingPermissionRequestTests | testResolveAllowOnce | P0 | Skipped (Red) |
| PendingPermissionRequestTests | testResolveAlwaysAllow | P0 | Skipped (Red) |
| PendingPermissionRequestTests | testResolveDeny | P0 | Skipped (Red) |
| PendingPermissionRequestTests | testResolveTwiceDoesNotCrash | P1 | Skipped (Red) |
| PendingPermissionRequestTests | testPermissionDialogResultAllCases | P0 | Skipped (Red) |
| PendingPermissionRequestTests | testPermissionAuditEntryStructure | P0 | Skipped (Red) |
| PendingPermissionRequestTests | testPermissionAuditEntryIsSendable | P1 | Skipped (Red) |

### Edge Cases
| Test File | Test Method | Priority | Status |
|-----------|------------|----------|--------|
| PermissionHandlerTests | testEvaluateHandlesEmptyInput | P1 | Skipped (Red) |
| PermissionHandlerTests | testEvaluateHandlesUnknownToolName | P1 | Skipped (Red) |
| PermissionHandlerTests | testGlobalModeSwitchAtRuntime | P2 | Skipped (Red) |
| PermissionHandlerTests | testDefaultGlobalModeIsAutoApprove | P2 | Skipped (Red) |

## Priority Distribution

| Priority | Count |
|----------|-------|
| P0 | 17 |
| P1 | 7 |
| P2 | 2 |
| P3 | 0 |
| **Total** | **26** |

## Test Strategy

- **Detected Stack:** Backend (Swift/XCTest -- no frontend browser tests)
- **Test Framework:** XCTest (Swift Package Manager)
- **Generation Mode:** AI Generation (backend stack, no browser recording needed)
- **Execution Mode:** Sequential (single agent)

### Test Levels
- **Unit**: PermissionHandler evaluate logic, PendingPermissionRequest model, PermissionAuditEntry model, PermissionDialogResult enum
- **Integration**: To be added during implementation (AgentBridge + PermissionHandler + SDK canUseTool callback)

### What is NOT tested here (deferred to implementation phase)
- **UI Tests**: PermissionDialogView Sheet rendering, button interactions, parameter display -- these require SwiftUI view testing or manual QA
- **Integration Tests**: AgentBridge canUseTool callback integration with PermissionHandler -- requires mocking SDK Agent
- **E2E Tests**: Full permission flow from SDK tool call through UI dialog to resolution -- requires running app

## Files to Implement (Red Phase Triggers)

These files must be created/modified for the tests to pass:

### NEW files:
1. `SwiftWork/SDKIntegration/PermissionHandler.swift` -- PermissionHandler @Observable @MainActor class
2. `SwiftWork/Models/UI/PermissionAuditEntry.swift` -- Audit log entry struct (Sendable)
3. `SwiftWork/Models/UI/PendingPermissionRequest.swift` -- Request model with continuation
4. `SwiftWork/Models/UI/PermissionDialogResult.swift` -- User dialog result enum (if not in PendingPermissionRequest)

### UPDATE files:
5. `SwiftWork/Views/Permission/PermissionDialogView.swift` -- Complete rewrite from stub
6. `SwiftWork/SDKIntegration/AgentBridge.swift` -- Add canUseTool callback + pendingPermissionRequest
7. `SwiftWork/Views/Workspace/WorkspaceView.swift` -- Add .sheet(item:) binding

### Types to define:
- `GlobalPermissionMode` enum: `.autoApprove`, `.manualReview`, `.denyAll`
- `PermissionDialogResult` enum: `.allowOnce`, `.alwaysAllow`, `.deny`

## Next Steps (Task-by-Task Activation)

During implementation of each task from Story 3-1:

1. Remove `throw XCTSkip(...)` from the relevant test methods
2. Run tests: `swift test --filter PermissionHandlerTests` or `swift test --filter PendingPermissionRequestTests`
3. Verify the activated test **fails first**, then implement the feature
4. Verify the test passes after implementation (green phase)
5. Refactor if needed, keeping tests green
6. Commit passing tests

### Suggested activation order (matches story task order):
1. Task 1: Activate PermissionHandler tests (evaluate, global modes, session overrides, persistent rules)
2. Task 2: Activate audit log tests (auditLog entries)
3. Task 4: UI tests remain manual/visual for now
4. Task 5: Activate PendingPermissionRequest and continuation tests

## Implementation Guidance

### Key API signatures to implement:

```swift
// GlobalPermissionMode enum
enum GlobalPermissionMode: Sendable {
    case autoApprove, manualReview, denyAll
}

// PermissionDialogResult enum
enum PermissionDialogResult: Sendable {
    case allowOnce, alwaysAllow, deny
}

// PermissionAuditEntry struct
struct PermissionAuditEntry: Sendable {
    let toolName: String
    let input: String
    let decision: PermissionDecision
    let timestamp: Date
    let sessionOverride: Bool
}

// PermissionHandler class
@MainActor @Observable
final class PermissionHandler {
    var globalMode: GlobalPermissionMode
    var auditLog: [PermissionAuditEntry]

    func evaluate(toolName: String, input: [String: Any]) -> PermissionDecision
    func addSessionOverride(toolName: String, decision: PermissionDecision)
    func addPersistentRule(toolName: String, pattern: String, decision: Decision)
    func clearSessionOverrides()
}
```

### Critical constraints:
- `@Sendable` closure in `canUseTool` callback requires `await MainActor.run {}` for PermissionHandler access
- `withCheckedContinuation` must resume exactly once (escape key / sheet dismiss = deny)
- Default `globalMode` must be `.autoApprove` for backward compatibility
- `PermissionDecision` (existing) and `PermissionDialogResult` (new) are distinct types
