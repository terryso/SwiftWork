# Story 3.4: Inspector Panel

Status: done

## Story

As a 用户,
I want 通过右侧面板查看选中事件的详细信息,
so that 我可以深入了解 Agent 每一步操作的完整数据。

## Acceptance Criteria

1. **Given** 用户点击 Timeline 中的任意事件 **When** 事件被选中 **Then** Inspector Panel 显示该事件的完整详情：JSON 格式的原始数据、执行耗时、Token 用量（FR37）

2. **Given** Inspector Panel 当前处于展开状态 **When** 用户点击 Inspector 切换按钮 **Then** Panel 折叠收起，Workspace 区域扩展到全宽（FR41）

3. **Given** Inspector Panel 当前处于折叠状态 **When** 用户点击切换按钮 **Then** Panel 展开，恢复之前的宽度

**覆盖的 FRs:** FR37, FR41
**覆盖的 ARCHs:** ARCH-8 (Observation 框架), ARCH-12 (分层边界)
**覆盖的 NFRs:** NFR21 (Inspector 展开状态持久化)

## Tasks / Subtasks

- [x] Task 1: InspectorView 完整实现——事件详情展示（AC: #1）
  - [x] 1.1 重写 `SwiftWork/Views/Workspace/Inspector/InspectorView.swift`：接收 `selectedEvent: AgentEvent?`、`toolContentMap: [String: ToolContent]` 参数
  - [x] 1.2 当 `selectedEvent == nil` 时显示空状态（"选择一个事件以查看详情" + 图标）
  - [x] 1.3 当 `selectedEvent != nil` 时显示事件详情区域：
    - 事件类型标签（带颜色区分）
    - 时间戳（格式化显示）
    - 内容摘要文本
    - 事件类型相关的特化区域：
      - `.toolUse` / `.toolResult` / `.toolProgress`: 从 `toolContentMap` 获取配对的 `ToolContent`，显示工具名、输入参数 JSON、输出结果、执行耗时、状态
      - `.result`: 显示状态（成功/失败）、耗时（`durationMs`）、Token 用量（`usage`）、费用（`totalCostUsd`、`costBreakdown`）、Turn 数
      - `.assistant`: 显示模型名称、stopReason
      - `.system`: 显示 subtype、sessionId
      - 其他类型：通用 metadata 展示
  - [x] 1.4 添加 JSON 原始数据区域：将 `event.metadata` 序列化为格式化 JSON 字符串，带 CopyButton（复用 `ToolCardView` 中的 `CopyButton`）
  - [x] 1.5 JSON 区域默认折叠，点击"原始数据"标题行展开/折叠
  - [x] 1.6 确保 InspectorView 不超过 300 行，如超出则拆分为子视图（如 `EventDetailView`、`ToolEventInspector.swift`）

- [x] Task 2: Inspector Panel 展开/折叠机制（AC: #2, #3）
  - [x] 2.1 修改 `ContentView.swift`：将 WorkspaceView 包裹在 `HSplitView` 或 `HStack` 中，右侧放置 InspectorView
  - [x] 2.2 添加 `@State private var inspectorWidth: CGFloat = 300` 和 `@State private var isInspectorVisible: Bool = false`（已存在）
  - [x] 2.3 使用 `HSplitView` 让用户可以拖拽调整 Inspector 宽度，或使用固定宽度 + 动画过渡
  - [x] 2.4 切换按钮放在 WorkspaceView 的 toolbar 区域（右上角），使用 Sidebar 描图标的 Inspector 图标（`sidebar.right`）
  - [x] 2.5 折叠时 `inspectorWidth = 0`，展开时 `inspectorWidth = 300`，带 `withAnimation(.easeInOut(duration: 0.25))` 过渡
  - [x] 2.6 Inspector 展开状态已通过 `AppStateManager.saveInspectorVisibility` 持久化到 `AppConfiguration`。ContentView 已有 `onChange(of: isInspectorVisible)` 保存状态，以及 `configureAndRestoreState()` 中 `isInspectorVisible = appStateManager.isInspectorVisible` 恢复。本 Task 不需要修改 AppStateManager

