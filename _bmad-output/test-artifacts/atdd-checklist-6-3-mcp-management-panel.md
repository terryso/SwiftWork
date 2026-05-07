---
stepsCompleted:
  - step-01-preflight-and-context
  - step-02-generation-mode
  - step-03-test-strategy
  - step-04c-aggregate
  - step-05-validate-and-complete
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-05-07'
storyId: '6.3'
storyKey: '6-3-mcp-management-panel'
storyFile: '_bmad-output/implementation-artifacts/6-3-mcp-management-panel.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-6-3-mcp-management-panel.md'
generatedTestFiles:
  - 'SwiftWorkTests/ViewModels/MCPManagementViewModelTests.swift'
  - 'SwiftWorkTests/Views/Settings/MCPManagementViewTests.swift'
inputDocuments:
  - '_bmad-output/implementation-artifacts/6-3-mcp-management-panel.md'
  - 'SwiftWork/Services/MCPServerConfigStore.swift'
  - 'SwiftWork/Models/SwiftData/MCPServerConfig.swift'
  - 'SwiftWork/SDKIntegration/AgentBridge.swift'
  - 'SwiftWork/Views/Settings/SettingsView.swift'
  - 'SwiftWorkTests/ViewModels/AddMCPServerViewModelTests.swift'
  - 'SwiftWorkTests/Services/MCPServerConfigStoreTests.swift'
---

# ATDD Checklist: Story 6.3 — MCP 管理面板

## TDD Red Phase (Current)

Red-phase test scaffolds generated. All tests assert EXPECTED behavior and will FAIL until the feature is implemented.

- **Unit Tests (ViewModel):** 37 tests
- **Unit Tests (View):** 8 tests
- **Total:** 45 tests
- **TDD Phase:** RED (all tests assert expected behavior, will compile-fail or assertion-fail)

## Test Stack

| Property | Value |
|----------|-------|
| Stack | `backend` (Swift/macOS native) |
| Framework | XCTest |
| Pattern | @MainActor + SwiftData in-memory containers |
| Mock Strategy | Direct AgentBridge instantiation (no real SDK Agent) |

## Acceptance Criteria Coverage

### AC1 — Server 列表显示

| Test ID | Priority | Test Method | Level |
|---------|----------|-------------|-------|
| AC1-01 | P0 | `testLoadServersPopulatesFromStore` | Unit (ViewModel) |
| AC1-02 | P0 | `testLoadServersReturnsEmptyWhenNoConfigs` | Unit (ViewModel) |
| AC1-03 | P0 | `testLoadServersSortsByCreationDate` | Unit (ViewModel) |
| AC1-04 | P0 | `testStatusForServerReturnsDisabledWhenNotEnabled` | Unit (ViewModel) |
| AC1-05 | P0 | `testStatusForServerReturnsOfflineWhenAgentNotRunning` | Unit (ViewModel) |
| AC1-06 | P0 | `testStatusForServerReturnsConnectedWhenSDKConnected` | Unit (ViewModel) |
| AC1-07 | P0 | `testStatusForServerReturnsFailedWhenSDKFailed` | Unit (ViewModel) |
| AC1-08 | P0 | `testStatusForServerReturnsDisconnectedWhenMissingFromSDK` | Unit (ViewModel) |
| AC1-09 | P0 | `testDisplayStatusHasSixCases` | Unit (Enum) |
| AC1-10 | P0 | `testConnectedStatusIsGreen` | Unit (Enum) |
| AC1-11 | P0 | `testFailedStatusIsRed` | Unit (Enum) |
| AC1-12 | P0 | `testPendingStatusIsAmber` | Unit (Enum) |
| AC1-13 | P0 | `testDisabledStatusIsGray` | Unit (Enum) |
| AC1-14 | P0 | `testDisconnectedStatusIsGray` | Unit (Enum) |
| AC1-15 | P0 | `testOfflineStatusIsGray` | Unit (Enum) |
| AC1-16 | P0 | `testDisplayStatusHasLocalizedLabels` | Unit (Enum) |
| AC1-17 | P0 | `testSettingsViewHasMCPTab` | Unit (View) |
| AC1-18 | P0 | `testMCPManagementViewInitializesWithStore` | Unit (View) |

