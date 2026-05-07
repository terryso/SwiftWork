# Story 6-4 手工验收清单

## 前置条件

- [ ] 应用已构建并启动
- [ ] 已配置有效的 API Key
- [ ] 准备一个可用的 MCP Server（SSE 或 stdio）

---

## AC1 — Agent 启动时 MCP 连接

- [ ] 打开 Settings → MCP 面板，确认之前已添加的 MCP Server 显示在列表中
- [ ] 返回 Workspace，发送一条消息触发 Agent 创建
- [ ] 打开 MCP 管理面板，确认 Server 状态为 connected（绿色）而非 disconnected
- [ ] 查看控制台日志，确认出现 "SwiftWork MCP: N configs loaded"

## AC2 — MCP 工具 Tool Card 渲染

- [ ] 在已连接 MCP Server 的会话中，请求 Agent 使用一个 MCP 工具（如 "用 weather 工具查一下东京天气"）
- [ ] Timeline 中出现 Tool Card，确认：
  - [ ] 蓝色主题背景
  - [ ] 显示 "cube.box" 图标
  - [ ] 工具名显示为实际名称（如 `get_forecast`），而非 `mcp__weather__get_forecast`
  - [ ] 副标题显示 "via {serverName}"
- [ ] 工具执行中显示 "Running..." 进度指示器
- [ ] 工具执行完成后显示绿色 checkmark + 结果摘要
- [ ] 工具执行失败时显示红色 xmark + 错误信息

## AC3 — 运行时动态更新 MCP 工具池

- [ ] Agent 正在运行时，打开 Settings → MCP
- [ ] 添加一个新的 MCP Server → 关闭弹窗
- [ ] 返回会话，请求 Agent 使用刚添加的 MCP 工具 → 确认可用
- [ ] 再次打开 MCP 管理面板，编辑已有 Server（如改 URL）→ 关闭弹窗
- [ ] 查看控制台日志，确认出现 "hot-update result — added: ..., removed: ..., errors: ..."
- [ ] 删除一个 MCP Server → 确认 Agent 后续不再使用该工具

## AC4 — MCP 连接错误不崩溃

- [ ] 添加一个不可达的 MCP Server（如 SSE URL 填 `http://localhost:99999/sse`）
- [ ] 发送消息创建 Agent → 确认应用不崩溃
- [ ] Agent 正常响应（跳过 MCP 连接失败）
- [ ] MCP 管理面板中该 Server 显示错误状态
- [ ] 删除无效 Server → 确认无残留影响

---

## 验收结果

- 日期：________
- 结果：通过 / 不通过
- 备注：________________________
