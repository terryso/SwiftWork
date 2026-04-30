---
project_name: 'swiftwork'
user_name: 'Nick'
date: '2026-05-01'
sections_completed:
  ['technology_stack', 'language_rules', 'framework_rules', 'testing_rules', 'quality_rules', 'workflow_rules', 'anti_patterns']
status: 'complete'
optimized_for_llm: true
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

**Runtime & Language:**
- Swift 6.1+（strict concurrency）
- macOS 14+ (Sonoma) 最低部署目标
- Apple Silicon (ARM64) 原生，Intel 通过 Rosetta 兼容

**UI Framework:**
- SwiftUI（SwiftUI Lifecycle，非 AppKit Lifecycle）
- Observation 框架（`@Observable`，**禁止** `ObservableObject`）
- SwiftData（本地持久化）
- NavigationSplitView（Sidebar + Workspace 三栏布局）

**Core Dependencies (SPM):**
- `open-agent-sdk-swift` — Agent 核心能力，`SDKMessage` 枚举（18 种事件类型）直接驱动 UI
- `swift-markdown` (Apple) — Markdown 渲染
- `Splash` (JohnSundell) — 代码语法高亮
- `Sparkle` 2.x — macOS 自动更新

**Build & Test:**
- Xcode 构建系统 + Swift Package Manager
- XCTest 测试框架
- 支持 `swift build` 和 `swift test`

---

## Critical Implementation Rules

### Language-Specific Rules (Swift)

- **使用 `@Observable`**，不用 `ObservableObject` + `@Published`。macOS 14+ 最低目标允许使用 Observation 框架
- **Swift Concurrency**：所有异步操作使用 `async/await` 和 `AsyncStream`。不使用 Combine、NotificationCenter、delegate 模式
- **`@MainActor`**：`@Observable` 属性必须在 `@MainActor` 上更新，SDK 事件流消费时自动在 MainActor 上更新 events 数组
- **Task 取消**：所有异步操作必须支持 Task 取消（检查 `Task.isCancelled`），AsyncStream subscription 在取消时必须正确清理
- **禁止 force unwrap（`!`）**处理 SDK 返回值
- **Strict concurrency**：遵循 Swift 6.1 并发安全规则，`Sendable` 一致性检查

### Framework-Specific Rules (SwiftUI + SDK)

**事件驱动架构——核心数据流：**
```
SDK AsyncStream<SDKMessage> → AgentBridge → EventMapper(SDKMessage → AgentEvent) → TimelineViewModel.events → SwiftUI 自动重渲染
```

**View 绝不直接引用 SDK 类型。** View 只消费 `AgentEvent`（UI 中间模型），`SDKMessage` 到 `AgentEvent` 的转换发生在 `EventMapper` 中。

**SDKMessage 处理必须使用 exhaustive switch**，包含 `@unknown default` 降级渲染为"未知事件"占位卡片。Swift 编译器保证覆盖完整性。

**ToolRenderable 协议驱动的可扩展渲染：** 每种 Tool 类型注册自己的 SwiftUI 渲染器。新增 Tool 只需新增 `ToolRenderable` 实现，不修改核心 Timeline 逻辑。

**Timeline 渲染策略：**
- 使用 `LazyVStack` 懒加载
- 超 500 事件时启用虚拟化窗口（只渲染可视区域 ± buffer）
- 流式文本（`.partialMessage`）使用 `Text` + 定时器增量更新，避免全量重绘

**SwiftData 模型规则：**
- 每个 Model 必须有 `id: UUID` 主键
- Event 使用 `rawData: Data` 存储 SDK 事件完整 JSON（不展开为强类型字段，因为 18 种事件类型且可能增长）
- 事件 append-only，不修改历史事件
- Session 和 Event 一对多关系，会话删除时级联删除事件
- 大会话（1000+ 事件）通过分页加载

