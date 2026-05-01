# Story 2.2: Tool Card 完整体验

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a 用户,
I want 看到 Tool 调用的结构化卡片，包括参数、进度、结果，并可展开查看详情,
so that 我可以清晰理解 Agent 执行了什么操作以及结果如何。

## Acceptance Criteria

1. **Given** Agent 调用了某个工具 **When** Timeline 渲染 `.toolUse` 事件 **Then** 显示 ToolCallView 卡片，包含工具名（如 Bash、Edit）、输入参数摘要、执行状态指示器（FR14）
2. **Given** 工具正在执行中 **When** 接收到 `.toolProgress` 事件 **Then** 卡片显示旋转进度指示器和已用时间（FR15）
3. **Given** 工具执行完成 **When** 接收到 `.toolResult` 事件 **Then** ToolResultView 显示成功（绿色）/ 失败（红色）状态和结果摘要（截断预览）（FR17） **And** 工具调用卡片默认折叠显示摘要，点击展开显示完整参数和结果（FR16）
4. **Given** 用户点击某个工具调用卡片 **When** 卡片被选中 **Then** Inspector Panel 展开显示该事件的完整详情（FR18）

**覆盖的 FRs:** FR14, FR15, FR16, FR17, FR18
**覆盖的 ARCHs:** ARCH-9

## Tasks / Subtasks

- [ ] Task 1: 实现 ToolUse/ToolResult 事件配对机制（AC: #3）
  - [ ] 1.1 在 `TimelineViewModel` 或 `AgentBridge` 中创建 `toolContentMap: [String: ToolContent]` 字典，key 为 `toolUseId`
  - [ ] 1.2 当收到 `.toolUse` 事件时，通过 `ToolContent.fromToolUseEvent()` 创建初始 ToolContent 并存入 map
  - [ ] 1.3 当收到 `.toolProgress` 事件时，从 map 中查找对应 ToolContent，调用 `applyingProgress()` 更新
  - [ ] 1.4 当收到 `.toolResult` 事件时，从 map 中查找对应 ToolContent，合并 output、isError、status 字段
  - [ ] 1.5 确保 `@Observable` 的属性变更正确触发 SwiftUI 重渲染

- [ ] Task 2: 重构 TimelineView 的工具事件渲染为统一卡片（AC: #1, #2, #3）
  - [ ] 2.1 创建 `ToolCardView.swift`（`SwiftWork/Views/Workspace/Timeline/EventViews/ToolCardView.swift`）作为统一工具卡片容器
  - [ ] 2.2 `ToolCardView` 接收完整的 `ToolContent`（已配对 toolUse + toolResult），而非单个 `AgentEvent`
  - [ ] 2.3 卡片结构：标题行（summaryTitle + 工具名 + 状态标签）+ 可选副标题 + 展开/折叠区域
  - [ ] 2.4 标题行显示工具图标（从 ToolRendererRegistry 获取或 SF Symbol fallback）、summaryTitle、状态标签（pending/running/completed/failed）
  - [ ] 2.5 状态标签颜色：`.pending` 灰色、`.running` 蓝色 + ProgressView、`.completed` 绿色、`.failed` 红色
  - [ ] 2.6 折叠状态（默认）：仅显示标题行 + 副标题，用 `DisclosureGroup` 或自定义 `@State isExpanded`
  - [ ] 2.7 展开状态：显示完整 input JSON、output 内容（截断预览 + 可展开）、进度信息

- [ ] Task 3: 集成 ToolRenderable 渲染器到 ToolCardView（AC: #1, #3）
  - [ ] 3.1 ToolCardView 折叠状态的标题行委托给 `ToolRenderable.summaryTitle()` 和 `ToolRenderable.subtitle()`
  - [ ] 3.2 ToolCardView 展开状态委托给 `ToolRenderable.body(content:)` 渲染工具特定详情
  - [ ] 3.3 为骨架渲染器（BashToolRenderer、FileEditToolRenderer、SearchToolRenderer）补充展开状态的 body 实现
  - [ ] 3.4 未注册工具使用通用渲染：显示 toolName + 原始 input 文本 + output 文本

