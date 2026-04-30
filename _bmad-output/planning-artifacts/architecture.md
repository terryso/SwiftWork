---
stepsCompleted:
  - step-01-init
  - step-02-context
  - step-03-starter
  - step-04-decisions
  - step-05-patterns
  - step-06-structure
  - step-07-validation
  - step-08-complete
workflowType: 'architecture'
lastStep: 8
status: 'complete'
completedAt: '2026-05-01'
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/prd-validation-report.md
  - docs/openwork-design.md
workflowType: 'architecture'
project_name: 'swiftwork'
user_name: 'Nick'
date: '2026-05-01'
---

# Architecture Decision Document - SwiftWork

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**

48 条 FR 分布在 8 个能力域中：

| 能力域 | FR 数量 | 架构影响 |
|--------|---------|----------|
| 会话管理 (Session Management) | 6 | 数据层设计、SwiftData 模型、窗口状态恢复 |
| 事件流可视化 (Event Visualization) | 7 | 核心架构驱动——事件驱动的 UI 渲染管线 |
| 工具执行可视化 (Tool Execution) | 6 | `ToolRenderable` 协议、可扩展卡片系统 |
| 权限与审批 (Permission) | 7 | 权限引擎、审计日志、UI 弹窗系统 |
| Agent 配置与交互 | 6 | SDK 集成层、设置持久化 |
| 执行计划可视化 | 3 | PlanView 组件、步骤状态机 |
| 调试与检查 | 5 | Debug Panel、Inspector、原始数据访问 |
| 内容渲染 | 3 | Markdown 渲染、代码高亮、虚拟化 |
| 应用外壳 | 5 | macOS 系统集成、菜单栏、Dock Badge |

**Non-Functional Requirements:**

21 条 NFR 跨 5 个分类，以下为对架构决策影响最大的：

| NFR 分类 | 关键指标 | 架构影响 |
|----------|----------|----------|
| Performance | 冷启动 < 2s、事件延迟 < 100ms、60fps 滚动 | 虚拟化滚动、异步渲染管线、懒加载 |
| Security | Keychain 存储、HTTPS、审计日志 | KeychainManager、安全存储抽象层 |
| Reliability | 异常不崩溃、8h+ 无泄漏、1000+ 事件正常 | 错误边界、内存管理策略、AsyncStream 生命周期 |
| Compatibility | macOS 14+、ARM64 原生、深色模式 | 最低部署目标、Appearance 适配 |
| Data Persistence | 会话持久化、配置持久化、窗口状态 | SwiftData schema、UserDefaults + Keychain |

**Scale & Complexity:**

- Primary domain: macOS 原生桌面应用（SwiftUI）
- Complexity level: Medium
- 预估架构组件数: ~25-30 个核心类型（Views、ViewModels、Models、Services）

### Technical Constraints & Dependencies

**硬约束：**

1. **macOS 14+ 最低部署目标** — 必须使用 `@Observable`（非 `ObservableObject`）、`NavigationSplitView`、SwiftData
2. **open-agent-sdk-swift 作为核心依赖** — SDK 的 `SDKMessage` 枚举（18 种事件类型）直接驱动 UI 组件映射
3. **Swift Package Manager** — 不支持 CocoaPods/Carthage
4. **本地优先架构** — 无后端服务，所有数据存储在客户端
5. **单开发者项目** — 架构复杂度必须在个人可维护范围内

**关键依赖：**

| 依赖 | 角色 | 架构影响 |
|------|------|----------|
| open-agent-sdk-swift | Agent 核心能力 | SDK Integration Layer 的核心抽象对象 |
| swift-markdown | Markdown 渲染 | 内容渲染管线 |
| Splash | 代码语法高亮 | 内容渲染管线 |
| Sparkle | 自动更新 | 应用生命周期管理 |
| SwiftData | 本地持久化 | Data Layer 的基础 |

### Cross-Cutting Concerns Identified

1. **事件驱动架构** — 整个 UI 以 `SDKMessage` 事件流为核心，所有组件围绕事件消费/渲染设计
2. **权限安全边界** — 权限决策影响 SDK 调用链和 UI 弹窗，是横切关注点
3. **性能虚拟化** — 大量事件场景下的内存和渲染优化影响 Timeline、Debug Panel 等多个组件
4. **错误恢复与降级** — SDK 事件模型变更、网络异常、数据损坏等场景的统一错误处理
5. **状态持久化** — 会话状态、窗口状态、配置状态需要一致的持久化策略
6. **流式数据管理** — `AsyncStream` 的生命周期管理贯穿 SDK 集成层和 ViewModel 层

## Starter Template Evaluation

### Primary Technology Domain

macOS 原生桌面应用（SwiftUI），基于项目需求分析确定。不使用 Web 跨平台框架，而是 Xcode + SwiftUI 原生方案。

### Starter Options Considered

SwiftWork 作为 macOS 原生 SwiftUI 应用，不存在传统 Web 意义上的"starter template"（如 Next.js、Vite）。评估的选项包括：