**权限系统：**
- `PermissionHandler`（文件名）= `PermissionEngine`（概念名）评估工具调用权限
- 三种全局模式：autoApprove / manualReview / denyAll
- "Always Allow" 持久化为 `PermissionRule`，"Allow Once" 仅会话级临时授权
- 权限评估发生在 SDK 调用 Tool 之前
- 审计日志记录所有权限决策（工具名、操作内容、用户决策、时间戳）

### Architecture Boundary Rules

**分层依赖方向（单向）：**
```
Views → ViewModels → SDKIntegration → Models
                        ↘ Services ↗
```

| 层 | 可以依赖 | 禁止依赖 |
|---|---|---|
| Views (SwiftUI) | ViewModel, Models/UI | SDKIntegration, SwiftData Models |
| ViewModels (@Observable) | SDKIntegration, Models/UI, Services | SwiftUI View 类型 |
| SDKIntegration | open-agent-sdk-swift, Models/UI, Services | View, ViewModel |
| Models | 无外部依赖 | 任何业务层 |
| Services | 系统框架 | 业务层 |

### Naming Conventions

| 类别 | 规则 | 示例 |
|------|------|------|
| View | PascalCase + `View` 后缀 | `TimelineView`、`ToolCallView` |
| ViewModel | PascalCase + `ViewModel` 后缀 | `SessionViewModel` |
| SwiftData Model | PascalCase 单数，无后缀 | `Session`、`Event` |
| Protocol | PascalCase，能力描述 | `ToolRenderable`、`Inspectable` |
| Enum | PascalCase | `PermissionDecision` |
| Enum case | camelCase | `.approved`、`.toolUse` |
| 函数 | camelCase，动词开头 | `evaluate(permission:)` |
| 文件名 | 与主类型名一致 | `TimelineView.swift` |

### Testing Rules

- 测试文件组织：`SwiftWorkTests/` 下按层级分目录（`ViewModels/`、`SDKIntegration/`、`Services/`、`Models/`）
- 测试文件命名：`<被测类型>Tests.swift`（如 `AgentBridgeTests.swift`）
- SDK 集成测试通过 mock `AgentBridge` 协议实现，不依赖真实 API
- ViewModels 测试验证事件流处理逻辑和状态变更
- 性能相关测试（NFR）通过 Instruments 验证，不作为自动化测试

### Code Quality & Style Rules

- 每个 View 文件只包含一个主 View 类型（私有辅助 View 可嵌套同文件）
- ViewModel 与 View 配对但分文件：`TimelineView.swift` + `TimelineViewModel.swift`
- 单个 View 文件不超过 300 行（超出则拆分子 View）
- 扩展文件单独存放：`Utils/Extensions/String+SensitiveData.swift`
- 不添加多余注释，代码应自文档化
- 统一加载状态枚举：`LoadingState<T>`（idle / loading / loaded / error）
- 统一错误模型：`AppError`（domain / code / message / underlying）

### Security Rules

- **API Key 必须通过 `KeychainManager` 存储**，禁止 UserDefaults、文件、明文
- 网络通信 HTTPS（SDK 内置，无需额外配置）
- Tool Result 中的敏感信息（API Key、密码模式）默认遮罩，用户可手动展开
- 本地数据存储在 App Sandbox 内，使用 macOS 原生文件权限保护

### Error Handling Rules

| 错误类型 | 处理方式 | 用户可见 |
|----------|----------|----------|
| SDK 事件流断开 | 显示连接中断提示，保留已加载事件 | 是 |
| API 限流/网络错误 | Timeline 显示错误卡片，允许重试 | 是 |
| SDK 未知事件类型 | `@unknown default` 渲染为"未知事件"占位卡片 | 是 |
| SwiftData 写入失败 | 静默重试 3 次，失败则丢弃事件（不影响 UI） | 否 |
| UI 渲染异常 | 单个事件卡片错误不影响其他事件 | 部分 |

**核心原则：永远不 crash。** 所有 SDK 调用包裹在 `do/catch` 中。

---

## Project Structure

