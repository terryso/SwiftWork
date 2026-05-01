# Story 2.4: Markdown 渲染与代码高亮

Status: done

## Story

As a 用户,
I want Agent 的文本输出能正确渲染 Markdown 和代码高亮,
so that 我可以舒适地阅读 Agent 的分析和代码建议。

## Acceptance Criteria

1. **Given** Agent 输出包含 Markdown 内容 **When** Timeline 渲染文本事件 **Then** MarkdownRenderer 正确渲染标题（H1-H3）、列表（有序/无序）、粗体/斜体、行内代码（\`code\`）、链接、表格（FR42）
2. **Given** Agent 输出包含代码块（fenced code block） **When** 渲染代码块 **Then** CodeHighlighter 使用 Splash 对 Swift 代码进行语法高亮；非 Swift 代码块（Python、JavaScript、Bash）以等宽字体纯文本显示（FR43）
3. **Given** 事件内容超过一定长度 **When** 渲染长文本 **Then** 默认折叠显示前 N 行，点击"展开"显示完整内容（FR44）

**覆盖的 FRs:** FR42, FR43, FR44
**覆盖的 ARCHs:** swift-markdown, Splash（SPM 依赖已配置）

## Tasks / Subtasks

- [x] Task 1: 实现 MarkdownRenderer 服务（AC: #1）
  - [x] 1.1 创建 `SwiftWork/Services/MarkdownRenderer.swift`
  - [x] 1.2 使用 `import Markdown` 解析 Markdown 文本为 AST（`Document(parsing:)`）
  - [x] 1.3 实现 `MarkupVisitor` 协议遍历 AST 节点，转换为 SwiftUI View 层级
  - [x] 1.4 支持的 Markdown 元素映射：
    - `Heading` (H1-H3) -> `Text` with `.font(.headline/title2/title3)`
    - `Paragraph` -> `Text` block with spacing
    - `Strong` -> `Text.bold()`
    - `Emphasis` -> `Text.italic()`
    - `InlineCode` -> 背景色等宽 `Text`
    - `CodeBlock` -> 委托给 `CodeHighlighter` 处理
    - `UnorderedList` / `OrderedList` -> SwiftUI `VStack` of bullet/numbered items
    - `Link` -> 可点击 `Text` with `.underline()` + accent color
    - `Table` -> SwiftUI `Grid` or `VStack/HStack` layout
    - `BlockQuote` -> 左边条 + 缩进容器
    - `ThematicBreak` -> `Divider()`
  - [x] 1.5 提供 public API: `func renderMarkdown(_ markdown: String) -> AnyView` 或返回自定义 view 类型

- [x] Task 2: 实现 CodeHighlighter 服务（AC: #2）
  - [x] 2.1 创建 `SwiftWork/Services/CodeHighlighter.swift`
  - [x] 2.2 使用 Splash `SyntaxHighlighter<AttributedStringOutputFormat>` 高亮 Swift 代码
  - [x] 2.3 创建适配 Light/Dark Mode 的 `Theme`（基于 `Theme.sundellsColors` 调整 plainTextColor 和背景色以适配两种模式）
  - [x] 2.4 将 Splash 输出的 `NSAttributedString` 转换为 SwiftUI 可用的 `AttributedString` 或 `Text` 序列
  - [x] 2.5 非 Swift 语言（python, javascript, bash, json, etc.）降级为等宽字体纯文本渲染
  - [x] 2.6 提取 code block 的语言标识符（fenced code block 的 info string）用于语言判断
  - [x] 2.7 提供 public API: `func highlight(code: String, language: String?) -> AnyView` 或返回自定义 view 类型

- [x] Task 3: 创建 MarkdownContentView 复合视图（AC: #1, #2）
  - [x] 3.1 创建 `SwiftWork/Views/Workspace/Timeline/EventViews/MarkdownContentView.swift`
  - [x] 3.2 接收 Markdown 字符串，调用 `MarkdownRenderer` 渲染为 SwiftUI 视图
  - [x] 3.3 处理 code block 节点时调用 `CodeHighlighter` 嵌入高亮视图
  - [x] 3.4 支持文本选择（`.textSelection(.enabled)`）
  - [x] 3.5 遵循 300 行文件上限——如果 MarkdownVisitor 逻辑过多，拆分为 `MarkdownVisitor.swift`

- [x] Task 4: 集成到 AssistantMessageView 和 StreamingTextView（AC: #1）
  - [x] 4.1 修改 `AssistantMessageView`：将 `Text(event.content)` 替换为 `MarkdownContentView(markdown: event.content)`
  - [x] 4.2 保持左侧标识线（Story 2-3 已添加的 2px `Color.secondary.opacity(0.3)` 竖线）
  - [x] 4.3 修改 `StreamingTextView`：流式文本阶段仍使用纯 `Text`（避免 Markdown 解析闪烁），仅最终 `assistant` 事件使用 Markdown 渲染
  - [x] 4.4 确保 `.partialMessage` 阶段不触发 Markdown 解析（性能考虑）

- [x] Task 5: 实现长文本折叠/展开（AC: #3）
  - [x] 5.1 在 `MarkdownContentView` 中添加 `@State private var isExpanded = false`
  - [x] 5.2 定义折叠阈值：超过 20 行或 1000 字符时自动折叠
  - [x] 5.3 折叠态：截断显示 + "展开" 按钮（与 `ToolResultContentView` 的 Expand 按钮风格一致）
  - [x] 5.4 展开态：显示完整内容 + "折叠" 按钮
  - [x] 5.5 使用 `withAnimation` 实现平滑过渡

- [x] Task 6: 编写测试（AC: 全部）
  - [x] 6.1 测试 `MarkdownRenderer` 对各 Markdown 元素的解析和渲染
  - [x] 6.2 测试 `CodeHighlighter` 对 Swift 代码生成 `NSAttributedString` 输出（颜色属性非空）
  - [x] 6.3 测试 `CodeHighlighter` 对非 Swift 代码返回纯文本视图
  - [x] 6.4 测试长文本折叠/展开逻辑
  - [x] 6.5 所有测试通过 `swift test`

## Dev Notes

### 核心目标：从"纯文本"到"富文本阅读体验"

Story 2-1 到 2-3 建立了完整的事件视觉系统。本 story 的核心工作是**将 `AssistantMessageView` 和 `ResultView` 中的纯文本 `Text` 替换为 Markdown 富文本渲染**，让用户能舒适阅读 Agent 的分析、代码建议和格式化输出。

**当前状态（需要改什么）：**

1. `AssistantMessageView`：使用 `Text(event.content)` 纯文本显示。Agent 返回的 Markdown 内容（标题、列表、代码块）全部作为纯文本渲染，可读性差。
2. `StreamingTextView`：使用 `Text(text)` 纯文本显示流式输出。这个阶段不需要 Markdown 解析。
3. `ResultView`：使用 `Text(event.content)` 纯文本显示结果摘要。可以受益于 Markdown 渲染。
4. `ToolResultContentView`：使用 `Text` 纯文本显示工具输出。如果工具输出包含 Markdown，也可以渲染（但优先级低于助手消息）。

### 技术方案：swift-markdown + Splash 渲染管线

```
Agent 文本输出 (Markdown String)
    |
    v