| 选项 | 描述 | 决定 |
|------|------|------|
| Xcode macOS App 模板 (SwiftUI Lifecycle) | Apple 官方模板，最简结构 | ✅ 采用 |
| Tauri + React (OpenWork 方案) | 跨平台 Web 方案 | ❌ 排除——PRD 明确要求原生 |
| Electron | Web 桌面方案 | ❌ 排除——性能和体验不符合要求 |

### Selected Starter: Xcode macOS App (SwiftUI Lifecycle)

**选择理由：**
- PRD 明确要求 macOS 原生性能和系统集成
- SwiftUI Lifecycle（非 AppKit Lifecycle）与 `@Observable`、SwiftData 配合最佳
- 单开发者项目，Xcode 原生模板的复杂度最低
- 所有依赖均支持 SPM 集成

**初始化方式：**

1. 在 Xcode 中创建新的 macOS App 项目，选择 SwiftUI 生命周期
2. 设置最低部署目标为 macOS 14 (Sonoma)
3. 通过 SPM 添加以下依赖：

```
Package Dependencies:
- open-agent-sdk-swift (https://github.com/terryso/open-agent-sdk-swift)
- swift-markdown (https://github.com/apple/swift-markdown)
- Splash (https://github.com/JohnSundell/Splash)
- Sparkle (https://github.com/sparkle-project/Sparkle) — 2.x (当前最新 2.9.1)
```

**Architectural Decisions Provided by Starter:**

**Language & Runtime:**
- Swift 6.1+，利用 strict concurrency
- SwiftUI + Observation 框架（`@Observable`，非 `@ObservableObject`）
- Swift Concurrency（async/await、AsyncStream）

**Styling Solution:**
- SwiftUI 原生样式系统
- 遵循 macOS Human Interface Guidelines
- 自动适配深色/浅色模式（NFR17）

**Build Tooling:**
- Xcode 构建系统
- Swift Package Manager 依赖管理
- 支持命令行构建：`swift build`、`swift test`

**Testing Framework:**
- XCTest（Swift 原生测试框架）
- SwiftUI View 测试通过 `@Testable` 导入

**Code Organization:**
- 采用分层架构（App → ViewModel → SDK Integration → Data）
- 按 Feature 分组的文件结构

**Development Experience:**
- Xcode Previews 用于 SwiftUI 实时预览
- Instruments 用于性能分析（NFR 验证）
- Accessibility Inspector 用于可访问性检查

**Note:** 项目初始化应该是第一个实施 Story。

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
1. 事件驱动架构模式 — SDKMessage → UI 映射机制
2. 数据持久化方案 — SwiftData schema 和事件存储策略
3. 状态管理方案 — Observation 框架 + 事件流绑定
4. SDK 集成层抽象 — AgentBridge 协议设计

**Important Decisions (Shape Architecture):**
5. 权限系统架构 — 权限引擎 + 审计日志
6. 内容渲染管线 — Markdown + 代码高亮的集成方式
7. 性能优化策略 — 虚拟化滚动和懒加载方案

**Deferred Decisions (Post-MVP):**
8. 自动更新集成（Sparkle）— Phase 4 实现
9. 多 Agent 可视化 — Growth 阶段
10. 会话搜索（Spotlight）— Vision 阶段

### Data Architecture

**Decision 1: SwiftData 作为持久化引擎**

| 维度 | 决策 |
|------|------|
| 方案 | SwiftData（系统框架） |
| 版本 | macOS 14+ 内置 |
| 理由 | PRD 约束 macOS 14+，SwiftData 是 Apple 官方推荐的现代数据持久化方案，与 SwiftUI 深度集成 |
| 替代方案 | Core Data（过重）、SQLite.swift（非系统框架）、UserDefaults（仅适合简单配置） |
| 影响 | Data Layer 全部组件 |

**Decision 2: 数据模型设计**

```
SwiftData Models:
├── Session
│   ├── id: UUID
│   ├── title: String
│   ├── createdAt: Date
│   ├── updatedAt: Date
│   ├── workspacePath: String?
│   └── events: [Event] (relationship)
├── Event
│   ├── id: UUID
│   ├── sessionID: UUID
│   ├── eventType: String (SDKMessage case name)
│   ├── rawData: Data (JSON)
│   ├── timestamp: Date
│   └── order: Int
├── PermissionRule
│   ├── id: UUID
│   ├── toolName: String
│   ├── pattern: String
│   ├── decision: String (allow/deny)
│   └── createdAt: Date
└── AppConfiguration
    ├── id: UUID
    ├── key: String
    ├── value: Data
    └── updatedAt: Date
```

**关键设计决策：**
- Event 使用 `rawData: Data` 存储 SDK 事件的完整 JSON，而非展开为强类型字段。理由：SDK 事件类型有 18 种且可能增长，展开字段会导致 schema 频繁变更
- Session 和 Event 为一对多关系，支持高效查询
- AppConfiguration 为 KV 结构，存储非敏感配置（API Key 存 Keychain）

**Decision 3: 事件存储策略**

- 事件按 `order` 顺序存储，支持时间线重放
- 事件只追加（append-only），不修改历史事件
- 会话删除时级联删除所有关联事件
- 大会话（1000+ 事件）通过分页加载，不一次性载入内存

### Authentication & Security

**Decision 4: 安全架构**

