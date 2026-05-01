# Story 2.1: Tool 可视化基础架构

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a 开发者,
I want 建立可扩展的工具卡片渲染系统,
so that 每种工具类型可以注册自己的 SwiftUI 渲染器，新增工具类型时无需修改核心 Timeline 逻辑。

## Acceptance Criteria

1. **Given** 项目已初始化 **When** 实现 `ToolRenderable` 协议 **Then** 协议定义 `toolName`（静态属性）、`body(content:)` 方法返回 `some View`
2. **Given** `ToolRendererRegistry` 已实现 **When** 调用 `register(renderer)` 和 `renderer(for:)` **Then** Registry 支持注册和查找 `ToolRenderable` 实现，查找未注册工具时返回 `nil`
3. **Given** TimelineView 渲染 `.toolUse` 事件 **When** 通过 Registry 查找渲染器 **Then** 已注册的工具使用自定义渲染器，未注册的工具使用默认 `ToolCallView` 渲染（现有行为保持不变）
4. **Given** 工具卡片需要展示 Tool 调用和 Tool Result 的关联 **When** `ToolUse` 事件和对应的 `ToolResult` 事件通过 `toolUseId` 关联 **Then** 渲染系统能将 Tool 调用和其结果配对展示在同一卡片中
5. **Given** 工具渲染系统已建立 **When** 编写单元测试 **Then** 测试覆盖 Registry 的注册/查找/默认回退逻辑，以及 ToolContent 数据提取

**覆盖的 FRs:** FR14 (基础), FR19 (基础)
**覆盖的 ARCHs:** ARCH-9

## Tasks / Subtasks

- [x] Task 1: 定义 `ToolRenderable` 协议（AC: #1）
  - [x] 1.1 在 `SwiftWork/SDKIntegration/ToolRenderable.swift` 中定义协议
  - [x] 1.2 协议要求：`static var toolName: String { get }`、`func body(content: ToolContent) -> any View`
  - [x] 1.3 协议提供默认扩展方法用于生成摘要标题和副标题（`summaryTitle(content:)`、`subtitle(content:)`）
  - [x] 1.4 协议遵循 `Sendable`（确保线程安全，工具渲染器可能在不同上下文创建）

- [x] Task 2: 扩展 `ToolContent` 模型以支持工具渲染（AC: #1, #4）
  - [x] 2.1 在 `SwiftWork/Models/UI/ToolContent.swift` 中添加 `status` 字段：枚举 `ToolExecutionStatus`（`.pending` / `.running` / `.completed` / `.failed`）
  - [x] 2.2 添加 `elapsedTimeSeconds: Int?` 字段（来自 `.toolProgress`）
  - [x] 2.3 添加 `summaryTitle: String?` 计算属性（从 `input` JSON 提取摘要，如文件路径、命令）
  - [x] 2.4 确保 `ToolContent` 仍为 `Sendable` struct
  - [x] 2.5 添加 `init` 便捷方法从 `AgentEvent` 提取 `ToolContent`（从 event.metadata 字典解析）

- [x] Task 3: 实现 `ToolRendererRegistry`（AC: #2, #3）
  - [x] 3.1 在 `SwiftWork/SDKIntegration/ToolRendererRegistry.swift` 中创建 `@MainActor @Observable final class ToolRendererRegistry`
  - [x] 3.2 内部维护 `private var renderers: [String: any ToolRenderable] = [:]`（key 为 toolName）
  - [x] 3.3 实现 `func register(_ renderer: any ToolRenderable)` — 注册自定义渲染器
  - [x] 3.4 实现 `func renderer(for toolName: String) -> (any ToolRenderable)?` — 查找渲染器，未注册返回 `nil`
  - [x] 3.5 实现 `static func shared() -> ToolRendererRegistry` 单例（通过 `@MainActor` 全局实例）
  - [x] 3.6 实现预注册逻辑：在 `init` 中注册 SDK 已知工具的默认渲染器（BashToolRenderer、FileEditToolRenderer、SearchToolRenderer — 仅骨架实现，Story 2-2 和 2-3 完善细节）

