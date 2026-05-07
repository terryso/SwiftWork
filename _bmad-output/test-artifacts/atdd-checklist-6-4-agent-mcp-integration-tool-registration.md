---
stepsCompleted:
  - step-01-preflight-and-context
  - step-02-generation-mode
  - step-03-test-strategy
  - step-04-generate-tests
  - step-04c-aggregate
lastStep: step-04c-aggregate
lastSaved: '2026-05-07'
storyId: '6.4'
storyKey: '6-4-agent-mcp-integration-tool-registration'
storyFile: '_bmad-output/implementation-artifacts/6-4-agent-mcp-integration-tool-registration.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-6-4-agent-mcp-integration-tool-registration.md'
generatedTestFiles:
  - SwiftWorkTests/SDKIntegration/MCPToolRendererTests.swift
  - SwiftWorkTests/SDKIntegration/AgentBridgeMCPIntegrationTests.swift
inputDocuments:
  - '_bmad-output/implementation-artifacts/6-4-agent-mcp-integration-tool-registration.md'
  - 'SwiftWork/SDKIntegration/ToolRendererRegistry.swift'
  - 'SwiftWork/SDKIntegration/EventMapper.swift'
  - 'SwiftWork/SDKIntegration/AgentBridge.swift'
  - 'SwiftWork/SDKIntegration/ToolRenderable.swift'
  - 'SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/SkillToolRenderer.swift'
  - 'SwiftWork/Models/UI/ToolContent.swift'
  - 'SwiftWorkTests/SDKIntegration/ToolRendererRegistryTests.swift'
  - 'SwiftWorkTests/SDKIntegration/EventMapperTests.swift'
  - 'SwiftWorkTests/ViewModels/MCPManagementViewModelTests.swift'
---

# ATDD Checklist: Story 6.4 — Agent MCP 集成与工具注册

## TDD Red Phase (Current)

Red-phase test scaffolds generated.

- Unit Tests: 27 tests in 2 files (all will FAIL until implementation)
- Test Framework: XCTest (Swift native)

## Acceptance Criteria Coverage

### AC1 — Agent 启动时 MCP 连接

| Test | Priority | File | Status |
|------|----------|------|--------|
| configure() loads MCP configs from MCPServerConfigStore | P0 | AgentBridgeMCPIntegrationTests | RED |
| configure() handles empty MCP config store | P0 | AgentBridgeMCPIntegrationTests | RED |
| configure() handles nil mcpConfigStore | P0 | AgentBridgeMCPIntegrationTests | RED |
| configure() filters by scope and enabled | P1 | AgentBridgeMCPIntegrationTests | RED |
| enabledConfigsForWorkspace no workspace | P0 | AgentBridgeMCPIntegrationTests | RED |
| toSDKConfigs converts SwiftData to SDK format | P0 | AgentBridgeMCPIntegrationTests | RED |

### AC2 — MCP 工具 Tool Card 渲染

| Test | Priority | File | Status |
|------|----------|------|--------|
| summaryTitle extracts tool name from namespace | P0 | MCPToolRendererTests | RED |
| summaryTitle handles underscore in tool name | P0 | MCPToolRendererTests | RED |
| summaryTitle falls back for two-part name | P1 | MCPToolRendererTests | RED |
| summaryTitle falls back for non-MCP toolName | P1 | MCPToolRendererTests | RED |
| subtitle extracts server name as "via {serverName}" | P0 | MCPToolRendererTests | RED |
| subtitle returns nil for non-MCP tool | P0 | MCPToolRendererTests | RED |
| subtitle returns nil for malformed namespace | P1 | MCPToolRendererTests | RED |
| MCPToolRenderer has blue accent color | P0 | MCPToolRendererTests | RED |
| MCPToolRenderer has icon | P0 | MCPToolRendererTests | RED |
| MCPToolRenderer body returns a View | P0 | MCPToolRendererTests | RED |
| Registry returns MCPToolRenderer for mcp__ prefix | P0 | MCPToolRendererTests | RED |
| Registry returns MCPToolRenderer for any mcp__ prefix | P0 | MCPToolRendererTests | RED |
| Registry exact match takes priority over prefix | P0 | MCPToolRendererTests | RED |
| Registry returns nil for unregistered non-MCP tool | P0 | MCPToolRendererTests | RED |
| Registry returns MCPToolRenderer for minimal mcp name | P1 | MCPToolRendererTests | RED |
| EventMapper adds isMCP metadata for MCP toolUse | P0 | MCPToolRendererTests | RED |
| EventMapper adds serverName metadata for MCP toolUse | P0 | MCPToolRendererTests | RED |
| EventMapper does not add isMCP for non-MCP toolUse | P0 | MCPToolRendererTests | RED |
| EventMapper adds isMCP for MCP toolProgress | P1 | MCPToolRendererTests | RED |
| EventMapper does not add isMCP for non-MCP toolProgress | P1 | MCPToolRendererTests | RED |
| EventMapper preserves existing metadata for MCP toolUse | P0 | MCPToolRendererTests | RED |