```
SwiftWork/
├── App/                          # App entry, ContentView, MenuBar
├── Views/
│   ├── Sidebar/                  # SidebarView, SessionRowView
│   ├── Workspace/
│   │   ├── Timeline/             # TimelineView + EventViews/*
│   │   ├── InputBar/             # InputBarView
│   │   └── Inspector/            # InspectorView, DebugView
│   ├── Permission/               # PermissionDialogView, PermissionRulesView
│   ├── Settings/                 # SettingsView, APIKeySettingsView, ModelPickerView
│   └── Onboarding/               # WelcomeView
├── ViewModels/                   # SessionViewModel, SettingsViewModel
├── SDKIntegration/               # AgentBridge, EventMapper, PermissionHandler, ToolRendererRegistry
├── Models/
│   ├── SwiftData/                # Session, Event, PermissionRule, AppConfiguration
│   └── UI/                       # AgentEvent, AgentEventType, ToolContent, PermissionDecision, AppError
├── Services/                     # KeychainManager, MarkdownRenderer, CodeHighlighter, SensitiveDataFilter
└── Utils/                        # Constants, Extensions (Color+Theme, String+SensitiveData, Date+Formatting)
```

---

## Dependency Integration Guide

### open-agent-sdk-swift（核心 SDK）

**本地路径：** `/Users/nick/CascadeProjects/open-agent-sdk-swift`
**GitHub：** https://github.com/terryso/open-agent-sdk-swift

#### SDKMessage 枚举——18 种事件类型（完整列表）

| Case | 关联数据 | UI 映射 | 优先级 |
|------|---------|---------|--------|
| `.partialMessage(PartialData)` | `text`, `parentToolUseId?` | 流式逐字渲染 | MVP |
| `.assistant(AssistantData)` | `text`, `model`, `stopReason`, `error?` | 最终回答气泡 | MVP |
| `.toolUse(ToolUseData)` | `toolName`, `toolUseId`, `input` (JSON String) | ToolCallView 卡片 | MVP |
| `.toolResult(ToolResultData)` | `toolUseId`, `content`, `isError` | ToolResultView（绿/红） | MVP |
| `.toolProgress(ToolProgressData)` | `toolUseId`, `toolName`, `elapsedTimeSeconds?` | 进度指示器 + 计时 | MVP |
| `.result(ResultData)` | `subtype`, `text`, `usage?`, `numTurns`, `durationMs`, `totalCostUsd`, `costBreakdown`, `errors?` | 结果摘要卡片 | MVP |
| `.userMessage(UserMessageData)` | `message`, `uuid?`, `sessionId?` | 用户消息气泡 | MVP |
| `.system(SystemData)` | `subtype`(.init/.status/.rateLimit 等), `message`, `sessionId?`, `tools?`, `model?` | 系统状态提示 | MVP |
| `.hookStarted(HookStartedData)` | `hookId`, `hookName`, `hookEvent` | Hook 执行卡片 | Growth |
| `.hookProgress(HookProgressData)` | `hookId`, `hookName`, `stdout?`, `stderr?` | Hook 实时输出 | Growth |
| `.hookResponse(HookResponseData)` | `hookId`, `hookName`, `output?`, `exitCode?` | Hook 结果卡片 | Growth |
| `.taskStarted(TaskStartedData)` | `taskId`, `taskType`, `description` | 子任务卡片 | Growth |
| `.taskProgress(TaskProgressData)` | `taskId`, `taskType`, `usage?` | 子任务进度 | Growth |
| `.authStatus(AuthStatusData)` | `status`, `message` | 认证状态提示 | MVP |
| `.filesPersisted(FilesPersistedData)` | `filePaths` | 文件写入通知 | Growth |
| `.localCommandOutput(LocalCommandOutputData)` | `output`, `command` | 命令输出展示 | Growth |
| `.promptSuggestion(PromptSuggestionData)` | `suggestions` | 建议提示列表 | Growth |
| `.toolUseSummary(ToolUseSummaryData)` | `toolUseCount`, `tools` | 工具使用汇总 | Growth |