MarkdownRenderer (swift-markdown `MarkupVisitor`)
    |
    |  解析为 AST，遍历节点生成 SwiftUI View
    |
    |  遇到 CodeBlock 节点时：
    v
CodeHighlighter (Splash)
    |
    |  Swift 代码 -> SyntaxHighlighter + AttributedStringOutputFormat -> NSAttributedString -> AttributedString
    |  非 Swift 代码 -> 纯等宽 Text
    v
SwiftUI View 层级 (Text, VStack, HStack, etc.)
```

### swift-markdown 关键 API

```swift
import Markdown

// 解析 Markdown 文本为 AST
let document = Document(parsing: markdownString)

// 实现 MarkupVisitor 遍历 AST
struct MarkdownVisitor: MarkupVisitor {
    typealias Result = AnyView  // 或 some View

    mutating func visitHeading(_ heading: Heading) -> Result { ... }
    mutating func visitParagraph(_ paragraph: Paragraph) -> Result { ... }
    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> Result { ... }
    mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> Result { ... }
    mutating func visitOrderedList(_ orderedList: OrderedList) -> Result { ... }
    mutating func visitInlineCode(_ inlineCode: InlineCode) -> Result { ... }
    mutating func visitLink(_ link: Link) -> Result { ... }
    mutating func visitTable(_ table: Table) -> Result { ... }
    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> Result { ... }
    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> Result { ... }
    // ... 其他 visit 方法
}
```

**关键注意事项：**
- `MarkupVisitor` 的 `Result` 关联类型决定了每个 visit 方法返回什么。使用 `AnyView` 是最灵活但性能略差。对于 Timeline 懒加载场景，性能影响可接受。
- `CodeBlock` 有 `language` 属性（String?），对应 fenced code block 的 info string（如 `swift`、`python`）。
- `Heading` 有 `level` 属性（Int），1-6。
- `Table` 在 swift-markdown 中是 GFM 扩展，需要使用 `ParseOptions` 中的选项启用。
- swift-markdown **不提供** SwiftUI 渲染——它只提供 AST。开发者需要自己将 AST 转换为 View。

### Splash 关键 API

```swift
import Splash