- [x] Task 3: 事件选中状态连线（AC: #1）
  - [x] 3.1 TimelineView 已有 `@State private var selectedEventId: UUID?` 和 ToolCardView 的 `isSelected` 绑定——需要将 selectedEventId 提升到共享层级
  - [x] 3.2 方案：在 `WorkspaceView.swift` 中添加 `@State private var selectedEventId: UUID?`，传递给 TimelineView（作为 Binding 或回调）和 InspectorView
  - [x] 3.3 TimelineView 的 `selectedEventId` 改为 `@Binding var selectedEventId: UUID?`，移除本地的 `@State`
  - [x] 3.4 所有事件视图（不仅是 ToolCardView）都支持选中：在 eventView 的外层添加 `.contentShape(Rectangle())` + `.onTapGesture { selectedEventId = event.id }`
  - [x] 3.5 选中事件视觉反馈：非工具类事件被选中时显示蓝色边框高亮（类似 ToolCardView 的 `isSelected` 行为）

- [x] Task 4: 单元测试（AC: #1-#3）
  - [x] 4.1 在 `SwiftWorkTests/Views/Workspace/Inspector/InspectorViewTests.swift` 中添加测试：
    - 测试 selectedEvent 为 nil 时显示空状态文本
    - 测试 selectedEvent 有值时显示事件类型标签和内容
    - 测试 toolUse 事件显示配对的 ToolContent 详情
    - 测试 result 事件显示 Token 用量和耗时
    - 测试 JSON 原始数据区域展开/折叠
  - [x] 4.2 所有新测试通过 `swift test`，现有测试无回归

## Dev Notes

### 核心目标

实现 Inspector Panel——右侧可展开/折叠的详情面板，显示 Timeline 中选中事件的完整数据。这是用户深入理解 Agent 每一步操作的关键窗口。

### 已有基础（必须在此基础上扩展，不重新创建）

1. **`InspectorView.swift`**（`Views/Workspace/Inspector/`）——当前是占位符（仅 `Text("Inspector")`），需要完全重写
2. **`ContentView.swift`**（`App/`）——已有 `@State private var isInspectorVisible: Bool = false`、`onChange(of: isInspectorVisible)` 保存到 AppStateManager、`configureAndRestoreState()` 恢复。**不需要修改** Inspector 可见性持久化逻辑
3. **`AppStateManager.swift`**（`Services/`）——已有 `isInspectorVisible` 属性、`saveInspectorVisibility(_:)`、`loadBool(key:)` 恢复逻辑、`inspectorVisibleKey = "appState.inspectorVisible"`。**不需要修改**
4. **`TimelineView.swift`**（`Views/Workspace/Timeline/`）——已有 `@State private var selectedEventId: UUID?`，ToolCardView 已绑定 `isSelected`。需要将 selectedEventId 提升为 `@Binding`
5. **`WorkspaceView.swift`**（`Views/Workspace/`）——当前是 VStack（Timeline + InputBar）。需要改为包含 Inspector 的三栏布局或改为让 ContentView 处理 Inspector
6. **`AgentEvent.swift`**（`Models/UI/`）——已有完整事件模型：id、type、content、metadata、timestamp。metadata 字典中包含 Inspector 需要展示的所有数据
7. **`AgentEventType.swift`**（`Models/UI/`）——18 种事件类型枚举
8. **`ToolContent.swift`**（`Models/UI/`）——工具配对数据结构：toolName、toolUseId、input、output、isError、status、elapsedTimeSeconds
9. **`CopyButton`**（`Views/Workspace/Timeline/EventViews/ToolCardView.swift`）——已实现复制按钮组件，InspectorView 可直接复用
10. **`ToolCardView`**——已有 `isSelected` 和 `onSelect` 回调机制

### 架构决策参考