### AC2 — 展开详情

| Test ID | Priority | Test Method | Level |
|---------|----------|-------------|-------|
| AC2-01 | P0 | `testSelectServerSetsSelection` | Unit (ViewModel) |
| AC2-02 | P0 | `testSelectServerTogglesOffWhenSameClicked` | Unit (ViewModel) |
| AC2-03 | P0 | `testSelectServerSwitchesToDifferentServer` | Unit (ViewModel) |
| AC2-04 | P0 | `testServerStatusesContainsToolsList` | Unit (ViewModel) |

### AC3 — 禁用 Server

| Test ID | Priority | Test Method | Level |
|---------|----------|-------------|-------|
| AC3-01 | P0 | `testToggleServerDisablesConfig` | Unit (ViewModel) |
| AC3-02 | P0 | `testToggleServerReloadsServers` | Unit (ViewModel) |
| AC3-03 | P1 | `testToggleServerNonExistentNameDoesNotCrash` | Unit (ViewModel) |

### AC4 — 启用 Server

| Test ID | Priority | Test Method | Level |
|---------|----------|-------------|-------|
| AC4-01 | P0 | `testToggleServerEnablesConfig` | Unit (ViewModel) |

### AC5 — 删除 Server

| Test ID | Priority | Test Method | Level |
|---------|----------|-------------|-------|
| AC5-01 | P0 | `testDeleteServerRemovesConfig` | Unit (ViewModel) |
| AC5-02 | P0 | `testDeleteServerReloadsList` | Unit (ViewModel) |
| AC5-03 | P0 | `testDeleteServerClearsSelection` | Unit (ViewModel) |
| AC5-04 | P1 | `testDeleteServerNonExistentDoesNotCrash` | Unit (ViewModel) |
| AC5-05 | P0 | `testMCPManagementViewShowsDeleteConfirmation` | Unit (View) |

### AC6 — 重连 Server

| Test ID | Priority | Test Method | Level |
|---------|----------|-------------|-------|
| AC6-01 | P0 | `testReconnectServerCallsAgentBridge` | Unit (ViewModel) |
| AC6-02 | P0 | `testReconnectServerRefreshesStatus` | Unit (ViewModel) |
| AC6-03 | P1 | `testReconnectServerNonExistentDoesNotCrash` | Unit (ViewModel) |

### AC7 — 错误详情展示

| Test ID | Priority | Test Method | Level |
|---------|----------|-------------|-------|
| AC7-01 | P0 | `testServerStatusesContainsErrorFromSDK` | Unit (ViewModel) |
| AC7-02 | P0 | `testFromSDKNeedsAuthMapsToFailed` | Unit (Enum) |

### AC8 — 空状态

| Test ID | Priority | Test Method | Level |
|---------|----------|-------------|-------|
| AC8-01 | P0 | `testViewModelInitializesWithEmptyServers` | Unit (ViewModel) |
| AC8-02 | P0 | `testIsEmptyStateTrueWhenNoServers` | Unit (ViewModel) |
| AC8-03 | P0 | `testIsEmptyStateFalseWhenServersExist` | Unit (ViewModel) |
| AC8-04 | P0 | `testMCPManagementViewShowsEmptyState` | Unit (View) |

## SDK API Mapping from() Tests

| Test ID | Priority | Test Method |
|---------|----------|-------------|
| SDK-01 | P0 | `testFromSDKConnected` |
| SDK-02 | P0 | `testFromSDKFailed` |
| SDK-03 | P0 | `testFromSDKPending` |
| SDK-04 | P0 | `testFromSDKDisabled` |
| SDK-05 | P0 | `testFromSDKNeedsAuthMapsToFailed` |

## Generated Files

| File | Tests | AC Coverage |
|------|-------|-------------|
| `SwiftWorkTests/ViewModels/MCPManagementViewModelTests.swift` | 37 | AC1-AC8 |
| `SwiftWorkTests/Views/Settings/MCPManagementViewTests.swift` | 8 | AC1, AC5, AC8 |

## Red-Green-Refactor Workflow

### RED Phase (Current — TEA Complete)

