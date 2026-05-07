---
stepsCompleted: ['step-01-preflight-and-context', 'step-02-generation-mode', 'step-03-test-strategy', 'step-04c-aggregate', 'step-05-validate-and-complete']
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-05-07'
storyId: '6.6'
storyKey: '6-6-mcp-advanced-settings-config'
storyFile: '_bmad-output/implementation-artifacts/6-6-mcp-advanced-settings-config.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-6-6-mcp-advanced-settings-config.md'
generatedTestFiles:
  - 'SwiftWorkTests/Services/MCPConfigFileManagerTests.swift'
  - 'SwiftWorkTests/Views/Settings/MCP/MCPAdvancedSettingsViewTests.swift'
  - 'SwiftWorkTests/Services/MCPConfigFileIntegrationTests.swift'
---

# ATDD Checklist: Story 6.6 — MCP 高级设置与配置文件

## TDD Red Phase (Current)

Red-phase test scaffolds generated. All tests assert EXPECTED behavior and will FAIL until Story 6-6 is implemented.

- Unit Tests: 2 test files, 46 test methods
- Integration Tests: 1 test file, 9 test methods
- Total: 55 test methods across 3 files

## Acceptance Criteria Coverage

### AC1 — 高级设置折叠区

| Test File | Tests | Priority |
|-----------|-------|----------|
| `MCPAdvancedSettingsViewTests.swift` | 创建 (2), ViewModel 初始化 (2), 折叠状态 (2), 刷新配置 (2) | P0 |
| `MCPConfigFileManagerTests.swift` | 文件监控 (4) | P0-P1 |

**覆盖场景：**
- MCPAdvancedSettingsView 可实例化（有/无 workspacePath）
- ViewModel 默认折叠、可切换
- ViewModel 默认 global scope、可切换
- 文件监控注册/停止不崩溃
- 文件变更触发回调
- 刷新配置不崩溃

### AC2 — 配置文件路径显示

| Test File | Tests | Priority |
|-----------|-------|----------|
| `MCPConfigFileManagerTests.swift` | 路径解析 (5) | P0 |
| `MCPAdvancedSettingsViewTests.swift` | ViewModel 路径 (3) | P0 |
| `MCPConfigFileIntegrationTests.swift` | 路径解析集成 (1) | P0 |

**覆盖场景：**
- Global scope 解析到 `~/.claude/settings.json`
- Global scope 忽略 workspacePath
- Project scope 解析到 `{workspace}/.claude/settings.json`
- Project scope workspacePath 为 nil/空时返回 nil
- ViewModel 正确代理 Manager 的路径解析

### AC3 — 在 Finder 中显示

| Test File | Tests | Priority |
|-----------|-------|----------|
| `MCPConfigFileManagerTests.swift` | revealInFinder (2), 文件存在检查 (2), 文件读取 (2) | P0-P1 |
| `MCPConfigFileIntegrationTests.swift` | 文件存在 (1) | P0 |

**覆盖场景：**
- revealInFinder 存在文件不崩溃
- revealInFinder 不存在文件不崩溃
- configFileExists 正确检测文件存在/不存在
- readConfigFile 读取/返回 nil

### AC4 — 外部编辑检测与重新加载

| Test File | Tests | Priority |
|-----------|-------|----------|
| `MCPConfigFileManagerTests.swift` | JSON 解析 (13), 导入 SwiftData (7) | P0 |
| `MCPConfigFileIntegrationTests.swift` | 端到端导入 (6), 热更新 (2) | P0 |

**覆盖场景：**
- JSON 解析：单服务器、多服务器、stdio/sse/http 类型
- JSON 解析：args、env、headers 正确解码
- JSON 解析：type 推断（command → stdio, url → sse）
- JSON 解析：enabled 默认值和显式 false
- JSON 解析：无效 JSON、空 mcpServers、缺失字段容错
- 导入：新增、去重覆盖、保留 SwiftData 独有
- 导入：scope 正确设置
- 导入：空文件不清除已有配置
- AgentBridge.updateMCPServers 热更新不崩溃
- 禁用后热更新反映正确状态

## Test Strategy

- **Stack:** Swift/macOS backend (XCTest)
- **Test Levels:** Unit (Service + ViewModel), Integration (端到端导入)
- **No E2E:** 纯 Swift 项目无浏览器测试

| Level | File | Count | Coverage |
|-------|------|-------|----------|
| Unit | MCPConfigFileManagerTests | 37 | AC2 路径解析 + AC3 文件操作 + AC4 JSON 解析/导入/监控 |
| Unit | MCPAdvancedSettingsViewTests | 13 | AC1 折叠区 + AC2 ViewModel |
| Integration | MCPConfigFileIntegrationTests | 9 | AC2-4 端到端导入和热更新 |

## Generated Files

