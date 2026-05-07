# Story 6.2 手工验收清单

Story: MCP 添加与编辑弹窗
验收人: ____________
日期: ____________

## 前置条件

- [ ] 代码已拉取到 `feat/epic6-mcp-server` 分支
- [ ] Xcode 项目可正常打开
- [ ] Story 6-1 已完成（MCPServerConfig 模型 + MCPServerConfigStore 可用）

## AC1 — 添加 MCP Server 弹窗

- [ ] `SwiftWork/Views/Settings/MCP/` 目录下包含 4 个文件：MCPTransportTypePicker、MCPFormFields、AddMCPServerSheet、EditMCPServerSheet
- [ ] `AddMCPServerSheet` 包含 Server 名称输入框
- [ ] `AddMCPServerSheet` 包含传输类型选择器（Remote / Local）
- [ ] Remote 模式显示 URL 输入框
- [ ] Local 模式显示 Command 输入框 + 提示文本
- [ ] 弹窗布局：标题区 → 表单区 → 底部操作区（取消 + 添加）

## AC2 — Remote 类型配置

- [ ] `AddMCPServerViewModelTests.testSubmitRemoteConfigCreatesSSEConfig` 通过
- [ ] Remote 提交调用 `MCPServerConfigStore.add()`，transportType 为 `.sse`
- [ ] URL 正确传入 config.url
- [ ] 保存到 SwiftData 后可通过 `store.list()` 查询到
- [ ] `testSubmitRemoteConfigWithProjectScope` 通过（project scope 正确传入 workspacePath）

## AC3 — Local 类型配置

- [ ] `AddMCPServerViewModelTests.testSubmitLocalConfigCreatesStdioConfig` 通过
- [ ] Local 提交调用 `MCPServerConfigStore.add()`，transportType 为 `.stdio`
- [ ] 命令解析：`npx -y @modelcontextprotocol/server-filesystem /tmp` → command="npx", args=["-y", "@modelcontextprotocol/server-filesystem", "/tmp"]
- [ ] `testCommandWithNoArgsProducesEmptyArgs` 通过（无参数命令处理正确）
- [ ] args 编码为 JSON Data 存入 config.args

## AC4 — 编辑已有配置

- [ ] `EditMCPServerSheet` 预填充已有配置数据（name、transportMode、url/command）
- [ ] 编辑 stdio 配置时，command 从 command + args 重建（如 "npx -y mcp-server"）
- [ ] 提交调用 `MCPServerConfigStore.replace()` 更新配置
- [ ] 编辑保留原始 config.id
- [ ] `AgentBridge.updateMCPServers()` 方法存在并在编辑保存后被调用
- [ ] Agent 未运行时 `updateMCPServers()` 提前返回（guard isRunning）

## AC5 — 输入验证

- [ ] 空名称 → isValid 为 false，添加/保存按钮 disabled
- [ ] 纯空格名称 → isValid 为 false
- [ ] Remote 模式空 URL → isValid 为 false
- [ ] Local 模式空 Command → isValid 为 false
- [ ] validate() 设置中文错误提示（"Server 名称不能为空"、"URL 不能为空"、"Command 不能为空"）
- [ ] 错误提示以行内红色 banner 显示（参照 OpenWork add-mcp-modal.tsx 样式）
- [ ] 重复名称提交抛出 `MCPServerConfigError.duplicateName`，弹窗显示错误提示

## 组件质量

- [ ] `MCPTransportMode` 枚举仅含 remote / local 两个 case，遵循 CaseIterable + Sendable
- [ ] `AddMCPServerViewModel` 使用 `@Observable`（非 ObservableObject）
- [ ] ViewModel 标注 `@MainActor`
- [ ] `MCPFormFields` 被 Add 和 Edit Sheet 共享复用
- [ ] `MCPTransportTypePicker` 使用 segmented control 风格，参照 OpenWork 交互
- [ ] 无 force unwrap（`!`）
- [ ] AddMCPServerSheet 290 行以内，EditMCPServerSheet 110 行以内

## 自动化测试

- [ ] 34/34 ATDD 测试通过（31 AddMCPServerViewModelTests + 3 MCPTransportModeTests）
- [ ] `xcodebuild test` 全量通过
- [ ] `xcodebuild build` 构建成功

## 回归验证

- [ ] 全量测试通过（`swift test`）
- [ ] 应用启动无 crash
- [ ] 现有功能（Session、Skill、Permission、Story 6-1 MCP 配置）无回归

## 已知限制（不阻塞发布）

- [ ] 已知：命令解析不支持引号内空格（MVP 限制，Dev Notes 已记录）
- [ ] 已知：Remote 模式默认创建 SSE 类型，不支持 HTTP 子选项（后续增强）
- [ ] 已知：Sheet 由 Story 6-3 的 MCP 管理面板触发，当前无法通过 UI 直接验证完整流程
- [ ] 已知：热更新失败仅记录 os_log，用户无感知（config 已保存，下次启动生效）

## 验收结论

- [ ] **通过** — 所有 checklist 项目完成
- [ ] **不通过** — 原因：___________________________

签名: ____________ 日期: ____________