- [x] Task 4: 重构 TimelineView 以使用 Registry（AC: #3）
  - [x] 4.1 修改 `TimelineView` 添加 `toolRendererRegistry: ToolRendererRegistry` 参数（通过 `@Environment` 或 init 传入）
  - [x] 4.2 修改 `eventView(for:)` 中 `.toolUse` 分支：先从 event 构建 `ToolContent`，然后查询 Registry
  - [x] 4.3 如果 Registry 返回渲染器：调用 `renderer.body(content:)` 获取自定义 View
  - [x] 4.4 如果 Registry 返回 `nil`：回退到现有 `ToolCallView(event:)` 行为（零回归风险）
  - [x] 4.5 `.toolResult` 事件渲染逻辑暂不改变（Tool Result 配对在 Story 2-2 实现折叠卡片时处理）

- [x] Task 5: 创建默认工具渲染器骨架（AC: #1, #3）
  - [x] 5.1 创建 `SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/BashToolRenderer.swift` — 骨架实现，`toolName = "Bash"`，`body` 返回带终端图标 + 命令摘要的卡片
  - [x] 5.2 创建 `SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/FileEditToolRenderer.swift` — 骨架实现，`toolName = "FileEdit"`（或 SDK 中实际使用的工具名），`body` 返回带文件图标 + 文件路径摘要的卡片
  - [x] 5.3 创建 `SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/SearchToolRenderer.swift` — 骨架实现，`toolName = "Search"`（或 `Grep`），`body` 返回带搜索图标 + 查询摘要的卡片
  - [x] 5.4 每个骨架渲染器提取 `summaryTitle` 和 `subtitle` 的基础逻辑（从 input JSON 解析关键参数）

- [x] Task 6: 编写测试（AC: #5）
  - [x] 6.1 创建 `SwiftWorkTests/SDKIntegration/ToolRendererRegistryTests.swift`
  - [x] 6.2 测试 `register` 后 `renderer(for:)` 返回正确渲染器
  - [x] 6.3 测试未注册工具名返回 `nil`
  - [x] 6.4 测试 `register` 同名工具覆盖旧渲染器
  - [x] 6.5 测试空 Registry 的 `renderer(for:)` 始终返回 `nil`
  - [x] 6.6 创建 `SwiftWorkTests/Models/ToolContentTests.swift` — 测试 ToolContent 从 AgentEvent 提取逻辑
  - [x] 6.7 测试 `summaryTitle` 从常见工具 input JSON 格式中正确提取摘要
  - [x] 6.8 所有测试通过 `swift test`

## Dev Notes

### 核心架构约束

- **@Observable（非 ObservableObject）**：`ToolRendererRegistry` 使用 `@Observable` 标注
- **@MainActor**：`ToolRendererRegistry` 在 MainActor 上运行（管理 UI 渲染器）
- **分层边界**：`ToolRenderable` 协议定义在 `SDKIntegration/`（与 `EventMapper` 同层），具体渲染器实现放在 `Views/` 下（因为它们返回 SwiftUI View）
- **View 不直接引用 SDK 类型**：`ToolContent` 是 UI 中间模型，从 `AgentEvent.metadata` 提取数据，View 只消费 `ToolContent`
- **Swift 6.1 strict concurrency**：`ToolRenderable` 协议和 `ToolContent` 都需要 `Sendable` 一致性
- **Single View 文件 < 300 行**：骨架渲染器应保持简洁

### 前序 Story 关键上下文

Epic 1 已全部完成（Story 1-1 到 1-6），以下基础设施已就绪：

**已有的工具相关实现（必须在此基础上扩展，不重新创建）：**

1. **`AgentEventType` 枚举**（`SwiftWork/Models/UI/AgentEventType.swift`）：已包含 `.toolUse`、`.toolResult`、`.toolProgress` case
2. **`AgentEvent` struct**（`SwiftWork/Models/UI/AgentEvent.swift`）：`metadata: [String: any Sendable]` 字典存储工具数据
3. **`ToolContent` struct**（`SwiftWork/Models/UI/ToolContent.swift`）：已有 `toolName`、`toolUseId`、`input`、`output`、`isError` 字段
4. **`EventMapper`**（`SwiftWork/SDKIntegration/EventMapper.swift`）：已将 SDK 的 `.toolUse` 映射为 `AgentEvent(type: .toolUse, content: data.toolName, metadata: ["toolName": ..., "toolUseId": ..., "input": ...])`
5. **`ToolCallView`**（`SwiftWork/Views/Workspace/Timeline/EventViews/ToolCallView.swift`）：现有基础渲染——显示工具名 + input 文本，灰色背景
6. **`ToolResultView`**（显示成功/失败结果）、**`ToolProgressView`**（显示进度+时间）
7. **`TimelineView`**（`SwiftWork/Views/Workspace/Timeline/TimelineView.swift`）：已有 `eventView(for:)` 的 switch-case 映射