| File | Path | Lines | Status |
|------|------|-------|--------|
| MCPConfigFileManagerTests | `SwiftWorkTests/Services/MCPConfigFileManagerTests.swift` | ~340 | RED |
| MCPAdvancedSettingsViewTests | `SwiftWorkTests/Views/Settings/MCP/MCPAdvancedSettingsViewTests.swift` | ~200 | RED |
| MCPConfigFileIntegrationTests | `SwiftWorkTests/Services/MCPConfigFileIntegrationTests.swift` | ~280 | RED |

## Implementation Tasks (RED to GREEN)

### Task 1: 创建 MCPConfigFileManager 服务 (AC: #2, #3, #4)

1. 新建 `SwiftWork/Services/MCPConfigFileManager.swift`
2. 实现 `configFilePath(scope:workspacePath:) -> String?`
3. 实现 `configFileExists(atPath:) -> Bool`
4. 实现 `readConfigFile(atPath:) -> Data?`
5. 实现 `revealInFinder(path:)` 调用 NSWorkspace
6. 实现 `loadMCPConfigsFromFile(atPath:) -> [MCPServerConfig]`
7. 实现 `importFromFile(atPath:scope:workspacePath:store:)` 导入 + 去重
8. 实现 `startWatching(path:onChange:)` / `stopWatching()` 文件监控
9. Run: `swift test --filter MCPConfigFileManagerTests`

### Task 2: 创建 MCPAdvancedSettingsView (AC: #1, #2, #3)

1. 新建 `SwiftWork/Views/Settings/MCP/MCPAdvancedSettingsView.swift`
2. 新建 `SwiftWork/Views/Settings/MCP/MCPAdvancedSettingsViewModel.swift`（或内嵌 ViewModel）
3. 实现折叠/展开交互（参照 MCPServerDetailView 动画）
4. 实现 scope 切换按钮（Project/Global）
5. 实现配置文件路径显示（monospaced）
6. 实现"在 Finder 中显示"按钮
7. 实现"刷新配置"手动按钮
8. Run: `swift test --filter MCPAdvancedSettingsViewTests`

### Task 3: 集成到 MCPManagementView (AC: #1)

1. 修改 `SwiftWork/Views/Settings/MCP/MCPManagementView.swift`
2. 在 serverList 底部插入 MCPAdvancedSettingsView
3. 传递 workspacePath（从 agentBridge.activeWorkspaceRoot 获取）
4. Run: `swift test --filter MCPConfigFileIntegrationTests`

### Task 4: 回归测试 (AC: #1-#4)

1. 运行全部测试确保无回归
2. 运行 `swift test`
3. 确认 Story 6-1 至 6-5 测试全部通过

## Execution Commands

```bash
# Run all tests
swift test

# Run specific test files
swift test --filter MCPConfigFileManagerTests
swift test --filter MCPAdvancedSettingsViewTests
swift test --filter MCPConfigFileIntegrationTests

# Run via xcodebuild
xcodebuild test -scheme SwiftWork -destination 'platform=macOS' -only-testing:SwiftWorkTests/MCPConfigFileManagerTests
xcodebuild test -scheme SwiftWork -destination 'platform=macOS' -only-testing:SwiftWorkTests/MCPAdvancedSettingsViewTests
xcodebuild test -scheme SwiftWork -destination 'platform=macOS' -only-testing:SwiftWorkTests/MCPConfigFileIntegrationTests
```

## Red-Green-Refactor Workflow

1. **RED** (current): All 55 tests generated as failing scaffolds
2. **GREEN**: Implement features task-by-task, fixing compile errors and assertion failures
3. **REFACTOR**: Clean up after all tests pass

## Key Risks & Assumptions

1. **MCPConfigFileManager API 设计** — 测试假设 Manager 提供 `configFilePath`, `configFileExists`, `readConfigFile`, `loadMCPConfigsFromFile`, `importFromFile`, `revealInFinder`, `startWatching`, `stopWatching` 方法。实现需匹配这些签名。
2. **JSON 类型推断** — 当 `type` 字段缺失时，测试验证 `command` 存在推断为 `stdio`，`url` 存在推断为 `sse`。Dev Notes 明确描述了此行为。
3. **导入去重策略** — 文件配置覆盖 SwiftData 同名配置（update），新增不存在的配置（add），SwiftData 独有配置保留不变。这是 Dev Notes 中明确的策略。
4. **文件监控可靠性** — DispatchSource 在原子写入场景可能失效。测试验证基本功能不崩溃，生产实现建议以"手动刷新"为主方案。
5. **MCPAdvancedSettingsViewModel** — View 测试文件中包含临时 ViewModel 类定义（用于编译通过），实现时应替换为正式 ViewModel。
6. **workspace 未绑定** — 当 workspacePath 为 nil 时 project scope 不可用，测试验证了此行为。
