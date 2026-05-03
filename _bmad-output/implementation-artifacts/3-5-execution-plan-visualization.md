# Story 3.5: 执行计划可视化

Status: done

## Story

As a 用户,
I want 看到 Agent 的任务拆解计划和执行进度,
so that 我可以理解 Agent 的工作方式和当前进展。

## Acceptance Criteria

1. **Given** Agent 生成了任务执行计划 **When** 接收到 Plan 相关事件 **Then** PlanView 显示步骤列表，每个步骤显示序号和描述（FR34）

2. **Given** Plan 步骤列表已渲染 **When** Agent 开始执行某个步骤 **Then** 该步骤状态变为"执行中"（显示旋转指示器），已完成步骤显示勾号（FR35）

3. **Given** 计划包含有依赖关系的步骤 **When** 渲染 PlanView **Then** 通过缩进或连线方式显示步骤之间的依赖关系（FR36）

**覆盖的 FRs:** FR34, FR35, FR36
**覆盖的 ARCHs:** ARCH-8 (Observation 框架), ARCH-9 (ToolRenderable 协议), ARCH-12 (分层边界)

## Tasks / Subtasks

- [x] Task 1: 数据模型——PlanStep 和 PlanData（AC: #1, #2, #3）
  - [x] 1.1 在 `SwiftWork/Models/UI/` 下新建 `PlanStep.swift`：定义 `PlanStep` struct（`id: String`、`description: String`、`status: PlanStepStatus`、`dependencies: [String]`），遵循 `Identifiable`、`Sendable`
  - [x] 1.2 在 `PlanStep.swift` 中定义 `PlanStepStatus` enum（`pending`、`inProgress`、`completed`、`failed`），遵循 `String`、`Sendable`、`Equatable`
  - [x] 1.3 在 `PlanStep.swift` 中定义 `PlanData` struct（`planId: String`、`content: String?`、`approved: Bool`、`steps: [PlanStep]`），遵循 `Sendable`

- [x] Task 2: 事件类型扩展——EventMapper 和 AgentEventType 适配 Plan 事件（AC: #1）
  - [x] 2.1 在 `AgentEventType.swift` 中新增 case `plan`，并更新 `CaseIterable` 一致性
  - [x] 2.2 在 `EventMapper.swift` 的 exhaustive switch 中，将 `.toolUse` 中 toolName 为 `"EnterPlanMode"` 和 `"ExitPlanMode"` 的事件映射为 `AgentEvent(type: .plan, ...)`
  - [x] 2.3 对于 `ExitPlanMode` 工具的 toolResult 事件，解析其 content 文本中的计划步骤（编号列表），提取为 `PlanData` 并存入 metadata
  - [x] 2.4 对于 `TodoWrite` 工具的 toolUse 事件，映射为 `AgentEvent(type: .plan, ...)`，将 todos 存入 metadata
  - [x] 2.5 对于 `TodoWrite` 工具的 toolResult 事件，解析返回的 todo 列表文本并更新 PlanData
  - [x] 2.6 确保 SDKMessage exhaustive switch 仍然完整编译——新增的 `plan` case 不影响已有的 18 种 SDKMessage 映射

- [x] Task 3: PlanView SwiftUI 视图实现（AC: #1, #2, #3）
  - [x] 3.1 新建 `SwiftWork/Views/Workspace/Timeline/EventViews/PlanView.swift`
  - [x] 3.2 PlanView 接收 `event: AgentEvent` 参数，从 `event.metadata` 中提取 `PlanData` 或从 `event.content` 中解析步骤列表
  - [x] 3.3 渲染步骤列表：每个步骤显示序号圆圈（带颜色）和描述文本（FR34）
  - [x] 3.4 步骤状态指示器：`pending` 空心圆、`inProgress` 旋转指示器（复用 ThinkingView 的动画模式）、`completed` 绿色勾号、`failed` 红色叉号（FR35）
  - [x] 3.5 依赖关系可视化：有 `dependencies` 的步骤通过左侧缩进（嵌套层级）表示依赖（FR36）
  - [x] 3.6 卡片样式：圆角矩形背景、折叠/展开按钮（默认折叠，显示步骤摘要），与 ToolCardView 视觉风格一致
  - [x] 3.7 确保 PlanView 不超过 300 行——如超出则拆分子视图（如 `PlanStepRow.swift`）