// 创建语法高亮器（泛型，输出格式为参数）
let highlighter = SyntaxHighlighter<AttributedStringOutputFormat>(
    format: AttributedStringOutputFormat(theme: theme)
)

// 高亮代码，返回 NSAttributedString
let attributedString = highlighter.highlight(codeString)

// 转换为 SwiftUI 可用的 AttributedString
if let swiftAttributedString = try? AttributedString(attributedString, including: \.uiKit) {
    // macOS 上使用 \.appKit
    Text(swiftAttributedString)
}
```

**关键注意事项：**
- Splash **仅支持 Swift 语法**。内置 `SwiftGrammar()` 是唯一的 Grammar 实现。
- Splash 的 `Color` 类型是 Splash 自定义的（不是 SwiftUI 的 Color）。`Theme` 使用 `Splash.Color`。
- Splash 的 `AttributedStringOutputFormat` 输出 `NSAttributedString`（非 SwiftUI `AttributedString`）。
- macOS 上转换：`try AttributedString(nsAttributedString, including: \.appKit)`。
- `Theme` 的 `font` 属性是 `Splash.Font`，需要用 `Splash.Font(size:)` 或 `Splash.Font(name:size:)` 创建。

### Splash Theme 适配 Light/Dark Mode

Splash 的 `Theme` 使用固定的 RGB 颜色值，不感知 macOS 外观模式。解决方案：

**方案 A（推荐）：** 使用 `Theme.sundellsColors(withFont:)` 作为基础，在创建 `NSAttributedString` 后桥接为 `AttributedString`，让 SwiftUI 管理外观切换。Swift 代码块的背景色使用 SwiftUI `Color` 而非 Splash 背景色。

**方案 B：** 创建两套 Theme（Light/Dark），运行时根据 `@Environment(\.colorScheme)` 切换。更精确但更复杂。

推荐方案 A，因为：
- 代码块的背景色由 SwiftUI 容器控制，不依赖 Splash 的 `backgroundColor`
- Splash 只负责 token 颜色，背景透明即可
- 更简单的实现

### MarkdownContentView 设计

```swift
struct MarkdownContentView: View {
    let markdown: String
    @State private var isExpanded = false

