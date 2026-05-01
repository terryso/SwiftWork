# Story 2.3: 事件类型视觉系统

Status: done

## Story

As a 用户,
I want 通过颜色和图标直观区分不同类型的事件和工具,
so that 我可以快速扫描 Timeline 理解 Agent 的执行状态。

## Acceptance Criteria

1. **Given** Timeline 中有多种类型的事件 **When** 渲染事件列表 **Then** 不同事件类型有差异化的视觉样式：用户消息（蓝色左侧气泡）、工具调用（灰色卡片）、工具结果（绿色/红色卡片）、系统事件（浅灰色）、错误（红色高亮）（FR11, FR12）
2. **Given** 工具调用属于不同类型（文件操作、Shell 命令、搜索等） **When** 渲染 ToolCallView **Then** 不同工具类型展示差异化的卡片样式：Bash（终端图标）、FileEdit（文件图标）、Search（搜索图标）（FR19）
3. **Given** 事件包含错误 **When** 渲染错误事件 **Then** 错误卡片使用红色边框和背景高亮，显示错误详情（FR12）

**覆盖的 FRs:** FR11, FR12, FR19
**覆盖的 ARCHs:** Color+Theme.swift

## Tasks / Subtasks

- [x] Task 1: 建立统一主题颜色和图标系统（AC: #1, #2, #3）
  - [x] 1.1 在 `Color+Theme.swift` 中定义事件类型颜色命名空间：`EventStyle` 结构体，包含每种事件类型的背景色、前景色、边框色
  - [x] 1.2 定义事件类型图标映射：`EventIcon` 结构体，包含每种事件类型和工具类型的 SF Symbol 名称
  - [x] 1.3 颜色方案——事件类型：
    - 用户消息 `.userMessage`：蓝色背景 `.blue.opacity(0.15)`，右对齐气泡
    - 助手消息 `.assistant`：无特殊背景，左对齐纯文本
    - 工具调用 `.toolUse`：灰色卡片 `.gray.opacity(0.1)`，左侧工具图标
    - 系统事件 `.system`：浅灰色文字 `.secondary`，小字体
    - 结果 `.result`：bar 背景，状态色图标（绿/红/橙）
    - 错误事件：红色边框 + 红色背景 `.red.opacity(0.08)`，警告图标
    - 思考中 `.thinking`：旋转齿轮 + 灰色文字
  - [x] 1.4 颜色方案——工具类型差异化：
    - Bash：`terminal` 图标，绿色点缀 `.green.opacity(0.1)` 左边条
    - Edit/Write：`pencil.line`/`pencil.and.outline` 图标，橙色点缀 `.orange.opacity(0.1)` 左边条
    - Read：`doc.text` 图标，蓝色点缀 `.blue.opacity(0.1)` 左边条
    - Grep：`text.magnifyingglass` 图标，紫色点缀 `.purple.opacity(0.1)` 左边条
    - 未注册工具：`wrench.and.screwdriver` 图标，无特殊颜色
  - [x] 1.5 确保所有颜色同时适配 Light Mode 和 Dark Mode（使用 `.opacity()` 而非硬编码 RGB）

- [x] Task 2: 更新 ToolCardView 视觉差异化（AC: #1, #2）
  - [x] 2.1 修改 `ToolCardView` 的 `cardBackground` 使用工具类型对应的背景色（通过 `EventStyle` 获取）
  - [x] 2.2 为 `ToolCardView` 添加左侧 3px 彩色边条（`toolAccentColor`），通过 `EventStyle` 获取每种工具类型的颜色
  - [x] 2.3 修改 `toolIcon` 属性使用 `EventIcon` 映射，而非硬编码 switch
  - [x] 2.4 修改图标颜色——当前统一 `.secondary`，改为使用 `EventStyle` 中定义的工具类型对应前景色
  - [x] 2.5 错误状态强化：当 `content.isError == true` 时，卡片背景改为 `.red.opacity(0.08)` + 红色左边条 + 红色状态标签加深

