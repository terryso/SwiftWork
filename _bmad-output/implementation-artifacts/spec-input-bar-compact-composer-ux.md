---
title: 'Input Bar Compact Composer UX'
type: 'refactor'
created: '2026-05-04'
status: 'done'
route: 'plan-code-review'
baseline_commit: '8d3a1ae3d2b0125342943bc97e3c0ca02c85a710'
context:
  - '{project-root}/_bmad-output/project-context.md'
---

# Input Bar Compact Composer UX

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** 当前输入框虽然已经具备自动增高和最大高度后的内部滚动能力，但默认态仍显得过高、过厚，视觉上像占了多行。它缺少稳定的 placeholder 呈现和更像常见聊天应用的紧凑默认体验，导致输入器看起来比时间线更抢空间。

**Approach:** 保留现有 IME-safe AppKit bridge、Enter 发送 / Shift+Enter 换行和最大高度后的内部滚动机制，在此基础上把输入器打磨成默认单行的紧凑 composer：收紧默认高度与内外边距、补上 overlay placeholder，并校准滚动与按钮对齐，让它在短消息时轻量、长消息时自然扩展。

## Boundaries & Constraints

**Always:** 保持 `NSTextView` + `NSScrollView` 方案，不退回纯 SwiftUI 输入组件；保持中文/日文 IME 组合输入安全；保持 Enter 发送、Shift+Enter/Option+Enter 换行；继续采用“达到最大高度后在输入框内部滚动”的行为；placeholder 文案继续使用现有输入栏约定“输入消息发送给 Agent...”。

**Ask First:** 如果实现中发现需要改变发送按钮显隐规则、Agent 运行时的输入禁用策略，或把“长粘贴折叠为 chip/附件”纳入本次范围，必须先问用户。

**Never:** 不重做 InputBar 整体布局结构；不引入富文本编辑器、第三方输入库或动画驱动的复杂高度系统；不修改 Timeline、AgentBridge 或消息发送语义；不把 openwork 的长粘贴折叠、全局焦点系统等扩展体验偷偷塞进这次实现。

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| 默认态 | 空输入框，Workspace 初次显示 | 输入框呈现为紧凑单行高度，placeholder 与文本基线对齐，发送/停止按钮仍与底边自然对齐 | N/A |
| 自动增高 | 用户连续输入并产生换行 | 输入框按内容逐步增高，直到设定的最大可见高度 | N/A |
| 超过上限 | 用户粘贴或输入超过最大可见高度的长文本 | 输入框高度不再继续撑开布局，内部出现垂直滚动，文本不被裁剪 | N/A |
| IME 组合 | 中文/日文输入法处于 marked text 状态时按 Enter | 不提前发送，继续交给系统处理组合输入 | 继续沿用现有 IME 保护逻辑 |
| 清空态切换 | 用户发送消息或手动清空文本 | 输入框恢复单行紧凑高度，placeholder 再次出现，滚动位置回到顶部 | 若滚动视图状态未重置，应显式恢复到默认展示状态 |

</frozen-after-approval>

## Code Map

- `SwiftWork/Views/Workspace/InputBar/InputBarView.swift` -- 输入栏容器、按钮对齐、placeholder overlay 宿主和整体视觉密度调整
- `SwiftWork/Views/Workspace/InputBar/IMESafeTextView.swift` -- IME-safe `NSTextView` bridge、高度计算、最大高度后内部滚动、文本区域 inset 校准
- `SwiftWorkTests/Views/Workspace/InputBar/InputBarViewTests.swift` -- 输入栏多行/发送行为契约测试的补充与回归保护

## Tasks & Acceptance

**Execution:**
- [x] `SwiftWork/Views/Workspace/InputBar/IMESafeTextView.swift` -- 收紧单行高度、文本 inset 和最大可见高度计算，确保默认态接近单行 composer、超限时仍由内部滚动承载 -- 直接解决“默认占很多行”的根因，同时保留现有 IME-safe 架构
- [x] `SwiftWork/Views/Workspace/InputBar/InputBarView.swift` -- 调整输入栏内外 padding、按钮底边对齐和壳层视觉密度，并在空文本时提供不影响输入的 overlay placeholder -- 让短消息场景更像常见聊天应用，减少“输入框像大卡片”的观感
- [x] `SwiftWork/Views/Workspace/InputBar/InputBarView.swift` + `SwiftWork/Views/Workspace/InputBar/IMESafeTextView.swift` -- 在文本清空、重新编辑和超过最大高度滚动之间保持稳定状态切换，不出现高度抖动、placeholder 重叠或按钮跳动 -- 防止 UX 打磨后出现交互毛刺
- [x] `SwiftWorkTests/Views/Workspace/InputBar/InputBarViewTests.swift` -- 保留并补强对多行输入、Enter/Shift+Enter 契约及紧凑 composer 行为意图的测试说明 -- 为这次 UX 调整建立回归保护