1. All 45 test scaffolds generated asserting EXPECTED behavior
2. Tests will fail with compile errors until types/methods are implemented:
   - `MCPManagementViewModel` class
   - `MCPServerDisplayStatus` enum
   - `MCPManagementView` SwiftUI view
   - AgentBridge MCP management methods (`mcpServerStatus()`, `toggleMcpServer()`, `reconnectMcpServer()`)

### GREEN Phase (DEV Team)

During implementation of each task:

1. Implement `MCPServerDisplayStatus` enum (Task 2.2 context) — activates AC1 display status tests
2. Implement `MCPManagementViewModel` — activates AC1 load, AC2 selection, AC3/AC4 toggle, AC5 delete, AC6 reconnect, AC7 error, AC8 empty state tests
3. Add `SettingsTab.mcp` to SettingsView — activates AC1 view tests
4. Create `MCPManagementView` — activates AC1/AC8 view tests
5. Add MCP methods to AgentBridge — enables integration testing

### REFACTOR Phase

After all tests pass:

- Review test coverage for gaps
- Extract shared test helpers if patterns emerge
- Consider adding performance tests for large server lists

## Implementation Guidance

### Types to Create

| Type | File | Priority |
|------|------|----------|
| `MCPServerDisplayStatus` (enum) | `SwiftWork/Views/Settings/MCP/MCPManagementView.swift` | P0 |
| `MCPManagementViewModel` (class) | `SwiftWork/Views/Settings/MCP/MCPManagementView.swift` | P0 |
| `MCPManagementView` (SwiftUI View) | `SwiftWork/Views/Settings/MCP/MCPManagementView.swift` | P0 |
| `MCPServerRowView` (SwiftUI View) | `SwiftWork/Views/Settings/MCP/MCPServerRowView.swift` | P0 |
| `MCPServerDetailView` (SwiftUI View) | `SwiftWork/Views/Settings/MCP/MCPServerDetailView.swift` | P0 |

### Methods to Add to AgentBridge

| Method | Signature |
|--------|-----------|
| `mcpServerStatus()` | `func mcpServerStatus() async -> [String: McpServerStatus]` |
| `toggleMcpServer(name:enabled:)` | `func toggleMcpServer(name: String, enabled: Bool) async throws` |
| `reconnectMcpServer(name:)` | `func reconnectMcpServer(name: String) async throws` |

### Files to Modify

| File | Change |
|------|--------|
| `SwiftWork/Views/Settings/SettingsView.swift` | Add `case mcp = "MCP Servers"` to SettingsTab; add `mcpTab` ViewBuilder; widen picker to 340pt |

## Execution Commands

```bash
# Run all MCP management tests
swift test --filter MCPManagementViewModelTests
swift test --filter MCPServerDisplayStatusTests
swift test --filter MCPManagementViewTests

# Run all MCP-related tests ( Stories 6.1 + 6.2 + 6.3)
swift test --filter MCP
```

## Key Risks and Assumptions

1. **McpServerStatus availability:** Tests assume `McpServerStatus` struct from OpenAgentSDK has `name`, `status`, `tools`, and `error` fields
2. **McpServerStatusEnum availability:** Tests assume SDK enum has `.connected`, `.failed`, `.pending`, `.disabled`, `.needsAuth` cases
3. **AgentBridge.weak reference:** ViewModel holds `weak` reference to AgentBridge — tests use direct instantiation which means agent is nil (expected for red phase)
4. **SwiftUI View tests:** Limited to initialization/protocol conformance — full UI behavior tested manually
5. **No real SDK Agent:** All Agent-based tests verify method calls without actual Agent running — SDK status retrieval returns empty

## Knowledge Base References Applied

- `data-factories.md` — Test helper factories (makeContext, makeStore, addTestConfig)
- `component-tdd.md` — Red-green-refactor workflow
- `test-quality.md` — Isolation rules, one-assertion-per-test pattern
- `test-healing-patterns.md` — Graceful failure handling in tests

## Next Steps

1. **Implement feature** using `dev-story` workflow for Story 6-3
2. **Activate tests** by removing compile errors as types are implemented
3. **Run tests** after each task to verify RED -> GREEN transition
4. **Commit** passing tests incrementally