- [x] Task 3: 更新各 EventView 的视觉样式（AC: #1, #3）
  - [x] 3.1 `UserMessageView`：当前已使用蓝色气泡，确认符合设计要求（无需大改）
  - [x] 3.2 `AssistantMessageView`：添加左侧浅色竖线标识（类似 ChatGPT 的小竖条），保持纯文本风格
  - [x] 3.3 `SystemEventView`：确认当前 `.secondary` + 小字体样式符合要求（可能添加系统图标 `info.circle`）
  - [x] 3.4 `ResultView`：确认当前状态色方案符合要求（绿色成功/红色失败/橙色取消），无需大改
  - [x] 3.5 `ThinkingView`：确认当前旋转齿轮 + 灰色文字样式符合要求
  - [x] 3.6 `UnknownEventView`：添加更明显的占位样式——虚线边框 + 问号图标居中

- [x] Task 4: 错误事件视觉强化（AC: #3）
  - [x] 4.1 `SystemEventView` 当 `isError == true` 时：添加红色背景 `.red.opacity(0.08)` + 红色左边条 + `exclamationmark.triangle.fill` 图标
  - [x] 4.2 `ToolCardView` 当 `content.isError == true` 时：红色边框 `RoundedRectangle.stroke(Color.red.opacity(0.3))` 取代当前的淡红背景
  - [x] 4.3 `ResultView` 当 `subtype != "success"` 且 `subtype != "cancelled"` 时：红色边框 + 红色背景加深，确保错误结果足够醒目
  - [x] 4.4 确保 `TimelineView` 中 `systemOrThinking` 的错误分支（`isError == true`）渲染的 `SystemEventView` 传递正确的错误样式

- [x] Task 5: 更新 ToolRenderable 协议添加视觉属性（AC: #2）
  - [x] 5.1 在 `ToolRenderable` 协议中添加可选属性：`static var accentColor: Color { get }`（工具类型主题色）
  - [x] 5.2 在 `ToolRenderable` 协议中添加可选属性：`static var icon: String { get }`（SF Symbol 图标名）
  - [x] 5.3 提供默认实现：`accentColor` 返回 `.gray`，`icon` 返回 `"wrench.and.screwdriver"`
  - [x] 5.4 更新每个现有渲染器的实现：
    - `BashToolRenderer`：`accentColor = .green`，`icon = "terminal"`
    - `FileEditToolRenderer`：`accentColor = .orange`，`icon = "pencil.line"`
    - `SearchToolRenderer`：`accentColor = .purple`，`icon = "text.magnifyingglass"`
    - `ReadToolRenderer`：`accentColor = .blue`，`icon = "doc.text"`
    - `WriteToolRenderer`：`accentColor = .orange`，`icon = "pencil.and.outline"`
  - [x] 5.5 更新 `ToolCardView` 从 `renderer.accentColor` 和 `renderer.icon` 获取视觉属性，替换当前硬编码 switch

- [x] Task 6: 编写测试（AC: 全部）
  - [x] 6.1 测试 `EventStyle` 为每种事件类型返回正确的颜色
  - [x] 6.2 测试 `EventIcon` 为每种事件类型和工具类型返回正确的 SF Symbol 名称
  - [x] 6.3 测试 `ToolRenderable.accentColor` 和 `ToolRenderable.icon` 的默认值
  - [x] 6.4 测试各渲染器的 `accentColor` 和 `icon` 返回预期值
  - [x] 6.5 所有测试通过 `swift test`

## Dev Notes

### 核心目标：从"功能正确"到"视觉可扫描"

Story 2-1 建立了可扩展的 ToolRenderable 架构，Story 2-2 实现了工具卡片配对和展开/折叠体验。本 story 的核心工作是**为现有组件添加视觉差异化**，让用户在扫描 Timeline 时能直觉地识别不同类型的事件和工具，无需逐字阅读。