| 维度 | 决策 |
|------|------|
| API Key 存储 | macOS Keychain（通过 `Security` framework） |
| 网络通信 | HTTPS（SDK 内置，无需额外配置） |
| 本地数据 | SwiftData 默认存储在 App Sandbox 内 |
| 审计日志 | PermissionAuditEntry（内存 + 可选持久化） |
| 敏感信息遮罩 | UI 层正则匹配过滤（API Key、密码模式） |

**Decision 5: 权限引擎设计**

```
PermissionEngine
├── globalMode: PermissionMode (autoApprove / manualReview / denyAll)
├── rules: [PermissionRule] (持久化)
├── sessionOverrides: [ToolName: Decision] (会话级临时授权)
└── func evaluate(toolCall: ToolCall) -> PermissionDecision

PermissionDecision:
├── .approved (自动通过)
├── .denied (自动拒绝)
├── .requiresApproval(toolName, description, parameters) (弹窗请求)
└── .alwaysAllowed(toolName, pattern) (已记住的授权)
```

- 权限评估发生在 SDK 调用 Tool 之前（通过 SDK Hook 机制）
- "Always Allow" 持久化为 PermissionRule
- "Allow Once" 仅在当前会话生效（sessionOverrides）
- 审计日志记录所有权限决策

### API & Communication Patterns

**Decision 6: 事件流通信架构**

```
SDK (open-agent-sdk-swift)
    │
    │  AsyncStream<SDKMessage>
    ▼
AgentBridge (SDK Integration Layer)
    │
    │  转换 + 增强
    ▼
TimelineViewModel (ViewModel Layer)
    │
    │  @Observable 属性变更
    ▼
TimelineView (SwiftUI)
```

**关键模式：**
- SDK 通过 `AsyncStream<SDKMessage>` 推送事件
- `AgentBridge` 封装 Agent 创建/配置，暴露 `EventPublisher`
- `TimelineViewModel` 消费事件流，维护 `[AgentEvent]` 数组
- SwiftUI 通过 `@Observable` 自动响应数组变更

**Decision 7: 错误处理策略**

| 错误类型 | 处理方式 | 用户可见 |
|----------|----------|----------|
| SDK 事件流断开 | 显示连接中断提示，保留已加载事件 | 是 |
| API 限流/网络错误 | 在 Timeline 显示错误卡片，允许重试 | 是 |
| SDK 未知事件类型 | 渲染为"未知事件"卡片（`@unknown default`） | 是 |
| SwiftData 写入失败 | 静默重试 3 次，失败则丢弃事件（不影响 UI） | 否 |
| UI 渲染异常 | 单个事件卡片错误不影响其他事件渲染 | 部分 |

### Frontend Architecture

**Decision 8: 状态管理 — Observation 框架**

| 维度 | 决策 |
|------|------|
| 方案 | `@Observable`（Swift Observation 框架） |
| 替代方案 | `ObservableObject` + `@Published`（旧模式，不推荐） |
| 理由 | macOS 14+ 最低目标允许使用 Observation，性能更优（自动追踪属性变更） |
| 影响 | 所有 ViewModel |

**Decision 9: 组件架构 — 事件驱动 + 协议扩展**

```
核心组件协议:
├── protocol ToolRenderable
│   ├── var toolName: String { get }
│   ├── func body(content: ToolContent) -> some View
│   └── 注册机制：ToolRendererRegistry
├── protocol EventViewMapper
│   ├── func view(for: SDKMessage) -> any View
│   └── switch-case 穷举，编译时保证完整性
└── protocol Inspectable
    ├── var summary: String { get }
    ├── var detail: AnyView { get }
    └── var rawJSON: String { get }
```

**Decision 10: Timeline 渲染策略**

- 使用 `LazyVStack` 实现懒加载
- 超过 500 个事件时启用虚拟化窗口（只渲染可视区域 ± buffer）
- 事件卡片使用 `@ViewBuilder` + switch/case 映射
- 流式文本（`.partialMessage`）使用 `Text` + 定时器增量更新，避免全量重绘

### Infrastructure & Deployment

**Decision 11: 项目结构**

```
SwiftWork/
├── App/
│   ├── SwiftWorkApp.swift (App entry)
│   ├── ContentView.swift (Root layout)
│   └── MenuBar.swift
├── Views/
│   ├── Sidebar/
│   │   └── SidebarView.swift
│   ├── Workspace/
│   │   ├── WorkspaceView.swift
│   │   ├── Timeline/
│   │   │   ├── TimelineView.swift
│   │   │   ├── EventViews/
│   │   │   │   ├── UserMessageView.swift
│   │   │   │   ├── ThinkingView.swift
│   │   │   │   ├── ToolCallView.swift
│   │   │   │   ├── ToolResultView.swift
│   │   │   │   ├── PlanView.swift
│   │   │   │   └── ResultView.swift
│   │   │   └── TimelineViewModel.swift
│   │   ├── InputBar/
│   │   │   ├── InputBarView.swift
│   │   │   └── InputBarViewModel.swift
│   │   └── Inspector/
│   │       ├── InspectorView.swift
│   │       └── DebugView.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── PermissionRulesView.swift
│   └── Onboarding/
│       └── WelcomeView.swift
├── ViewModels/
│   ├── SessionViewModel.swift
│   └── SettingsViewModel.swift
├── SDKIntegration/
│   ├── AgentBridge.swift
│   ├── EventMapper.swift
│   ├── PermissionHandler.swift
│   └── ToolRendererRegistry.swift
├── Models/
│   ├── SwiftData/
│   │   ├── Session.swift
│   │   ├── Event.swift
│   │   ├── PermissionRule.swift
│   │   └── AppConfiguration.swift
│   └── UI/
│       ├── AgentEvent.swift
│       ├── ToolContent.swift
│       └── PermissionDecision.swift
├── Services/
│   ├── KeychainManager.swift
│   ├── MarkdownRenderer.swift
│   └── SensitiveDataFilter.swift
└── Utils/
    ├── Constants.swift
    └── Extensions/
```

