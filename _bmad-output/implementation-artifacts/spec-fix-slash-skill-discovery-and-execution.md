---
title: 'Fix Slash Skill Discovery and Execution'
type: 'bugfix'
created: '2026-05-07'
status: 'done'
baseline_commit: '4f8736e5e36e70918815e2fcc3c2afcee9ffc5df'
context:
  - '{project-root}/_bmad-output/project-context.md'
---

# Fix Slash Skill Discovery and Execution

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** 当前 slash skill 体验在两个关键点上失效：输入 `/` 时常看不到可用 skill；发送 `/polyv-live-cli 获取最新5个频道` 这类明确指令时，消息又会被当作普通文本交给 Agent，模型可能绕开已注册 skill 自行猜测执行路径。

**Approach:** 同时修复 slash 的发现与执行链路：让输入框能响应后到的 skill 列表，并在发送时显式识别 `/skill-name args` / `/alias args`，命中已注册且可用 skill 时走确定性的 Skill 路由，未命中时继续保留普通文本语义。

## Boundaries & Constraints

**Always:** 保持现有 `SkillRegistry` / `SkillTool` / Timeline 架构；保持普通消息与“非行首 slash 文本”行为不变；slash 路由只认已注册 skill 名称或 alias，并在执行前校验 availability；没有可用 skill 或没有匹配项时，UI 不能静默失败。

**Ask First:** 如果必须新增 Session 持久化字段、引入独立命令模式状态机，或把未知 slash 从“原样发送”改成“阻止发送”，必须先问用户。

**Never:** 不把 `polyv-live-cli` 写死；不继续只赌模型会自己调用 SkillTool；不绕过 SDK skill 流程去直接拼 Bash；不顺手重做 Settings、Timeline 或权限系统。

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| 延迟发现 | `InputBarView` 先出现，`AgentBridge.configure()` 后完成 | 用户再输入 `/` 时能看到最新 skill 列表 | 若 registry 仍为空，显示明确空状态 |
| 直接执行 | 已注册且可用的 `polyv-live-cli` 存在；用户发送 `/polyv-live-cli 获取最新5个频道` | 发送链路识别为 slash skill 指令，并走 Skill 执行路径 | 若 skill 不可用，保留输入并提示失败 |
| alias 执行 | 用户发送 `/别名 参数...` | 解析到 canonical skill，参数原样保留 | alias 无效时退回统一失败/回退逻辑 |
| 未知 slash | 用户发送 `/unknown do something` | 不吞消息，继续允许按普通文本发送 | UI 可提示“未匹配到 Skill”，但不得崩溃 |

</frozen-after-approval>

## Code Map

- `SwiftWork/SDKIntegration/AgentBridge.swift` -- skill 状态快照、slash 解析与执行路由入口
- `SwiftWork/Views/Workspace/InputBar/InputBarView.swift` -- slash 输入监听、技能列表注入、发送 handoff
- `SwiftWork/Views/Workspace/InputBar/SkillAutocompleteViewModel.swift` -- 查询、匹配、空状态与选中项逻辑
- `SwiftWork/Views/Workspace/InputBar/SkillAutocompleteMenuView.swift` -- 列表与空状态展示
- `SwiftWorkTests/SDKIntegration/AgentBridgeSkillTests.swift` -- slash 路由与发现回归保护
- `SwiftWorkTests/Views/Workspace/InputBar/SkillAutocompleteViewModelTests.swift` -- slash 触发、空状态与 alias 场景保护

## Tasks & Acceptance

**Execution:**
- [x] `SwiftWork/SDKIntegration/AgentBridge.swift` -- 把可供 UI 使用的 skill 列表变成可靠可观察状态，并新增行首 `/skill args` / `/alias args` 的解析与路由；命中已注册且可用 skill 时走确定性的 Skill 执行路径，未命中时保持普通文本发送 -- 修复“列表拿不到”和“slash 被当普通话术”两个根因
- [x] `SwiftWork/Views/Workspace/InputBar/InputBarView.swift` -- 去掉仅在 `onAppear` 单次注入 skill 数据的假设，改为持续响应技能列表变化；在 `/` 触发时稳定展示菜单或空状态，并保持 Enter / Escape / Arrow 契约 -- 让 slash 发现能力与 agent 配置时序解耦
- [x] `SwiftWork/Views/Workspace/InputBar/SkillAutocompleteViewModel.swift` + `SwiftWork/Views/Workspace/InputBar/SkillAutocompleteMenuView.swift` -- 明确区分“隐藏”“无可用 skill”“无匹配项”三类状态，并保留足够匹配信息支持发送阶段路由 -- 避免 UI 继续把失败表现成“什么都没发生”
- [x] `SwiftWorkTests/SDKIntegration/AgentBridgeSkillTests.swift` + `SwiftWorkTests/Views/Workspace/InputBar/SkillAutocompleteViewModelTests.swift` + 相关 InputBar/集成测试文件 -- 补上发现刷新、空状态、canonical 名称/alias 路由、未知 slash 回退及普通文本不受影响的覆盖 -- 锁住回归面