**当前状态分析（需要改什么）：**

当前所有 EventView 的视觉差异非常有限：
- `UserMessageView`：蓝色气泡（已有差异化，符合要求）
- `AssistantMessageView`：纯文本，无任何视觉标识（需要添加左侧标识线）
- `ToolCardView`：统一灰色卡片 `.gray.opacity(0.1)`，工具图标统一 `.secondary` 灰色（需要按工具类型差异化）
- `SystemEventView`：小字体灰色文字（符合要求，错误态需强化）
- `ResultView`：已有状态色图标（符合要求，错误态需强化）
- `UnknownEventView`：灰色问号图标（需要更明显的占位样式）

### 设计方案：工具类型左边条

参照 OpenWork 的 tool-call.tsx，每种工具类型应有独特颜色标识。SwiftWork 的实现方式是**卡片左侧 3px 彩色边条**，这比 OpenWork 的整体背景着色更克制，但足以让用户快速区分。

```
当前 ToolCardView：
┌──────────────────────────────────────┐
│ [灰色图标] [title]       [completed]│  ← 所有工具统一灰色图标
│           [toolName]                 │
│           [subtitle]                 │
└──────────────────────────────────────┘

目标 ToolCardView（以 Bash 为例）：
┌──┬───────────────────────────────────┐
│绿│ [绿色终端图标] [title]  [completed]│  ← 工具类型对应颜色图标
│色│              [toolName]           │
│边│              [subtitle]           │
│条│                                   │
└──┴───────────────────────────────────┘
  ^ 3px 绿色左边条（Bash=绿, Edit=橙, Read=蓝, Grep=紫）
```

### Color+Theme.swift 设计

当前文件仅有 `Color.themeAccent`。本 story 扩展为结构化的主题系统：

```swift
extension Color {
    // 现有
    static let themeAccent = Color.blue

    // 新增：事件类型视觉样式
    enum EventStyle {
        // 事件类型背景色
        static func background(for eventType: AgentEventType) -> Color { ... }
        // 事件类型前景/图标色
        static func foreground(for eventType: AgentEventType) -> Color { ... }
        // 工具类型强调色（左边条 + 图标）
        static func toolAccent(for toolName: String) -> Color { ... }
    }

    enum EventIcon {
        // 事件类型 SF Symbol
        static func systemImage(for eventType: AgentEventType) -> String { ... }
        // 工具类型 SF Symbol
        static func systemImage(for toolName: String) -> String { ... }
    }
}
```

**使用 Color enum 而非 struct 的原因：** SwiftUI 的 `Color` 是 struct，在其上定义 enum 作为命名空间是项目现有模式（`Color.themeAccent`）。新定义放在同一文件，保持一致。

### ToolRenderable 协议扩展

当前 `ToolRenderable` 协议只有 `toolName`、`body(content:)`、`summaryTitle(content:)`、`subtitle(content:)`。本 story 新增视觉属性：

```swift
protocol ToolRenderable: Sendable {
    static var toolName: String { get }
    static var accentColor: Color { get }  // 新增
    static var icon: String { get }         // 新增
    @ViewBuilder @MainActor
    func body(content: ToolContent) -> any View
    func summaryTitle(content: ToolContent) -> String
    func subtitle(content: ToolContent) -> String?
}

// 默认实现
extension ToolRenderable {
    static var accentColor: Color { .gray }
    static var icon: String { "wrench.and.screwdriver" }
    // ... 现有默认实现不变
}
```

**为什么在协议上加而非只在 Color+Theme 里映射：** 协议属性让每个渲染器自己定义颜色和图标，新增工具时只需在渲染器里写，不需要去 Color+Theme 维护映射表。这保持了 ToolRenderable 的"注册即用"设计原则。

**注意：** `accentColor` 是 `static var`（类属性），因为 ToolRendererRegistry 按 `toolName` 查找渲染器实例，而颜色和图标是类型级别的，与具体实例无关。通过 `type(of: renderer).accentColor` 访问。

