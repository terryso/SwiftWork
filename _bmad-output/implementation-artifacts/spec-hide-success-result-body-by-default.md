---
title: 'fix: hide success result body by default'
type: 'bugfix'
created: '2026-05-04'
status: 'done'
baseline_commit: '17b78a1638937c68559f2ad2a29288603b15fb63'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** 当前 Timeline 会把 success `.result` 既当作状态统计卡，又继续显示一大段正文；即使这段正文和上一条 assistant 不完全相同，用户看到的仍像是“回答后又来一份总结/套话/拼接文本”，体验很怪。你希望 success result 卡片只承担状态与统计信息，不再承担回答正文展示。

**Approach:** 调整 `ResultView` 的 success 渲染规则：success `.result` 默认不显示正文内容，只保留 success 状态、耗时、轮次、费用等元信息；error / cancelled 结果继续显示正文，保证失败和取消原因仍然可见。

## Boundaries & Constraints

**Always:** 保留 `.result` 事件卡片本身；保留 success 卡片的状态标识和底部统计信息；保留 error / cancelled 卡片正文；修改尽量局部，避免影响 `.assistant`、工具卡片、Inspector 元数据和 Timeline 的滚动逻辑。

**Ask First:** 如果实施时发现某些 success `.result` 是系统里**唯一**的用户可见输出，而且隐藏正文会让某类成功流程完全无解释，需要先停下来确认是否要引入更细的白名单/条件分支。

**Never:** 不删除 success `.result` 卡片；不移除耗时/轮次/费用；不改 SDK 事件映射；不顺带调整 Timeline 布局、排序或滚动行为；不再依赖“和上一条 assistant 是否完全相同”作为 success 正文是否隐藏的条件。

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Success result | `.result(subtype: success)` 携带正文和统计信息 | 只显示 success 状态与统计信息，不显示正文块 | N/A |
| Cancelled result | `.result(subtype: cancelled)` 携带取消说明 | 保留取消正文和 cancelled 状态样式 | N/A |
| Error result | `.result` 为错误 subtype，正文包含失败原因 | 保留错误正文和错误样式 | N/A |

</frozen-after-approval>

## Code Map

- `SwiftWork/Views/Workspace/Timeline/EventViews/ResultView.swift` -- success / cancelled / error 三类结果卡片的正文与统计信息渲染逻辑；本次修复主入口。
- `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` -- 当前把 `.result` 事件传给 `ResultView`，需要确认是否还存在多余的 success 判定入口。
- `SwiftWorkTests/Views/Timeline/EventVisualSystemTests.swift` -- 适合补 success 默认隐藏正文、cancelled / error 继续显示正文、统计信息保留的逻辑测试。
- `SwiftWorkTests/Views/Timeline/MarkdownRenderingIntegrationTests.swift` -- 现有 ResultView Markdown 集成约束，适合保持 non-success 正文仍可渲染 Markdown。

## Tasks & Acceptance

**Execution:**
- [x] `SwiftWork/Views/Workspace/Timeline/EventViews/ResultView.swift` -- 将 success `.result` 的正文展示改为默认关闭，仅保留状态与统计信息；cancelled / error 继续显示正文 -- 让 success result 回到“状态卡”角色，消除第二份回答感。
- [x] `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` -- 移除这次 UX 不再需要的 success 正文隐藏判定接线，确保 `.result` 渲染路径保持最小必要复杂度 -- 避免继续依赖“是否重复”的旧策略。
- [x] `SwiftWorkTests/Views/Timeline/EventVisualSystemTests.swift` -- 调整测试，覆盖 success 默认隐藏正文、cancelled / error 保留正文、统计信息继续保留 -- 防止行为回退到“只在完全重复时才隐藏”。
- [x] `SwiftWorkTests/Views/Timeline/MarkdownRenderingIntegrationTests.swift` -- 保留对 non-success ResultView 正文 Markdown 渲染的集成约束 -- 确保收窄 success 正文后不误伤其他结果类型。

**Acceptance Criteria:**
- Given Timeline 渲染 success `.result` 事件， when 结果卡片显示， then 卡片不显示正文块，只显示 success 状态和底部统计信息。
- Given Timeline 渲染 cancelled 或 error `.result` 事件， when 结果卡片显示， then 卡片仍显示正文内容和对应状态样式。
- Given success `.result` 事件带有耗时、轮次或费用， when 卡片渲染， then 这些统计信息仍然显示，不因正文隐藏而消失。

## Design Notes

这次不再把 success result 当成“可能与 assistant 重复的第二条正文”，而是直接把它定义成“执行结果状态卡”。这样可以跟实际体验对齐：用户真正关心的回答正文已经在 assistant 卡片里，看的是内容；success result 看的是状态和成本。

换句话说，规则应变成：

```swift
assistant -> 展示最终回答正文
result(success) -> 只展示状态 + 元信息
result(error/cancelled) -> 展示状态 + 原因正文 + 元信息
```

## Verification

**Commands:**
- `swift test` -- expected: 测试通过，且 ResultView 相关行为符合新的 success-only 状态卡规则

## Suggested Review Order

**Success result card behavior**

- 先看 success 为什么只剩状态和统计，不再展示正文。
  [`ResultView.swift:22`](../../SwiftWork/Views/Workspace/Timeline/EventViews/ResultView.swift#L22)

- 确认 `.result` 事件现在直接走精简后的 `ResultView` 路径。
  [`TimelineView.swift:333`](../../SwiftWork/Views/Workspace/Timeline/TimelineView.swift#L333)

**Regression coverage**

- 核对 success 隐藏正文、error/cancelled 保留正文、空白正文不渲染的约束。
  [`EventVisualSystemTests.swift:158`](../../SwiftWorkTests/Views/Timeline/EventVisualSystemTests.swift#L158)

- 补一眼 non-success 结果仍保留 Markdown 正文能力。
  [`MarkdownRenderingIntegrationTests.swift:66`](../../SwiftWorkTests/Views/Timeline/MarkdownRenderingIntegrationTests.swift#L66)