- [x] Task 4: TimelineView 集成——PlanView 渲染到事件流中（AC: #1）
  - [x] 4.1 在 `TimelineView.swift` 的 `eventView(for:)` 方法中添加 `.plan` case，渲染 `PlanView(event: event)`
  - [x] 4.2 在 `InspectorView.swift` 的 `eventDetail(for:)` switch 中添加 `.plan` case，显示 Plan 详情（步骤列表、状态汇总）
  - [x] 4.3 在 `EventDetailSections.swift` 中添加 `planEventSection(event:)` 方法

- [x] Task 5: 单元测试（AC: #1-#3）
  - [x] 5.1 新建 `SwiftWorkTests/Views/Timeline/PlanViewTests.swift`：
    - 测试 PlanStep 模型初始化和状态枚举
    - 测试 PlanData 包含步骤列表和依赖关系
    - 测试 EventMapper 将 EnterPlanMode toolUse 映射为 .plan 事件
    - 测试 EventMapper 将 ExitPlanMode toolResult 解析计划步骤
    - 测试 PlanView 渲染空计划和非空计划
  - [x] 5.2 所有新测试通过 `swift test`，现有测试无回归

## Dev Notes

### 核心目标

实现执行计划可视化——在 Timeline 中渲染 Agent 的任务拆解计划（步骤列表、执行状态、依赖关系）。这是 Epic 3 的最后一个 Story，完成后用户将拥有对 Agent 行为的完整可视化掌控力。

### 已有基础（必须在此基础上扩展，不重新创建）

1. **`AgentEventType.swift`**（`Models/UI/`）——当前 19 个 case（含 `unknown`），需新增 `plan` case。注意：这是 `CaseIterable` 枚举，新增 case 后所有 exhaustive switch 必须处理
2. **`EventMapper.swift`**（`SDKIntegration/`）——当前 exhaustive switch 处理 18 种 `SDKMessage` case。**不需要新增 SDKMessage case**——Plan 相关事件通过 `.toolUse`（toolName = EnterPlanMode/ExitPlanMode/TodoWrite）到达，需在现有 `.toolUse` case 内部通过 toolName 分支映射为 `.plan` 类型
3. **`AgentEvent.swift`**（`Models/UI/`）——已有 `metadata: [String: any Sendable]`，足够存储 PlanData 信息，无需修改
4. **`AgentBridge.swift`**（`SDKIntegration/`）——已有 `toolContentMap` 配对机制。Plan 事件不需要配对（不是 toolUse+toolResult 模式），但 EnterPlanMode/ExitPlanMode 的 toolResult 可能需要从 toolContentMap 获取
5. **`TimelineView.swift`**（`Views/Workspace/Timeline/`）——已有 `eventView(for:)` 的 exhaustive switch，需添加 `.plan` case。**注意**：selectedEventId 已改为 `@Binding`（Story 3-4）
6. **`InspectorView.swift`** + `EventDetailSections.swift`（`Views/Workspace/Inspector/`）——已有类型特化 section 模式，需添加 `.plan` case
7. **`ThinkingView.swift`**（`Views/Workspace/Timeline/EventViews/`）——旋转动画模式可复用
8. **`ToolCardView.swift`**——折叠/展开 UI 模式可参考
9. **`ResultView.swift`**——卡片样式（圆角矩形 + overlay 边框）可参考

### 架构关键决策

**SDK 没有独立的 "plan" SDKMessage case。** Plan 功能通过 SDK 的两个 Specialist Tools 实现：

1. **`EnterPlanMode`** 工具——Agent 进入计划模式。SDK 事件流表现为：
   - `.toolUse`（toolName="EnterPlanMode"）→ `.toolResult`（content="Entered plan mode..."）
2. **`ExitPlanMode`** 工具——Agent 退出计划模式并提交计划。SDK 事件流表现为：
   - `.toolUse`（toolName="ExitPlanMode", input={plan: "...", approved: true/false}）→ `.toolResult`（content="Plan mode exited. Plan: ...")
3. **`TodoWrite`** 工具——Agent 管理 todo 检查清单（也可以视为计划步骤）

**数据映射策略：**

