---
stepsCompleted: ['step-01-preflight-and-context', 'step-02-generation-mode', 'step-03-test-strategy', 'step-04c-aggregate', 'step-05-validate-and-complete']
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-05-07'
storyId: '6.2'
storyKey: '6-2-mcp-add-edit-modal'
storyFile: '/Users/nick/CascadeProjects/swiftwork/_bmad-output/implementation-artifacts/6-2-mcp-add-edit-modal.md'
atddChecklistPath: '/Users/nick/CascadeProjects/swiftwork/_bmad-output/test-artifacts/atdd-checklist-6-2-mcp-add-edit-modal.md'
generatedTestFiles:
  - '/Users/nick/CascadeProjects/swiftwork/SwiftWorkTests/ViewModels/AddMCPServerViewModelTests.swift'
---

# ATDD Checklist: Story 6.2 — MCP 添加与编辑弹窗

## TDD Red Phase (Current)

Red-phase test scaffolds generated.

- **ViewModel Tests:** 32 tests (will fail until ViewModel is implemented)
- **Stack:** Backend (Swift/XCTest)
- **Execution Mode:** Sequential (single test file, no subagents needed)

## Acceptance Criteria Coverage

| AC | Description | Tests | Priority | Level |
|----|-------------|-------|----------|-------|
| AC1 | AddMCPServerSheet 弹窗 — ViewModel 初始状态 | `testViewModelInitializesWithEmptyName`, `testViewModelInitializesWithRemoteMode`, `testViewModelInitializesWithEmptyURL`, `testViewModelInitializesWithEmptyCommand`, `testViewModelInitializesWithNoError`, `testViewModelInitializesNotSubmitting` + `MCPTransportModeTests` (3 tests) | P0 | Unit |
| AC2 | Remote 类型配置 (SSE) | `testSubmitRemoteConfigCreatesSSEConfig`, `testSubmitRemoteConfigPersistsToSwiftData`, `testSubmitRemoteConfigWithProjectScope` | P0 | Unit |
| AC3 | Local 类型配置 (stdio + command 解析) | `testSubmitLocalConfigCreatesStdioConfig`, `testCommandParsingExtractsFirstTokenAsCommand`, `testCommandWithNoArgsProducesEmptyArgs`, `testSubmitLocalConfigWithProjectScope` | P0 | Unit |
| AC4 | 编辑已有配置 | `testEditModePreFillsViewModelWithExistingConfig`, `testEditModePreFillsViewModelWithExistingStdioConfig`, `testSubmitEditCallsStoreReplace`, `testEditPreservesConfigID`, `testEditUpdatesTimestamp` | P0 | Unit |
| AC5 | 输入验证 | `testValidationFailsWhenNameIsEmptyRemoteMode`, `testValidationFailsWhenNameIsWhitespace`, `testValidationFailsWhenURLEmptyInRemoteMode`, `testValidationFailsWhenURLIsWhitespaceInRemoteMode`, `testValidationFailsWhenCommandEmptyInLocalMode`, `testValidationFailsWhenCommandIsWhitespaceInLocalMode`, `testValidationPassesWithValidRemoteConfig`, `testValidationPassesWithValidLocalConfig`, `testValidateSetsErrorMessageForInvalidInput`, `testValidateClearsErrorMessageForValidInput` | P0 | Unit |

## Test Priority Distribution

| Priority | Count | Description |
|----------|-------|-------------|
| P0 | 22 | Core acceptance criteria — must pass before merge |
| P1 | 10 | Edge cases and quality improvements |
| **Total** | **32** | |

## Test File Inventory

### Generated Test Files

| File | Tests | AC Coverage |
|------|-------|-------------|
| `SwiftWorkTests/ViewModels/AddMCPServerViewModelTests.swift` | 32 | AC1–AC5 |
| `SwiftWorkTests/ViewModels/MCPTransportModeTests.swift` (embedded in same file) | 3 | AC1 |

