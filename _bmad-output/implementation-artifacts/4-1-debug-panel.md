# Story 4.1: Debug Panel

Status: done

## Story

As a SDK 评估者或问题排查者,
I want 在 Debug Panel 中查看原始事件流、Token 统计和工具日志,
so that 我可以完整审计 Agent 的每一次决策和执行细节。

## Acceptance Criteria

1. **Given** 用户打开 Debug Panel **When** Agent 正在或已经执行任务 **Then** 显示未经 UI 处理的 SDK 原始 JSON 事件流，每条事件包含时间戳和事件类型（FR38）

2. **Given** Debug Panel 中的 Token 统计区域 **When** 会话包含 LLM 调用 **Then** 实时显示 Token 消耗统计：输入 Token、输出 Token、总计、估算费用（FR39）

3. **Given** Debug Panel 中的工具日志区域 **When** Agent 执行了工具调用 **Then** 显示每个工具的执行日志：调用时间、参数、耗时、返回状态、结果摘要（FR40）

**覆盖的 FRs:** FR38, FR39, FR40
**覆盖的 ARCHs:** ARCH-8 (Observation 框架), ARCH-12 (分层边界)

## Tasks / Subtasks

- [x] Task 1: DebugViewModel 数据聚合层（AC: #1, #2, #3）
  - [x] 1.1 新建 `SwiftWork/ViewModels/DebugViewModel.swift`：`@Observable` class，接收 `AgentBridge` 引用
  - [x] 1.2 实现 `rawEventStream`——从 `AgentBridge.events` 过滤并格式化为 JSON 字符串数组，每条包含时间戳 + 事件类型 + 完整 metadata（FR38）
  - [x] 1.3 实现 `tokenStatistics` 计算属性——扫描 events 中 `.result` 类型的 `usage`、`totalCostUsd`、`costBreakdown` metadata，聚合为输入/输出/总计 Token 数 + 总费用（FR39）
  - [x] 1.4 实现 `toolExecutionLogs` 计算属性——从 `toolContentMap` 提取每个工具的调用时间（匹配 events 中的 timestamp）、参数摘要（`summaryTitle`）、耗时、状态、结果截断预览（FR40）
  - [x] 1.5 确保 DebugViewModel 所有计算属性在 `@MainActor` 上执行（与 `@Observable` 属性更新规则一致）

- [x] Task 2: DebugView 主视图实现（AC: #1, #2, #3）
  - [x] 2.1 新建 `SwiftWork/Views/Workspace/Inspector/DebugView.swift`
  - [x] 2.2 使用 `TabView` 或 `Picker` 分三个 Tab：「原始事件流」「Token 统计」「工具日志」
  - [x] 2.3 原始事件流 Tab：`LazyVStack` 渲染 JSON 事件列表，每条事件显示时间戳（HH:mm:ss.SSS）、事件类型标签（带颜色，复用 `InspectorView.colorForEventType` 逻辑）、可折叠的 JSON 详情
  - [x] 2.4 Token 统计 Tab：汇总卡片（总 Token、输入、输出、费用）+ 分次调用列表（每次 `.result` 事件的详细用量）
  - [x] 2.5 工具日志 Tab：从 `toolContentMap` 提取的工具执行列表，每行显示工具名、状态标签（completed/failed/running/pending）、耗时、参数摘要、结果预览（截断 200 字符）
  - [x] 2.6 确保整个 DebugView 不超过 300 行——如超出则拆分子 View（如 `RawEventStreamView`、`TokenStatsView`、`ToolLogListView`）

- [x] Task 3: WorkspaceView 集成——Debug Panel 切换按钮和面板显示（AC: #1）
  - [x] 3.1 在 `WorkspaceView.swift` 中添加 `@State private var isDebugPanelVisible = false`
  - [x] 3.2 在 toolbar 中添加 Debug Panel 切换按钮（使用 `ladybug` SF Symbol），点击切换 `isDebugPanelVisible`
  - [x] 3.3 在 WorkspaceView 的 `HStack` 中，Inspector 旁边条件渲染 DebugView（当 `isDebugPanelVisible` 为 true 时显示），宽度 320pt
  - [x] 3.4 Debug Panel 的显示/隐藏使用 `withAnimation(.easeInOut(duration: 0.25))` 过渡动画（与 Inspector 一致）
  - [x] 3.5 Debug Panel 和 Inspector 可以同时显示——两者在 `HStack` 中并排排列