由于 SDK 不发送独立的 "plan" 事件，SwiftWork 需要在 EventMapper 中**检测 toolName** 并重新映射：

```
SDKMessage.toolUse(toolName="EnterPlanMode")
  → AgentEvent(type: .plan, content: "进入计划模式", metadata: ["planAction": "enter"])

SDKMessage.toolUse(toolName="ExitPlanMode")
  → AgentEvent(type: .plan, content: planContent, metadata: ["planAction": "exit", "approved": ..., "steps": ...])

SDKMessage.toolResult(for ExitPlanMode)
  → 更新上一个 .plan 事件（或通过 toolContentMap 配对）

SDKMessage.toolUse(toolName="TodoWrite")
  → AgentEvent(type: .plan, content: "更新任务清单", metadata: ["planAction": "todoUpdate", "todos": ...])
```

**但注意：EventMapper.map() 是纯函数、无状态！** 不能跨事件追踪状态。因此有两种方案：

- **方案 A（推荐）**：将 EnterPlanMode/ExitPlanMode 的 `.toolUse` 直接映射为 `.plan` 类型事件，在 metadata 中携带从 input 解析出的数据。AgentBridge 的 `processToolContentMap` 已有 toolUse+toolResult 配对逻辑——Plan 事件的 toolResult 内容会通过 toolContentMap 被捕获，PlanView 可以同时显示 toolUse（计划内容）和 toolResult（执行结果）
- **方案 B**：保持 `.toolUse` 类型不变，仅通过 ToolCardView 渲染，在 ToolRenderable 中为 PlanTools 注册特化渲染器

**推荐方案 A**：独立 `.plan` 事件类型让 Timeline 和 Inspector 可以专门处理计划可视化，不与普通工具调用混在一起。这也是 `AgentEventType` 枚举可扩展性的体现。

**步骤解析策略：**

ExitPlanMode 的 `plan` 字段是自由文本（Markdown 格式的计划内容）。PlanView 需要从此文本中解析步骤列表。解析规则：

1. 尝试按编号列表解析（`1.`、`2.`、`3.` 或 `1)`、`2)`、`3)`）
2. 尝试按 Markdown 列表解析（`-` 或 `*` 开头的列表项）
3. 如果无法解析为结构化步骤，则整体显示为计划文本（降级为纯 Markdown 渲染）

**TodoWrite 工具**：input 包含 `action`（add/toggle/remove/list/clear）、`text`、`id`、`priority`。toolResult 包含操作结果文本。这些事件映射为 `.plan` 类型时，metadata 中携带 todo 操作信息。

**依赖关系可视化（FR36）：**

SDK 的 `Task` 类型有 `blockedBy` 和 `blocks` 字段表示依赖。但 PlanMode 工具不直接暴露结构化依赖数据——依赖关系嵌在计划文本中。因此 FR36 的实现方式是：

1. 从计划文本中尝试提取依赖线索（如"在步骤 X 完成后"、"依赖于"等关键词）——**这是 best-effort，不保证 100% 准确**
2. 如果无法提取依赖，则使用顺序依赖（步骤 N 依赖于步骤 N-1）作为默认可视化
3. TodoWrite 的 todo 列表天然有序，用缩进层级表示

### 关键技术注意事项

1. **`AgentEventType` 新增 case 后**，所有 exhaustive switch 必须处理：TimelineView.eventView(for:)、InspectorView.eventDetail(for:)、InspectorView.colorForEventType(_:)。**编译器会强制报错，不会遗漏**

2. **EventMapper 不修改 SDKMessage switch**——18 种 SDKMessage case 保持不变。Plan 映射是在 `.toolUse` case 内部通过 toolName 分支实现的：

```swift
case .toolUse(let data):
    if data.toolName == "EnterPlanMode" || data.toolName == "ExitPlanMode" || data.toolName == "TodoWrite" {
        return AgentEvent(type: .plan, content: ..., metadata: [...], timestamp: .now)
    }
    // 原有的 toolUse 映射
    return AgentEvent(type: .toolUse, ...)
```

3. **ToolContentMap 配对**：EnterPlanMode/ExitPlanMode 的 toolUse 事件如果被映射为 `.plan` 类型，则 `AgentBridge.processToolContentMap(for:)` 中 `event.type == .toolUse` 的检查不会匹配。**需要在 processToolContentMap 中也处理 `.plan` 类型事件**——或者让 Plan 事件不走 toolContentMap 配对（PlanView 直接从 event.content 和 metadata 获取数据）