    private static let collapseLineThreshold = 20
    private static let collapseCharThreshold = 1000

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let renderedViews = MarkdownRenderer.render(markdown)
            if shouldCollapse && !isExpanded {
                // 截断渲染
                renderedViews.prefix(collapsedCount)
                expandButton
            } else {
                renderedViews
                if shouldCollapse { collapseButton }
            }
        }
    }
}
```

**注意：** MarkdownContentView 作为独立 View 文件，不超过 300 行。如果 `MarkdownVisitor` 逻辑复杂，将 visitor 拆分到 `MarkdownVisitor.swift`（放在 `Services/` 目录，因为它是纯逻辑转换，不是 View）。

### 前序 Story 关键上下文

**Story 2-3 已完成的内容（必须在此基础上扩展，不重新创建）：**

1. **`Color+Theme.swift`**：已有 `Color.EventStyle` 和 `Color.EventIcon`。Markdown 渲染可以使用这些已有的主题颜色（如行内代码背景色可以参考 `EventStyle` 的风格）。
2. **`AssistantMessageView`**：已有左侧 2px 竖线标识。修改时保留竖线，仅替换 `Text(event.content)` 为 `MarkdownContentView`。
3. **`StreamingTextView`**：保持纯文本 `Text`，不改动。
4. **`ResultView`**：已有状态色和摘要展示。可以将 `Text(event.content)` 改为 `MarkdownContentView`，但保持统计信息行不变。

### 文件变更清单

**NEW（新建文件）：**
- `SwiftWork/Services/MarkdownRenderer.swift` — Markdown AST 解析 + MarkupVisitor 实现
- `SwiftWork/Services/CodeHighlighter.swift` — Splash 语法高亮封装
- `SwiftWork/Views/Workspace/Timeline/EventViews/MarkdownContentView.swift` — Markdown 复合 SwiftUI View

**UPDATE（更新文件）：**
- `SwiftWork/Views/Workspace/Timeline/EventViews/AssistantMessageView.swift` — 替换 `Text` 为 `MarkdownContentView`
- `SwiftWork/Views/Workspace/Timeline/EventViews/ResultView.swift` — 替换 `Text(event.content)` 为 `MarkdownContentView`（可选，如果内容确实是 Markdown）

**UNCHANGED（不修改——零回归风险）：**
- `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` — 事件分发逻辑不变
- `SwiftWork/Views/Workspace/Timeline/EventViews/StreamingTextView.swift` — 流式文本保持纯文本（性能优先）
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolCardView.swift` — 工具卡片不变
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolResultContentView.swift` — 工具输出保持纯文本（工具输出通常是 JSON/日志，不需要 Markdown 渲染）
- `SwiftWork/SDKIntegration/AgentBridge.swift` — 数据层不变
- `SwiftWork/SDKIntegration/EventMapper.swift` — 事件映射不变

### 性能注意事项

- **Markdown 解析不应在每次 SwiftUI body 求值时执行**。应在数据到达时（EventMapper 映射事件时）或首次渲染时解析，缓存结果。可以简单地在 `MarkdownContentView` 中用 `@State` 缓存解析后的 View。
- **Splash 高亮是 CPU 密集操作**。对于长代码块，应在主线程执行但时间应控制在 16ms 以内（单帧）。如果代码超过 100 行，考虑截断高亮。
- **`LazyVStack` 懒加载**：TimelineView 已使用 LazyVStack（Story 1-5），不可见的 MarkdownContentView 不会渲染。
- **流式文本不解析 Markdown**：`.partialMessage` 阶段使用 `StreamingTextView`（纯文本），仅在 `.assistant` 最终事件中使用 `AssistantMessageView`（Markdown 渲染）。这避免了流式阶段的反复解析。
- **`AnyView` 类型擦除开销**：在 LazyVStack 中，SwiftUI 的差异比较仍能正常工作。如果发现性能问题，可以在后续 Story 2-5 中优化为 `@ViewBuilder` 直接返回具体类型。

### 与后续 Story 的关系

- **Story 2-5（Timeline 性能优化）**：将引入虚拟化窗口。Markdown 渲染的性能特征需要被 2-5 考虑。本 story 应确保 Markdown 渲染是惰性的（不预渲染不可见内容）。
- **Story 3-4（Inspector Panel）**：Inspector 将展示原始 Markdown 文本和渲染后的视图对比。本 story 的 `MarkdownRenderer` 可以被 Inspector 复用。

### Splash 只支持 Swift 的限制

Splash 仅内置 Swift 语法高亮。对于其他语言（Python、JavaScript、Bash、JSON 等），本 story 的策略是：

1. **Swift 代码块**：使用 Splash 全功能语法高亮（关键字、类型、字符串、注释等不同颜色）
2. **其他语言代码块**：等宽字体 + 统一颜色（plain text）。这是 MVP 阶段的合理降级。
3. **语言检测**：从 fenced code block 的 info string 提取语言标识符（` ```swift ` 中的 `swift`）。
4. **未来扩展**：如果需要多语言高亮，可以替换为支持更多语言的库（如 TreeSitter），但那不是本 story 的范围。

### Project Structure Notes