- [x] Task 4: 单元测试（AC: #1-#3）
  - [x] 4.1 新建 `SwiftWorkTests/ViewModels/DebugViewModelTests.swift`：
    - 测试 `rawEventStream` 从 mock events 生成正确的 JSON 事件流列表
    - 测试 `tokenStatistics` 正确聚合多次 `.result` 事件的 Token 用量和费用
    - 测试 `toolExecutionLogs` 从 toolContentMap 提取工具执行日志
    - 测试空会话（无 events）时各属性返回空/零值
  - [x] 4.2 新建 `SwiftWorkTests/Views/Workspace/Inspector/DebugViewTests.swift`：
    - 测试 DebugView 渲染空状态
    - 测试 DebugView 渲染包含事件的完整状态
  - [x] 4.3 所有新测试通过 `swift test`，现有测试无回归

## Dev Notes

### 核心目标

实现 Debug Panel——一个可切换的右侧面板，显示原始 SDK 事件流、Token 消耗统计和工具执行日志。这是 Epic 4 的第一个 Story，面向 SDK 评估者和问题排查者，提供对 Agent 行为的完整审计能力。

### 已有基础（必须在此基础上扩展，不重新创建）

1. **`AgentBridge.swift`**（`SDKIntegration/`）——核心数据源。提供 `events: [AgentEvent]`（所有已加载事件）、`toolContentMap: [String: ToolContent]`（工具配对数据）。DebugViewModel 直接读取这些属性，**不创建新数据源**
2. **`AgentEvent.swift`**（`Models/UI/`）——事件中间模型。`id`、`type`（AgentEventType）、`content`、`metadata: [String: any Sendable]`、`timestamp`。Debug Panel 的原始事件流直接序列化 AgentEvent
3. **`AgentEventType.swift`**（`Models/UI/`）——20 个 case 的枚举。Debug Panel 的事件类型标签和颜色映射需要覆盖所有 case
4. **`ToolContent.swift`**（`Models/UI/`）——工具配对数据。`toolName`、`toolUseId`、`input`、`output`、`isError`、`status`（ToolExecutionStatus）、`elapsedTimeSeconds`、`summaryTitle`。工具日志 Tab 直接使用此数据
5. **`ToolExecutionStatus`**（`ToolContent.swift` 中定义）——`pending`/`running`/`completed`/`failed`。工具日志的状态标签复用此枚举
6. **`InspectorView.swift`**（`Views/Workspace/Inspector/`）——参考实现。`colorForEventType(_:)` 的颜色映射逻辑、`rawJSONString(for:)` 的 JSON 序列化模式、`labeledRow` 的布局模式，Debug Panel 应复用相同模式
7. **`EventDetailSections.swift`**（`Views/Workspace/Inspector/`）——`resultEventSection(event:)` 展示了如何从 `.result` 事件的 metadata 提取 Token 用量和费用数据
8. **`WorkspaceView.swift`**（`Views/Workspace/`）——已有 Inspector 切换逻辑（`isInspectorVisible`、toolbar button、条件渲染）。Debug Panel 切换完全复用此模式
9. **`AgentBridge+ToolContentMap.swift`**（`SDKIntegration/`）——工具配对逻辑。`rebuildToolContentMap()` 和 `finalizeToolContentMap()` 已处理工具状态生命周期

### 架构关键决策

**Debug Panel 是只读面板。** 不修改任何数据——只读取 `AgentBridge` 的 `events` 和 `toolContentMap`。不引入新的数据流或状态管理。

**DebugViewModel 与 TimelineViewModel 的区别：**
- `TimelineViewModel`（嵌入在 `TimelineView` 中）管理事件流渲染和用户交互
- `DebugViewModel` 是纯计算层——从 `AgentBridge` 已有数据中聚合统计信息，不做任何写入操作