**分层边界规则：**
- InspectorView 是 View 层，只依赖 Models/UI（AgentEvent、ToolContent）和 SwiftUI
- InspectorView 不直接引用 SDK 类型
- 事件选中状态由 WorkspaceView 或 ContentView 管理（State hoisting 模式）

**HSplitView vs NavigationSplitView：**
- ContentView 已使用 `NavigationSplitView`（Sidebar + Detail）
- Inspector Panel 应在 Detail 区域内部实现，不新增 NavigationSplitView 层级
- 推荐在 WorkspaceView 内部使用 `HStack` + 动画宽度控制，或使用 `GeometryReader` + 固定宽度 Inspector
- **不使用 HSplitView**——它在 NavigationSplitView 内部嵌套时有布局问题

**推荐布局方案：**
```
ContentView (NavigationSplitView)
├── Sidebar: SidebarView
└── Detail:
    └── WorkspaceView (HStack)
        ├── VStack (Timeline + InputBar)  [flexible width]
        └── InspectorView                [fixed/animated width]
```

### 关键技术注意事项

1. **ContentView 的 isInspectorVisible 已正确持久化**：`onChange(of: isInspectorVisible)` -> `appStateManager.saveInspectorVisibility(newValue)`。`configureAndRestoreState()` 中 `isInspectorVisible = appStateManager.isInspectorVisible`。本 Story 只需将 `isInspectorVisible` 传递给 WorkspaceView 使用，不需要额外持久化逻辑。

2. **WorkspaceView 需要同时接收 agentBridge 和 isInspectorVisible**：当前 WorkspaceView 只接收 `agentBridge`、`eventStore`、`session`、`settingsViewModel`、`sessionViewModel`。需要添加 `isInspectorVisible: Binding<Bool>` 参数（或通过 `@Environment` 传递）。

3. **事件选中状态提升**：TimelineView 的 `selectedEventId` 需要提升到 WorkspaceView 层级，这样 WorkspaceView 可以同时传递给 TimelineView（作为 Binding）和 InspectorView（作为只读值）。

4. **Inspector 的事件详情渲染**：使用 `@ViewBuilder` + switch on `event.type` 为不同事件类型渲染不同的详情布局。每个 case 可以抽取为私有子视图保持文件行数不超 300。

5. **metadata 到 Inspector 详情的映射**：
   - `.toolUse`: `metadata["toolName"]`、`metadata["toolUseId"]`、`metadata["input"]`
   - `.toolResult`: `metadata["toolUseId"]`、`metadata["isError"]`
   - `.result`: `metadata["durationMs"]`、`metadata["totalCostUsd"]`、`metadata["numTurns"]`、`metadata["usage"]`（可能是嵌套字典）
   - `.assistant`: `metadata["model"]`、`metadata["stopReason"]`
   - `.system`: `metadata["subtype"]`、`metadata["sessionId"]`
   - `.userMessage`: content 字段即消息文本

6. **ToolContent 配对数据**：AgentBridge 的 `toolContentMap: [String: ToolContent]` 是已配对的工具数据，Inspector 显示工具相关事件时应从 `toolContentMap` 获取完整信息（input、output、status、elapsedTime）。需要将 `toolContentMap` 传递给 InspectorView。

7. **动画性能**：Inspector 宽度变化使用 `withAnimation(.easeInOut(duration: 0.25))`。避免在 Inspector 内容中使用复杂动画。

### UI 设计参考

**Inspector Panel 布局（右侧面板）：**

```
┌──────────────────────────────────────────────────────────────────┐
│ Timeline Area                              │ Inspector Panel    │
│                                             │                   │
│  [事件1]                                    │ 📋 事件详情        │
│  [事件2] (选中，蓝色边框)                    │                   │
│  [事件3]                                    │ 类型: ToolUse     │
│                                             │ 工具: Bash        │
│                                             │ 时间: 14:32:05    │
│                                             │                   │
│                                             │ ─── 执行信息 ───  │
│                                             │ 状态: completed   │
│                                             │ 耗时: 3s          │
│                                             │                   │
│                                             │ ─── 参数 ───────  │
│                                             │ { "command":      │
│                                             │   "ls -la" }      │
│                                             │                   │
│                                             │ ─── 输出 ───────  │
│                                             │ total 48          │
│                                             │ drwxr-xr-x...     │
│                                             │                   │
│                                             │ ▶ 原始数据 [Copy] │
│                                             │                   │
├─────────────────────────────────────────────┤                   │
│ [InputBar]                                  │                   │
└─────────────────────────────────────────────┴───────────────────┘
                                                  [↗] 切换按钮
```

