# Story 6.1 手工验收清单

Story: MCP 配置模型与持久化
验收人: ____________
日期: ____________

## 前置条件

- [ ] 代码已拉取到 `feat/epic6-mcp-server` 分支
- [ ] Xcode 项目可正常打开

## AC1 — SwiftData 持久化模型

- [ ] 项目可编译通过（`swift build` 无错误）
- [ ] `MCPServerConfig` 已在 `SwiftWorkApp.modelContainer` 中注册
- [ ] `TransportType` 枚举包含 stdio / sse / http 三个 case
- [ ] `MCPServerScope` 枚举包含 project / global 两个 case
- [ ] `MCPServerConfig` 含全部字段：name, transportType, command, url, args, env, headers, enabled, scope, workspacePath, createdAt, updatedAt
- [ ] `name` 和 `id` 字段标注了 `@Attribute(.unique)`

## AC2 — 应用重启自动恢复

- [ ] `swift test --filter MCPServerConfigStoreTests` 全部通过
- [ ] `testConfigsPersistAfterSave` 通过（模拟重启恢复场景）

## AC3 — 项目级 scope 隔离

- [ ] `testGlobalConfigsVisibleForAllWorkspaces` 通过
- [ ] `testProjectConfigsOnlyVisibleForMatchingWorkspace` 通过
- [ ] `testMixedGlobalAndProjectConfigsMerged` 通过
- [ ] `testDisabledConfigsExcludedFromWorkspaceQuery` 通过

## AC4 — 配置转 SDK McpServerConfig

- [ ] `testStdioConfigConvertsToSDKConfig` 通过
- [ ] `testSSEConfigConvertsToSDKConfig` 通过
- [ ] `testHTTPConfigConvertsToSDKConfig` 通过
- [ ] `testStdioConfigWithoutCommandSkipped` 通过
- [ ] `testSSEConfigWithoutURLSkipped` 通过
- [ ] `testDisabledConfigsExcludedFromSDKConversion` 通过

## AgentBridge 集成

- [ ] `AgentBridge` 拥有 `mcpConfigStore` 属性
- [ ] `configure()` 中读取 MCP 配置并传入 `AgentOptions.mcpServers`
- [ ] 配置为空时 `mcpServers` 传 `nil`（不触发 MCP 连接）
- [ ] `ContentView` 正确实例化并注入 `MCPServerConfigStore`
- [ ] 日志输出 MCP 配置数量（`os_log`）

## 回归验证

- [ ] 全量测试通过（`swift test`，排除已知的无关失败用例）
- [ ] 应用启动无 crash
- [ ] 现有功能（Session、Skill、Permission）无回归

## 已知限制（不阻塞发布）

- [ ] 已知：env 字段中的敏感信息存储在 SwiftData（非 Keychain），后续 Story 增强
- [ ] 已知：无 SwiftData `SchemaMigrationPlan`，后续 Story 加字段时需补充
- [ ] 已知：`update()` 方法无法将可选字段设为 nil，编辑弹窗应使用 `replace()`

## 验收结论

- [ ] **通过** — 所有 checklist 项目完成
- [ ] **不通过** — 原因：___________________________

签名: ____________ 日期: ____________