### Dependencies (already exist, not regenerated)

| File | Purpose |
|------|---------|
| `SwiftWorkTests/Services/MCPServerConfigStoreTests.swift` | Story 6-1 store CRUD tests |
| `SwiftWorkTests/Support/TestDataFactory.swift` | Shared test data helpers |

## Implementation Notes

### Types to Implement (Red Phase)

These types must be created for the tests to compile:

1. **`MCPTransportMode`** enum (`SwiftWork/Views/Settings/MCP/MCPTransportTypePicker.swift`)
   - Cases: `.remote`, `.local`
   - RawValue: `String`
   - Conformance: `CaseIterable`

2. **`AddMCPServerViewModel`** class (`SwiftWork/Views/Settings/MCP/AddMCPServerSheet.swift`)
   - `@MainActor @Observable final class`
   - Properties: `name`, `transportMode`, `url`, `command`, `isSubmitting`, `errorMessage`
   - Computed: `isValid: Bool`
   - Methods: `submit(store:scope:workspacePath:) throws -> MCPServerConfig`, `submitEdit(originalConfig:store:scope:workspacePath:) throws -> MCPServerConfig`, `validate() -> Bool`, `reset()`, `populateFromConfig(_:)`
   - Private: `parseCommand(_:) -> (command: String, args: [String])`

### Command Parsing Logic (AC3)

The ViewModel must parse a command string like `"npx -y @modelcontextprotocol/server-filesystem /tmp"` into:
- `command`: `"npx"` (first token)
- `args`: `["-y", "@modelcontextprotocol/server-filesystem", "/tmp"]` (remaining tokens, JSON-encoded as Data)

For edit mode, the reverse is needed: reconstruct the command string from `config.command` + `config.decodedArgs`.

### Store API Usage

| Operation | Store Method | Used In |
|-----------|-------------|---------|
| Add | `MCPServerConfigStore.add(...)` | `submit()` |
| Edit | `MCPServerConfigStore.replace(...)` | `submitEdit()` |
| List | `MCPServerConfigStore.list()` | Duplicate name check (handled by store) |

## Next Steps (Task-by-Task Activation)

During implementation of each task:

1. Create `MCPTransportMode` enum (Task 1) — activates `MCPTransportModeTests`
2. Create `AddMCPServerViewModel` with form state (Task 2.2, 2.3) — activates AC1 init tests
3. Implement validation logic (Task 2.4) — activates AC5 tests
4. Implement `submit()` for Remote mode (Task 2.5, 2.6) — activates AC2 tests
5. Implement `submit()` for Local mode with command parsing (Task 2.5) — activates AC3 tests
6. Implement `submitEdit()` and `populateFromConfig()` (Task 3) — activates AC4 tests
7. Run full test suite: `swift test` or Xcode Test Navigator
8. Verify all tests pass (green phase)
9. Commit passing tests

## Input Documents

- `/Users/nick/CascadeProjects/swiftwork/_bmad-output/implementation-artifacts/6-2-mcp-add-edit-modal.md` — Story file
- `/Users/nick/CascadeProjects/swiftwork/_bmad-output/project-context.md` — Project context
- `/Users/nick/CascadeProjects/swiftwork/SwiftWork/Services/MCPServerConfigStore.swift` — Store API
- `/Users/nick/CascadeProjects/swiftwork/SwiftWork/Models/SwiftData/MCPServerConfig.swift` — Model
- `/Users/nick/CascadeProjects/swiftwork/SwiftWorkTests/Services/MCPServerConfigStoreTests.swift` — Existing pattern reference
- `/Users/nick/CascadeProjects/swiftwork/SwiftWorkTests/Support/TestDataFactory.swift` — Factory pattern reference

## Recommended Next Workflow

- **Implement:** `bmad-dev-story 6-2` — Story implementation
- **After implementation:** Run `swift test` to verify green phase
- **Traceability:** `bmad-testarch-trace 6-2` — Generate traceability matrix after green phase