**空状态：**
```
┌──────────────────────┐
│                      │
│    🔍                │
│  选择一个事件        │
│  以查看详情          │
│                      │
└──────────────────────┘
```

**切换按钮位置（WorkspaceView 右上角）：**
```
┌──────────────────────────────────────┐
│ [Timeline...]           [sidebar.right] │  ← Inspector 切换按钮
│ ...                                    │
└──────────────────────────────────────┘
```

### 数据流图

```
ContentView
├── isInspectorVisible: @State (已持久化 via AppStateManager)
├── onChange(of: isInspectorVisible) → appStateManager.saveInspectorVisibility
│
└── WorkspaceView
    ├── selectedEventId: @State (新增，管理选中状态)
    ├── isInspectorVisible: Binding<Bool> (从 ContentView 传入)
    │
    ├── HStack
    │   ├── VStack (Timeline + InputBar)
    │   │   └── TimelineView
    │   │       └── selectedEventId: @Binding (从 WorkspaceView 传入)
    │   │           └── 事件点击 → selectedEventId = event.id
    │   │
    │   └── InspectorView (if isInspectorVisible)
    │       ├── selectedEvent: AgentEvent? (从 agentBridge.events 中查找)
    │       ├── toolContentMap: [String: ToolContent]
    │       └── 切换按钮 → isInspectorVisible.toggle()
    │
    └── InspectorView
        ├── 空状态 (selectedEvent == nil)
        └── 事件详情 (selectedEvent != nil)
            ├── 基础信息（类型、时间戳、内容）
            ├── 类型特化区域
            │   ├── ToolEventInspector (toolUse/toolResult/toolProgress)
            │   ├── ResultEventInspector (.result)
            │   └── 通用 Metadata 展示
            └── JSON 原始数据 (折叠/展开 + CopyButton)
```

### 文件变更清单

**UPDATE（更新文件）：**
- `SwiftWork/Views/Workspace/Inspector/InspectorView.swift` -- 重写为完整的事件详情面板（当前是占位符）
- `SwiftWork/Views/Workspace/WorkspaceView.swift` -- 添加 selectedEventId 状态、HStack 布局包含 InspectorView、Inspector 切换按钮
- `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` -- selectedEventId 从 @State 改为 @Binding，所有事件视图添加点击选中支持
- `SwiftWork/App/ContentView.swift` -- 将 isInspectorVisible 传递给 WorkspaceView

**NEW（新建文件，仅当 InspectorView 超过 300 行时）：**
- `SwiftWork/Views/Workspace/Inspector/ToolEventInspector.swift` -- 工具事件特化详情视图（如拆分需要）

**UNCHANGED（不修改——零回归风险）：**
- `SwiftWork/Services/AppStateManager.swift` -- Inspector 可见性持久化已完整实现
- `SwiftWork/Models/UI/AgentEvent.swift` -- 事件模型不变
- `SwiftWork/Models/UI/AgentEventType.swift` -- 事件类型枚举不变
- `SwiftWork/Models/UI/ToolContent.swift` -- 工具内容模型不变
- `SwiftWork/SDKIntegration/AgentBridge.swift` -- 不需要修改
- `SwiftWork/ViewModels/SessionViewModel.swift` -- 不涉及
- `SwiftWork/Views/Sidebar/SidebarView.swift` -- 不涉及
- 所有 Permission 组件不变

### 与前后 Story 的关系