4. **PlanView 行数控制**：计划步骤渲染 + 依赖关系可视化可能超过 300 行。预估 200-250 行。如果超出则将 `PlanStepRow` 拆分为独立文件（`PlanStepRowView.swift`）

5. **Inspector 中的 Plan 详情**：显示计划内容（Markdown 渲染）、步骤列表汇总（已完成/总数）、批准状态

6. **动画性能**：PlanStep 的状态变化使用简单动画（`withAnimation(.easeInOut(duration: 0.2))`），与 ToolCardView 的展开/折叠动画一致

### UI 设计参考

**PlanView 布局（在 Timeline 中）：**

```
┌──────────────────────────────────────┐
│ [>] 执行计划                    [▼]  │  ← 标题行 + 展开/折叠按钮
│                                      │
│  ① 分析代码结构             [completed] │  ← 步骤 1（已完成，绿色勾号）
│  ② 实现核心逻辑             [inProgress] │  ← 步骤 2（执行中，旋转指示器）
│    └── 依赖: 步骤 1                  │  ← 依赖关系（缩进显示）
│  ③ 编写测试                 [pending] │  ← 步骤 3（待执行，空心圆）
│    └── 依赖: 步骤 2                  │
│                                      │
│  进度: 1/3 完成                       │  ← 底部摘要
└──────────────────────────────────────┘
```

**折叠状态：**
```
┌──────────────────────────────────────┐
│ [>] 执行计划 (3 步骤, 1 完成)   [▶]  │
└──────────────────────────────────────┘
```

**PlanStepRow 状态图标：**
- `pending`: 空心圆圈（`circle` SF Symbol，灰色）
- `inProgress`: 旋转齿轮（复用 ThinkingView 动画模式，蓝色）
- `completed`: 实心勾号圆（`checkmark.circle.fill`，绿色）
- `failed`: 实心叉号圆（`xmark.circle.fill`，红色）

**依赖关系可视化：**
- 有依赖的步骤通过左侧缩进（16pt per level）表示
- 依赖步骤之间用竖线连接（类似 tree view）

### 数据流图

```
SDK Agent 执行:
  调用 EnterPlanMode toolUse → SDKMessage.toolUse
  调用 ExitPlanMode toolUse → SDKMessage.toolUse
  ExitPlanMode toolResult → SDKMessage.toolResult
  调用 TodoWrite toolUse → SDKMessage.toolUse
  TodoWrite toolResult → SDKMessage.toolResult

EventMapper:
  .toolUse(toolName="EnterPlanMode") → AgentEvent(type: .plan, metadata: ["planAction": "enter"])
  .toolUse(toolName="ExitPlanMode") → AgentEvent(type: .plan, metadata: ["planAction": "exit", "plan": ...])
  .toolUse(toolName="TodoWrite") → AgentEvent(type: .plan, metadata: ["planAction": "todoUpdate", ...])

AgentBridge:
  appendAndPersist(.plan event) → events 数组
  如果 .plan 事件有 toolUseId，processToolContentMap 仍可配对对应的 toolResult

TimelineView:
  eventView(for: .plan event) → PlanView(event:)

InspectorView:
  eventDetail(for: .plan event) → planEventSection(event:)
```

### 文件变更清单

**NEW（新建文件）：**
- `SwiftWork/Models/UI/PlanStep.swift` -- PlanStep、PlanStepStatus、PlanData 数据模型
- `SwiftWork/Views/Workspace/Timeline/EventViews/PlanView.swift` -- 计划可视化视图（如超 300 行则额外拆分 `PlanStepRowView.swift`）
- `SwiftWorkTests/Views/Timeline/PlanViewTests.swift` -- PlanView 和 PlanStep 相关测试