**Acceptance Criteria:**
- Given 输入框为空, when Workspace 显示, then 输入栏呈现为明显单行的紧凑高度，而不是像默认多行编辑区
- Given 用户输入到第二行、第三行, when 文本自然换行, then 输入框逐步增高且按钮对齐保持稳定
- Given 文本高度超过上限, when 继续输入或粘贴长文本, then 输入框不再继续撑高父布局，而是在内部垂直滚动
- Given 输入框为空, when 用户尚未输入, then placeholder 可见且与正文对齐；when 用户输入后, then placeholder 立即消失且不干扰点击与输入
- Given IME 正在组合输入, when 用户按 Enter, then 不会误发送消息，既有 Enter/Shift+Enter 行为契约保持不变
- Given 用户发送消息后输入被清空, when 输入栏回到空态, then 高度恢复为默认单行并重新显示 placeholder

## Spec Change Log

- 2026-05-04 -- Implemented compact single-line-first composer sizing, overlay placeholder, stable scroll reset on clear, and regression coverage for compact composer metrics/placeholder behavior.
- 2026-05-04 -- Review patches aligned placeholder visibility with trimmed send-state, corrected placeholder offsets to match text origin, and preserved selection during external text sync.

## Design Notes

这次实现应吸收 `openwork` 的两个有效经验，但用 SwiftWork 现有结构表达，而不是照搬前端实现：

1. **紧凑默认态优先。** openwork 的核心体验不是“能自动增高”，而是“默认看起来就是一行输入框”。SwiftWork 已经有自动增高能力，因此重点是重新校准 `singleLineHeight`、`textContainerInset`、容器 padding 和按钮底边。
2. **Placeholder 作为 overlay，而不是依赖原生文本控件默认样式。** 这样能更稳定地控制位置、颜色和消失时机，并避免 AppKit bridge 下 placeholder 基线漂移。
3. **最大高度应服务于时间线，而不是吞掉它。** 建议维持中等上限，避免长 prompt 把底部 composer 撑成大面板；如果现有 `120pt` 在视觉上仍偏高，可适度下调，但必须保证 4–5 行文本仍有足够编辑空间。

## Verification

**Commands:**
- `swift build` -- expected: Build complete without errors
- `swift test` -- expected: Existing test suite passes with InputBar regression coverage intact

**Manual checks:**
- 在 app 中输入短消息，确认默认态明显是单行且比当前更紧凑
- 输入多行与超长文本，确认高度增长与内部滚动切换自然，没有裁剪和跳动
- 使用中文输入法测试 Enter、Shift+Enter 和组合输入，确认不会误发送

## Suggested Review Order

**Composer behavior and visual alignment**

- 从入口先看 placeholder、trimmed 输入态和按钮显隐的交互一致性。
  [`InputBarView.swift:13`](../../SwiftWork/Views/Workspace/InputBar/InputBarView.swift#L13)

- 这里集中定义紧凑单行、高度上限和 placeholder 基线偏移。
  [`IMESafeTextView.swift:4`](../../SwiftWork/Views/Workspace/InputBar/IMESafeTextView.swift#L4)

- 这里实现外部文本同步、清空回退和光标位置保留。
  [`IMESafeTextView.swift:94`](../../SwiftWork/Views/Workspace/InputBar/IMESafeTextView.swift#L94)

- 这里处理内容测量、到上限后的内部滚动与清空时滚动复位。
  [`IMESafeTextView.swift:108`](../../SwiftWork/Views/Workspace/InputBar/IMESafeTextView.swift#L108)

**Regression coverage**

- 先看新增契约测试，确认紧凑高度、滚动阈值与 placeholder 规则被锁住。
  [`InputBarViewTests.swift:143`](../../SwiftWorkTests/Views/Workspace/InputBar/InputBarViewTests.swift#L143)