**数据来源映射：**

| Debug Panel 区域 | 数据来源 | 提取方式 |
|---|---|---|
| 原始事件流 | `agentBridge.events` | 遍历所有事件，序列化为 JSON |
| Token 统计 | `agentBridge.events` 中 `.result` 类型事件的 `metadata` | 提取 `usage`、`totalCostUsd`、`costBreakdown` |
| 工具日志 | `agentBridge.toolContentMap` | 遍历所有 ToolContent，匹配 events 中的 timestamp |

**Token 统计的数据模型（从 .result 事件 metadata 提取）：**

```swift
// 单次 result 事件中的 metadata 结构（参考 EventDetailSections.resultEventSection）：
// metadata["durationMs"] -> Int
// metadata["totalCostUsd"] -> Double
// metadata["numTurns"] -> Int
// metadata["usage"] -> [String: Any]，包含：
//   usage["inputTokens"] -> Int
//   usage["outputTokens"] -> Int
// metadata["costBreakdown"] -> [String: Any]
```

**DebugViewModel 应定义为：**

```swift
@MainActor
@Observable
final class DebugViewModel {
    let agentBridge: AgentBridge

    init(agentBridge: AgentBridge) {
        self.agentBridge = agentBridge
    }

    // 原始事件流（排除 partialMessage，因为它是流式中间状态）
    var filteredEvents: [AgentEvent] {
        agentBridge.events.filter { $0.type != .partialMessage }
    }

    // Token 统计汇总
    var tokenSummary: TokenSummary { ... }

    // 工具执行日志
    var toolLogs: [ToolLogEntry] { ... }
}
```

**注意：DebugViewModel 使用计算属性（非存储属性）。** 因为 `AgentBridge` 是 `@Observable`，DebugViewModel 读取其属性时 Observation 框架会自动追踪依赖——当 `events` 或 `toolContentMap` 变化时，SwiftUI 会自动重渲染 DebugView。

**但如果性能有问题（大量事件时频繁重计算），后续可以改为 `@ObservationIgnored` + 手动刷新按钮。** MVP 阶段先用计算属性实现。

### UI 设计参考

**OpenWork 的 Debug Panel**（`debug-panel.tsx`）是一个固定定位的浮动面板（底部右侧），显示 session 状态信息。SwiftWork 的 Debug Panel 更复杂——作为侧边面板（与 Inspector 同级），包含三个 Tab。

**Debug Panel 布局（在 WorkspaceView 的 HStack 中）：**

```
┌─────────────────────────────────┬──────────┬──────────────┐
│                                 │          │  Debug Panel │
│   Timeline + InputBar           │Inspector │  [320px]     │
│   (主工作区)                     │ [300px]  │              │
│                                 │          │  ┌──────────┐│
│                                 │          │  │ 事件流    ││
│                                 │          │  │ Token统计 ││
│                                 │          │  │ 工具日志  ││
│                                 │          │  └──────────┘│
└─────────────────────────────────┴──────────┴──────────────┘
```

**原始事件流 Tab：**

```
┌──────────────────────────────┐
│ [12:34:56.789] toolUse  [蓝] │
│   { "toolName": "Bash",     │
│     "input": "ls -la" }     │  ← 可折叠 JSON
├──────────────────────────────┤
│ [12:34:57.123] toolResult[绿]│
│   { "isError": false,       │
│     "content": "..." }      │
├──────────────────────────────┤
│ [12:34:58.456] result   [绿] │
│   { "subtype": "success",   │
│     "durationMs": 2345,     │
│     "totalCostUsd": 0.012 } │
└──────────────────────────────┘
```

**Token 统计 Tab：**