**但 `static var` 与 `Sendable` 的兼容性：** `Color` 符合 `Sendable`，所以 `static var accentColor: Color` 在 `Sendable` 协议中是允许的。不需要 `nonisolated(unsafe)`。

### ToolCardView 左边条实现

```swift
// ToolCardView body 中
var body: some View {
    HStack(spacing: 0) {
        // 左边条
        RoundedRectangle(cornerRadius: 2)
            .fill(toolAccentColor)
            .frame(width: 3)

        // 卡片内容
        VStack(alignment: .leading, spacing: 0) {
            titleRow
            // ...
        }
        .padding(8)
    }
    .background(cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .overlay(
        RoundedRectangle(cornerRadius: 8)
            .stroke(borderColor, lineWidth: isSelected ? 2 : (content.isError ? 1 : 0))
    )
}
```

左边条使用 `toolAccentColor`，默认 `.clear`（未注册工具无边条）。错误状态时左边条变红。

### 错误事件视觉层级

错误的视觉突出度必须有层级，不能所有错误都一样红：

| 场景 | 视觉表现 | 程度 |
|------|---------|------|
| ToolCardView isError=true | 红色左边条 + 浅红背景 + 红色状态标签 | 中等醒目 |
| SystemEventView isError=true | 红色文字 + 红色背景 + 警告图标 | 中等醒目 |
| ResultView subtype=error | 红色图标 + 红色状态文字 + bar 背景 | 醒目 |
| SDK 流异常断开 | 红色 SystemEventView | 中等醒目 |

### 前序 Story 关键上下文

**Story 2-2 已完成的内容（必须在此基础上扩展，不重新创建）：**

1. **`ToolCardView.swift`**：已有完整的卡片结构（标题行、展开内容、状态标签、选中态），视觉统一灰色。本 story 在此基础上添加颜色差异化，不改变结构。
2. **`ToolResultContentView.swift`**：已有成功/失败样式、Diff 视图、Copy 按钮。符合要求，本 story 仅微调错误态背景色。
3. **`CopyButton`**：在 ToolCardView.swift 同文件中，无需修改。
4. **5 个 ToolRenderable 渲染器**：Bash、Edit、Grep、Read、Write。每个都实现了 `summaryTitle` 和 `subtitle`，但 `body` 都返回类似的灰色卡片。本 story 不需要修改它们的 `body` 方法（差异化由 ToolCardView 的左边条和图标颜色处理），但需要添加 `accentColor` 和 `icon` 属性。
5. **`ToolRendererRegistry`**：已有注册机制，无需修改。
6. **`TimelineView`**：已有完整的事件分发逻辑（`eventView(for:)`、`toolCardView(for:)`、`systemOrThinking`），无需修改事件分发逻辑。
7. **所有其他 EventView**（UserMessageView、AssistantMessageView、SystemEventView、ResultView、ThinkingView、UnknownEventView、StreamingTextView）：本 story 对这些做视觉微调。

### 现有文件详细状态

**`Color+Theme.swift`（当前仅 3 行）：**
```swift
extension Color {
    static let themeAccent = Color.blue
}
```
本 story 是此文件的主要扩展点。

**`ToolRenderable.swift`（当前 28 行）：**
- 协议定义 4 个成员 + 2 个默认实现
- 本 story 添加 2 个新的 static 属性 + 2 个默认实现

**`ToolCardView.swift`（当前 231 行）：**
- `toolIcon` 属性用硬编码 switch（第 34-43 行）——将被协议属性替代
- `cardBackground` 仅区分 isError 和非 isError（第 196-201 行）——将使用工具类型颜色
- 无左边条——将添加
- 图标统一 `.secondary` 灰色（第 79 行）——将使用工具类型颜色

### 文件变更清单