- `MarkdownRenderer.swift` 放在 `SwiftWork/Services/` — 渲染服务，与 `CodeHighlighter.swift` 同目录
- `CodeHighlighter.swift` 放在 `SwiftWork/Services/` — 高亮服务
- `MarkdownContentView.swift` 放在 `SwiftWork/Views/Workspace/Timeline/EventViews/` — 与其他 EventView 同目录
- 如果 `MarkdownVisitor` 逻辑超过 100 行，拆分为 `SwiftWork/Services/MarkdownVisitor.swift`
- 遵循单 View 文件不超过 300 行规则
- SPM 依赖已配置（`Package.swift` 中已有 `swift-markdown` 和 `Splash`），无需修改

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.4: Markdown 渲染与代码高亮]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision: 内容渲染管线 — MarkdownRenderer + CodeHighlighter]
- [Source: _bmad-output/project-context.md#swift-markdown + Splash 内容渲染管线]
- [Source: _bmad-output/project-context.md#Splash 集成方式]
- [Source: _bmad-output/project-context.md#代码块需要支持的语言]
- [Source: _bmad-output/implementation-artifacts/2-3-event-visual-system.md — 前序 Story 上下文和视觉系统]
- [Source: Package.swift — SPM 依赖配置（swift-markdown 0.5+, Splash 0.9+）]
- [Source: SwiftWork/Views/Workspace/Timeline/EventViews/AssistantMessageView.swift — 当前纯文本实现]
- [Source: SwiftWork/Views/Workspace/Timeline/EventViews/StreamingTextView.swift — 流式文本（不改动）]
- [Source: SwiftWork/Views/Workspace/Timeline/EventViews/ResultView.swift — 结果视图]
- [Source: Splash/Sources/Splash/Syntax/SyntaxHighlighter.swift — Splash 主 API]
- [Source: Splash/Sources/Splash/Output/AttributedStringOutputFormat.swift — NSAttributedString 输出]
- [Source: Splash/Sources/Splash/Theming/Theme.swift — Theme 结构（font, plainTextColor, tokenColors, backgroundColor）]
- [Source: Splash/Sources/Splash/Theming/Theme+Defaults.swift — 预设主题（sundellsColors, midnight, wwdc17, wwdc18, sunset, presentation）]
- [Source: Splash/Sources/Splash/Tokenizing/TokenType.swift — token 类型（keyword, string, type, call, number, comment, property, dotAccess, preprocessing, custom）]
- [Source: Splash/Sources/Splash/Grammar/Grammar.swift — Grammar 协议（仅内置 SwiftGrammar）]

## Dev Agent Record

### Agent Model Used

GLM-5.1

### Debug Log References

- Build issues resolved: disambiguated `Markdown.Text` vs `SwiftUI.Text`, `Markdown.Link` vs `SwiftUI.Link`, `Markdown.Table` vs `SwiftUI.Table` using fully qualified type names and private typealiases
- Fixed `HTMLBlock.rawHTML` which is non-Optional (String, not String?)
- Fixed `@MainActor` isolation by inlining Splash highlighting logic in MarkdownRenderer visitor
- Fixed `.accentColor` references: use `Color.accentColor` instead of `.accentColor` in ShapeStyle context

### Completion Notes List

- Implemented MarkdownRenderer as enum with `@MainActor` static `render()` method using swift-markdown's `MarkupVisitor` protocol
- MarkdownRenderer handles: H1-H6 headings, paragraphs, bold/italic/strikethrough, inline code, fenced code blocks, ordered/unordered lists, GFM tables, block quotes, thematic breaks, HTML blocks
- Implemented CodeHighlighter as standalone service using Splash for Swift syntax highlighting; non-Swift languages fall back to monospace plain text
- Created MarkdownContentView with collapse/expand support (thresholds: 1000 chars or 20 lines), gradient fade-out overlay, animated transitions
- Integrated MarkdownContentView into AssistantMessageView (replacing `Text(event.content)`) and ResultView
- StreamingTextView left unchanged (pure text for streaming phase)
- All 513 tests pass (39 new tests across 4 test suites: MarkdownRendererTests, CodeHighlighterTests, MarkdownContentViewTests, MarkdownRenderingIntegrationTests)
- Zero regressions in existing 474 tests

### File List

**NEW:**
- SwiftWork/Services/MarkdownRenderer.swift
- SwiftWork/Services/CodeHighlighter.swift
- SwiftWork/Views/Workspace/Timeline/EventViews/MarkdownContentView.swift

**MODIFIED:**
- SwiftWork/Views/Workspace/Timeline/EventViews/AssistantMessageView.swift
- SwiftWork/Views/Workspace/Timeline/EventViews/ResultView.swift
- SwiftWorkTests/Services/MarkdownRendererTests.swift
- SwiftWorkTests/Services/CodeHighlighterTests.swift
- SwiftWorkTests/Views/Timeline/MarkdownContentViewTests.swift
- SwiftWorkTests/Views/Timeline/MarkdownRenderingIntegrationTests.swift

## Change Log

- 2026-05-02: Implemented Story 2-4 — Markdown rendering with swift-markdown MarkupVisitor, Swift syntax highlighting with Splash, code block support with language detection, long text collapse/expand, integration into AssistantMessageView and ResultView. 39 new tests, 0 regressions.