**Decision 12: 部署与更新**

| 维度 | 决策 |
|------|------|
| 分发方式 | GitHub Releases + DMG |
| 自动更新 | Sparkle 2.x（当前最新 2.9.1） |
| 版本策略 | SemVer（语义化版本） |
| CI/CD | GitHub Actions（Xcode build + test + archive） |
| 最低部署 | macOS 14 Sonoma |

### Decision Impact Analysis

**Implementation Sequence:**

1. **项目初始化** — Xcode 项目 + SPM 依赖
2. **Data Layer** — SwiftData 模型定义（Session、Event、PermissionRule、AppConfiguration）
3. **SDK Integration Layer** — AgentBridge、EventMapper、PermissionHandler
4. **核心 UI 组件** — TimelineView、事件视图映射
5. **辅助 UI** — Sidebar、InputBar、Inspector
6. **权限系统** — PermissionEngine、PermissionView
7. **内容渲染** — MarkdownRenderer、代码高亮
8. **应用外壳** — 菜单栏、快捷键、设置页面

**Cross-Component Dependencies:**

- SDKMessage 枚举 → EventMapper → TimelineView（核心数据流）
- PermissionEngine → AgentBridge → PermissionView（权限拦截）
- SwiftData Models → SessionViewModel → SidebarView（数据持久化）
- KeychainManager → SettingsViewModel → SettingsView（安全存储）
- ToolRendererRegistry → ToolCallView → InspectorView（工具可视化）

## Implementation Patterns & Consistency Rules

### Pattern Categories Defined

**Critical Conflict Points Identified:** 6 个领域——AI Agent 在不同 Story 实现时可能做出不一致选择

### Naming Patterns

**Swift 类型命名：**

| 类别 | 规则 | 示例 |
|------|------|------|
| View 类型 | PascalCase + View 后缀 | `TimelineView`、`ToolCallView` |
| ViewModel 类型 | PascalCase + ViewModel 后缀 | `SessionViewModel`、`TimelineViewModel` |
| Model 类型（SwiftData） | PascalCase，无后缀 | `Session`、`Event`、`PermissionRule` |
| Protocol | PascalCase，能力描述 | `ToolRenderable`、`Inspectable`、`EventViewMapper` |
| Enum（UI 状态） | PascalCase | `PermissionDecision`、`AgentEventType` |
| Enum case | camelCase | `.approved`、`.requiresApproval`、`.toolUse` |
| 函数 | camelCase，动词开头 | `evaluate(permission:)`、`render(event:)` |
| 常量 | PascalCase（Swift 风格）或 camelCase（局部） | `Constants.maxEventsInMemory` |
| 文件名 | 与主类型名一致 | `TimelineView.swift`、`SessionViewModel.swift` |

**SwiftData 命名：**

| 类别 | 规则 | 示例 |
|------|------|------|
| Model 类型 | PascalCase 单数 | `Session`（非 `Sessions`） |
| 属性 | camelCase | `createdAt`、`workspacePath` |
| Relationship | camelCase 复数 | `events: [Event]` |
| ID 属性 | 统一用 `id: UUID` | 不使用 `sessionID` 作为主键 |

### Structure Patterns

**项目组织规则：**

1. **按层级分目录**：Views/、ViewModels/、SDKIntegration/、Models/、Services/、Utils/
2. **Views 内按功能分子目录**：Sidebar/、Workspace/、Settings/、Onboarding/
3. **每个 View 文件只包含一个主 View 类型**（辅助私有 View 可嵌套在同一文件）
4. **ViewModel 与 View 配对但分文件**：`TimelineView.swift` + `TimelineViewModel.swift`
5. **扩展文件单独存放**：`Utils/Extensions/String+SensitiveData.swift`

**测试文件组织：**

```
SwiftWorkTests/
├── ViewModels/
│   ├── SessionViewModelTests.swift
│   └── TimelineViewModelTests.swift
├── SDKIntegration/
│   ├── AgentBridgeTests.swift
│   ├── EventMapperTests.swift
│   └── PermissionHandlerTests.swift
├── Services/
│   └── KeychainManagerTests.swift
└── Models/
    └── PermissionRuleTests.swift
```

### Format Patterns

**事件数据格式：**

```swift
// UI 层事件模型（统一中间层）
struct AgentEvent: Identifiable {
    let id: UUID
    let type: AgentEventType          // 枚举
    let content: String               // 主要文本内容
    let metadata: [String: any Sendable]  // 附加元数据
    let timestamp: Date
    let rawSDKMessage: SDKMessage?     // 原始 SDK 消息（Inspector 用）
}
```