- [ ] Task 4: 更新 TimelineView 事件分发逻辑（AC: #1, #2, #3）
  - [ ] 4.1 修改 `eventView(for:)` 中 `.toolUse` 分支：查找 ToolCardView 并传入配对后的 ToolContent
  - [ ] 4.2 修改 `.toolResult` 分支：不再单独渲染 ToolResultView，而是触发对应 ToolCardView 更新（通过 toolContentMap）
  - [ ] 4.3 修改 `.toolProgress` 分支：不再单独渲染 ToolProgressView，而是触发对应 ToolCardView 更新
  - [ ] 4.4 确保事件流中 `.toolResult`/`.toolProgress` 到达时，对应的 ToolCardView 能响应式更新状态

- [ ] Task 5: 实现工具结果摘要和内容展示（AC: #3）
  - [ ] 5.1 创建 `ToolResultContentView.swift`（`SwiftWork/Views/Workspace/Timeline/EventViews/ToolResultContentView.swift`）
  - [ ] 5.2 成功结果：绿色状态图标 + 截断预览（前 200 字符或前 5 行）+ "展开" 按钮
  - [ ] 5.3 错误结果：红色状态图标 + 完整错误信息（不截断）+ 红色背景高亮
  - [ ] 5.4 Diff 格式检测：如果 output 包含 `+`/`-`/`@@` 行格式，使用 Diff 视图渲染（绿色/红色/蓝色背景区分）
  - [ ] 5.5 Copy 按钮：为 input JSON 和 output 内容提供复制到剪贴板功能

- [ ] Task 6: 实现点击选中与 Inspector 联动（AC: #4）
  - [ ] 6.1 ToolCardView 添加 `isSelected` 绑定或回调
  - [ ] 6.2 点击卡片时设置 TimelineView 的 `selectedEventId` 状态
  - [ ] 6.3 通过 `@Binding` 或 `@Environment` 将选中事件传递给 Inspector Panel（Inspector Panel 本身在 Story 3-4 完整实现，本 story 仅实现选中事件的数据传递）
  - [ ] 6.4 选中态视觉反馈：蓝色边框或高亮背景

- [ ] Task 7: 为现有骨架渲染器完善 body 实现（AC: #1）
  - [ ] 7.1 `BashToolRenderer` 展开视图：显示完整 command、timeout 参数（如有）、output 终端风格展示
  - [ ] 7.2 `FileEditToolRenderer` 展开视图：显示 file_path、old_string/new_string Diff 对比
  - [ ] 7.3 `SearchToolRenderer` 展开视图：显示 pattern、path、匹配结果列表预览
  - [ ] 7.4 每个渲染器的展开 body 使用调用各自的 `summaryTitle`/`subtitle` 生成丰富摘要

- [ ] Task 8: 补充 ToolRendererRegistry 注册更多工具（AC: #1）
  - [ ] 8.1 创建 `ReadToolRenderer.swift`（`toolName = "Read"`，图标 `doc.text`）
  - [ ] 8.2 创建 `WriteToolRenderer.swift`（`toolName = "Write"`，图标 `pencil.and.outline`）
  - [ ] 8.3 在 `ToolRendererRegistry.init()` 中注册新渲染器
  - [ ] 8.4 新渲染器遵循与现有渲染器相同的模式：自定义 summaryTitle、subtitle、展开 body

- [ ] Task 9: 编写测试（AC: 全部）
  - [ ] 9.1 测试 `toolContentMap` 的配对逻辑：toolUse + toolResult + toolProgress 正确合并
  - [ ] 9.2 测试未匹配的 toolResult（无对应 toolUse）的处理
  - [ ] 9.3 测试 ToolCardView 折叠/展开状态切换
  - [ ] 9.4 测试不同 status 下的视觉状态标签
  - [ ] 9.5 测试 Diff 格式检测逻辑
  - [ ] 9.6 所有测试通过 `swift test`

## Dev Notes

### 核心挑战：从"独立事件"到"配对卡片"

Story 2-1 建立的架构中，`.toolUse`、`.toolResult`、`.toolProgress` 是三个独立事件，各自独立渲染。本 story 的核心工作是**将这三个事件配对为统一的 ToolCardView**，使工具调用从"分散的三张卡片"变为"一张可展开的完整卡片"。

**关键数据流变更：**

```
当前（Story 2-1）：
  .toolUse     → ToolCallView (独立卡片)
  .toolResult  → ToolResultView (独立卡片)
  .toolProgress → ToolProgressView (独立卡片)

目标（Story 2-2）：
  .toolUse     → ToolCardView (创建卡片，status=pending)
  .toolProgress → ToolCardView (更新同一卡片，status=running)
  .toolResult  → ToolCardView (更新同一卡片，status=completed/failed)
```

