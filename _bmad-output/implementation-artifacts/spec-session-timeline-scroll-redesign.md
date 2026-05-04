---
title: 'Refactor: 会话时间线分页与底部跟随重构'
type: 'refactor'
created: '2026-05-04'
status: 'done'
baseline_commit: 'd820cec2c8143db9ba0f327a85904c7388ada767'
context:
  - '{project-root}/_bmad-output/project-context.md'
  - '{project-root}/_bmad-output/planning-artifacts/architecture.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** 当前会话时间线把“初始定位、顶部加载旧消息、底部跟随、虚拟化占位”耦合在同一个滚动流程里，导致点击“滑动到底部”后再回到顶部时可能出现大面积空白，并且不同会话的初始定位与流式回复跟随行为不稳定。这个问题已经不适合继续做补丁式修复，需要把会话展示改成更稳的分页与滚动模型。

**Approach:** 重构会话时间线为“最新页打开 + 顶部接近阈值自动补旧页 + 明确的底部跟随状态机 + 稳定的回到底部按钮”模型。参考 openwork 把“数据分页”和“滚动状态”拆开，但补上 SwiftWork 自己需要的向上分页与锚点保持，确保切会话、流式输出、离开底部和回到底部这几种路径都不会互相污染。

## Boundaries & Constraints

**Always:** 打开任意会话时默认展示最新一页消息；接近顶部时自动加载更早消息且保持当前阅读位置稳定；位于底部时发送新问题和 AI 流式回复必须持续跟随到底部；离开底部时显示现有样式的“回到底部”按钮；修复过程中优先保证滚动正确性，其次才是激进虚拟化；不得破坏现有事件映射、Tool 卡片、流式文本和 Inspector 选中行为。

**Ask First:** 如果实现中发现必须临时移除现有虚拟化占位策略、修改分页大小的用户可感知默认值，或需要改变“点击会话后默认展示最新页”的交互语义，先停下确认。

**Never:** 不要继续依赖 `events.first?.id` 触发“初始滚动”；不要让“回到底部”按钮重置成一个与真实视口脱节的尾部窗口；不要用固定高度占位去赌所有事件行高度；不要为了掩盖空白问题而直接关闭顶部自动加载；不要改动无关的 Sidebar、消息输入样式或事件持久化模型。

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| 打开长会话 | 用户点击一个包含很多历史消息的会话 | 首屏直接落在最新一页；最新消息可见；不会先跳顶部再跳底部 | N/A |
| 顶部补历史 | 用户向上滚动并接近顶部，且仍有更早消息 | 自动补入更早页；当前可见顶部消息的视觉位置基本保持不跳变；不会出现整片空白区 | 单次加载失败时保留当前已显示内容，不清空、不重置到底部，并暴露现有错误状态 |
| 底部跟随流式输出 | 视口当前在底部，用户发送新消息，AI 开始流式输出 | 时间线持续跟随到底部，最新用户消息、streaming 文本和最终 assistant 消息始终可见 | N/A |
| 离开底部后有新内容 | 用户手动离开底部，此时新增事件或 streamingText 增长 | 保持用户当前阅读位置，不强制跳到底部；显示“回到底部”按钮 | N/A |
| 使用按钮后再次上滑 | 用户点击“回到底部”，随后再次快速滚到顶部并触发旧消息加载 | 顶部分页仍稳定，锚点保持正确，不出现大面积空白或错误 spacer | 若连续触发加载，必须有进行中保护，避免重复 prepend |

</frozen-after-approval>

## Code Map

- `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` -- 当前时间线把初始滚动、顶部加载、底部按钮和虚拟窗口耦合在一起，是本次重构主战场。
- `SwiftWork/SDKIntegration/AgentBridge.swift` -- 当前维护尾部页、`trimmedEventCount` 与 `loadEarlierEvents()`；需要补强分页状态与并发保护。
- `SwiftWork/Views/Workspace/Timeline/ScrollModeManager.swift` -- 当前仅有 `followLatest/manualBrowse` 的轻量状态机，需要成为更明确的底部跟随判定入口。
- `SwiftWork/Views/Workspace/Timeline/TimelineVirtualizationManager.swift` -- 当前只按 `visibleRange + buffer` 裁剪；需要配合真实视口锚点，或在正确性优先下简化。
- `SwiftWork/Views/Workspace/WorkspaceView.swift` -- 会话切换时触发事件重载；需要提供稳定的“会话已切换/已重载”信号，避免 prepend 被误判成初始加载。
- `SwiftWorkTests/SDKIntegration/AgentBridgeTests.swift` -- 为顶部分页保护、尾页加载和状态复位补测试。
- `SwiftWorkTests/Views/Timeline/TimelineViewRefactoredTests.swift` -- 为会话初始定位、底部跟随和“回到底部”可见性补行为测试。
- `SwiftWorkTests/Views/Timeline/TimelinePerformanceTests.swift` -- 校验重构后长会话场景不引入明显回归。