- **Story 3-3（会话管理增强）**：3-3 修改了 SidebarView（右键菜单）和 InputBarView（IME 安全输入）。本 Story 修改 WorkspaceView 和 TimelineView，不冲突。
- **Story 3-5（执行计划可视化）**：3-5 将在 TimelineView 中添加 PlanView 渲染。本 Story 修改 TimelineView 的 selectedEventId 为 @Binding，3-5 需要适配此变更。
- **Story 1-6（应用状态恢复）**：Inspector 可见性持久化已在 1-6 中实现。本 Story 直接使用已有机制。
- **Story 2-2（Tool Card 完整体验）**：ToolCardView 已有 `isSelected` 和 `onSelect` 回调机制，本 Story 将选中状态提升到更高层级。
- **Story 4-1（Debug Panel）**：4-1 将在 Inspector 目录下添加 DebugView.swift。本 Story 实现 InspectorView 后，4-1 在同目录添加文件，不冲突。

### 前序 Story 学习（Story 3-3）

- Story 3-3 模式：View 文件超过 300 行应拆分子 View。InspectorView 预计 200-250 行（含 switch 分支），如果超出则将工具事件详情和 result 事件详情拆分为独立文件
- Story 3-3 模式：使用 `@Binding` 提升状态到父级（SessionRowView 的 renaming 状态从 SidebarView 管理）。本 Story 的 selectedEventId 遵循相同模式
- Story 3-3 发现：IMESafeTextView 包装 NSTextView 解决了输入法兼容问题。本 Story 不涉及文本输入，无需考虑

### Project Structure Notes