**SwiftData 存储格式：**

- 事件的 `eventType` 存储为 `String`（SDKMessage case 的 rawValue）
- 事件的 `rawData` 存储为 `Data`（JSON 编码的完整 SDK 消息）
- 时间统一使用 `Date` 类型，不使用时间戳整数

**错误格式：**

```swift
struct AppError: LocalizedError {
    let domain: ErrorDomain        // .sdk / .network / .data / .ui
    let code: String               // 机器可读错误码
    let message: String            // 用户可见描述
    let underlying: Error?         // 原始错误
}
```

### Communication Patterns

**事件流模式：**

```swift
// AgentBridge 暴露的事件流接口
@Observable
final class AgentBridge {
    var events: [AgentEvent] = []           // UI 消费的事件列表
    var isRunning: Bool = false             // Agent 执行状态
    var currentTask: Task<Void, Never>?     // 可取消的任务引用

    func startAgent(prompt: String) async { ... }
    func cancelAgent() { ... }
}
```

**状态更新规则：**

1. `@Observable` 属性在 `@MainActor` 上更新
2. SDK 事件通过 `AsyncStream` 消费，自动在 MainActor 上更新 `events` 数组
3. 不使用 Combine、NotificationCenter、或 delegate 模式
4. `Task` 取消时必须正确清理 AsyncStream subscription

### Process Patterns

**错误处理规则：**

1. **永远不 crash**：所有 SDK 调用包裹在 `do/catch` 中
2. **用户可见错误**：在 Timeline 渲染为红色错误卡片
3. **静默错误**：数据持久化失败时重试 3 次，之后 log 并继续
4. **未知 SDK 事件**：`@unknown default` 渲染为"未知事件"占位卡片

**加载状态规则：**

```swift
// 统一加载状态枚举
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(AppError)
}
```

**SwiftUI View 模式：**

```swift
// 标准 View 结构模板
struct FeatureView: View {
    @State private var viewModel = FeatureViewModel()

    var body: some View {
        // 使用 switch on loading state
        switch viewModel.state {
        case .idle: EmptyView()
        case .loading: ProgressView()
        case .loaded(let data): // 渲染数据
        case .error(let error): ErrorBanner(error: error)
        }
    }
}
```

### Enforcement Guidelines

**所有 AI Agent 必须遵守：**

1. **新建 View 必须使用 `@Observable` ViewModel**，不使用 `ObservableObject`
2. **新建 SwiftData Model 必须有 `id: UUID` 主键**
3. **SDKMessage 处理必须使用 exhaustive switch**，包含 `@unknown default`
4. **所有异步操作必须支持 Task 取消**（检查 `Task.isCancelled`）
5. **UI 事件必须通过 AgentEvent 中间模型**，View 不直接引用 SDKMessage
6. **API Key 相关操作必须通过 KeychainManager**，禁止明文存储
7. **权限评估必须通过 PermissionEngine**，View 不直接做权限判断

**Anti-Patterns（禁止）：**

- ❌ 在 View 中直接调用 SDK
- ❌ 使用 `ObservableObject` + `@Published`
- ❌ 将 API Key 存储在 UserDefaults 或文件中
- ❌ 在 SwiftUI View 中执行同步 IO 操作
- ❌ 使用 force unwrap（`!`）处理 SDK 返回值
- ❌ 单个 View 文件超过 300 行（应拆分子 View）

## Project Structure & Boundaries

### Complete Project Directory Structure

