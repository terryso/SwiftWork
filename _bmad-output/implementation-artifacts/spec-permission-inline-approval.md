---
title: '权限审批内联化'
type: 'feature'
created: '2026-05-04'
status: 'done'
context:
  - '{project-root}/_bmad-output/implementation-artifacts/3-1-permission-system.md'
baseline_commit: 'c2ee57ec0fb7771a6266261fe81bdfd73ad9ceb8'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** manualReview 模式下每次工具调用都弹出 macOS Sheet 阻塞整个 Workspace，交互极重。一次任务可能触发 5-10+ 次全屏阻塞弹窗，且不区分只读/写操作。

**Approach:** 将权限审批从 Sheet 弹窗改为 Timeline 内联卡片，用户在消息流中直接审批。同时自动放行只读工具，仅拦截写操作，大幅减少审批频率。新增 doom loop 检测防止 Agent 死循环。

## Boundaries & Constraints

**Always:**
- 权限请求必须作为 Timeline 内的 AgentEvent 渲染（不再使用 Sheet/Alert）
- 只读工具（Read、Glob、Grep）在 manualReview 模式下自动放行，不生成审批卡片
- doom loop 检测：同一 toolName + 相同 input 连续触发 3 次时生成特殊警告卡片
- "本会话允许"按钮的行为从 persistent rule 改为 session override（与 OpenWork 对齐）
- 已有的 autoApprove/denyAll 模式行为不变

**Ask First:** 无

**Never:**
- 不移除 PermissionDialogView.swift 和 PermissionRulesView.swift 文件（可能保留用于其他场景）
- 不修改 SwiftData 模型（PermissionRule、Session、Event 结构不变）
- 不修改 EventMapper（权限事件在 AgentBridge 层直接生成，不来自 SDK）
- 不修改 toolContentMap 逻辑（权限卡片独立于 tool card 系统）

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| 写操作需要审批 | manualReview 模式，工具为 Bash/Edit/Write | Timeline 插入 permissionRequest 事件，渲染内联审批卡片 | N/A |
| 只读操作自动放行 | manualReview 模式，工具为 Read/Glob/Grep | 不生成审批卡片，直接 approved | N/A |
| 用户点击"允许一次" | 审批卡片，Allow Once | 卡片变为已批准状态，session override 记录该 toolName | N/A |
| 用户点击"本会话允许" | 审批卡片，Allow for Session | 卡片变为已批准状态，session override 记录该 toolName | N/A |
| 用户点击"拒绝" | 审批卡片，Deny | 卡片变为已拒绝状态，SDK 收到 deny | N/A |
| Doom loop 检测 | 同 toolName+input 连续 3 次 | 插入 doom loop 警告卡片，用户必须选择允许或停止 | N/A |
| 快速连续审批 | 2+ 个审批卡片同时存在 | 每张卡片独立，用户可按任意顺序处理 | N/A |

</frozen-after-approval>

## Code Map

- `SwiftWork/Models/UI/AgentEventType.swift` -- 新增 `.permissionRequest` 和 `.doomLoopWarning` 事件类型
- `SwiftWork/SDKIntegration/AgentBridge.swift` -- 替换 Sheet 弹窗为内联事件注入，添加 doom loop 检测
- `SwiftWork/SDKIntegration/PermissionHandler.swift` -- 新增 `isReadOnlyTool()` 逻辑，manualReview 模式自动放行只读工具
- `SwiftWork/Views/Workspace/Timeline/EventViews/PermissionCardView.swift` -- 新建：内联权限审批卡片
- `SwiftWork/Views/Workspace/Timeline/EventViews/DoomLoopWarningView.swift` -- 新建：doom loop 警告卡片
- `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` -- eventView(for:) 中添加新事件类型的渲染分支
- `SwiftWork/Views/Workspace/WorkspaceView.swift` -- 移除 `.sheet(item:)` 权限弹窗绑定
- `SwiftWork/Views/Permission/PermissionDialogView.swift` -- 标记 @available(*, deprecated)

## Tasks & Acceptance