### 配对机制设计

**方案：在 AgentBridge 中维护 toolContentMap**

在 `AgentBridge` 中添加 `toolContentMap: [String: ToolContent]`（key 为 `toolUseId`），原因：
- AgentBridge 已经在 `@MainActor` 上管理事件流
- 事件配对发生在事件消费层（AgentBridge），而非 View 层
- ToolContent 已经有 `fromToolUseEvent`、`fromToolResultEvent`、`applyingProgress` 方法

```swift
// AgentBridge 新增
var toolContentMap: [String: ToolContent] = [:]

// 在 appendAndPersist 中处理配对
private func appendAndPersist(_ event: AgentEvent) {
    events.append(event)

    // 工具事件配对
    switch event.type {
    case .toolUse:
        let content = ToolContent.fromToolUseEvent(event)
        toolContentMap[content.toolUseId] = content
    case .toolProgress:
        let toolUseId = event.metadata["toolUseId"] as? String ?? ""
        if let existing = toolContentMap[toolUseId] {
            toolContentMap[toolUseId] = existing.applyingProgress(event)
        }
    case .toolResult:
        let resultContent = ToolContent.fromToolResultEvent(event)
        let toolUseId = resultContent.toolUseId
        if let existing = toolContentMap[toolUseId] {
            toolContentMap[toolUseId] = ToolContent(
                toolName: existing.toolName,
                toolUseId: existing.toolUseId,
                input: existing.input,
                output: resultContent.output,
                isError: resultContent.isError,
                status: resultContent.status,
                elapsedTimeSeconds: existing.elapsedTimeSeconds
            )
        }
    default:
        break
    }

    // ... 持久化逻辑不变
}
```

### TimelineView 渲染策略

**关键问题：toolResult 和 toolProgress 不再产生独立的卡片，而是更新已有的 ToolCardView。**

需要修改 `eventView(for:)` 逻辑：

```swift
@ViewBuilder
private func eventView(for event: AgentEvent) -> some View {
    switch event.type {
    case .toolUse:
        // 查找配对的 ToolContent，渲染 ToolCardView
        let toolUseId = event.metadata["toolUseId"] as? String ?? ""
        if let content = agentBridge.toolContentMap[toolUseId] {
            ToolCardView(content: content, registry: toolRendererRegistry, ...)
        } else {
            ToolCallView(event: event) // fallback
        }
    case .toolResult, .toolProgress:
        // 不再渲染独立卡片——配对更新由 toolContentMap 驱动
        EmptyView()
    // ... 其他 case 不变
    }
}
```

**注意：** 由于 `AgentBridge` 是 `@Observable`，`toolContentMap` 的变更会自动触发 SwiftUI 重渲染。当 `.toolResult` 到达并更新 `toolContentMap` 时，对应的 `ToolCardView` 会自动重渲染（因为 `content` 参数变了）。

### ToolCardView 结构设计

参照 OpenWork 的 `tool-call.tsx` 交互模式：

```
┌──────────────────────────────────────────┐
│ [icon] [summaryTitle]       [completed] │  <- 标题行（始终可见）
│        [toolName]                        │  <- 工具名（小字，灰色）
│        [subtitle]                        │  <- 操作摘要（可选）
├──────────────────────────────────────────┤  <- 点击展开/折叠
│ [Tool-specific body from renderer]       │
│                                          │
│ TOOL INPUT                          [Copy]│  <- 完整 input JSON
│ { "command": "npm test" }                │
│                                          │
│ TOOL OUTPUT                         [Copy]│  <- 结果（成功绿/失败红）
│ test results...                          │
└──────────────────────────────────────────┘
```

**折叠状态（默认）：** 仅标题行 + 工具名 + 副标题
**展开状态：** 标题行 + 工具特定 body（通过 ToolRenderable）+ input JSON + output + Copy 按钮

### Diff 格式检测

FileEdit 工具的 output 通常包含 unified diff 格式。检测逻辑：

```swift
private var isDiffContent: Bool {
    // 检查 output 是否包含 diff 标记行
    guard let output, !output.isEmpty else { return false }
    let lines = output.components(separatedBy: "\n")
    let diffLines = lines.filter { $0.hasPrefix("+") || $0.hasPrefix("-") || $0.hasPrefix("@@") }
    return diffLines.count >= 2 // 至少 2 行 diff 标记才认为是 diff
}
```