- `InspectorView.swift` 保持在 `Views/Workspace/Inspector/` 目录
- 如果需要拆分子视图，新建文件放在同目录（如 `ToolEventInspector.swift`）
- 测试文件：`SwiftWorkTests/Views/Workspace/Inspector/InspectorViewTests.swift`（新建）
- 遵循 View 只依赖 Models/UI 的分层规则
- 不引入新的 SPM 依赖

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.4: Inspector Panel]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 9: 组件架构 — Inspectable 协议]
- [Source: _bmad-output/planning-artifacts/architecture.md#项目结构 — Inspector/ 目录]
- [Source: _bmad-output/project-context.md#Architecture Boundary Rules — Views 只依赖 ViewModel 和 Models/UI]
- [Source: _bmad-output/project-context.md#OpenWork 参照 — debug-panel.tsx]
- [Source: _bmad-output/implementation-artifacts/3-3-session-management-enhanced.md -- 前序 Story dev notes 和 learning]
- [Source: SwiftWork/Views/Workspace/Inspector/InspectorView.swift -- 当前占位符实现]
- [Source: SwiftWork/App/ContentView.swift:13 -- isInspectorVisible 状态]
- [Source: SwiftWork/App/ContentView.swift:89-91 -- Inspector 可见性持久化]
- [Source: SwiftWork/Services/AppStateManager.swift -- saveInspectorVisibility 和 loadBool]
- [Source: SwiftWork/Views/Workspace/Timeline/TimelineView.swift:7 -- selectedEventId 当前是 @State]
- [Source: SwiftWork/Views/Workspace/Timeline/EventViews/ToolCardView.swift:8-9 -- isSelected/onSelect 机制]
- [Source: SwiftWork/Views/Workspace/Timeline/EventViews/ToolCardView.swift:228-252 -- CopyButton 组件可复用]
- [Source: SwiftWork/Models/UI/AgentEvent.swift -- metadata 字典包含 Inspector 所需数据]
- [Source: SwiftWork/Models/UI/ToolContent.swift -- 工具配对数据结构]
- [Source: SwiftWork/SDKIntegration/AgentBridge.swift:14 -- toolContentMap 访问方式]

## Dev Agent Record

### Agent Model Used

GLM-5.1

### Debug Log References

### Completion Notes List

- Implemented InspectorView with full event detail rendering: type-specific sections for tool events, result events, assistant events, system events, and generic metadata fallback
- Added JSON raw data section with expand/collapse toggle and CopyButton reuse
- InspectorView is 284 lines (under 300 line limit) — no sub-view splitting needed
- Hoisted selectedEventId from TimelineView @State to WorkspaceView @State, passed as @Binding to TimelineView
- Added selection highlight (blue border overlay) to ALL event views in Timeline, not just ToolCardView
- Added isInspectorVisible @Binding to WorkspaceView, wired from ContentView
- Inspector toggle button in WorkspaceView toolbar using sidebar.right icon with accent color highlight when active
- Inspector panel uses HStack layout with 300pt fixed width and animated transition (0.25s easeInOut)
- All 26 ATDD tests pass, full suite of 615 tests passes with 0 regressions
- Updated existing test files (ToolRendererRegistryTests, ToolCardTimelineIntegrationTests, TimelineViewRefactoredTests, MessageInputAgentExecutionIntegrationTests) to pass required new parameters

### File List

**UPDATE:**
- `SwiftWork/Views/Workspace/Inspector/InspectorView.swift` -- Rewrote from placeholder to full event detail panel with type-specific sections, JSON raw data, and empty state
- `SwiftWork/Views/Workspace/WorkspaceView.swift` -- Added selectedEventId @State, isInspectorVisible @Binding, HStack layout with InspectorView, toolbar toggle button
- `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` -- Changed selectedEventId from @State to @Binding, added tap gesture and selection highlight to all event views
- `SwiftWork/App/ContentView.swift` -- Passed isInspectorVisible binding to WorkspaceView
- `SwiftWorkTests/App/MessageInputAgentExecutionIntegrationTests.swift` -- Added isInspectorVisible and selectedEventId parameters to WorkspaceView/TimelineView calls
- `SwiftWorkTests/SDKIntegration/ToolRendererRegistryTests.swift` -- Added selectedEventId binding to TimelineView calls
- `SwiftWorkTests/Views/Timeline/ToolCardTimelineIntegrationTests.swift` -- Added selectedEventId binding to TimelineView calls
- `SwiftWorkTests/Views/Timeline/TimelineViewRefactoredTests.swift` -- Added selectedEventId binding to TimelineView calls

**UNCHANGED (as designed):**
- `SwiftWork/Services/AppStateManager.swift`
- `SwiftWork/Models/UI/AgentEvent.swift`
- `SwiftWork/Models/UI/AgentEventType.swift`
- `SwiftWork/Models/UI/ToolContent.swift`
- `SwiftWork/SDKIntegration/AgentBridge.swift`

### Review Findings

- [x] [Review][Patch] Double selection border on ToolCardView events [SwiftWork/Views/Workspace/Timeline/TimelineView.swift:50-53] -- Fixed: added hasOwnSelectionBorder() helper to skip the ForEach overlay for ToolCardView events that already render their own selection border.
- [x] [Review][Patch] InspectorView exceeds 300-line limit [SwiftWork/Views/Workspace/Inspector/InspectorView.swift] -- Fixed: extracted type-specific event sections (tool, result, assistant, system, generic) into EventDetailSections.swift extension. InspectorView now 196 lines.
- [x] [Review][Patch] rawJSONString called twice per render cycle [SwiftWork/Views/Workspace/Inspector/InspectorView.swift:290+296] -- Fixed: computed once into a local let binding within rawDataSection.
- [x] [Review][Patch] isRawDataExpanded state persists across event selection changes [SwiftWork/Views/Workspace/Inspector/InspectorView.swift:8] -- Fixed: added .onChange(of: selectedEvent?.id) to reset isRawDataExpanded on event change.
- [x] [Review][Defer] CopyButton is defined in ToolCardView.swift, not its own file [SwiftWork/Views/Workspace/Timeline/EventViews/ToolCardView.swift:228] -- deferred, pre-existing

## Change Log

- 2026-05-03: Story 3-4 implementation complete. Inspector Panel with event details, expand/collapse, and selection wiring. All 26 ATDD tests pass, 615 total tests pass with 0 regressions.