```
SwiftWork/
├── SwiftWork.xcodeproj
├── SwiftWork/
│   ├── App/
│   │   ├── SwiftWorkApp.swift              # @main App entry
│   │   ├── ContentView.swift               # Root NavigationSplitView
│   │   └── AppDelegate.swift               # Menu bar, Dock badge, 窗口状态
│   ├── Views/
│   │   ├── Sidebar/
│   │   │   ├── SidebarView.swift           # 会话列表
│   │   │   ├── SessionRowView.swift        # 单行会话
│   │   │   └── SidebarToolbar.swift        # 新建/搜索按钮
│   │   ├── Workspace/
│   │   │   ├── WorkspaceView.swift         # 主工作区容器
│   │   │   ├── Timeline/
│   │   │   │   ├── TimelineView.swift      # 事件流核心视图
│   │   │   │   ├── TimelineViewModel.swift # 事件流状态管理
│   │   │   │   └── EventViews/
│   │   │   │       ├── UserMessageView.swift
│   │   │   │       ├── ThinkingView.swift
│   │   │   │       ├── AssistantMessageView.swift
│   │   │   │       ├── ToolCallView.swift
│   │   │   │       ├── ToolResultView.swift
│   │   │   │       ├── ToolProgressView.swift
│   │   │   │       ├── PlanView.swift
│   │   │   │       ├── ResultView.swift
│   │   │   │       └── UnknownEventView.swift
│   │   │   ├── InputBar/
│   │   │   │   ├── InputBarView.swift      # 输入栏
│   │   │   │   └── InputBarViewModel.swift
│   │   │   └── Inspector/
│   │   │       ├── InspectorView.swift     # 右侧详情面板
│   │   │       └── DebugView.swift         # Debug Panel
│   │   ├── Permission/
│   │   │   ├── PermissionDialogView.swift  # 权限审批弹窗
│   │   │   └── PermissionRulesView.swift   # 权限规则列表
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift          # 设置页面
│   │   │   ├── APIKeySettingsView.swift    # API Key 管理
│   │   │   └── ModelPickerView.swift       # 模型选择
│   │   └── Onboarding/
│   │       └── WelcomeView.swift           # 首次启动引导
│   ├── ViewModels/
│   │   ├── SessionViewModel.swift          # 会话 CRUD + 切换
│   │   └── SettingsViewModel.swift         # 配置管理
│   ├── SDKIntegration/
│   │   ├── AgentBridge.swift               # Agent 创建、配置、事件流
│   │   ├── EventMapper.swift               # SDKMessage → AgentEvent
│   │   ├── PermissionHandler.swift         # 权限评估 + 审计
│   │   └── ToolRendererRegistry.swift      # ToolRenderable 注册表
│   ├── Models/
│   │   ├── SwiftData/
│   │   │   ├── Session.swift               # 会话持久化模型
│   │   │   ├── Event.swift                 # 事件持久化模型
│   │   │   ├── PermissionRule.swift        # 权限规则模型
│   │   │   └── AppConfiguration.swift      # KV 配置模型
│   │   └── UI/
│   │       ├── AgentEvent.swift            # UI 事件中间模型
│   │       ├── AgentEventType.swift        # 事件类型枚举
│   │       ├── ToolContent.swift           # 工具调用数据
│   │       ├── PermissionDecision.swift    # 权限决策枚举
│   │       └── AppError.swift              # 统一错误模型
│   ├── Services/
│   │   ├── KeychainManager.swift           # Keychain 存取
│   │   ├── MarkdownRenderer.swift          # Markdown → AttributedString
│   │   ├── CodeHighlighter.swift           # Splash 语法高亮
│   │   └── SensitiveDataFilter.swift       # 敏感信息遮罩
│   └── Utils/
│       ├── Constants.swift                 # 全局常量
│       └── Extensions/
│           ├── Color+Theme.swift           # 主题颜色
│           ├── String+SensitiveData.swift  # 敏感信息检测
│           └── Date+Formatting.swift       # 日期格式化
├── SwiftWorkTests/
│   ├── ViewModels/
│   │   ├── SessionViewModelTests.swift
│   │   └── TimelineViewModelTests.swift
│   ├── SDKIntegration/
│   │   ├── AgentBridgeTests.swift
│   │   ├── EventMapperTests.swift
│   │   └── PermissionHandlerTests.swift
│   ├── Services/
│   │   └── KeychainManagerTests.swift
│   └── Models/
│       └── PermissionRuleTests.swift
├── SwiftWorkUITests/
│   └── SwiftWorkUITests.swift
├── Package.swift                            # SPM 配置（如果使用纯 SPM）
├── .github/
│   └── workflows/
│       └── ci.yml                          # Xcode build + test
└── README.md
```

### Architectural Boundaries

**Layer Communication Rules:**

```
┌─────────────────────────────────────────────────┐
│ Views (SwiftUI)                                  │
│ 只依赖 ViewModel 和 Models/UI                    │
│ 不直接引用 SDKIntegration 或 SwiftData Models    │
├─────────────────────────────────────────────────┤
│ ViewModels (@Observable)                         │
│ 依赖 SDKIntegration、Models/UI、Services          │
│ 不直接引用 SwiftUI View 类型                      │
├─────────────────────────────────────────────────┤
│ SDKIntegration                                   │
│ 依赖 open-agent-sdk-swift、Models/UI、Services    │
│ 不直接引用 View 或 ViewModel                      │
├─────────────────────────────────────────────────┤
│ Models (SwiftData + UI)                          │
│ 无外部依赖，纯数据定义                             │
├─────────────────────────────────────────────────┤
│ Services                                         │
│ 依赖系统框架（Security、swift-markdown、Splash）   │
│ 不依赖业务层                                      │
└─────────────────────────────────────────────────┘

依赖方向：Views → ViewModels → SDKIntegration → Models
                                    ↘ Services ↗
```

**Boundary Rules:**

1. **Views → ViewModels**：通过 `@State`/`@Environment` 注入，View 只读 ViewModel 的属性
2. **ViewModels → SDKIntegration**：通过 AgentBridge 的公开方法调用
3. **SDKIntegration → Models**：EventMapper 将 SDKMessage 转换为 AgentEvent
4. **任何人 → Services**：通过单例或 `@Dependency` 注入
5. **SwiftData Models** 只在 ViewModels 和 SDKIntegration 中使用，Views 不直接操作

### Requirements to Structure Mapping

**FR 能力域 → 文件映射：**