**UPDATE（更新文件）：**
- `SwiftWork/Models/UI/AgentEventType.swift` -- 新增 `plan` case
- `SwiftWork/SDKIntegration/EventMapper.swift` -- 在 `.toolUse` case 中添加 toolName 分支映射 Plan 工具
- `SwiftWork/SDKIntegration/AgentBridge.swift` -- 在 `processToolContentMap` 中处理 `.plan` 类型事件（如需要配对 toolResult）
- `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` -- 在 `eventView(for:)` 中添加 `.plan` case
- `SwiftWork/Views/Workspace/Inspector/InspectorView.swift` -- 在 `eventDetail(for:)` 和 `colorForEventType(_:)` 中添加 `.plan` case
- `SwiftWork/Views/Workspace/Inspector/EventDetailSections.swift` -- 添加 `planEventSection(event:)` 方法

**UNCHANGED（不修改——零回归风险）：**
- `SwiftWork/Models/UI/AgentEvent.swift` -- metadata 字典足够存储 PlanData
- `SwiftWork/Models/UI/ToolContent.swift` -- 不需要修改
- `SwiftWork/Views/Workspace/WorkspaceView.swift` -- 不涉及
- `SwiftWork/Views/Workspace/Inspector/InspectorView.swift` 的结构不变（仅添加 case）
- `SwiftWork/App/ContentView.swift` -- 不涉及
- `SwiftWork/Services/AppStateManager.swift` -- 不涉及
- 所有 Permission 组件不变
- 所有 Sidebar 组件不变

### 与前后 Story 的关系

- **Story 3-4（Inspector Panel）**：3-4 将 selectedEventId 提升为 @Binding，在 InspectorView 中添加了 exhaustive switch。本 Story 添加 `.plan` case 到 Inspector 的 switch 中，编译器会提示
- **Story 2-1（Tool 可视化基础架构）**：ToolRenderable 协议 + ToolRendererRegistry。本 Story 不使用 ToolRenderable（Plan 不是普通工具），而是直接在 TimelineView 中用 `.plan` case 渲染 PlanView
- **Story 2-2（Tool Card 完整体验）**：ToolCardView 的折叠/展开和状态标签模式。PlanView 参考相同的视觉风格
- **Story 4-1（Debug Panel）**：4-1 将在 Inspector 目录添加 DebugView。本 Story 仅在同目录的 EventDetailSections.swift 添加方法，不冲突

### 前序 Story 学习（Story 3-4）

- Story 3-4 模式：InspectorView 的 exhaustive switch 添加新 case 时，必须在 eventDetail(for:) 和 colorForEventType(_:) 中同时添加
- Story 3-4 模式：View 文件超过 300 行应拆分子 View。PlanView 预计 200-250 行（含步骤渲染和依赖可视化），如超出则拆分 PlanStepRowView
- Story 3-4 模式：使用 `@Binding` 提升状态。selectedEventId 已提升到 WorkspaceView
- Story 3-4 发现：EventDetailSections.swift 是从 InspectorView 拆出的扩展文件，新 section 方法添加到该文件

### Project Structure Notes

