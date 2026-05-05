# Story 5-1: SDK Skill 管线打通 — 手工验收清单

## 前置条件

- [ ] SwiftWork 应用已编译并启动
- [ ] 已配置有效 API Key
- [ ] 确认 Xcode Console 日志可见

---

## AC1 — AgentOptions 启用 Skill 发现

- [ ] 启动应用并发送一条消息
- [ ] 检查 Xcode Console 日志，确认输出 `SwiftWork SkillRegistry: N skills registered (M discovered from filesystem)`
- [ ] N ≥ 5（至少包含 5 个 BuiltInSkills）

## AC2 — 文件系统 Skill 发现

- [ ] 在项目目录下创建 `.claude/skills/test-skill/SKILL.md`（内容随意）
- [ ] 重启应用并发送一条消息
- [ ] 检查日志中 `discovered from filesystem` 数量 ≥ 1
- [ ] 清理测试文件

## AC3 — Skill 列表注入系统提示

- [ ] 发送消息 "你有哪些可用的 skill？请列出"
- [ ] Agent 回复中应包含 commit、review、simplify、debug、test 等 skill 名称
- [ ] 如果 Agent 未列出，发送 "请使用 Skill 工具调用 commit skill" 确认 SkillTool 可用

## AC4 — SkillTool 执行成功路径

- [ ] 发送消息 "请使用 commit skill"
- [ ] Agent 应执行 commit skill 的 promptTemplate（生成 commit message）
- [ ] 不崩溃，返回正常结果

## AC5 — SkillTool 执行失败路径

- [ ] 发送消息 "请使用 Skill 工具调用一个不存在的 skill，名称为 nonexistent"
- [ ] Agent 应收到错误信息（skill 不存在）
- [ ] 应用不崩溃，Agent 可继续对话

## AC6 — BuiltInSkills 共存

- [ ] 发送消息 "请列出所有可用的 skill"
- [ ] 回复中应同时出现 commit、review、simplify、debug、test
- [ ] 如果项目目录下有自定义 skill，也应一并出现

## AC7 — UI 层暴露 skill 列表（面向后续 Story）

- [ ] 本 AC 为内部接口，无直接 UI 验收
- [ ] 可在 Debug Panel 或 LLDB 中验证 `agentBridge.discoveredSkills.count ≥ 5`

---

## 回归检查

- [ ] 现有会话功能正常（创建/切换/删除会话）
- [ ] Timeline 事件流正常渲染（消息、Tool Card、系统提示）
- [ ] 权限系统正常工作（手动审批模式下工具调用弹卡）
- [ ] 自动化测试：601 测试全部通过