## Tasks & Acceptance

**Execution:**
- [x] `SwiftWork/SDKIntegration/AgentBridge.swift` -- 把会话事件加载明确成“最新页窗口 + 可继续向前补页”的状态模型，保留现有持久化接口但新增顶部分页进行中保护、会话切换后的分页状态重置，以及供 Timeline 使用的稳定分页元数据 -- 先把数据层变成可预测的输入。
- [x] `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` -- 移除以 `events.first?.id` 为键的初始滚动任务，改为基于会话切换/重载信号执行一次性首屏定位；首屏默认落在最新页；接近顶部时自动请求旧页并在 prepend 后保持当前顶部锚点；仅当处于跟随模式时才自动滚到底部；按钮继续复用现有视觉样式但只负责回到底部，不负责重写虚拟窗口真相 -- 解决空白区与滚动互相打架的核心。
- [x] `SwiftWork/Views/Workspace/Timeline/ScrollModeManager.swift` -- 收敛为可复用的滚动状态入口：明确“在底部/离开底部/程序性回底部”的状态切换和阈值，避免内容增长被误判成用户手势 -- 让按钮显示和自动跟随依据同一事实来源。
- [x] `SwiftWork/Views/Workspace/Timeline/TimelineVirtualizationManager.swift` -- 让渲染窗口跟随真实视口锚点更新；如果现有 spacer 估算无法在本次改造中保证正确性，则降级为更保守但正确的窗口策略，不允许再出现由固定高度估算导致的大片空白 -- 正确性优先于激进优化。
- [x] `SwiftWork/Views/Workspace/WorkspaceView.swift` -- 在会话切换时为 Timeline 提供稳定的 reload 周期边界，确保切换会话时总是按“最新页打开”执行一次，而顶部补页不会误触发同一路径 -- 隔离会话切换与分页 prepend。
- [x] `SwiftWorkTests/SDKIntegration/AgentBridgeTests.swift` -- 覆盖：长会话首次加载只取尾页、连续顶部加载不会并发重复、切换会话后分页状态复位 -- 锁住数据层行为。
- [x] `SwiftWorkTests/Views/Timeline/TimelineViewRefactoredTests.swift` -- 覆盖：打开会话默认到最新页、在底部发送/流式输出持续跟随、离开底部显示按钮、点击按钮后再上滑补历史不产生空白区的关键状态转换 -- 锁住核心交互。
- [x] `SwiftWorkTests/Views/Timeline/TimelinePerformanceTests.swift` -- 为长会话滚动与分页补基线断言，确认重构没有把性能退化到不可接受 -- 保住 NFR13 / ARCH-10 的底线。

**Acceptance Criteria:**
- Given 用户点击一个已有很多历史消息的会话，when 时间线首次渲染完成，then 直接显示最新一页消息而不是顶部旧消息，并且不会出现二次跳转造成的闪动。
- Given 用户向上滚动并接近顶部且还有旧消息，when 自动分页触发，then 更早消息被补进来，当前阅读位置保持稳定，不出现大面积空白、跳到底部或重复加载同一页。
- Given 用户当前位于底部，when 发送新问题并收到 AI 流式回复，then 时间线持续跟随到底部，直到最终 assistant/result 事件完成。
- Given 用户主动离开底部，when 后续有新事件或 streaming 内容增长，then 时间线保持当前阅读位置不动，并显示现有样式的“回到底部”按钮。
- Given 用户点击“回到底部”按钮后再次滚回顶部，when 顶部分页再次发生，then 滚动锚点仍然正确，顶部区域不会出现明显错误占位或大片空白。