| FR 能力域 | View 文件 | ViewModel 文件 | SDK/Service 文件 | Model 文件 |
|-----------|-----------|---------------|-----------------|------------|
| 会话管理 | SidebarView, SessionRowView | SessionViewModel | — | Session.swift |
| 事件流可视化 | TimelineView, EventViews/* | TimelineViewModel | EventMapper | AgentEvent, AgentEventType |
| 工具执行可视化 | ToolCallView, ToolResultView, ToolProgressView | TimelineViewModel | ToolRendererRegistry | ToolContent |
| 权限与审批 | PermissionDialogView, PermissionRulesView | — | PermissionHandler | PermissionRule, PermissionDecision |
| Agent 配置与交互 | InputBarView, WelcomeView, APIKeySettingsView, ModelPickerView | InputBarViewModel, SettingsViewModel | AgentBridge | AppConfiguration |
| 执行计划可视化 | PlanView | TimelineViewModel | EventMapper | — |
| 调试与检查 | InspectorView, DebugView | — | — | — |
| 内容渲染 | (嵌入在各 EventView 中) | — | MarkdownRenderer, CodeHighlighter | — |
| 应用外壳 | ContentView, AppDelegate | — | — | — |

### Integration Points

**Internal Communication:**

| 发送方 | 接收方 | 机制 | 数据 |
|--------|--------|------|------|
| SDK (AsyncStream) | AgentBridge | AsyncStream<SDKMessage> | 18 种事件类型 |
| AgentBridge | TimelineViewModel | @Observable events 数组更新 | [AgentEvent] |
| TimelineViewModel | TimelineView | SwiftUI 自动响应 | AgentEvent |
| PermissionHandler | PermissionDialogView | @State sheet binding | PermissionDecision |
| SessionViewModel | SidebarView | @Observable sessions 数组 | [Session] |

**External Integrations:**

| 外部系统 | 集成点 | 方向 |
|----------|--------|------|
| LLM API | open-agent-sdk-swift (SDK 内部) | SDK → API |
| macOS Keychain | KeychainManager | App → System |
| macOS 通知中心 | AppDelegate (UNUserNotificationCenter) | App → System |
| macOS Dock | AppDelegate (NSApplication) | App → System |
| Sparkle 更新 | AppDelegate (SUUpdater) | System → App |

**Data Flow:**

```
用户输入 → InputBarView → TimelineViewModel.sendMessage()
    → AgentBridge.startAgent(prompt:)
        → SDK Agent.stream()
            → AsyncStream<SDKMessage>
                → EventMapper.map(SDKMessage) → AgentEvent
                    → TimelineViewModel.events.append(event)
                        → SwiftUI 自动重渲染 TimelineView
```

## Architecture Validation Results

### Coherence Validation

**Decision Compatibility:** ✅ 所有决策互相兼容

- SwiftData + @Observable + SwiftUI 全部要求 macOS 14+，无版本冲突
- AsyncStream + Observation 框架构成一致的事件流方案
- Keychain + Security framework 与 SDK 的 HTTPS 通信无冲突
- 所有 SPM 依赖（open-agent-sdk-swift、swift-markdown、Splash、Sparkle）支持同一平台目标
- 无互相矛盾的决策

**Pattern Consistency:** ✅ 实现模式支撑架构决策

- 命名规范（PascalCase View、ViewModel 后缀）与项目结构文件名一致
- 事件流模式（AsyncStream → AgentBridge → TimelineViewModel）与数据流图吻合
- 错误处理规则与 Decision 7 的策略表一致
- Anti-Patterns 规则强化了架构边界（View 不直接调 SDK、不用 ObservableObject）

**Structure Alignment:** ✅ 项目结构支持所有架构决策

- 分层目录（Views/ViewModels/SDKIntegration/Models/Services）与依赖方向一致
- FR 能力域映射到具体文件，无遗漏领域
- 集成点（Internal/External/Data Flow）清晰定义了组件间通信

### Requirements Coverage Validation

**Functional Requirements Coverage:** ✅ 48/48 FR 全部有架构支撑

| FR 能力域 | 覆盖状态 | 架构支撑 |
|-----------|----------|----------|
| 会话管理 (FR1-6) | ✅ | Session model + SessionViewModel + SidebarView |
| 事件流可视化 (FR7-13) | ✅ | TimelineView + EventViews/* + EventMapper + TimelineViewModel |
| 工具执行可视化 (FR14-19) | ✅ | ToolCallView/ResultView/ProgressView + ToolRendererRegistry |
| 权限与审批 (FR20-26) | ✅ | PermissionHandler + PermissionEngine + PermissionDialogView |
| Agent 配置与交互 (FR27-32) | ✅ | AgentBridge + InputBarView + SettingsView + WelcomeView |
| 执行计划可视化 (FR34-36) | ✅ | PlanView + EventMapper |
| 调试与检查 (FR37-41) | ✅ | InspectorView + DebugView |
| 内容渲染 (FR42-44) | ✅ | MarkdownRenderer + CodeHighlighter |
| 应用外壳 (FR45-49) | ✅ | ContentView + AppDelegate + SettingsView |

**Non-Functional Requirements Coverage:** ✅ 21/21 NFR 全部有架构支撑

| NFR 分类 | 覆盖状态 | 架构支撑 |
|----------|----------|----------|
| Performance (NFR1-5) | ✅ | LazyVStack、虚拟化窗口、异步渲染、分页加载 |
| Security (NFR6-10) | ✅ | KeychainManager、HTTPS（SDK 内置）、SensitiveDataFilter、审计日志 |
| Reliability (NFR11-14) | ✅ | do/catch 全包裹、@unknown default 降级、AsyncStream 取消清理 |
| Compatibility (NFR15-18) | ✅ | macOS 14+ 部署目标、SwiftUI 原生、Appearance 自动适配 |
| Data Persistence (NFR19-21) | ✅ | SwiftData 持久化、AppConfiguration KV、窗口状态通过 UserDefaults |

### Implementation Readiness Validation

**Decision Completeness:** ✅ 12 个决策全部有明确方案

- 4 个 Critical Decisions 全部文档化（事件驱动、SwiftData、Observation、AgentBridge）
- 3 个 Important Decisions 全部文档化（权限、渲染、性能）
- 3 个 Deferred Decisions 明确标注延迟阶段
- 所有关键依赖版本已验证（Sparkle 2.9.1、open-agent-sdk-swift Swift 6.1）

**Structure Completeness:** ✅ 完整目录树 + 40+ 文件定义

- 所有源文件、测试文件、配置文件已定义
- 集成点（5 个 Internal、5 个 External）已映射
- 完整数据流图从用户输入到 UI 渲染

**Pattern Completeness:** ✅ 6 个冲突领域全覆盖

- 命名规范（9 条规则 + 示例）
- 结构模式（5 条组织规则）
- 格式模式（AgentEvent、AppError、SwiftData 格式）
- 通信模式（事件流 + 状态更新规则）
- 流程模式（错误处理 + 加载状态）
- 7 条强制规则 + 6 条 Anti-Patterns

### Gap Analysis Results

**Critical Gaps:** 0

**Important Gaps:**

1. **窗口状态持久化细节** — NFR21 要求"窗口位置和 Inspector 展开状态在应用重启后保持"，当前仅提及 UserDefaults，未定义具体的 WindowStateManager 或存储键名。实施时应在 Services/ 中补充。
2. **PermissionEngine 命名一致性** — Decision 5 使用 `PermissionEngine`，项目结构中使用 `PermissionHandler`。实施时应统一为 `PermissionHandler`（实现文件名），`PermissionEngine` 作为概念名称保留在文档中。

**Nice-to-Have Gaps:**

1. **可访问性（Accessibility）标注** — PRD Domain-Specific Requirements 提到"所有 UI 组件必须能通过 Accessibility Inspector 检查"，但模式文档中未定义 Accessibility 标注规范。可在实施 Story 中按组件补充。
2. **主题/颜色系统细节** — `Color+Theme.swift` 已列入项目结构，但未定义具体色板。可在 Phase 2（Agent 可视化）时随 UI 打磨一起定义。
3. **SDK 版本锁定** — 未指定 open-agent-sdk-swift 的最低版本约束。应在 `Package.swift` 中使用 `.upToNextMinor(from:)` 锁定。

### Architecture Completeness Checklist

**Requirements Analysis**

- [x] Project context thoroughly analyzed
- [x] Scale and complexity assessed
- [x] Technical constraints identified
- [x] Cross-cutting concerns mapped

**Architectural Decisions**

- [x] Critical decisions documented with versions
- [x] Technology stack fully specified
- [x] Integration patterns defined
- [x] Performance considerations addressed

**Implementation Patterns**

- [x] Naming conventions established
- [x] Structure patterns defined
- [x] Communication patterns specified
- [x] Process patterns documented

**Project Structure**

- [x] Complete directory structure defined
- [x] Component boundaries established
- [x] Integration points mapped
- [x] Requirements to structure mapping complete

### Architecture Readiness Assessment

**Overall Status:** READY FOR IMPLEMENTATION

**Confidence Level:** High

**Key Strengths:**

1. **事件驱动架构清晰** — SDKMessage → AgentEvent → SwiftUI View 的数据流管线设计明确，编译时类型安全保证完整覆盖
2. **分层边界严格** — 依赖方向单向，Views 不接触 SDK，通过 ViewModel 和 AgentBridge 隔离
3. **可扩展性内置** — ToolRenderable 协议 + ToolRendererRegistry 允许新增工具类型无需修改核心代码
4. **PRD 对齐完整** — 48 FR 和 21 NFR 100% 有对应架构组件支撑

**Areas for Future Enhancement:**

1. 窗口状态持久化的具体实现方案
2. 主题/颜色系统的详细定义
3. 可访问性标注规范
4. 性能虚拟化滚动的具体实现策略（当会话超过 500 事件时）

### Implementation Handoff

**AI Agent Guidelines:**

- 严格遵循所有 12 个架构决策，不自行替换技术方案
- 一致使用实现模式（命名规范、状态管理、错误处理）
- 尊重项目结构和分层边界
- 遇到架构问题时参考本文档，不自行决定

**First Implementation Priority:**

1. 创建 Xcode macOS App 项目（SwiftUI Lifecycle，macOS 14+）
2. 添加 SPM 依赖
3. 建立目录结构和占位文件
4. 实现 SwiftData 模型（Session、Event、PermissionRule、AppConfiguration）
5. 实现 AgentBridge 和 EventMapper
6. 实现 TimelineView 极简版（Phase 1 目标）
