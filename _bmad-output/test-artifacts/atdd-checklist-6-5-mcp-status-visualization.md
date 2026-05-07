---
stepsCompleted: ['step-01-preflight-and-context', 'step-02-generation-mode', 'step-03-test-strategy', 'step-04c-aggregate', 'step-05-validate-and-complete']
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-05-07'
storyId: '6.5'
storyKey: '6-5-mcp-status-visualization'
storyFile: '_bmad-output/implementation-artifacts/6-5-mcp-status-visualization.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-6-5-mcp-status-visualization.md'
generatedTestFiles:
  - 'SwiftWorkTests/ViewModels/MCPStatusViewModelTests.swift'
  - 'SwiftWorkTests/Views/Workspace/Inspector/InspectorMCPMetadataTests.swift'
  - 'SwiftWorkTests/Views/Workspace/WorkspaceStatusBarTests.swift'
  - 'SwiftWorkTests/App/MCPStatusVisualizationIntegrationTests.swift'
---

# ATDD Checklist: Story 6.5 — MCP 状态可视化

## TDD Red Phase (Current)

Red-phase test scaffolds generated. All tests assert EXPECTED behavior and will FAIL until Story 6-5 is implemented.

- Unit Tests: 4 test files, 48 test methods
- Integration Tests: 1 test file, 10 test methods
- Total: 58 test methods across 4 files

## Acceptance Criteria Coverage

### AC1 — Status Bar MCP 连接数指标

| Test File | Tests | Priority |
|-----------|-------|----------|
| `MCPStatusViewModelTests.swift` | 初始状态 (4), connectedCount (2), failedCount (2), pendingCount (1), totalConfiguredCount (2), 离线状态 (3), refreshStatus (3), loadConfiguredServers (2), 状态摘要文本 (4), Agent 启动/停止 (2), 定时刷新 (2), Edge Cases (3) | P0-P1 |
| `WorkspaceStatusBarTests.swift` | 视图创建 (2), 集成验证 (1), 状态显示格式 (4), 混合状态 (1) | P0-P1 |
| `MCPStatusVisualizationIntegrationTests.swift` | 端到端配置和显示 (1), 部分连接失败 (1) | P0 |

**覆盖场景：**
- MCP 连接数指标显示（"3 MCP 已连接"格式）
- 无 MCP 连接时显示 "就绪"
- 连接失败时显示琥珀色警告
- pending 状态显示加载指示器
- Agent 未运行时的离线状态展示
- Agent 启动/停止时自动更新
- 定时刷新机制（每 5 秒）
- 配置列表从 SwiftData 加载

### AC2 — MCP 工具 Tool Card 来源标识（回归验证）

| Test File | Tests | Priority |
|-----------|-------|----------|
| `MCPStatusVisualizationIntegrationTests.swift` | MCP 元数据验证 (2), MCPToolRenderer 回归 (2), Registry 回归 (1) | P0 |

**说明：** AC2 已由 Story 6-4 实现（MCPToolRenderer、EventMapper MCP 元数据、ToolRendererRegistry 前缀匹配）。本 Story 的测试包含回归验证确保功能不被破坏。

### AC3 — Inspector MCP 工具元数据展示

| Test File | Tests | Priority |
|-----------|-------|----------|
| `InspectorMCPMetadataTests.swift` | MCP 检测 (2), 元数据完整性 (1), 工具名解析 (5), 展示逻辑 (3), 一致性 (2) | P0-P1 |
| `MCPStatusVisualizationIntegrationTests.swift` | 元数据端到端流转 (3) | P0 |

**覆盖场景：**
- 通过 `isMCP` 元数据检测 MCP 工具事件
- 显示：来源 MCP、服务器名、命名空间全名、实际工具名
- `components(separatedBy: "__")` 解析逻辑
- Inspector 和 MCPToolRenderer 解析逻辑一致性
- 畸形命名空间容错处理

## Test Strategy

- **Stack:** Swift/macOS backend (XCTest)
- **Test Levels:** Unit (ViewModel 逻辑 + 解析逻辑), Integration (端到端流转)
- **No E2E:** 纯 Swift 项目无浏览器测试

| Level | File | Count | Coverage |
|-------|------|-------|----------|
| Unit | MCPStatusViewModelTests | 30 | AC1 全部计算属性和状态逻辑 |
| Unit | InspectorMCPMetadataTests | 13 | AC3 元数据检测和解析 |
| Unit | WorkspaceStatusBarTests | 8 | AC1 视图创建和状态显示 |
| Integration | MCPStatusVisualizationIntegrationTests | 10 | AC1+AC2+AC3 端到端 |