**`.result` 的 `Subtype` 枚举：** `.success` | `.errorMaxTurns` | `.errorDuringExecution` | `.errorMaxBudgetUsd` | `.cancelled` | `.errorMaxStructuredOutputRetries`

#### Agent 创建与流式调用

```swift
import OpenAgentSDK

// 创建 Agent
let options = AgentOptions(
    apiKey: keychainManager.getAPIKey(),  // 从 Keychain 读取
    model: "claude-sonnet-4-6",          // 或用户选择的模型
    maxTurns: 10,
    permissionMode: .default,             // 或 .autoApprove / .manualReview
    tools: getAllBaseTools(tier: .core),   // 注册核心工具
    cwd: workspacePath                    // 工作目录
)
let agent = Agent(options: options)

// 流式消费事件
for await message in agent.stream("你的任务描述") {
    let agentEvent = EventMapper.map(message)  // SDKMessage → AgentEvent
    timelineViewModel.events.append(agentEvent)
}
```

**关键 API 注意事项：**
- `agent.stream()` 返回 `AsyncStream<SDKMessage>`，在 `for await` 循环中消费
- `agent.interrupt()` 用于取消正在执行的查询
- `agent.switchModel(_:)` 动态切换模型（运行时生效）
- `agent.setPermissionMode(_:)` 动态切换权限模式
- `agent.setCanUseTool(_:)` 设置自定义权限回调，优先于 `permissionMode`
- `ToolUseData.input` 是 **JSON String**（不是 Dictionary），需要时用 `JSONSerialization` 解析
- `ResultData` 包含完整的 Token 统计和费用信息（`usage`、`totalCostUsd`、`costBreakdown`）

#### 权限回调集成

```swift
// SwiftWork 应使用 canUseTool 回调拦截工具调用
agent.setCanUseTool { toolName, input in
    // 1. 查询 PermissionHandler 评估权限
    let decision = permissionHandler.evaluate(toolName: toolName, input: input)
    switch decision {
    case .approved:
        return .allow
    case .denied:
        return .deny(reason: "用户拒绝")
    case .requiresApproval:
        // 2. 弹出 PermissionDialogView，等待用户决策
        //    这需要通过 MainActor 在 UI 线程弹窗，并 await 用户操作
        return await presentPermissionDialog(toolName: toolName, input: input)
    }
}
```

**`PermissionMode` 枚举：** `.default` | `.autoApprove` | 其他模式（查看 SDK 源码 `PermissionTypes.swift`）

---

### OpenWork（UI 参照源）

**本地路径：** `/Users/nick/CascadeProjects/openwork`
**GitHub：** https://github.com/different-ai/openwork

**用途：参照交互行为和视觉设计，不参考 React/Web 实现方式。**

#### Story → OpenWork 组件映射