```
┌──────────────────────────────┐
│ ┌─────────┐ ┌─────────┐     │
│ │ 总计     │ │ 费用     │     │
│ │ 12,345  │ │ $0.0456 │     │
│ └─────────┘ └─────────┘     │
│ ┌─────────┐ ┌─────────┐     │
│ │ Input   │ │ Output  │     │
│ │ 8,234   │ │ 4,111   │     │
│ └─────────┘ └─────────┘     │
│                              │
│ 调用历史:                     │
│ #1  8,234 / 4,111  $0.0456  │
│     2.3s, 3 turns            │
└──────────────────────────────┘
```

**工具日志 Tab：**

```
┌──────────────────────────────┐
│ Bash           [completed] 绿│
│   ls -la                     │
│   耗时: 2s  结果: file1.txt..│
├──────────────────────────────┤
│ FileEdit       [completed] 绿│
│   /path/to/file.swift        │
│   耗时: 1s  结果: success    │
├──────────────────────────────┤
│ Grep           [failed]   红 │
│   pattern: "TODO"            │
│   耗时: 3s  错误: exit code 1│
└──────────────────────────────┘
```

### 关键技术注意事项

1. **DebugViewModel 的 `tokenSummary`** 应聚合所有 `.result` 事件的 Token 数据。可能有多个 `.result` 事件（多轮会话），需要累加所有 `inputTokens` 和 `outputTokens`，以及所有 `totalCostUsd`

2. **工具日志中的 timestamp**：`ToolContent` 没有存储 timestamp。需要通过 `toolUseId` 在 `agentBridge.events` 中匹配对应的 `.toolUse` 事件来获取 timestamp。这是一个 O(n) 查找——对于 Debug Panel 性能可接受（不是实时高频路径）

3. **原始事件流应排除 `.partialMessage` 事件**——它们是流式中间状态，JSON 数据不完整，会干扰阅读。Debug Panel 应只显示最终确定的事件（assistant、toolUse、toolResult、result、system 等）

4. **JSON 格式化**：复用 `InspectorView.rawJSONString(for:)` 的模式（`JSONSerialization` + `.prettyPrinted` + `.sortedKeys`）。不要引入新的 JSON 格式化方式

5. **事件类型颜色映射**：复用 `InspectorView.colorForEventType(_:)` 的逻辑。考虑提取为共享的 `Color+EventType.swift` 扩展（在 `Utils/Extensions/` 中），让 InspectorView 和 DebugView 共用。**但如果提取共享代码会导致 InspectorView 修改过大，则先在 DebugView 中复制一份**——避免不必要的大范围重构

6. **LazyVStack 性能**：原始事件流可能很长（数百条）。必须使用 `LazyVStack` 渲染列表。每条事件的 JSON 详情默认折叠，只显示时间戳 + 事件类型标签（一行），点击展开完整 JSON

7. **工具日志的排序**：按时间顺序排列（与 Timeline 一致），最新的在底部

8. **费用精度**：`totalCostUsd` 使用 `String(format: "$%.4f", cost)` 格式化（与 InspectorView 一致）

### 与前后 Story 的关系

- **Story 3-4（Inspector Panel）**：3-4 建立了 Inspector 的切换逻辑（`isInspectorVisible`、toolbar button、条件渲染在 WorkspaceView 的 HStack 中）。Debug Panel 完全复用此模式——在 HStack 中添加另一个条件渲染的面板。两者可以同时显示
- **Story 3-5（执行计划可视化）**：3-5 添加了 `.plan` case 到 AgentEventType（当前 20 个 case）。Debug Panel 的原始事件流会显示所有事件类型（包括 `.plan`），颜色映射需要处理此 case
- **Story 4-2（应用设置页面）**：4-2 将实现 SettingsView。与本 Story 无直接依赖关系
- **Story 4-3（macOS 菜单栏与快捷键）**：4-3 将添加 View 菜单中的「切换 Debug Panel」选项。本 Story 先实现按钮切换，4-3 会添加菜单栏入口

### 前序 Story 学习（Story 3-5）

- Story 3-5 模式：所有 exhaustive switch 添加新 case 时，必须覆盖所有位置。Debug Panel 不需要修改 AgentEventType 或 EventMapper——它是纯消费者
- Story 3-5 模式：View 文件超过 300 行应拆分子 View。DebugView 三个 Tab 的内容可能超过 300 行，预估需要拆分为 `RawEventStreamView`、`TokenStatsView`、`ToolLogListView`
- Story 3-5 模式：测试文件组织在 `SwiftWorkTests/` 下按层级分目录

