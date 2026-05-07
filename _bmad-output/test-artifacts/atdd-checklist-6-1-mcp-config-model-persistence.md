---
stepsCompleted: ['step-01-preflight-and-context', 'step-02-generation-mode', 'step-03-test-strategy', 'step-04-generate-tests', 'step-04c-aggregate', 'step-05-validate-and-complete']
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-05-07'
storyId: '6.1'
storyKey: '6-1-mcp-config-model-persistence'
storyFile: '_bmad-output/implementation-artifacts/6-1-mcp-config-model-persistence.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-6-1-mcp-config-model-persistence.md'
generatedTestFiles:
  - 'SwiftWorkTests/Services/MCPServerConfigStoreTests.swift'
inputDocuments:
  - '_bmad-output/implementation-artifacts/6-1-mcp-config-model-persistence.md'
  - '_bmad-output/project-context.md'
  - '_bmad/tea/config.yaml'
  - '.build/checkouts/checkouts/open-agent-sdk-swift/Sources/OpenAgentSDK/Types/MCPConfig.swift'
  - 'SwiftWork/Models/SwiftData/PermissionRule.swift'
  - 'SwiftWork/Models/SwiftData/Session.swift'
  - 'SwiftWork/Models/SwiftData/AppConfiguration.swift'
  - 'SwiftWork/App/SwiftWorkApp.swift'
  - 'SwiftWork/SDKIntegration/AgentBridge.swift'
  - 'SwiftWorkTests/Services/EventStoreTests.swift'
---

# ATDD Checklist: Story 6.1 - MCP 配置模型与持久化

## TDD Red Phase (Current)

Red-phase test scaffolds generated.

- Unit/Integration Tests: 34 tests (will compile-fail until `MCPServerConfig`, `TransportType`, `MCPServerScope`, and `MCPServerConfigStore` are implemented)
- No E2E tests (Swift/XCTest backend project -- not applicable)

## Acceptance Criteria Coverage

| AC | Description | Test Coverage | Priority |
|----|-------------|---------------|----------|
| AC#1 | SwiftData 持久化模型 | `testMCPServerConfigHasRequiredFields`, `testTransportTypeHasThreeCases`, `testMCPServerScopeHasTwoCases`, `testTransportTypeRawValues`, `testMCPServerScopeRawValues`, `testMCPServerConfigNameIsUnique`, `testMCPServerConfigIdIsUnique`, `testMCPServerConfigIsPersistentModel`, `testAddMCPServerConfig`, `testListMCPServerConfigs`, `testUpdateMCPServerConfig`, `testDeleteMCPServerConfig`, `testListEmptyWhenNoConfigs`, `testDecodedArgsReturnsCorrectArray`, `testDecodedEnvReturnsCorrectDictionary`, `testDecodedHeadersReturnsCorrectDictionary`, `testDecodedArgsReturnsNilWhenNil`, `testTransportTypeIsSendable`, `testMCPServerScopeIsSendable` | P0/P1 |
| AC#2 | 应用重启自动恢复 | `testConfigsPersistAfterSave` | P0 |
| AC#3 | 项目级 scope 隔离 | `testGlobalConfigsVisibleForAllWorkspaces`, `testProjectConfigsOnlyVisibleForMatchingWorkspace`, `testMixedGlobalAndProjectConfigsMerged`, `testDisabledConfigsExcludedFromWorkspaceQuery`, `testListByScope` | P0/P1 |
| AC#4 | 配置转 SDK McpServerConfig | `testStdioConfigConvertsToSDKConfig`, `testSSEConfigConvertsToSDKConfig`, `testHTTPConfigConvertsToSDKConfig`, `testStdioConfigWithoutCommandSkipped`, `testSSEConfigWithoutURLSkipped`, `testDisabledConfigsExcludedFromSDKConversion`, `testMultipleConfigsConvertToSDKDictionary`, `testAgentBridgeConfigurePassesMCPConfigsToSDK` | P0/P1 |
| Error | 错误处理 | `testStoreHandlesErrorsGracefully`, `testDeleteNonExistentConfigDoesNotCrash` | P1 |

## Test Priority Breakdown

- **P0 (Must pass):** 21 tests -- critical path for all 4 ACs
- **P1 (Should pass):** 13 tests -- edge cases, helper methods, and Sendable conformance

## Implementation Guidance

### New source files to create:

1. **`SwiftWork/Models/SwiftData/MCPServerConfig.swift`**
   - `TransportType` enum: `.stdio`, `.sse`, `.http` (String rawValue, Codable, Sendable)
   - `MCPServerScope` enum: `.project`, `.global` (String rawValue, Codable, Sendable)
   - `MCPServerConfig` @Model class with all fields per AC1
   - Extension with `decodedArgs`, `decodedEnv`, `decodedHeaders` computed properties

2. **`SwiftWork/Services/MCPServerConfigStore.swift`**
   - `MCPServerConfigStore` @MainActor final class
   - CRUD methods: `add`, `update`, `delete`, `list`, `list(scope:)`
   - `enabledConfigsForWorkspace(_:)` -- scope-aware filtering
   - `toSDKConfigs(_:)` -- converts `[MCPServerConfig]` to `[String: McpServerConfig]`

### Existing files to modify:

3. **`SwiftWork/App/SwiftWorkApp.swift`** -- register `MCPServerConfig.self` in `modelContainer`
4. **`SwiftWork/SDKIntegration/AgentBridge.swift`** -- inject `MCPServerConfigStore`, pass MCP configs to `AgentOptions.mcpServers`

### Required changes to make tests pass:

1. Create `MCPServerConfig` SwiftData model with all fields
2. Create `TransportType` and `MCPServerScope` enums
3. Create `MCPServerConfigStore` service with full CRUD
4. Implement `enabledConfigsForWorkspace(_:)` with scope filtering
5. Implement `toSDKConfigs(_:)` with stdio/sse/http conversion
6. Add JSON decode helpers on `MCPServerConfig`
7. Register model in `SwiftWorkApp.swift`
8. Integrate into `AgentBridge.configure()`

## Next Steps (Task-by-Task Activation)

During implementation of each task:

1. Implement the source files listed above
2. Run tests: `swift test` or Xcode test runner
3. Tests will transition from compile-fail to runtime-fail to pass as implementation progresses
4. Verify all 34 tests pass before marking story complete
5. Commit passing tests

## Key Risks & Assumptions

- **SwiftData in-memory testing**: Tests use `isStoredInMemoryOnly: true` with in-memory `ModelContainer`, following the same pattern as `EventStoreTests`
- **SDK McpServerConfig API**: Tests reference `McpStdioConfig` and `McpTransportConfig` types from `OpenAgentSDK` -- these are verified to exist in the SDK checkout
- **Name uniqueness**: `@Attribute(.unique)` on `name` field may require SwiftData error handling in `add()` method
- **args/env/headers as Data?**: JSON-encoded `Data` fields align with `Event.rawData` pattern and are safest for SwiftData compatibility

## Recommended Next Workflow

- `bmad-dev-story` with story `6-1` to implement the feature
- After implementation, run `swift test` to verify all tests pass (green phase)