**UPDATE（更新文件）：**
- `SwiftWork/Utils/Extensions/Color+Theme.swift` — 添加 `EventStyle` 和 `EventIcon` enum 命名空间，定义事件类型和工具类型的颜色/图标映射
- `SwiftWork/SDKIntegration/ToolRenderable.swift` — 添加 `static var accentColor: Color` 和 `static var icon: String` 属性及默认实现
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolCardView.swift` — 添加左边条、使用工具类型颜色替代统一灰色、使用协议属性替代硬编码 switch
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/BashToolRenderer.swift` — 添加 `accentColor = .green`、`icon = "terminal"`
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/FileEditToolRenderer.swift` — 添加 `accentColor = .orange`、`icon = "pencil.line"`
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/SearchToolRenderer.swift` — 添加 `accentColor = .purple`、`icon = "text.magnifyingglass"`
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/ReadToolRenderer.swift` — 添加 `accentColor = .blue`、`icon = "doc.text"`
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/WriteToolRenderer.swift` — 添加 `accentColor = .orange`、`icon = "pencil.and.outline"`
- `SwiftWork/Views/Workspace/Timeline/EventViews/AssistantMessageView.swift` — 添加左侧标识线
- `SwiftWork/Views/Workspace/Timeline/EventViews/SystemEventView.swift` — 错误态视觉强化（红色背景 + 左边条）
- `SwiftWork/Views/Workspace/Timeline/EventViews/ResultView.swift` — 错误态视觉强化（红色边框加深）
- `SwiftWork/Views/Workspace/Timeline/EventViews/UnknownEventView.swift` — 虚线边框占位样式