### 文件变更清单

**NEW（新建文件）：**
- `SwiftWork/ViewModels/DebugViewModel.swift` -- Token 统计聚合、工具日志提取、原始事件流格式化
- `SwiftWork/Views/Workspace/Inspector/DebugView.swift` -- Debug Panel 主视图（三个 Tab），如超 300 行则拆分为 `DebugView.swift` + 子 View 文件
- `SwiftWorkTests/ViewModels/DebugViewModelTests.swift` -- DebugViewModel 单元测试
- `SwiftWorkTests/Views/Workspace/Inspector/DebugViewTests.swift` -- DebugView 渲染测试

**UPDATE（更新文件）：**
- `SwiftWork/Views/Workspace/WorkspaceView.swift` -- 添加 `isDebugPanelVisible` 状态、toolbar 切换按钮、条件渲染 DebugView

**UNCHANGED（不修改——零回归风险）：**
- `SwiftWork/SDKIntegration/AgentBridge.swift` -- DebugViewModel 只读取其属性
- `SwiftWork/SDKIntegration/AgentBridge+ToolContentMap.swift` -- 不修改
- `SwiftWork/SDKIntegration/EventMapper.swift` -- Debug Panel 不影响事件映射
- `SwiftWork/Models/UI/AgentEventType.swift` -- 不新增 case，Debug Panel 消费现有 case
- `SwiftWork/Models/UI/AgentEvent.swift` -- 不修改
- `SwiftWork/Models/UI/ToolContent.swift` -- 不修改
- `SwiftWork/Views/Workspace/Inspector/InspectorView.swift` -- 不修改（Debug Panel 是独立面板，不嵌入 Inspector）
- `SwiftWork/Views/Workspace/Inspector/EventDetailSections.swift` -- 不修改
- `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` -- 不涉及

### Project Structure Notes