- `PlanStep.swift` 放在 `Models/UI/` 目录（与其他 UI 模型 AgentEvent、ToolContent、PermissionDecision 并列）
- `PlanView.swift` 放在 `Views/Workspace/Timeline/EventViews/` 目录（与 ResultView、ThinkingView 等事件视图并列）
- 测试文件 `PlanViewTests.swift` 放在 `SwiftWorkTests/Views/Timeline/` 目录
- 遵循 View 只依赖 Models/UI 的分层规则
- 不引入新的 SPM 依赖

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.5: 执行计划可视化]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 9: 组件架构 — ToolRenderable 协议]
- [Source: _bmad-output/planning-artifacts/architecture.md#项目结构 — EventViews/ 目录和 PlanView.swift]
- [Source: _bmad-output/project-context.md#Architecture Boundary Rules — Views 只依赖 ViewModel 和 Models/UI]
- [Source: _bmad-output/project-context.md#OpenWork 参照 — tool-call.tsx 展开/折叠模式]
- [Source: _bmad-output/implementation-artifacts/3-4-inspector-panel.md -- 前序 Story dev notes 和 learning]
- [Source: SwiftWork/Models/UI/AgentEventType.swift -- 当前 19 个事件类型枚举]
- [Source: SwiftWork/SDKIntegration/EventMapper.swift -- exhaustive switch 处理 18 种 SDKMessage]
- [Source: SwiftWork/SDKIntegration/AgentBridge.swift:processToolContentMap -- toolUse+toolResult 配对逻辑]
- [Source: SwiftWork/Views/Workspace/Timeline/TimelineView.swift:eventView(for:) -- 事件视图映射 switch]
- [Source: SwiftWork/Views/Workspace/Inspector/InspectorView.swift -- Inspector 事件详情 switch]
- [Source: SwiftWork/Views/Workspace/Inspector/EventDetailSections.swift -- 类型特化 section 模式]
- [Source: SwiftWork/Views/Workspace/Timeline/EventViews/ThinkingView.swift -- 旋转动画可复用]
- [Source: SwiftWork/Views/Workspace/Timeline/EventViews/ResultView.swift -- 卡片样式可参考]
- [Source: open-agent-sdk-swift/Sources/.../PlanTools.swift -- EnterPlanMode/ExitPlanMode SDK 工具定义]
- [Source: open-agent-sdk-swift/Sources/.../TodoWriteTool.swift -- TodoWrite SDK 工具定义]
- [Source: open-agent-sdk-swift/Sources/.../TaskTypes.swift -- PlanEntry、PlanStatus、TodoItem SDK 类型]

## Dev Agent Record

### Agent Model Used

GLM-5.1

### Debug Log References

- ATDD red-phase tests (PlanStepModelTests, PlanEventMapperTests, PlanViewTests) were pre-authored; implementation turned them green
- AgentEventTypeTests.testAgentEventTypeAllCases hardcoded count 19 updated to 20 after adding .plan case
- PlanViewTests Sendable conformance fix: `[Any]` changed to `[[String: any Sendable]]` and `[] as [Any]` to `[] as [String]` for Swift 6.1 strict concurrency

### Completion Notes List

- Task 1: Created PlanStep.swift with PlanStep (Identifiable+Sendable), PlanStepStatus (String+Sendable+Equatable with pending/inProgress/completed/failed), PlanData (Sendable)
- Task 2: Added .plan case to AgentEventType (20 cases total). Updated EventMapper with mapPlanToolUse helper that handles EnterPlanMode/ExitPlanMode/TodoWrite. Added parseExitPlanInput, parsePlanSteps (numbered list + markdown list regex), parseTodoInput, and extractPlanFromRawInput helpers. All 18 existing SDKMessage mappings unchanged.
- Task 3: Created PlanView.swift (~260 lines, under 300 line limit). Features: expand/collapse card with teal accent bar, step list with status icons (pending=empty circle, inProgress=rotating gear reusing ThinkingView pattern, completed=green checkmark, failed=red xmark), dependency indentation (16pt per level with connector line), progress bar, numbered/markdown list content parsing fallback. PlanStepRow extracted as sub-view with default allSteps parameter for backward-compatible test instantiation.
- Task 4: Added .plan case to TimelineView.eventView(for:) rendering PlanView(event:). Added .plan case to InspectorView.eventDetail(for:) and colorForEventType returning .teal. Added planEventSection(event:) to EventDetailSections.swift with plan action, plan ID, approved status, step summary/list, and input data sections.
- Task 5: All 46 Story 3-5 ATDD tests pass (16 PlanEventMapper + 15 PlanStepModel + 15 PlanView). Full regression suite: 661 tests, 0 failures.

### File List

**NEW:**
- SwiftWork/Models/UI/PlanStep.swift
- SwiftWork/Views/Workspace/Timeline/EventViews/PlanView.swift

**UPDATED:**
- SwiftWork/Models/UI/AgentEventType.swift (added .plan case)
- SwiftWork/SDKIntegration/EventMapper.swift (added mapPlanToolUse, parseExitPlanInput, parsePlanSteps, parseTodoInput, extractPlanFromRawInput)
- SwiftWork/Views/Workspace/Timeline/TimelineView.swift (added .plan case to eventView)
- SwiftWork/Views/Workspace/Inspector/InspectorView.swift (added .plan case to eventDetail and colorForEventType)
- SwiftWork/Views/Workspace/Inspector/EventDetailSections.swift (added planEventSection)
- SwiftWorkTests/Models/UI/AgentEventTypeTests.swift (updated count 19->20, added .plan to expected cases)
- SwiftWorkTests/Views/Timeline/PlanViewTests.swift (fixed Sendable conformance for Swift 6.1)
