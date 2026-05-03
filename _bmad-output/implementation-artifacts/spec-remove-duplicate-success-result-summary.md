---
title: 'fix: remove duplicate success summary from result card'
type: 'bugfix'
created: '2026-05-04'
status: 'done'
baseline_commit: '17b78a1638937c68559f2ad2a29288603b15fb63'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Timeline 里成功完成后的 `.assistant` 最终回答已经完整展示了回复正文，但紧跟着的 `.result` 卡片又把同一段成功内容渲染一遍，造成“回答内容 + 回答总结”重复，视觉上显得别扭。底部的耗时、轮次、费用元信息本身仍然有价值，不应一起删掉。

**Approach:** 调整成功态 `ResultView` 的展示规则：成功结果卡片只保留状态与元信息，不再重复渲染正文摘要；失败或取消结果继续展示结果内容，确保异常场景仍然能在 Timeline 中直接看到原因。

## Boundaries & Constraints

**Always:** 保留 `.result` 事件卡片本身；保留成功态的状态标识、耗时、轮次、费用；保留失败/取消态的正文内容；修改必须尽量局部，避免影响 Timeline 其他事件类型或 Inspector 元数据。

**Ask First:** 如果调查后发现某些成功 `.result` 场景没有对应 assistant 正文，且去掉摘要会导致关键信息完全消失，需要先停下来确认是否要引入“仅在与上一条 assistant 重复时才隐藏”的更复杂规则。

**Never:** 不删除 `.result` 事件；不移除底部元信息行；不改动 SDK 事件映射语义；不顺带重做 Timeline 布局或样式系统。

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Success with duplicate text | `.assistant` 已显示最终回答，随后 `.result(subtype: success)` 携带相同或等价正文 | Result 卡片仅显示 success 状态和底部元信息，不重复显示正文块 | N/A |
| Error result | `.result` subtype 为错误，正文包含失败原因 | Result 卡片继续显示错误正文与错误样式 | N/A |
| Cancelled result | `.result` subtype 为 cancelled，正文包含取消说明 | Result 卡片继续显示取消正文，并保留 cancelled 状态样式 | N/A |

</frozen-after-approval>

## Code Map

- `SwiftWork/Views/Workspace/Timeline/EventViews/ResultView.swift` -- `.result` 卡片的正文、状态和元信息渲染逻辑；本次 bugfix 的主入口。
- `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` -- 确认 `.result` 事件仍经由 `ResultView` 渲染，避免误改其他事件路径。
- `SwiftWorkTests/Views/Timeline/EventVisualSystemTests.swift` -- 现有 `ResultView` 轻量测试所在位置，适合补充成功/取消/错误场景的渲染约束测试。

## Tasks & Acceptance

**Execution:**
- [x] `SwiftWork/Views/Workspace/Timeline/EventViews/ResultView.swift` -- 让成功态结果卡片跳过正文摘要渲染，仅保留状态与元信息；失败/取消态继续显示正文 -- 直接消除成功回答的双重展示。
- [x] `SwiftWorkTests/Views/Timeline/EventVisualSystemTests.swift` -- 补充/调整 `ResultView` 相关测试，覆盖成功态不再展示重复正文以及错误/取消态仍保留正文的约束 -- 防止这个 UX 回归。

**Acceptance Criteria:**
- Given assistant 最终回答已经在 Timeline 中显示， when 紧接着渲染成功 `.result` 事件， then Result 卡片不再重复渲染正文摘要，只显示 success 状态和元信息。
- Given `.result` 为错误或取消结果， when Timeline 渲染该事件， then 卡片仍显示结果正文和对应状态样式，方便用户直接看到失败或取消原因。
- Given 成功 `.result` 携带耗时、轮次或费用， when Result 卡片渲染， then 这些元信息继续显示，避免丢失有用的执行统计。

## Design Notes

这个问题本质上不是“是否要保留 result 卡片”，而是“同一条成功回答不该在 assistant 和 result 两个视图里连续展示两次”。因此最小、最稳妥的修复是只收窄成功态正文展示，而不是调整事件映射或改 Timeline 排序。

这样可以保持现有事件模型不变：

```swift
assistant -> 展示最终回答正文
result(success) -> 展示状态 + 元信息
result(error/cancelled) -> 展示状态 + 原因正文 + 元信息
```

## Verification

**Commands:**
- `swift test` -- expected: 测试通过，且 ResultView 相关约束未回归

## Suggested Review Order

**Duplicate suppression logic**

- 先看重复判断边界，只在前一条 assistant 明确重复时隐藏 success 正文。
  [`ResultView.swift:3`](../../SwiftWork/Views/Workspace/Timeline/EventViews/ResultView.swift#L3)

- 看 Timeline 如何把当前 result 事件接到这条判定上。
  [`TimelineView.swift:333`](../../SwiftWork/Views/Workspace/Timeline/TimelineView.swift#L333)

**Regression coverage**

- 核对 success 隐藏、success 保留、error/cancelled 保留，以及重复判定边界测试。
  [`EventVisualSystemTests.swift:158`](../../SwiftWorkTests/Views/Timeline/EventVisualSystemTests.swift#L158)

- 补一眼 cancelled 场景仍保留 Markdown 正文的集成约束。
  [`MarkdownRenderingIntegrationTests.swift:66`](../../SwiftWorkTests/Views/Timeline/MarkdownRenderingIntegrationTests.swift#L66)