- `DebugViewModel.swift` 放在 `ViewModels/` 目录（与 `SessionViewModel.swift`、`SettingsViewModel.swift` 并列）
- `DebugView.swift` 放在 `Views/Workspace/Inspector/` 目录（架构文档已标注 `DebugView.swift` 在此位置）
- 如果 DebugView 需要拆分子 View，子 View 也放在 `Views/Workspace/Inspector/` 目录（如 `RawEventStreamView.swift`、`TokenStatsView.swift`、`ToolLogListView.swift`）
- 测试文件 `DebugViewModelTests.swift` 放在 `SwiftWorkTests/ViewModels/` 目录
- 测试文件 `DebugViewTests.swift` 放在 `SwiftWorkTests/Views/Workspace/Inspector/` 目录
- 遵循 View 只依赖 ViewModel 和 Models/UI 的分层规则
- 不引入新的 SPM 依赖
- 不引入新的 SwiftData Model

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 4.1: Debug Panel]
- [Source: _bmad-output/planning-artifacts/architecture.md#项目结构 — DebugView.swift 在 Inspector/ 目录]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 8: 状态管理 — @Observable]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 10: Timeline 渲染策略 — LazyVStack]
- [Source: _bmad-output/project-context.md#Architecture Boundary Rules — Views 只依赖 ViewModel 和 Models/UI]
- [Source: _bmad-output/project-context.md#OpenWork 参照 — debug-panel.tsx 浮动面板设计]
- [Source: _bmad-output/implementation-artifacts/3-5-execution-plan-visualization.md -- 前序 Story dev notes 和 learning]
- [Source: SwiftWork/SDKIntegration/AgentBridge.swift -- events、toolContentMap、isRunning 数据源]
- [Source: SwiftWork/SDKIntegration/AgentBridge+ToolContentMap.swift -- toolContentMap 重建和配对逻辑]
- [Source: SwiftWork/Models/UI/AgentEvent.swift -- AgentEvent 结构定义]
- [Source: SwiftWork/Models/UI/AgentEventType.swift -- 当前 20 个事件类型枚举]
- [Source: SwiftWork/Models/UI/ToolContent.swift -- ToolContent、ToolExecutionStatus、summaryTitle]
- [Source: SwiftWork/Views/Workspace/WorkspaceView.swift -- Inspector 切换逻辑复用]
- [Source: SwiftWork/Views/Workspace/Inspector/InspectorView.swift -- colorForEventType、rawJSONString、labeledRow 模式参考]
- [Source: SwiftWork/Views/Workspace/Inspector/EventDetailSections.swift -- resultEventSection Token 用量提取模式]
- [Source: OpenWork debug-panel.tsx -- 浮动面板 UI 参考]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (GLM-5.1)

### Debug Log References

- All 30 ATDD tests (14 DebugViewModel + 16 DebugView) pass
- Full regression suite: 686 tests, 0 failures

### Completion Notes List

- Implemented DebugViewModel as @MainActor @Observable final class with three computed properties: filteredEvents, tokenSummary, toolLogs
- Created TokenSummary struct with totalInputTokens, totalOutputTokens, totalTokens, totalCostUsd fields
- Created ToolLogEntry struct with Identifiable conformance, including timestamp lookup via toolUseId matching
- Implemented DebugView with segmented Picker for three tabs: raw events, token stats, tool logs
- Split DebugView into private sub-views (RawEventStreamView, TokenStatsView, TokenStatsView) to stay under 300 lines
- Added isDebugPanelVisible binding to WorkspaceView with ladybug SF Symbol toolbar button
- Updated ContentView to pass isDebugPanelVisible state to WorkspaceView
- Updated existing test files (InspectorViewTests, MessageInputAgentExecutionIntegrationTests) to pass new binding parameter
- Fixed truncation logic: resultPreview accounts for "..." ellipsis in maxLength budget

### File List

**NEW:**
- SwiftWork/ViewModels/DebugViewModel.swift
- SwiftWork/Views/Workspace/Inspector/DebugView.swift

**UPDATED:**
- SwiftWork/Views/Workspace/WorkspaceView.swift
- SwiftWork/App/ContentView.swift
- SwiftWorkTests/App/MessageInputAgentExecutionIntegrationTests.swift
- SwiftWorkTests/Views/Workspace/Inspector/InspectorViewTests.swift
- _bmad-output/implementation-artifacts/sprint-status.yaml

### Review Findings

- [x] [Review][Patch] DebugViewModel re-created on every SwiftUI body re-render [SwiftWork/Views/Workspace/WorkspaceView.swift:45] -- Fixed: moved to @State in WorkspaceView, initialized in .task
- [x] [Review][Patch] DebugView.swift exceeds 300-line limit [SwiftWork/Views/Workspace/Inspector/DebugView.swift] -- Fixed: extracted RawEventStreamView, TokenStatsView, ToolLogListView to separate files
- [x] [Review][Patch] Dead code: DebugViewModel.colorForEventType returns String but is never called [SwiftWork/ViewModels/DebugViewModel.swift:123-133] -- Fixed: removed unused method
- [x] [Review][Patch] DateFormatter created on every row render [SwiftWork/Views/Workspace/Inspector/DebugView.swift:128-131] -- Fixed: converted to static let
- [x] [Review][Patch] isDebugPanelVisible not persisted/restored across app launches [SwiftWork/App/ContentView.swift:14] -- Fixed: added AppStateManager persistence matching Inspector pattern
- [x] [Review][Patch] TokenStatsView accesses agentBridge.events directly, bypassing DebugViewModel [SwiftWork/Views/Workspace/Inspector/DebugView.swift:158] -- Fixed: added perCallTokenBreakdown computed property to DebugViewModel
- [x] [Review][Defer] ForEach uses index as identity [SwiftWork/Views/Workspace/Inspector/DebugView.swift:169] -- deferred, low risk due to append-only event pattern
- [x] [Review][Defer] Duplicated colorForEventType between InspectorView and DebugView -- deferred, pre-existing pattern choice per spec guidance
