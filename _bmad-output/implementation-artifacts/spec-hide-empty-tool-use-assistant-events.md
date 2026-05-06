---
title: 'Hide Empty Tool-Use Assistant Events'
type: 'bugfix'
created: '2026-05-07'
status: 'done'
baseline_commit: 'eecc8325d02e2028baaf130bb19c3570128ac646'
context:
  - '{project-root}/_bmad-output/project-context.md'
---

# Hide Empty Tool-Use Assistant Events

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** 当前 Timeline 会把某些 `assistant` 事件直接渲染成回复气泡，即使它们的 `content` 为空。SDK 在 `stopReason = tool_use` 时会发出这种空 assistant 事件，于是界面上出现一条没有内容的空白行，打断对话阅读。

**Approach:** 在事件映射或展示链路里把“空内容 + tool_use stopReason”识别为非用户可见的中间事件，不再生成可见 assistant 气泡，同时保留真正有文本内容的 assistant 回复、partialMessage 合并与工具卡片链路不变。

## Boundaries & Constraints

**Always:** 保持现有 `SDKMessage -> AgentEvent -> TimelineView` 分层；只隐藏明确属于 tool-use 过渡态且内容为空的 assistant 事件；正常 assistant 文本、结果卡片、toolUse/toolResult、partialMessage 清空逻辑必须保持可用；如果需要改动映射层，测试要覆盖 stopReason 与内容组合。

**Ask First:** 如果修复必须改变 `AgentEvent` 基础结构、把 `EventMapper.map` 改成可抛错/可选返回，或同时想隐藏其他空内容事件类型，先问用户。

**Never:** 不把所有空 assistant 事件一刀切吞掉；不影响 Debug/Inspector 对 stopReason 元数据的既有可见性约定之外的事件；不顺手重构 Timeline 虚拟化、Markdown 渲染或 Tool 卡片体系。

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| tool_use 过渡态 | `SDKMessage.assistant(text: "", stopReason: "tool_use")` | 不产生用户可见的 assistant 空白气泡 | 后续 toolUse/toolResult 继续正常出现 |
| 正常回答 | `SDKMessage.assistant(text: "有正文", stopReason: "end_turn")` | 正常显示 assistant 回复 | N/A |
| 非 tool_use 空内容 | `SDKMessage.assistant(text: "", stopReason: 其他值或空)` | 保持现有行为，避免过度吞事件 | 若后续决定要隐藏，需单独讨论 |
| partial -> assistant 收尾 | 前面已有 partialMessage，随后收到空 `tool_use` assistant | partial 流状态正确收尾，不出现额外空白行 | 工具链路继续可见 |

</frozen-after-approval>

## Code Map

- `SwiftWork/SDKIntegration/EventMapper.swift` -- SDK assistant 事件当前无条件映射为可见 assistant Event
- `SwiftWork/SDKIntegration/AgentBridge.swift` -- 事件流消费、partialMessage 清空和 append/persist 入口
- `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` -- assistant 事件始终进入 `AssistantMessageView`
- `SwiftWork/Views/Workspace/Timeline/EventViews/AssistantMessageView.swift` -- 空内容仍会占据可见布局
- `SwiftWorkTests/SDKIntegration/EventMapperTests.swift` -- assistant/tool_use 组合的映射回归保护

## Tasks & Acceptance

**Execution:**
- [x] `SwiftWork/SDKIntegration/EventMapper.swift` 或 `SwiftWork/SDKIntegration/AgentBridge.swift` -- 为“空内容 + tool_use stopReason”的 assistant 事件加上非用户可见处理，不再落成空白 assistant 气泡 -- 从根源消除空行
- [x] `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` / `AssistantMessageView.swift`（如需要） -- 保证 UI 只渲染真正可见的 assistant 回复，不靠空 Markdown 占位 -- 让 Timeline 视觉结果与事件语义一致
- [x] `SwiftWorkTests/SDKIntegration/EventMapperTests.swift` 及相关 Timeline/Bridge 测试文件 -- 增加空 tool_use assistant 隐藏、正常 assistant 保留、非 tool_use 空内容不误伤的覆盖 -- 锁住过滤边界

**Acceptance Criteria:**
- [x] Given SDK 发出 `assistant(text: "", stopReason: "tool_use")`, when Timeline 更新, then 界面不显示额外的 assistant 空白行
- [x] Given SDK 发出带正文的 assistant 事件, when Timeline 更新, then 正常 assistant 回复仍然显示
- [x] Given toolUse/toolResult 事件紧随其后, when 空 tool_use assistant 被过滤, then 工具卡片链路仍然完整可见
- [x] Given 非 `tool_use` 的空 assistant 事件, when 当前修复生效, then 不会被本次 bugfix 意外吞掉

## Design Notes

- 更稳妥的方向是把这种事件视为**不可见过渡态**，尽量在映射/append 阶段就拦掉，而不是让 UI 去渲染一个空 `MarkdownContentView`。
- 但 `AgentBridge` 里仍有 `assistant` 事件触发 `streamingText = ""` 的收尾逻辑，所以实现时要确保过滤后不会让 partial 流残留。

## Verification

**Commands:**
- `swift build` -- expected: 事件映射与 Timeline 改动后正常编译
- `swift test` -- expected: 新增空 tool_use assistant 回归测试通过，现有事件映射测试继续通过

## Suggested Review Order

**Visibility contract**

- 先看这个精确谓词如何只标记空 `tool_use` assistant 过渡事件。
  [`AgentEvent.swift:24`](../../SwiftWork/Models/UI/AgentEvent.swift#L24)

- 这里保留事件用于调试审计，但把可见性决定留给上层。
  [`AgentBridge.swift:696`](../../SwiftWork/SDKIntegration/AgentBridge.swift#L696)

- 这里把 Timeline 的展示与滚动统一建立在可见事件集合上。
  [`TimelineView.swift:38`](../../SwiftWork/Views/Workspace/Timeline/TimelineView.swift#L38)

- 这里定义真正的 UI 过滤边界，只隐藏那一类过渡事件。
  [`TimelineView.swift:527`](../../SwiftWork/Views/Workspace/Timeline/TimelineView.swift#L527)

**Regression coverage**

- 先看映射层如何保留 stopReason 元数据，支持后续过滤判断。
  [`EventMapperTests.swift:61`](../../SwiftWorkTests/SDKIntegration/EventMapperTests.swift#L61)

- 这里锁住 Bridge 层“清 streaming 但仍保留事件”的行为。
  [`AgentBridgeTests.swift:271`](../../SwiftWorkTests/SDKIntegration/AgentBridgeTests.swift#L271)

- 这里覆盖 Timeline 只隐藏目标事件且滚动目标不被带偏。
  [`TimelineViewRefactoredTests.swift:48`](../../SwiftWorkTests/Views/Timeline/TimelineViewRefactoredTests.swift#L48)