| SwiftWork Story | OpenWork 参照文件 | 参照内容 |
|----------------|-------------------|---------|
| 1.3 会话管理 Sidebar | `domains/session/sidebar/workspace-session-list.tsx` | 会话列表分组（按 workspace）、会话树结构（parentID 层级）、最多预览 6 个会话、折叠/展开 workspace 分组、右键菜单操作 |
| 1.4 消息输入 | `domains/session/surface/composer/composer.tsx` | Composer 布局（文本区 + 底部工具栏）、模型选择器按钮、Agent 选择器、@提及（agent/file）、粘贴文本芯片、发送/停止按钮切换 |
| 1.5 Timeline 事件流 | `domains/session/surface/message-list.tsx` | 消息虚拟化（`@tanstack/react-virtual`）、Step 聚类分组（连续 Tool 调用合并为 cluster）、消息块类型区分（user message vs step cluster） |
| 1.5 Timeline 事件流 | `domains/session/surface/session-surface.tsx` | SessionSurface 整体布局（message-list + composer + status-bar）、Inspector slice 发布、渲染状态管理 |
| 2.2 Tool Card | `domains/session/surface/tool-call.tsx` | ToolCallView 结构：标题行（summary title + toolName + subtitle）+ 状态标签（completed=绿/running=蓝/error=红）+ 可展开详情（Diff 视图 + Tool request JSON + Tool result JSON）+ Copy 按钮 |
| 2.2 Tool Card | `domains/session/surface/tool-call.tsx` | Diff 高亮：`+` 行绿色、`-` 行红色、`@@` 行蓝色（用于 FileEdit 工具结果） |
| 3.1 权限对话框 | `domains/session/chat/permission-approval-modal.tsx` | 权限类型标签映射（bash/edit/read/external_directory/task 等）、详情字段（command/description/cwd/filepath/url/query/diff 等）、三个按钮：Allow Once / Always Allow / Reject |
| 4.1 Debug Panel | `domains/session/surface/debug-panel.tsx` | 固定定位面板（底部右侧浮动）、显示 session 状态信息（ID、transition 状态、消息数量、todo 数量） |
| 滚动行为 | `domains/session/surface/scroll-controller.ts` | 两种模式：follow-latest（自动滚到底部）和 manual-browse（用户手动浏览）、底部 96px gap 判定是否"在底部"、向上滚动 >16px 退出 follow 模式、600ms 手势窗口防误判 |

**参照原则：**
- 参照 OpenWork 的**交互逻辑**（什么时候折叠、什么时候弹窗、滚动行为）
- 参照 OpenWork 的**信息展示层次**（摘要行 → 展开详情 → Inspector 完整数据）
- **不参照** React 组件实现（useState/useEffect/useMemo、CSS class、Web 事件）
- **不参照** OpenWork 的数据获取方式（SSE 事件流 vs SDK AsyncStream）

#### OpenWork 的 ToolCallView 交互模式（SwiftWork 应复刻）

```
┌──────────────────────────────────────┐
│ [summary title]           [completed]│  ← 标题行 + 状态标签
│ [toolName]                           │  ← 工具名（小字）
│ [subtitle / detail]                  │  ← 操作摘要
├──────────────────────────────────────┤  ← 点击展开/折叠
│ Diff (如果有)                        │
│   + 绿色行                           │
│   - 红色行                           │
│   @@ 蓝色行                    [Copy]│
│                                      │
│ TOOL REQUEST                    [Copy]│
│ { JSON input }                       │
│                                      │
│ TOOL RESULT                     [Copy]│
│ { JSON output }                      │
└──────────────────────────────────────┘
```

---

### ChatGPTUI（辅助 UI 参考）

**GitHub：** https://github.com/alfianlosari/ChatGPTUI

**用途：仅参考用户消息气泡和最终回答展示的 SwiftUI 实现模式。**

| 可参考 | 不可参考 |
|--------|---------|
| 用户消息气泡的 SwiftUI 布局（右侧对齐、圆角、背景色） | `ObservableObject` + `@Published` 架构（ChatGPTUI 用旧模式，SwiftWork 必须用 `@Observable`） |
| 流式文本逐字显示的 SwiftUI 实现方式 | ChatGPT 特定的 API 调用逻辑 |
| 消息列表的 ScrollView + LazyVStack 组织 | 聊天界面为中心的设计理念（SwiftWork 是事件驱动，不是聊天） |

**注意：ChatGPTUI 不是 SPM 依赖，不导入其代码。只参考 SwiftUI View 的布局写法。**

---

### swift-markdown + Splash（内容渲染管线）

**渲染架构：**
```
Agent 文本输出 (Markdown String)
    ↓
MarkdownRenderer (swift-markdown)
    ↓ 解析 Markdown AST
AttributedString / 自定义 NSAttributedString
    ↓
CodeHighlighter (Splash)
    ↓ 对 code block 进行语法高亮
SwiftUI Text / AttributedString 展示
```