**当前 EventMapper 中工具事件的 metadata 结构（直接使用，不修改 EventMapper）：**
```swift
// .toolUse event:
content: data.toolName           // "Bash", "FileEdit" 等
metadata: [
    "toolName": data.toolName,   // String
    "toolUseId": data.toolUseId, // String
    "input": data.input          // JSON String（注意：是 String，不是 Dictionary）
]

// .toolResult event:
content: data.content            // 结果文本
metadata: [
    "toolUseId": data.toolUseId, // String — 关联 key
    "isError": data.isError      // Bool
]

// .toolProgress event:
content: data.toolName
metadata: [
    "toolUseId": data.toolUseId,    // String — 关联 key
    "toolName": data.toolName,
    "elapsedTimeSeconds": Int       // 已用秒数
]
```

**关键：`ToolUseData.input` 是 JSON String，不是 Dictionary。** 需要时用 `JSONSerialization.jsonObject(with:)` 解析。

### ToolRenderable 协议设计

```swift
// SwiftWork/SDKIntegration/ToolRenderable.swift
import SwiftUI

/// 可扩展的工具卡片渲染协议。
/// 每种工具类型注册一个实现，ToolRendererRegistry 查找并调用。
protocol ToolRenderable: Sendable {
    /// 此渲染器处理的工具名称（与 SDK ToolUseData.toolName 匹配）
    static var toolName: String { get }

    /// 根据工具内容生成 SwiftUI 视图
    @MainActor
    func body(content: ToolContent) -> any View

    /// 可选：生成摘要标题（用于折叠状态显示）
    func summaryTitle(content: ToolContent) -> String

    /// 可选：生成副标题（如文件路径、命令摘要）
    func subtitle(content: ToolContent) -> String?
}

extension ToolRenderable {
    func summaryTitle(content: ToolContent) -> String {
        content.toolName
    }

    func subtitle(content: ToolContent) -> String? {
        nil
    }
}
```

### ToolRendererRegistry 设计

```swift
// SwiftWork/SDKIntegration/ToolRendererRegistry.swift
@MainActor
@Observable
final class ToolRendererRegistry {
    private var renderers: [String: any ToolRenderable] = [:]

    init() {
        // 预注册默认骨架渲染器
        register(BashToolRenderer())
        register(FileEditToolRenderer())
        register(SearchToolRenderer())
    }

    func register(_ renderer: any ToolRenderable) {
        renderers[type(of: renderer).toolName] = renderer
    }

    func renderer(for toolName: String) -> (any ToolRenderable)? {
        renderers[toolName]
    }
}
```

### ToolContent 扩展设计

在现有 `ToolContent` struct 上添加字段和方法：

```swift
// 扩展 ToolContent
enum ToolExecutionStatus: String, Sendable {
    case pending    // 仅 toolUse，尚无 toolResult
    case running    // 收到 toolProgress
    case completed  // toolResult isError=false
    case failed     // toolResult isError=true
}

// 新增字段
var status: ToolExecutionStatus
var elapsedTimeSeconds: Int?

// 便捷初始化：从 AgentEvent.metadata 提取
static func fromToolUseEvent(_ event: AgentEvent) -> ToolContent { ... }
static func fromToolResultEvent(_ event: AgentEvent) -> ToolContent { ... }
```

### TimelineView 集成方式

**关键：保持向后兼容，零回归风险。**