### AC3 — 运行时动态更新 MCP 工具池

| Test | Priority | File | Status |
|------|----------|------|--------|
| updateMCPServers() does not crash when not running | P0 | AgentBridgeMCPIntegrationTests | RED |
| updateMCPServers() reloads configs from store | P0 | AgentBridgeMCPIntegrationTests | RED |
| updateMCPServers() handles store errors gracefully | P1 | AgentBridgeMCPIntegrationTests | RED |

### AC4 — MCP 连接错误不崩溃

| Test | Priority | File | Status |
|------|----------|------|--------|
| mcpServerStatus() returns empty dict when no agent | P0 | AgentBridgeMCPIntegrationTests | RED |
| mcpServerStatus() returns status after configure | P0 | AgentBridgeMCPIntegrationTests | RED |
| toggleMcpServer with no agent does not crash | P0 | AgentBridgeMCPIntegrationTests | RED |
| reconnectMcpServer with no agent does not crash | P0 | AgentBridgeMCPIntegrationTests | RED |
| Agent creation with invalid MCP URL does not crash | P1 | AgentBridgeMCPIntegrationTests | RED |

## Test Level Distribution

| Level | Count | Description |
|-------|-------|-------------|
| Unit | 21 | MCPToolRenderer, EventMapper, ToolRendererRegistry tests |
| Integration | 6 | AgentBridge MCP config injection and runtime behavior |

## Priority Distribution

| Priority | Count |
|----------|-------|
| P0 | 22 |
| P1 | 5 |
| **Total** | **27** |

## Generated Files

1. `SwiftWorkTests/SDKIntegration/MCPToolRendererTests.swift` (21 tests)
   - MCPToolRenderer: summaryTitle, subtitle, static properties, body view
   - ToolRendererRegistry: MCP prefix matching
   - EventMapper: MCP metadata detection

2. `SwiftWorkTests/SDKIntegration/AgentBridgeMCPIntegrationTests.swift` (6 tests)
   - AC1: Agent configure MCP injection
   - AC3: Runtime MCP update
   - AC4: Error resilience

## Implementation Tasks Covered by Tests

| Task | Tests |
|------|-------|
| Task 1: MCP 配置注入验证 | AC1 tests in AgentBridgeMCPIntegrationTests |
| Task 2: MCPToolRenderer 实现 | AC2 renderer tests in MCPToolRendererTests |
| Task 3: ToolRendererRegistry 前缀匹配 | AC2 registry tests in MCPToolRendererTests |
| Task 4: EventMapper MCP 元数据 | AC2 EventMapper tests in MCPToolRendererTests |
| Task 5: 运行时动态更新增强 | AC3 tests in AgentBridgeMCPIntegrationTests |
| Task 6: 错误处理与降级 | AC4 tests in AgentBridgeMCPIntegrationTests |

## Next Steps (Task-by-Task Activation)

During implementation of each task:

1. Run the specific failing test(s) for the current task
2. Implement the minimal code to make the test pass (green phase)
3. Run tests: `swift test` or Xcode Test Navigator
4. Commit passing tests
5. Move to the next task

## Notes

- All tests use in-memory SwiftData containers (no file system side effects)
- EventMapper tests use real SDKMessage types (no mocks needed for pure function)
- AgentBridge tests may require the SDK Agent to handle MCP gracefully for non-reachable servers
- The existing MCPManagementViewModelTests (Story 6-3) provide complementary coverage for the management panel UI layer
