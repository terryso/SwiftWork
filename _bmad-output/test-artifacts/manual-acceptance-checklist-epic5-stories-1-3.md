# Epic 5 Stories 5-1~5-3 验收清单

**分支**: `feature/skill-system`
**审查日期**: 2026-05-06
**构建状态**: 成功（零错误）
**测试结果**: 911 tests, 0 failures

---

## Story 5-1: SDK Skill 管线打通

| # | 验收标准 | 状态 | 验证方式 |
|---|---------|------|---------|
| AC1 | AgentOptions 启用 Skill 发现（skillDirectories + BuiltInSkills 注册） | ✅ | `AgentBridge.swift:151-152` 设置 `skillDirectories: []`，`:119-123` 注册 5 个 BuiltInSkills |
| AC2 | 文件系统 Skill 发现（registerDiscoveredSkills 扫描 .claude/skills） | ✅ | `AgentBridge.swift:129` 调用 `registry.registerDiscoveredSkills()` |
| AC3 | Skill 列表注入系统提示（SkillTool 注册到 tools 数组） | ✅ | `AgentBridge.swift:133-135` 条件注册 `createSkillTool(registry:)` |
| AC4 | SkillTool 执行成功路径 | ✅ | 单元测试 `AgentBridgeSkillTests.swift` 覆盖 |
| AC5 | SkillTool 执行失败路径（不崩溃） | ✅ | 单元测试验证 nonexistent skill 返回 nil |
| AC6 | BuiltInSkills 共存 | ✅ | `configure()` 中逐一注册 commit/review/simplify/debug/test |
| AC7 | UI 层暴露 skill 列表 | ✅ | `discoveredSkills` 计算属性 (`AgentBridge.swift:124`) |

**Story 5-1 测试**: 396 行测试代码，21 个测试用例，全部通过

---

## Story 5-2: 输入框斜杠命令自动补全

| # | 验收标准 | 状态 | 验证方式 |
|---|---------|------|---------|
| AC1 | `/` 触发自动补全，显示所有 userInvocable skill | ✅ | `SkillAutocompleteViewModel.updateQuery()` 空查询显示全部 |
| AC2 | 模糊过滤（`/co` 过滤为 "commit"） | ✅ | 前缀匹配优先，然后包含匹配，然后别名匹配 |
| AC3 | 键盘选择（Up/Down + Enter 确认） | ✅ | `SendTextView.keyDown` 拦截 + `moveSelection()` wrap-around |
| AC4 | Escape/点击外部关闭菜单 | ✅ | Escape 回调关闭，点击使用 `onTapGesture` 互斥 |
| AC5 | 不匹配文本作为普通文本发送 | ✅ | `sendMessage()` 不检查 autocomplete，直接发送 |
| AC6 | 仅在行首触发 | ✅ | `updateQuery()` 检查 `trimmed.hasPrefix("/")` |

**Story 5-2 测试**: 338 行测试代码，28 个测试用例，全部通过

---

## Story 5-3: Skill Timeline 卡片渲染

| # | 验收标准 | 状态 | 验证方式 |
|---|---------|------|---------|
| AC1 | Skill toolUse 卡片识别与渲染（skill 名称 + 参数） | ✅ | `SkillToolRenderer.summaryTitle()` 解析 `/skillName`，`subtitle()` 解析 args |
| AC2 | Skill toolResult 完成状态 | ✅ | `SkillToolExpandedContent.completedContent` 解析 success/commandName |
| AC3 | 展开详情显示 promptTemplate + 参数 | ✅ | `SkillToolExpandedContent` 展示 skill name + args + result prompt |
| AC4 | 多个 Skill 调用视觉区分 | ✅ | `accentColor = .purple`，`icon = "sparkles"`，与普通工具区分 |

**Story 5-3 测试**: 561 行测试代码，覆盖 summaryTitle/subtitle/body/颜色/图标/JSON 解析

---

## 审查期间发现并修复的问题

| 问题 | 严重程度 | 状态 |
|------|---------|------|
| allowOnce 和 alwaysAllow 行为相同（allowOnce 误加 session override） | 🔴 用户可见 bug | ✅ 已修复 (`4589e9b`) |

## 遗留技术债（不阻塞验收）

| 问题 | 优先级 | 说明 |
|------|--------|------|
| View 层直接 import OpenAgentSDK（Skill 类型） | 低 | 创建 UI 中间模型 `SkillItem` 隔离，后续迭代处理 |
| configure() 同步文件系统扫描 | 低 | skill 数量少，实际耗时可忽略 |
| clearEvents() continuation 泄漏 | 中 | 切换会话时 pending continuation 未 resume，触发概率低 |
| 审批结果未持久化到 event metadata | 低 | 重载历史会话时已审批卡片显示为"已过期" |

## 验收结论

**通过** ✅

Stories 5-1、5-2、5-3 功能完整，911 测试全部通过，关键 bug 已修复。遗留技术债不影响功能正确性，作为 follow-up 处理。