```swift
// TimelineView 新增参数（有合理默认值）
struct TimelineView: View {
    let agentBridge: AgentBridge
    var toolRendererRegistry: ToolRendererRegistry = ToolRendererRegistry()
    // ...

    @ViewBuilder
    private func eventView(for event: AgentEvent) -> some View {
        switch event.type {
        // ... 其他 case 不变
        case .toolUse:
            toolUseView(event: event)  // 新方法
        // ...
        }
    }

    @ViewBuilder
    private func toolUseView(event: AgentEvent) -> some View {
        let toolName = event.content
        if let renderer = toolRendererRegistry.renderer(for: toolName) {
            let content = ToolContent.fromToolUseEvent(event)
            renderer.body(content: content)
        } else {
            ToolCallView(event: event)  // 回退到现有实现
        }
    }
}
```

### 骨架渲染器说明

本 story 创建的 BashToolRenderer、FileEditToolRenderer、SearchToolRenderer 是**骨架实现**——它们的主要目的是：

1. 验证 ToolRenderable 协议和 Registry 的注册/查找机制工作正确
2. 提供每种工具类型的**差异化图标和基础摘要**（比现有 ToolCallView 稍好）
3. 为 Story 2-2（完整 Tool Card 体验）和 Story 2-3（事件视觉系统）奠定扩展基础

**不做：**
- 不实现展开/折叠功能（Story 2-2）
- 不实现 Tool Result 配对展示（Story 2-2）
- 不实现完整的差异化视觉样式和颜色系统（Story 2-3）
- 不实现 Diff 高亮（Story 2-2）
- 不修改 ToolResultView 或 ToolProgressView 的现有行为

### SDK 工具名映射

open-agent-sdk-swift 的核心工具名（用于渲染器注册）：

| SDK 工具名 | 说明 | 骨架渲染器图标 |
|-----------|------|-------------|
| `Bash` | Shell 命令执行 | `terminal` (SF Symbol) |
| `Read` | 文件读取 | `doc.text` |
| `Write` | 文件写入 | `pencil.and.outline` |
| `Edit` | 文件编辑 | `pencil.line` |
| `Glob` | 文件匹配搜索 | `magnifyingglass` |
| `Grep` | 内容搜索 | `text.magnifyingglass` |
| `LS` | 目录列表 | `folder` |

**注意：** 具体工具名需要查看 SDK 源码确认。在 `ToolRendererRegistry.init()` 中注册时使用实际工具名。如果不确定，先注册最常用的 `Bash`、`Read`/`Write`/`Edit`，其余在 Story 2-2 补充。

### Input JSON 解析注意事项

SDK 的 `ToolUseData.input` 是 JSON String。常见的 input 格式：

```json
// Bash
{"command": "npm test"}

// Read
{"file_path": "/path/to/file.swift"}

// Write
{"file_path": "/path/to/file.swift", "content": "file content here"}

// Edit
{"file_path": "/path/to/file.swift", "old_string": "...", "new_string": "..."}

// Grep
{"pattern": "search term", "path": "/path/to/search"}
```

骨架渲染器的 `summaryTitle` 和 `subtitle` 方法应解析这些 JSON 提取关键字段。使用：
```swift
guard let data = content.input.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
else { return nil }
```

### 文件变更清单

**NEW（新建文件）：**
- `SwiftWork/SDKIntegration/ToolRenderable.swift` — ToolRenderable 协议定义
- `SwiftWork/SDKIntegration/ToolRendererRegistry.swift` — 渲染器注册表（覆盖现有空文件，如果有的话）
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/BashToolRenderer.swift` — Bash 工具渲染器骨架
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/FileEditToolRenderer.swift` — 文件操作渲染器骨架
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/SearchToolRenderer.swift` — 搜索工具渲染器骨架
- `SwiftWorkTests/SDKIntegration/ToolRendererRegistryTests.swift` — Registry 单元测试
- `SwiftWorkTests/Models/ToolContentTests.swift` — ToolContent 提取逻辑测试

**UPDATE（更新文件）：**
- `SwiftWork/Models/UI/ToolContent.swift` — 添加 `ToolExecutionStatus` 枚举、`status` 字段、`elapsedTimeSeconds` 字段、从 AgentEvent 提取的便捷方法
- `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` — 添加 `toolRendererRegistry` 参数，修改 `.toolUse` 分支使用 Registry
- `SwiftWork.xcodeproj/project.pbxproj` — 添加新文件引用

**UNCHANGED（不修改——零回归风险）：**
- `SwiftWork/SDKIntegration/EventMapper.swift` — 事件映射逻辑已完成，不需改动
- `SwiftWork/SDKIntegration/AgentBridge.swift` — 事件管理逻辑已完成
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolCallView.swift` — 作为未注册工具的默认回退
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolResultView.swift` — Story 2-2 处理
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolProgressView.swift` — Story 2-2 处理
- `SwiftWork/Views/Workspace/WorkspaceView.swift` — 暂不修改（Registry 通过默认参数传入）