Diff 渲染：`+` 行绿色背景，`-` 行红色背景，`@@` 行蓝色背景。参照 OpenWork 的 Diff 高亮实现。

### 选中事件与 Inspector 联动

本 story 需要建立事件选中的基础设施，为 Story 3-4（Inspector Panel）做准备：

1. 在 `TimelineView` 中添加 `@State private var selectedEventId: UUID?`
2. `ToolCardView` 接收 `isSelected: Bool` 和 `onSelect: () -> Void`
3. 点击卡片时设置 `selectedEventId`
4. 通过 `@Binding` 将 `selectedEventId` 传递给父视图 `WorkspaceView`

Inspector Panel 的完整实现在 Story 3-4，本 story 仅传递选中事件 ID。

### 前序 Story 关键上下文

**Story 2-1 已完成的内容（必须在此基础上扩展，不重新创建）：**

1. **`ToolRenderable` 协议**（`SwiftWork/SDKIntegration/ToolRenderable.swift`）：`toolName`、`body(content:)`、`summaryTitle(content:)`、`subtitle(content:)`
2. **`ToolRendererRegistry`**（`SwiftWork/SDKIntegration/ToolRendererRegistry.swift`）：`@MainActor @Observable`，已预注册 Bash、Edit、Grep
3. **`ToolContent`**（`SwiftWork/Models/UI/ToolContent.swift`）：已有 `ToolExecutionStatus`、`status`、`elapsedTimeSeconds`、`fromToolUseEvent`、`fromToolResultEvent`、`applyingProgress`
4. **3 个骨架渲染器**（`SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/`）：BashToolRenderer、FileEditToolRenderer、SearchToolRenderer，仅实现折叠态
5. **TimelineView** 已集成 Registry 的 `toolUseView(event:)` 方法

**Review 发现的问题（已知但未修复）：**
- MockToolRenderer 使用 `nonisolated(unsafe)` 的 thread-unsafe static，仅影响测试，不影响生产代码
- `summaryTitle` JSON 解析在 ToolContent 和 3 个渲染器中重复——本 story 可考虑提取共用 JSON 解析辅助方法

### 现有文件详细状态

**`ToolCallView.swift`（当前实现——将作为未注册工具的 fallback）：**
- 显示 `event.content`（工具名）+ `event.metadata["input"]`（原始 input 文本）
- 灰色背景，圆角 8px
- 本 story 中保持不变，仅作为 ToolRendererRegistry 中未注册工具的回退

**`ToolResultView.swift`（当前实现——将被 ToolCardView 的展开区域替代）：**
- 显示 `event.content`（结果文本）+ isError 状态
- 成功绿色背景，失败红色背景
- 本 story 中 `.toolResult` 不再单独渲染此 view，但文件保留作为独立引用

**`ToolProgressView.swift`（当前实现——将被 ToolCardView 的进度指示器替代）：**
- 显示 ProgressView + 工具名 + 已用时间
- 本 story 中 `.toolProgress` 不再单独渲染此 view，但文件保留作为独立引用

**`EventMapper.swift`——不修改：**
- `.toolUse` → metadata 包含 `toolName`、`toolUseId`、`input`
- `.toolResult` → metadata 包含 `toolUseId`、`isError`
- `.toolProgress` → metadata 包含 `toolUseId`、`toolName`、`elapsedTimeSeconds`
- 映射逻辑已完整，无需改动

### SDK 工具名确认（从 Story 2-1 的 Review 修正）

| SDK 工具名 | 说明 | 渲染器 | SF Symbol |
|-----------|------|--------|-----------|
| `Bash` | Shell 命令 | BashToolRenderer | `terminal` |
| `Read` | 文件读取 | ReadToolRenderer (NEW) | `doc.text` |
| `Write` | 文件写入 | WriteToolRenderer (NEW) | `pencil.and.outline` |
| `Edit` | 文件编辑 | FileEditToolRenderer | `pencil.line` |
| `Glob` | 文件匹配 | SearchToolRenderer（暂不独立，用通用渲染） | — |
| `Grep` | 内容搜索 | SearchToolRenderer | `text.magnifyingglass` |

### 文件变更清单