**Execution:**
- [x] `AgentEventType.swift` -- 新增 `.permissionRequest` 和 `.doomLoopWarning` 两个 case -- 支持新事件类型在 Timeline 中渲染
- [x] `PermissionHandler.swift` -- 新增 `isReadOnlyTool(_ toolName:) -> Bool` 静态方法，识别 Read/Glob/Grep；在 `evaluateManualReview` 中对只读工具直接返回 `.approved` -- 减少 60-70% 审批频率
- [x] `PermissionCardView.swift` -- 新建内联审批卡片视图：工具类型标签 + 操作摘要 + 参数展示 + 三个按钮（拒绝/允许一次/本会话允许），已处理后显示终态 -- 核心交互替代 Sheet
- [x] `DoomLoopWarningView.swift` -- 新建 doom loop 警告卡片：检测图标 + 警告文案 + 允许/停止按钮 -- 防止 Agent 死循环
- [x] `AgentBridge.swift` -- 重构 `presentPermissionDialog`：不再设置 `pendingPermissionRequest`，改为创建 `AgentEvent(type: .permissionRequest)` 注入 events 数组；doom loop 检测逻辑：维护 `[String: Int]` 计数器追踪最近 toolName+input hash 的重复次数 -- 从弹窗模式切换到内联模式
- [x] `TimelineView.swift` -- 在 `eventView(for:)` 中添加 `.permissionRequest` → `PermissionCardView` 和 `.doomLoopWarning` → `DoomLoopWarningView` 渲染分支 -- 新事件类型可视化
- [x] `WorkspaceView.swift` -- 移除 `.sheet(item: $bridge.pendingPermissionRequest, ...)` 代码块 -- 清理旧 Sheet 逻辑
- [x] `PermissionDialogView.swift` -- 添加 `@available(*, deprecated, message: "Use PermissionCardView inline instead")` -- 标记废弃

**Acceptance Criteria:**
- Given manualReview 模式，when Agent 调用 Bash/Edit/Write 工具，then Timeline 中出现内联审批卡片（无 Sheet 弹窗）
- Given manualReview 模式，when Agent 调用 Read/Glob/Grep 工具，then 自动放行，不出现审批卡片
- Given 审批卡片已显示，when 用户点击"允许一次"或"本会话允许"，then 卡片变为已批准状态，Agent 继续执行
- Given 审批卡片已显示，when 用户点击"拒绝"，then 卡片变为已拒绝状态，SDK 收到 deny
- Given 同一工具+相同输入连续触发 3 次，when 第 3 次触发，then Timeline 中出现 doom loop 警告卡片
- Given autoApprove 模式，when 任何工具调用，then 行为与之前完全一致（零回归）

## Spec Change Log

## Design Notes

### 内联审批卡片的交互模式

审批卡片嵌入 Timeline，与 toolUse/toolResult 卡片同级。卡片有两种状态：

**待审批（active）：**
```
┌─ ⚠️ 需要审批 ──────────────── 待定 ─┐
│ 终端命令                             │
│ rm -rf /tmp/build                    │
│ 命令:  rm -rf /tmp/build             │
│ 工作目录:  /Users/nick/project        │
│                                      │
│ [拒绝]         [允许一次]  [本会话允许]│
└──────────────────────────────────────┘
```

**已处理（resolved）：**
```
┌─ ✓ 已批准 ──────────────── 已批准 ─┐
│ 终端命令: rm -rf /tmp/build         │
└──────────────────────────────────────┘
```

### 数据流：SDK canUseTool → 内联卡片 → 用户操作 → SDK 结果

```
SDK canUseTool 回调
  → PermissionHandler.evaluate()
  → .requiresApproval
  → AgentBridge 创建 AgentEvent(type: .permissionRequest)
  → 追加到 events 数组
  → Timeline 渲染 PermissionCardView
  → 用户点击按钮
  → PermissionCardView 调用 AgentBridge.resolvePermission()
  → continuation.resume() → SDK 收到结果
```

### Doom Loop 检测逻辑

在 AgentBridge 中维护 `private var recentToolCalls: [(toolName: String, inputHash: String)] = []`（最近 20 条）。每次 canUseTool 回调时追加，超过 20 条时移除最旧的。当同一 `(toolName, inputHash)` 出现 >= 3 次时，插入 `.doomLoopWarning` 事件。

## Verification

**Commands:**
- `swift build` -- expected: 零错误，零警告
- `swift test` -- expected: 所有现有测试通过 + 新增测试通过

**Manual checks:**
- 切换到 manualReview 模式，执行一个需要多次工具调用的任务，确认无 Sheet 弹窗，审批卡片在 Timeline 内联显示
- 在 manualReview 模式下执行 Read 操作，确认无审批卡片出现
- 触发重复工具调用 3 次，确认 doom loop 警告卡片出现