### 性能注意事项

- `ToolRendererRegistry.renderer(for:)` 是 O(1) Dictionary 查找，无性能影响
- `ToolContent.fromToolUseEvent()` 解析 metadata 字典，O(1) 操作
- Input JSON 解析（`JSONSerialization`）仅在渲染器需要 `summaryTitle`/`subtitle` 时执行，且结果可缓存
- 骨架渲染器不涉及异步操作或额外数据获取

### 与后续 Story 的关系

本 story 是 Epic 2 的第一个 story，为后续 story 奠定架构基础：

- **Story 2-2（Tool Card 完整体验）**：将基于 `ToolRenderable` 协议完善每个渲染器的 `body(content:)`，实现折叠/展开、Tool Result 配对、进度指示器集成
- **Story 2-3（事件类型视觉系统）**：将基于渲染器协议添加颜色主题、图标系统、差异化的卡片样式
- **Story 2-4（Markdown 渲染与代码高亮）**：将为工具结果中的 Markdown 内容和代码高亮提供渲染服务
- **Story 2-5（Timeline 性能优化）**：将优化大量事件时的渲染性能

### OpenWork 参照

OpenWork 的 `tool-call.tsx` 中 `summarizeStep()` 函数为每种工具生成摘要标题和副标题。SwiftWork 的 `ToolRenderable` 协议中的 `summaryTitle(content:)` 和 `subtitle(content:)` 方法对应此功能。

OpenWork 的 ToolCallView 交互模式（本 story 仅实现基础架构，交互完善在 Story 2-2）：
```
┌──────────────────────────────────────┐
│ [summary title]           [completed]│  ← 标题行 + 状态标签
│ [toolName]                           │  ← 工具名（小字）
│ [subtitle / detail]                  │  ← 操作摘要
├──────────────────────────────────────┤  ← 点击展开/折叠（Story 2-2）
│ ...详细内容...                       │
└──────────────────────────────────────┘
```

### Project Structure Notes