**NEW（新建文件）：**
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolCardView.swift` — 统一工具卡片容器（折叠/展开、状态标签、选中态）
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolResultContentView.swift` — 工具结果内容展示（成功/失败/Diff/Copy）
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/ReadToolRenderer.swift` — Read 工具渲染器
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/WriteToolRenderer.swift` — Write 工具渲染器

**UPDATE（更新文件）：**
- `SwiftWork/SDKIntegration/AgentBridge.swift` — 添加 `toolContentMap` 字典，修改 `appendAndPersist` 处理工具事件配对，修改 `clearEvents` 清空 map
- `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` — 添加 `selectedEventId` 状态，修改 `.toolUse`/`.toolResult`/`.toolProgress` 分支，传递 selectedEventId 给 WorkspaceView
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/BashToolRenderer.swift` — 完善展开状态 body
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/FileEditToolRenderer.swift` — 完善展开状态 body + Diff 预览
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/SearchToolRenderer.swift` — 完善展开状态 body + 结果预览
- `SwiftWork/SDKIntegration/ToolRendererRegistry.swift` — 注册 ReadToolRenderer 和 WriteToolRenderer
- `SwiftWork/Views/Workspace/WorkspaceView.swift` — 接收 selectedEventId binding（为 Inspector 做准备）
- `SwiftWork.xcodeproj/project.pbxproj` — 添加新文件引用

**UNCHANGED（不修改——零回归风险）：**
- `SwiftWork/SDKIntegration/EventMapper.swift` — 事件映射逻辑不变
- `SwiftWork/SDKIntegration/ToolRenderable.swift` — 协议定义不变
- `SwiftWork/Models/UI/ToolContent.swift` — 模型已有配对所需的所有字段和方法
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolCallView.swift` — 作为未注册工具回退保留
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolResultView.swift` — 保留文件但不单独渲染
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolProgressView.swift` — 保留文件但不单独渲染

### 性能注意事项

- `toolContentMap` 是 Dictionary 查找 O(1)，无性能影响
- `ToolCardView` 使用 `@State isExpanded` 控制折叠，避免不必要的展开区域渲染
- Diff 格式检测仅在展开时执行（不在折叠状态）
- ToolContent 的配对更新创建新 struct（值语义），SwiftUI 自动比较新旧值决定重渲染
- 单个 ToolCardView 应控制在 200 行以内（含折叠/展开两种状态），超出则拆分子 View

### 与后续 Story 的关系

- **Story 2-3（事件类型视觉系统）**：将基于 ToolCardView 添加颜色主题、图标系统、差异化的卡片样式
- **Story 3-4（Inspector Panel）**：将使用本 story 建立的 `selectedEventId` 机制在右侧面板显示完整详情

### Project Structure Notes

- `ToolCardView` 放在 `EventViews/` — 与其他 EventView 同级，是工具卡片的统一入口
- `ToolResultContentView` 放在 `EventViews/` — 被 ToolCardView 引用的子组件
- 新渲染器（Read、Write）放在 `EventViews/ToolRenderers/` — 与现有渲染器同目录
- 遵循单 View 文件不超过 300 行规则
- 遵循 ViewModel 与 View 分文件规则

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.2: Tool Card 完整体验]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 9: ToolRenderable 协议 + ToolRendererRegistry]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 10: Timeline 渲染策略]
- [Source: _bmad-output/project-context.md#ToolRenderable 协议驱动的可扩展渲染]
- [Source: _bmad-output/project-context.md#OpenWork 参照 — tool-call.tsx ToolCallView 交互模式]
- [Source: _bmad-output/project-context.md#OpenWork 参照 — Diff 高亮（+绿色、-红色、@@蓝色）]
- [Source: _bmad-output/implementation-artifacts/2-1-tool-visualization-architecture.md — 前序 Story 上下文]
- [Source: SwiftWork/SDKIntegration/AgentBridge.swift:156-167 — appendAndPersist 方法（配对逻辑注入点）]
- [Source: SwiftWork/Views/Workspace/Timeline/TimelineView.swift:47-91 — eventView 和 toolUseView 方法]
- [Source: SwiftWork/Models/UI/ToolContent.swift — ToolContent 配对方法]
- [Source: SwiftWork/SDKIntegration/ToolRenderable.swift — ToolRenderable 协议]
- [Source: SwiftWork/SDKIntegration/ToolRendererRegistry.swift — Registry 注册/查找]
- [Source: SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/BashToolRenderer.swift — 骨架渲染器示例]

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