**UNCHANGED（不修改——零回归风险）：**
- `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` — 事件分发逻辑不变
- `SwiftWork/SDKIntegration/AgentBridge.swift` — 数据层不变
- `SwiftWork/SDKIntegration/EventMapper.swift` — 事件映射不变
- `SwiftWork/SDKIntegration/ToolRendererRegistry.swift` — 注册机制不变
- `SwiftWork/Models/UI/ToolContent.swift` — 数据模型不变
- `SwiftWork/Models/UI/AgentEventType.swift` — 枚举定义不变
- `SwiftWork/Views/Workspace/Timeline/EventViews/UserMessageView.swift` — 已符合要求
- `SwiftWork/Views/Workspace/Timeline/EventViews/ThinkingView.swift` — 已符合要求
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolResultContentView.swift` — 已符合要求

### 性能注意事项

- `EventStyle` 和 `EventIcon` 使用 static 方法/属性，无运行时开销
- 左边条使用 `RoundedRectangle.fill()` + `frame(width: 3)`，渲染成本可忽略
- `ToolCardView` 的 `toolAccentColor` 从 renderer 获取——已在 `init` 时确定，不随滚动重算
- 颜色使用 `.opacity()` 而非创建新 Color 实例，确保 Light/Dark Mode 自动适配
- 所有颜色计算在 View body 中完成，SwiftUI 的差异比较机制避免不必要的重渲染

### 与后续 Story 的关系

- **Story 2-4（Markdown 渲染与代码高亮）**：将使用 `CodeHighlighter`（Splash）渲染代码块，与本 story 的视觉系统无冲突
- **Story 2-5（Timeline 性能优化）**：将引入 LazyVStack + 虚拟化窗口，视觉样式不影响性能优化策略
- **Story 3-4（Inspector Panel）**：将使用本 story 建立的事件选中视觉反馈（蓝色边框），在 Inspector 中展示详情

### Project Structure Notes

- `Color+Theme.swift` 放在 `Utils/Extensions/` — 与项目现有扩展文件组织方式一致
- `ToolRenderable.swift` 协议修改放在 `SDKIntegration/` — 协议定义文件不变位置
- 各渲染器修改放在 `Views/Workspace/Timeline/EventViews/ToolRenderers/` — 渲染器文件不变位置
- 各 EventView 修改放在 `Views/Workspace/Timeline/EventViews/` — 事件视图文件不变位置
- 遵循单 View 文件不超过 300 行规则

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.3: 事件类型视觉系统]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 9: ToolRenderable 协议 + ToolRendererRegistry]
- [Source: _bmad-output/project-context.md#OpenWork 参照 — tool-call.tsx 工具卡片差异化样式]
- [Source: _bmad-output/project-context.md#OpenWork 参照 — ToolCallView 交互模式]
- [Source: _bmad-output/project-context.md#Timeline 渲染策略 — LazyVStack + 虚拟化]
- [Source: _bmad-output/implementation-artifacts/2-2-tool-card-experience.md — 前序 Story 上下文]
- [Source: SwiftWork/Utils/Extensions/Color+Theme.swift — 当前主题文件（3 行）]
- [Source: SwiftWork/SDKIntegration/ToolRenderable.swift — ToolRenderable 协议定义]
- [Source: SwiftWork/Views/Workspace/Timeline/EventViews/ToolCardView.swift — ToolCardView 当前实现]
- [Source: SwiftWork/SDKIntegration/ToolRendererRegistry.swift — Registry 注册/查找]
- [Source: SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/BashToolRenderer.swift — 渲染器示例]
- [Source: SwiftWork/Models/UI/AgentEventType.swift — 事件类型枚举（18 case + unknown）]

## Dev Agent Record

### Agent Model Used

GLM-5.1

### Debug Log References

- Build succeeded after fixing `Color.bar` vs `Material` type mismatch in ResultView (used `AnyShapeStyle` wrapping)

### Completion Notes List

- Implemented `Color.EventStyle` and `Color.EventIcon` enum namespaces in `Color+Theme.swift` with background/foreground/toolAccent colors and SF Symbol icon mappings for all event types and tool types
- Extended `ToolRenderable` protocol with `static var accentColor: Color` and `static var icon: String` properties with default implementations (`.gray` and `"wrench.and.screwdriver"`)
- Updated all 5 renderers (Bash, Edit, Grep, Read, Write) with tool-specific accent colors and icons
- Refactored `ToolCardView` with left accent bar (3px colored bar), tool-type-aware icon coloring, enhanced error styling (red border, red background, red left bar)
- Added left accent line to `AssistantMessageView` for visual identification
- Enhanced `SystemEventView` error state with red background, red left bar, warning icon; added info.circle for normal state
- Enhanced `ResultView` error state with red background and red border
- Updated `UnknownEventView` with dashed border and centered question mark icon
- All colors use `.opacity()` for automatic Light/Dark Mode adaptation
- 49 new unit tests in `EventVisualSystemTests.swift` covering EventStyle colors, EventIcon mappings, ToolRenderable protocol defaults, renderer-specific visual properties, and registry-resolved visual properties
- Full test suite: 456 tests pass, 0 failures (49 new + 407 existing)

### File List

**Modified:**
- SwiftWork/Utils/Extensions/Color+Theme.swift
- SwiftWork/SDKIntegration/ToolRenderable.swift
- SwiftWork/Views/Workspace/Timeline/EventViews/ToolCardView.swift
- SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/BashToolRenderer.swift
- SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/FileEditToolRenderer.swift
- SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/SearchToolRenderer.swift
- SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/ReadToolRenderer.swift
- SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/WriteToolRenderer.swift
- SwiftWork/Views/Workspace/Timeline/EventViews/AssistantMessageView.swift
- SwiftWork/Views/Workspace/Timeline/EventViews/SystemEventView.swift
- SwiftWork/Views/Workspace/Timeline/EventViews/ResultView.swift
- SwiftWork/Views/Workspace/Timeline/EventViews/UnknownEventView.swift

**Created:**
- SwiftWorkTests/Views/Timeline/EventVisualSystemTests.swift

**Sprint Status Updated:**
- _bmad-output/implementation-artifacts/sprint-status.yaml
