---
stepsCompleted: ['step-01-preflight-and-context', 'step-02-generation-mode', 'step-03-test-strategy', 'step-04-generate-tests']
lastStep: 'step-04-generate-tests'
lastSaved: '2026-05-03'
storyId: '4.1'
storyKey: '4-1-debug-panel'
storyFile: '_bmad-output/implementation-artifacts/4-1-debug-panel.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-4-1-debug-panel.md'
generatedTestFiles:
  - 'SwiftWorkTests/ViewModels/DebugViewModelTests.swift'
  - 'SwiftWorkTests/Views/Workspace/Inspector/DebugViewTests.swift'
inputDocuments:
  - '_bmad-output/implementation-artifacts/4-1-debug-panel.md'
  - '_bmad-output/project-context.md'
  - 'SwiftWork/SDKIntegration/AgentBridge.swift'
  - 'SwiftWork/Models/UI/AgentEvent.swift'
  - 'SwiftWork/Models/UI/AgentEventType.swift'
  - 'SwiftWork/Models/UI/ToolContent.swift'
  - 'SwiftWork/Views/Workspace/Inspector/InspectorView.swift'
  - 'SwiftWork/Views/Workspace/WorkspaceView.swift'
---

# ATDD Checklist -- Story 4.1: Debug Panel

## Summary

| Item | Value |
|------|-------|
| Story | 4.1 Debug Panel |
| Stack | Frontend (SwiftUI + XCTest) |
| Generation Mode | AI Generation (native Swift project, no browser automation) |
| Execution Mode | Sequential |
| Test Framework | XCTest |
| Test Files | 2 |
| Total Test Cases | 30 |

## Acceptance Criteria Mapping

### AC#1: Raw Event Stream (FR38)

> Given user opens Debug Panel, When Agent is executing or has executed tasks, Then display raw SDK JSON event stream with timestamps and event types.

| ID | Test Case | Level | Priority | File |
|----|-----------|-------|----------|------|
| AC1-01 | DebugViewModel filters out partialMessage events | Unit | P0 | DebugViewModelTests |
| AC1-02 | DebugViewModel returns all non-partialMessage events | Unit | P0 | DebugViewModelTests |
| AC1-03 | DebugViewModel returns empty list for empty session | Unit | P0 | DebugViewModelTests |
| AC1-04 | DebugViewModel preserves event order from AgentBridge | Unit | P1 | DebugViewModelTests |
| AC1-05 | DebugViewModel formats events as serializable JSON strings | Unit | P1 | DebugViewModelTests |
| AC1-06 | DebugView renders raw event stream tab | Component | P0 | DebugViewTests |
| AC1-07 | DebugView renders empty state when no events | Component | P0 | DebugViewTests |
| AC1-08 | DebugView handles all 20 AgentEventType cases | Component | P1 | DebugViewTests |

### AC#2: Token Statistics (FR39)

> Given Debug Panel Token statistics area, When session contains LLM calls, Then display real-time Token consumption: input, output, total, estimated cost.

| ID | Test Case | Level | Priority | File |
|----|-----------|-------|----------|------|
| AC2-01 | DebugViewModel aggregates single result event tokens | Unit | P0 | DebugViewModelTests |
| AC2-02 | DebugViewModel aggregates multiple result events | Unit | P0 | DebugViewModelTests |
| AC2-03 | DebugViewModel returns zero summary for empty session | Unit | P0 | DebugViewModelTests |
| AC2-04 | DebugViewModel extracts totalCostUsd correctly | Unit | P1 | DebugViewModelTests |
| AC2-05 | DebugViewModel handles result event with missing usage | Unit | P1 | DebugViewModelTests |
| AC2-06 | DebugView renders token statistics tab | Component | P0 | DebugViewTests |
| AC2-07 | DebugView renders zero-state token summary | Component | P1 | DebugViewTests |

### AC#3: Tool Execution Logs (FR40)

> Given Debug Panel tool log area, When Agent executed tool calls, Then display each tool's execution log: call time, parameters, duration, return status, result summary.

| ID | Test Case | Level | Priority | File |
|----|-----------|-------|----------|------|
| AC3-01 | DebugViewModel extracts tool logs from toolContentMap | Unit | P0 | DebugViewModelTests |
| AC3-02 | DebugViewModel returns empty logs for empty session | Unit | P0 | DebugViewModelTests |
| AC3-03 | DebugViewModel matches tool timestamps via toolUseId | Unit | P1 | DebugViewModelTests |
| AC3-04 | DebugViewModel includes tool status (completed/failed/running) | Unit | P0 | DebugViewModelTests |
| AC3-05 | DebugViewModel truncates long result output | Unit | P2 | DebugViewModelTests |
| AC3-06 | DebugView renders tool logs tab | Component | P0 | DebugViewTests |
| AC3-07 | DebugView renders tool log with all statuses | Component | P1 | DebugViewTests |

### Integration: WorkspaceView

| ID | Test Case | Level | Priority | File |
|----|-----------|-------|----------|------|
| INT-01 | WorkspaceView accepts isDebugPanelVisible binding | Component | P0 | DebugViewTests |
| INT-02 | WorkspaceView renders DebugView when visible | Component | P1 | DebugViewTests |
| INT-03 | Debug Panel and Inspector can be visible simultaneously | Component | P1 | DebugViewTests |

## Priority Distribution

| Priority | Count | Description |
|----------|-------|-------------|
| P0 | 14 | Must-pass for story acceptance |
| P1 | 13 | Important but not blocking |
| P2 | 1 | Nice-to-have edge case |
| P3 | 0 | Future consideration |

## Test Level Distribution

| Level | Count |
|-------|-------|
| Unit (DebugViewModel) | 14 |
| Component (DebugView + WorkspaceView) | 10 |
| Integration | 3 |

## TDD Red Phase Status

- All tests are designed to **FAIL** until implementation is complete
- Tests exercise types and APIs that do not yet exist (`DebugViewModel`, `DebugView`)
- WorkspaceView integration tests verify new binding parameter `isDebugPanelVisible`
- Tests follow existing project conventions: `@MainActor`, `XCTestCase`, `@testable import SwiftWork`