## Spec Change Log

## Design Notes

- 参考 openwork 的方向不是照搬 UI，而是照搬职责切分：**尾部窗口加载 / 滚动状态机 / 程序性回底部保护**分层处理。SwiftWork 需要在此基础上补上“向上自动分页 + prepend 锚点保持”。
- 本次重构的关键不是再加一个 if，而是把三类动作分开：
  1. **会话切换初始定位**：只在会话切换或重载完成后执行一次；
  2. **顶部补页**：只负责 prepend 和锚点保持；
  3. **底部跟随**：只在 `followLatest` 状态下对新增事件与 streaming 生效。
- 如果当前 spacer 虚拟化无法在异构行高下保持正确性，应优先退回较保守的窗口策略；“滚动正确、没有空白”比“理论上更省几个 view”更重要。

## Verification

**Commands:**
- `swift build` -- expected: 成功编译，Timeline/AgentBridge 相关改动无类型错误
- `swift test` -- expected: Timeline 与 AgentBridge 相关测试通过，现有测试无回归

## Suggested Review Order

**Timeline 行为入口**

- 先看时间线如何把“首屏定位、顶部补页、底部跟随”拆成独立职责。
  [`TimelineView.swift:4`](../../SwiftWork/Views/Workspace/Timeline/TimelineView.swift#L4)

- 顶部触发现在会先做 guard，再保存 prepend 视口快照。
  [`TimelineView.swift:397`](../../SwiftWork/Views/Workspace/Timeline/TimelineView.swift#L397)

- prepend 完成后优先按真实文档高度恢复视口，避免大片空白和跳变。
  [`TimelineView.swift:419`](../../SwiftWork/Views/Workspace/Timeline/TimelineView.swift#L419)

- 程序性滚动加 generation 保护，避免 streaming 时竞态误判。
  [`TimelineView.swift:467`](../../SwiftWork/Views/Workspace/Timeline/TimelineView.swift#L467)

**分页状态与会话重载**

- AgentBridge 现在集中暴露时间线分页元数据，供 UI 做稳定决策。
  [`AgentBridge.swift:5`](../../SwiftWork/SDKIntegration/AgentBridge.swift#L5)

- 顶部分页增加并发保护和错误状态更新，失败后仍可重试。
  [`AgentBridge.swift:226`](../../SwiftWork/SDKIntegration/AgentBridge.swift#L226)

- 分页状态统一从一个入口刷新，切会话时也会生成新的 reloadID。
  [`AgentBridge.swift:495`](../../SwiftWork/SDKIntegration/AgentBridge.swift#L495)

- Workspace 用独立 reload token 隔离“切会话”与“prepend 旧消息”两条路径。
  [`WorkspaceView.swift:15`](../../SwiftWork/Views/Workspace/WorkspaceView.swift#L15)

**滚动模式与保守渲染**

- 滚动模式现在显式区分程序滚动中的状态，防止内容增长误切 manual。
  [`ScrollModeManager.swift:10`](../../SwiftWork/Views/Workspace/Timeline/ScrollModeManager.swift#L10)

- 虚拟化默认退到 conservative 策略，先保证正确性再谈激进优化。
  [`TimelineVirtualizationManager.swift:9`](../../SwiftWork/Views/Workspace/Timeline/TimelineVirtualizationManager.swift#L9)

- 视图级滚动策略被提成纯逻辑，测试能直接锁住交互规则。
  [`TimelineView.swift:536`](../../SwiftWork/Views/Workspace/Timeline/TimelineView.swift#L536)

**测试收口**

- AgentBridge 测试覆盖了分页失败后的清理与重试。
  [`AgentBridgeTests.swift:334`](../../SwiftWorkTests/SDKIntegration/AgentBridgeTests.swift#L334)

- Timeline 行为测试直接锁住“流式优先、自动跟随、顶部触发条件”。
  [`TimelineViewRefactoredTests.swift:17`](../../SwiftWorkTests/Views/Timeline/TimelineViewRefactoredTests.swift#L17)

- 性能测试从旧 first-page 模型切到“最新页打开 + 向上 prepend”模型。
  [`TimelinePerformanceTests.swift:117`](../../SwiftWorkTests/Views/Timeline/TimelinePerformanceTests.swift#L117)