**swift-markdown 集成方式：**
- 使用 `import Markdown` 解析 Markdown AST
- 通过 `MarkupVisitor` 协议遍历 AST 节点，转换为 SwiftUI View 或 `AttributedString`
- 不使用 `NSAttributedString(markdown:)` 系统方法（功能有限，不支持自定义渲染）
- OpenWork 使用 `react-markdown` + `remark-gfm`（GFM 扩展），SwiftWork 需自行实现 GFM 兼容（表格、删除线、任务列表）

**Splash 集成方式：**
- `import Splash` 使用 `SyntaxHighlighter` 对代码字符串进行高亮
- 输出 `NSAttributedString`，可通过 `AttributedString` 桥接到 SwiftUI
- 需要为每种语言创建配置（或使用 Splash 内置的 Swift 高亮）
- 代码块需要支持的语言：Swift、Python、JavaScript、Bash（其他语言可降级为纯文本）

---

### Sparkle 2.x（自动更新）

- Phase 4 集成，不在 MVP 范围内
- 通过 SPM 集成 `https://github.com/sparkle-project/Sparkle`（2.x 分支）
- 在 `AppDelegate` 中配置 `SUUpdater`
- 需要配置 App 的 `Info.plist` 中的 `SUFeedURL` 指向 GitHub Releases 的 appcast

---

## Critical Don't-Miss Rules

**Anti-Patterns（严格禁止）：**

- ❌ 在 View 中直接调用 SDK（必须通过 ViewModel → AgentBridge）
- ❌ 使用 `ObservableObject` + `@Published`（必须用 `@Observable`）
- ❌ 将 API Key 存储在 UserDefaults 或文件中（必须用 Keychain）
- ❌ 在 SwiftUI View 中执行同步 IO 操作
- ❌ 使用 force unwrap（`!`）处理 SDK 返回值
- ❌ 单个 View 文件超过 300 行（应拆分子 View）
- ❌ View 直接引用 `SDKMessage` 类型（必须通过 `AgentEvent` 中间模型）
- ❌ View 直接做权限判断（必须通过 PermissionHandler）

**关键 Gotchas：**

- `PermissionEngine` 是文档概念名，实现文件名为 `PermissionHandler.swift`
- `SDKMessage` 枚举如果新增 case，Swift 编译器会通过 exhaustive switch 立即报错——这是特性不是 bug
- OpenWork 是 UI 参照源（React + Tauri），SwiftWork 是原生复刻——参考交互行为，不参考实现方式
- ChatGPTUI 仅作为用户消息气泡和最终回答展示的 UI 参考，不作为主 UI 框架
- `Event.rawData` 是 JSON `Data` 类型，不做强类型展开，避免 schema 频繁变更
- `ToolUseData.input` 是 **JSON String**（不是 Dictionary），解析时需要 `JSONSerialization.jsonObject(with:)`
- OpenWork 的 `scroll-controller.ts` 实现了精巧的 follow-latest / manual-browse 双模式——SwiftWork 应在 SwiftUI 中用 `ScrollViewReader` + `onChange` 复刻此行为
- OpenWork 的 `message-list.tsx` 使用 `@tanstack/react-virtual` 虚拟化——SwiftWork 用 `LazyVStack` 实现等价效果
- OpenWork 的 ToolCallView 中 `summarizeStep()` 函数为每种工具生成摘要标题和副标题——SwiftWork 应在 `ToolRenderable` 协议中实现类似逻辑

---

## Phased Development Reference

| Phase | 目标 | 核心 Stories |
|-------|------|-------------|
| Phase 1 (SDK→UI 闭环) | 证明 SDK 事件能驱动 UI | Story 1.1-1.6 |
| Phase 2 (Agent 可视化) | Tool Card 结构化体验 | Story 2.1-2.5 |
| Phase 3 (产品关键能力) | 权限、Inspector、PlanView | Story 3.1-3.5 |
| Phase 4 (差异化打磨) | Debug Panel、设置、外壳 | Story 4.1-4.4 |

---

Last Updated: 2026-05-01