**Acceptance Criteria:**
- [x] Given `WorkspaceView` 已显示输入框, when `AgentBridge.configure()` 稍后填充出可用 skills, then 用户输入 `/` 时无需重开会话就能看到当前 skill 列表
- [x] Given 当前没有任何可用 skill 或查询词没有命中, when 用户输入 `/` 或 `/foo`, then 输入栏显示明确的 slash 提示/空状态，而不是静默无提示
- [x] Given 已注册且可用的 `polyv-live-cli` skill 存在, when 用户发送 `/polyv-live-cli 获取最新5个频道`, then 发送链路会把它解析成该 skill 的一次显式执行，而不是仅把整句当普通 prompt
- [x] Given 用户发送某个 skill 的 alias 形式, when slash 路由执行, then 系统解析到 canonical skill 并保留原始参数
- [x] Given 用户发送 `/unknown do something`, when 没有任何已注册可用 skill 命中, then 用户输入不会丢失，且普通文本发送语义保持不变
- [x] Given 用户发送普通文本或非行首 slash 文本, when 消息提交, then 现有发送行为、队列逻辑和非 skill 交互完全不变

## Spec Change Log

## Verification

**Commands:**
- `swift build` -- expected: Build succeeds after新增的观察状态、slash 路由与 UI 更新
- `swift test` -- expected: 现有测试继续通过，并新增覆盖 slash 列表刷新、空状态、显式 skill 路由与未知命令回退

## Suggested Review Order

**Slash routing**

- 先看发送入口如何把普通消息与 slash 指令分流。
  [`AgentBridge.swift:350`](../../SwiftWork/SDKIntegration/AgentBridge.swift#L350)

- 这里把已解析的 slash skill 本地执行成标准 Skill tool 事件链。
  [`AgentBridge.swift:548`](../../SwiftWork/SDKIntegration/AgentBridge.swift#L548)

- 这里把 Skill tool 结果转成确定性的后续 agent 输入。
  [`AgentBridge.swift:598`](../../SwiftWork/SDKIntegration/AgentBridge.swift#L598)

**Input bar refresh and feedback**

- 先看输入栏如何在技能列表变化时持续刷新，而不是只读一次。
  [`InputBarView.swift:14`](../../SwiftWork/Views/Workspace/InputBar/InputBarView.swift#L14)

- 这里补上 slash 输入时的刷新与可见错误反馈。
  [`InputBarView.swift:96`](../../SwiftWork/Views/Workspace/InputBar/InputBarView.swift#L96)

- 这里定义 slash 菜单的隐藏、空列表与无匹配三态。
  [`SkillAutocompleteViewModel.swift:5`](../../SwiftWork/Views/Workspace/InputBar/SkillAutocompleteViewModel.swift#L5)

- 这里落实按命令 token 匹配而不是把整行参数一起过滤。
  [`SkillAutocompleteViewModel.swift:52`](../../SwiftWork/Views/Workspace/InputBar/SkillAutocompleteViewModel.swift#L52)

**Regression coverage**

- 先看显式 slash 执行已变成真实 Skill tool 事件，而不是仅改写提示词。
  [`AgentBridgeSkillTests.swift:457`](../../SwiftWorkTests/SDKIntegration/AgentBridgeSkillTests.swift#L457)

- 这里锁住 hidden skill 回退与动态 availability 刷新。
  [`AgentBridgeSkillTests.swift:543`](../../SwiftWorkTests/SDKIntegration/AgentBridgeSkillTests.swift#L543)

- 这里覆盖延迟发现刷新与“命令 + 参数”过滤边界。
  [`SkillAutocompleteViewModelTests.swift:344`](../../SwiftWorkTests/Views/Workspace/InputBar/SkillAutocompleteViewModelTests.swift#L344)