## Generated Files

| File | Path | Lines | Status |
|------|------|-------|--------|
| MCPStatusViewModelTests | `SwiftWorkTests/ViewModels/MCPStatusViewModelTests.swift` | ~310 | RED |
| InspectorMCPMetadataTests | `SwiftWorkTests/Views/Workspace/Inspector/InspectorMCPMetadataTests.swift` | ~210 | RED |
| WorkspaceStatusBarTests | `SwiftWorkTests/Views/Workspace/WorkspaceStatusBarTests.swift` | ~170 | RED |
| MCPStatusVisualizationIntegrationTests | `SwiftWorkTests/App/MCPStatusVisualizationIntegrationTests.swift` | ~240 | RED |

## Implementation Tasks (RED to GREEN)

### Task 1: 创建 MCPStatusViewModel (AC: #1)

1. 新建 `SwiftWork/Views/Workspace/MCPStatusViewModel.swift`
2. 实现 `@Observable` + `@MainActor` ViewModel
3. 实现计算属性：`connectedCount`, `failedCount`, `pendingCount`, `totalConfiguredCount`
4. 实现 `refreshStatus()` 方法
5. 实现 `loadConfiguredServers()` 方法
6. 实现 `statusSummaryText` 计算属性
7. 实现 `startPeriodicRefresh()` / `stopPeriodicRefresh()`
8. 实现 `onAgentRunningChanged(isRunning:)`
9. Remove `// WILL FAIL` markers from `MCPStatusViewModelTests` and run tests

### Task 2: 创建 WorkspaceStatusBar (AC: #1)

1. 新建 `SwiftWork/Views/Workspace/WorkspaceStatusBar.swift`
2. 实现 Status Bar 视图，绑定 MCPStatusViewModel
3. Remove `// WILL FAIL` markers from `WorkspaceStatusBarTests` and run tests

### Task 3: 集成 WorkspaceStatusBar 到 WorkspaceView (AC: #1)

1. 修改 `SwiftWork/Views/Workspace/WorkspaceView.swift`
2. 在 TimelineView 和 InputBarView 之间插入 WorkspaceStatusBar
3. 传递 `agentBridge` 和 `mcpConfigStore` 给 MCPStatusViewModel

### Task 4: 增强 InspectorView MCP 元数据展示 (AC: #3)

1. 修改 `SwiftWork/Views/Workspace/Inspector/EventDetailSections.swift`
2. 在 `toolEventSection(event:)` 中检测 MCP 工具事件
3. 显示 MCP 专属元数据区（来源、服务器、命名空间、工具名）
4. Remove markers from `InspectorMCPMetadataTests` and run tests

### Task 5: 验证 MCPToolRenderer 和回归测试 (AC: #2)

1. 验证 Story 6-4 的 MCPToolRenderer 正确渲染
2. 运行 `MCPStatusVisualizationIntegrationTests` 全部通过
3. 回归测试：确认全部现有测试通过

## Execution Commands

```bash
# Run all tests
swift test

# Run specific test file
swift test --filter MCPStatusViewModelTests
swift test --filter InspectorMCPMetadataTests
swift test --filter WorkspaceStatusBarTests
swift test --filter MCPStatusVisualizationIntegrationTests

# Run via xcodebuild
xcodebuild test -scheme SwiftWork -destination 'platform=macOS' -only-testing:SwiftWorkTests/MCPStatusViewModelTests
```

## Red-Green-Refactor Workflow

1. **RED** (current): All 58 tests generated as failing scaffolds
2. **GREEN**: Implement features task-by-task, removing test skips
3. **REFACTOR**: Clean up after all tests pass

## Key Risks & Assumptions

1. **MCPStatusViewModel API 设计** — 测试假设 ViewModel 接受 `MCPServerConfigStore` 和可选 `AgentBridge` 作为构造参数，暴露 `serverStatuses: [String: McpServerStatus]` 属性
2. **statusSummaryText 格式** — 测试验证文本包含关键内容（数字、"MCP"、"就绪"、"失败"），不验证精确字符串，允许实现灵活调整
3. **定时刷新实现** — 测试验证 start/stop 不崩溃，不验证精确 5 秒间隔
4. **Inspector MCP 解析** — 测试假设 Inspector 使用与 MCPToolRenderer 相同的 `components(separatedBy: "__")` 解析逻辑
5. **AC2 回归** — MCPToolRenderer 和 EventMapper MCP 元数据已由 Story 6-4 实现，测试只做回归验证