- `ToolRenderable` 协议放在 `SDKIntegration/` — 因为它是协议定义，与 `EventMapper` 同层
- `ToolRendererRegistry` 放在 `SDKIntegration/` — 负责注册和查找，属于 SDK 集成层
- 具体渲染器实现放在 `Views/Workspace/Timeline/EventViews/ToolRenderers/` — 因为它们返回 SwiftUI View
- 遵循命名规范：协议用能力描述（`ToolRenderable`）、Registry 无后缀、渲染器用 `XxxToolRenderer` 后缀

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.1: Tool 可视化基础架构]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 9: 组件架构 — ToolRenderable 协议 + ToolRendererRegistry]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 11: 项目结构 — SDKIntegration/]
- [Source: _bmad-output/project-context.md#框架规则 — ToolRenderable 协议驱动的可扩展渲染]
- [Source: _bmad-output/project-context.md#OpenWork 参照 — tool-call.tsx summarizeStep()]
- [Source: _bmad-output/implementation-artifacts/1-6-app-state-restore.md — 前序 Story 上下文和代码模式]
- [Source: SwiftWork/Models/UI/ToolContent.swift — 现有工具内容模型]
- [Source: SwiftWork/Models/UI/AgentEvent.swift — UI 事件中间模型]
- [Source: SwiftWork/SDKIntegration/EventMapper.swift — SDKMessage→AgentEvent 映射（metadata 结构）]
- [Source: SwiftWork/Views/Workspace/Timeline/TimelineView.swift — 现有事件视图映射]
- [Source: SwiftWork/Views/Workspace/Timeline/EventViews/ToolCallView.swift — 现有基础工具卡片（回退默认）]

## Dev Agent Record

### Agent Model Used

GLM-5.1

### Debug Log References

- MockToolRenderer in ATDD tests used `private static var _instanceToolName` which triggered Swift 6.1 strict concurrency error. Fixed with `nonisolated(unsafe)`.
- ATDD test `testEmptyRegistryReturnsNil` conflicted with `testRegistryInitPreregistersDefaultRenderers` — both call `ToolRendererRegistry()` init, but one expects empty and the other expects pre-registered Bash. Resolved by updating the empty test to check only truly unregistered tool names, since init correctly pre-registers per Task 3.6.
- Protocol `body(content:)` must return `any View` (not `some View`) for protocol conformance in Swift 6.1. TimelineView wraps result in `AnyView()` for @ViewBuilder compatibility.

### Completion Notes List

- All 6 tasks and 27 subtasks completed
- ToolRenderable protocol defined with static toolName, body(content:), summaryTitle(content:), subtitle(content:) with default implementations
- ToolContent extended with ToolExecutionStatus enum, status field, elapsedTimeSeconds, summaryTitle computed property, fromToolUseEvent/fromToolResultEvent static methods, applyingProgress method
- ToolRendererRegistry implemented as @MainActor @Observable with register/renderer(for:) and init pre-registration of 3 skeleton renderers
- TimelineView refactored to use registry via new toolUseView method with AnyView wrapping and ToolCallView fallback
- 3 skeleton renderers created: BashToolRenderer (terminal icon), FileEditToolRenderer (pencil.line icon), SearchToolRenderer (text.magnifyingglass icon)
- All 302 tests pass with 0 failures (25 in ToolRendererRegistryTests, 5 in ToolContentTests)

### File List

**NEW:**
- SwiftWork/SDKIntegration/ToolRenderable.swift
- SwiftWork/SDKIntegration/ToolRendererRegistry.swift
- SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/BashToolRenderer.swift
- SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/FileEditToolRenderer.swift
- SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/SearchToolRenderer.swift

**UPDATED:**
- SwiftWork/Models/UI/ToolContent.swift
- SwiftWork/Views/Workspace/Timeline/TimelineView.swift
- SwiftWorkTests/SDKIntegration/ToolRendererRegistryTests.swift (fixed MockToolRenderer concurrency, testEmptyRegistryReturnsNil assertion)

**UNCHANGED (zero regression):**
- SwiftWork/SDKIntegration/EventMapper.swift
- SwiftWork/SDKIntegration/AgentBridge.swift
- SwiftWork/Views/Workspace/Timeline/EventViews/ToolCallView.swift
- SwiftWork/Views/Workspace/Timeline/EventViews/ToolResultView.swift
- SwiftWork/Views/Workspace/Timeline/EventViews/ToolProgressView.swift

### Review Findings

#### Findings Summary

- [x] [Review][Defer] `summaryTitle` JSON parsing duplicated across 4 locations [SwiftWork/Models/UI/ToolContent.swift + ToolRenderers/*] — deferred, pre-existing pattern repeated in this story

- [x] [Review][Patch] Renderers now call self.summaryTitle(content:) instead of content.summaryTitle — Fixed: all 3 renderers updated to use their own protocol method. [SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/*.swift]

- [x] [Review][Patch] SearchToolRenderer toolName corrected from "Search" to "Grep" — Fixed to match SDK tool name. [SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/SearchToolRenderer.swift:4]

- [x] [Review][Patch] FileEditToolRenderer toolName corrected from "FileEdit" to "Edit" — Fixed to match SDK tool name. [SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/FileEditToolRenderer.swift:4]

- [ ] [Review][Patch] MockToolRenderer uses thread-unsafe shared static `_instanceToolName` — `nonisolated(unsafe)` suppresses the compiler warning but does not make it safe. Tests running in parallel could corrupt the toolName. This is a test-only issue but violates strict concurrency spirit. [SwiftWorkTests/SDKIntegration/ToolRendererRegistryTests.swift:409-413]

- [x] [Review][Patch] ToolContent.fromToolResultEvent documentation added — Clarified that returned ToolContent has empty toolName/input and is meant for merging with toolUse event via toolUseId. [SwiftWork/Models/UI/ToolContent.swift:55-67]

- [x] [Review][Patch] `status` var mutability documented — Added comment explaining why status is var while other fields are let. [SwiftWork/Models/UI/ToolContent.swift:17]
