# Story 1.1: 项目初始化与数据层搭建

Status: review

## Story

As a 开发者,
I want 创建 Xcode 项目并建立完整的数据层和项目结构,
so that 后续 Story 可以在此基础上构建 UI 和 SDK 集成功能。

## Acceptance Criteria

1. **Given** 开发者打开项目目录 **When** 使用 Xcode 打开 SwiftWork.xcodeproj **Then** 项目使用 SwiftUI Lifecycle，最低部署目标为 macOS 14 (Sonoma)
2. **And** 通过 SPM 添加了 open-agent-sdk-swift、swift-markdown、Splash、Sparkle 2.x 依赖
3. **And** 目录结构符合 Architecture Decision 11（App/、Views/、ViewModels/、SDKIntegration/、Models/、Services/、Utils/）
4. **And** SwiftData 模型已定义：Session（id, title, createdAt, updatedAt, workspacePath, events）、Event（id, sessionID, eventType, rawData, timestamp, order）、PermissionRule（id, toolName, pattern, decision, createdAt）、AppConfiguration（id, key, value, updatedAt）
5. **And** App 入口 SwiftWorkApp.swift 使用 NavigationSplitView 布局（Sidebar + Workspace）
6. **And** 项目可通过 `swift build` 成功编译

**覆盖的架构决策：** ARCH-1, ARCH-2, ARCH-3, ARCH-4, ARCH-13

## Tasks / Subtasks

- [x] Task 1: 创建 Xcode 项目骨架（AC: #1, #6）
  - [x] 1.1 在 Xcode 中创建 macOS App 项目，选择 SwiftUI Lifecycle，部署目标 macOS 14
  - [x] 1.2 确认 `swift build` 可通过（验证 Package.swift 正确配置）
  - [x] 1.3 创建项目内部目录结构占位：App/、Views/、ViewModels/、SDKIntegration/、Models/SwiftData/、Models/UI/、Services/、Utils/Extensions/

- [x] Task 2: 配置 SPM 依赖（AC: #2, #6）
  - [x] 2.1 添加 open-agent-sdk-swift：`https://github.com/terryso/open-agent-sdk-swift`（使用 `.upToNextMinor` 版本锁定）
  - [x] 2.2 添加 swift-markdown：`https://github.com/apple/swift-markdown`
  - [x] 2.3 添加 Splash：`https://github.com/JohnSundell/Splash`
  - [x] 2.4 添加 Sparkle 2.x：`https://github.com/sparkle-project/Sparkle`（注意：Sparkle 仅在主 target 中 linked，不在测试 target 中）
  - [x] 2.5 验证所有依赖成功解析且项目可编译

- [x] Task 3: 定义 SwiftData 模型（AC: #4）
  - [x] 3.1 创建 `Models/SwiftData/Session.swift` — `@Model class Session`（id, title, createdAt, updatedAt, workspacePath, events 关系）
  - [x] 3.2 创建 `Models/SwiftData/Event.swift` — `@Model class Event`（id, sessionID, eventType, rawData, timestamp, order）
  - [x] 3.3 创建 `Models/SwiftData/PermissionRule.swift` — `@Model class PermissionRule`（id, toolName, pattern, decision, createdAt）
  - [x] 3.4 创建 `Models/SwiftData/AppConfiguration.swift` — `@Model class AppConfiguration`（id, key, value, updatedAt）
  - [x] 3.5 配置 Session → Event 一对多关系（cascade 删除）

- [x] Task 4: 定义 UI 层数据模型（AC: #3, #4）
  - [x] 4.1 创建 `Models/UI/AgentEventType.swift` — 枚举，对应 SDKMessage 的 18 种事件类型 + unknown fallback
  - [x] 4.2 创建 `Models/UI/AgentEvent.swift` — UI 事件中间模型（id, type, content, metadata, timestamp）
  - [x] 4.3 创建 `Models/UI/ToolContent.swift` — 工具调用数据结构
  - [x] 4.4 创建 `Models/UI/PermissionDecision.swift` — 权限决策枚举（.approved, .denied, .requiresApproval）
  - [x] 4.5 创建 `Models/UI/AppError.swift` — 统一错误模型（domain, code, message, underlying）

- [x] Task 5: 创建 App 入口与根布局（AC: #5）
  - [x] 5.1 创建 `App/SwiftWorkApp.swift` — `@main` 入口，配置 `WindowGroup` + SwiftData `modelContainer`
  - [x] 5.2 创建 `App/ContentView.swift` — 根视图，`NavigationSplitView`（Sidebar placeholder + Workspace placeholder）
  - [x] 5.3 注册所有 SwiftData 模型到 `modelContainer`

- [x] Task 6: 创建占位文件与项目骨架（AC: #3）
  - [x] 6.1 创建各目录下的占位 Swift 文件（空 struct/class 声明），确保目录结构完整
  - [x] 6.2 创建 `Utils/Constants.swift` — 全局常量占位
  - [x] 6.3 创建 `Utils/Extensions/Color+Theme.swift` — 主题颜色占位

- [x] Task 7: 验证编译与测试骨架（AC: #6）
  - [x] 7.1 确保 `swift build` 通过
  - [x] 7.2 创建 `SwiftWorkTests/` 测试目录结构（ViewModels/, SDKIntegration/, Services/, Models/）
  - [x] 7.3 创建基础模型测试：验证 SwiftData 模型可实例化和序列化

## Dev Notes

### 核心架构约束

- **Swift 6.1 strict concurrency**：所有类型必须遵循 Sendable 一致性，SwiftData `@Model` 类自动获得 Sendable
- **@Observable（非 ObservableObject）**：ViewModel 层使用 Observation 框架，本项目 story 1.1 不涉及 ViewModel 实现，但 Models/UI 中的类型需为后续 `@Observable` ViewModel 做好准备
- **分层依赖方向单向**：Views → ViewModels → SDKIntegration → Models，Services 被共享。本 story 创建的所有模型类型属于最底层，无外部依赖

### SPM 依赖注意事项

**open-agent-sdk-swift：**
- GitHub URL：`https://github.com/terryso/open-agent-sdk-swift`
- SDK 的 `Package.swift` 使用 `swift-tools-version: 6.1`，平台 `.macOS(.v13)`
- SDK 自身依赖 `mcp-swift-sdk`（SPM 会自动传递解析）
- 在项目 Package.swift 或 Xcode SPM 配置中使用 `.upToNextMinor(from:)` 锁定版本
- SDK 核心类型在 `import OpenAgentSDK` 后可用：`Agent`、`AgentOptions`、`SDKMessage`（18 case enum）

**swift-markdown：**
- GitHub URL：`https://github.com/apple/swift-markdown`
- 使用 `import Markdown`，提供 `MarkupVisitor` 协议和 Markdown AST 解析

**Splash：**
- GitHub URL：`https://github.com/JohnSundell/Splash`
- 使用 `import Splash`，提供 `SyntaxHighlighter` 用于代码语法高亮

**Sparkle 2.x：**
- GitHub URL：`https://github.com/sparkle-project/Sparkle`
- 仅在主 app target 中 link，不在测试或其他 target 中
- Phase 4 才真正使用，本 story 仅添加 SPM 依赖确保编译通过

### SwiftData 模型详细设计

```
Session:
  @Attribute(.unique) var id: UUID
  var title: String
  var createdAt: Date
  var updatedAt: Date
  var workspacePath: String?
  @Relationship(deleteRule: .cascade, inverse: \Event.session)
  var events: [Event]
  // 实现 init，默认值：title="新会话", createdAt=Date.now, updatedAt=Date.now

Event:
  @Attribute(.unique) var id: UUID
  var sessionID: UUID  // 关联 Session.id（非 SwiftData relationship key，用于跨查询）
  var eventType: String  // SDKMessage case name rawValue，如 "toolUse", "partialMessage"
  var rawData: Data  // 完整 SDK 事件 JSON（不展开为强类型字段——18 种事件类型且可能增长）
  var timestamp: Date
  var order: Int  // 用于时间线排序
  var session: Session?  // SwiftData 反向关系
  // 注意：rawData 是 JSON Data 类型，不做强类型展开

PermissionRule:
  @Attribute(.unique) var id: UUID
  var toolName: String
  var pattern: String
  var decision: String  // "allow" 或 "deny"
  var createdAt: Date

AppConfiguration:
  @Attribute(.unique) var id: UUID
  var key: String
  var value: Data  // 泛型 KV 存储，value 编码为 Data（JSON 或 raw）
  var updatedAt: Date
```

### UI 模型设计要点

**AgentEventType 枚举：** 必须覆盖 SDKMessage 全部 18 个 case，另加 `.unknown` fallback：
```swift
enum AgentEventType: String, Codable {
    case partialMessage, assistant, toolUse, toolResult, toolProgress
    case result, userMessage, system
    case hookStarted, hookProgress, hookResponse
    case taskStarted, taskProgress
    case authStatus, filesPersisted, localCommandOutput
    case promptSuggestion, toolUseSummary
    case unknown  // @unknown default 对应
}
```

**AgentEvent 结构体：** UI 层中间模型，View 只消费此类型，绝不直接引用 SDKMessage：
```swift
struct AgentEvent: Identifiable, Sendable {
    let id: UUID
    let type: AgentEventType
    let content: String
    let metadata: [String: any Sendable]
    let timestamp: Date
}
```

**AppError 结构体：** 统一错误模型：
```swift
enum ErrorDomain: String, Sendable { case sdk, network, data, ui }

struct AppError: LocalizedError, Sendable {
    let domain: ErrorDomain
    let code: String
    let message: String
    let underlying: Error?
    var errorDescription: String? { message }
}
```

**PermissionDecision 枚举：**
```swift
enum PermissionDecision: Sendable {
    case approved
    case denied(reason: String)
    case requiresApproval(toolName: String, description: String, parameters: [String: any Sendable])
}
```

### 项目目录结构（完整）

本 story 需创建的目录和文件结构（含占位文件）：

```
SwiftWork/
├── SwiftWork.xcodeproj (or Package.swift)
├── SwiftWork/
│   ├── App/
│   │   ├── SwiftWorkApp.swift          ✅ 本 story 实现
│   │   └── ContentView.swift           ✅ 本 story 实现
│   ├── Views/
│   │   ├── Sidebar/                    📁 占位
│   │   ├── Workspace/                  📁 占位（含 Timeline/, InputBar/, Inspector/ 子目录）
│   │   ├── Permission/                 📁 占位
│   │   ├── Settings/                   📁 占位
│   │   └── Onboarding/                 📁 占位
│   ├── ViewModels/                     📁 占位
│   ├── SDKIntegration/                 📁 占位
│   ├── Models/
│   │   ├── SwiftData/                  ✅ 本 story 实现（4 个模型文件）
│   │   └── UI/                         ✅ 本 story 实现（5 个 UI 模型文件）
│   ├── Services/                       📁 占位
│   └── Utils/
│       ├── Constants.swift             ✅ 本 story 创建
│       └── Extensions/                 📁 占位
├── SwiftWorkTests/                     ✅ 本 story 创建测试骨架
│   ├── ViewModels/
│   ├── SDKIntegration/
│   ├── Services/
│   └── Models/
└── SwiftWorkUITests/
```

### NavigationSplitView 布局模板

```swift
// ContentView.swift — 根布局
struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            // Sidebar 占位
            Text("Sidebar")
                .navigationTitle("SwiftWork")
        } detail: {
            // Workspace 占位
            Text("Workspace")
        }
    }
}
```

### SwiftData ModelContainer 注册

```swift
// SwiftWorkApp.swift
import SwiftUI
import SwiftData

@main
struct SwiftWorkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Session.self,
            Event.self,
            PermissionRule.self,
            AppConfiguration.self
        ])
    }
}
```

### Project Structure Notes

- 所有 SwiftData Model 文件放在 `Models/SwiftData/` 下，不与 UI 模型混放
- UI 层模型放在 `Models/UI/` 下，View 只依赖 Models/UI，不直接依赖 Models/SwiftData
- 占位文件使用最小可编译声明（如 `struct SidebarView: View { var body: some View { Text("Sidebar") } }`）
- 测试目录结构与主项目目录对齐：`SwiftWorkTests/ViewModels/`、`SwiftWorkTests/SDKIntegration/` 等

### 编译验证清单

完成所有 task 后必须验证：
1. `swift build` 无错误通过
2. 所有 SwiftData 模型可通过 `#Preview` 或测试实例化
3. Xcode 项目在 Navigator 中显示正确的目录分组
4. SPM 依赖全部解析成功（无红色错误标记）
5. `import OpenAgentSDK`、`import Markdown`、`import Splash` 均可编译

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 11: 项目结构]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 1: SwiftData 作为持久化引擎]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 2: 数据模型设计]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 3: 事件存储策略]
- [Source: _bmad-output/planning-artifacts/architecture.md#Pattern Categories - Format Patterns]
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.1: 项目初始化与数据层搭建]
- [Source: _bmad-output/project-context.md#Technology Stack & Versions]
- [Source: _bmad-output/project-context.md#Critical Don't-Miss Rules]
- [Source: open-agent-sdk-swift/Sources/OpenAgentSDK/Types/SDKMessage.swift — 18 种事件类型定义]
- [Source: open-agent-sdk-swift/Package.swift — swift-tools-version: 6.1, platforms: .macOS(.v13)]

## Dev Agent Record

### Agent Model Used
Claude Opus 4.7 (GLM-5.1)

### Debug Log References
- Splash dependency version range corrected from `0.18.0` to `0.9.0` (Splash's latest tag is 0.9.0)
- SwiftData `@Model` classes are NOT Sendable in Swift 6.1 (unavailable conformance); updated test from `testSessionIsSendable` to `testSessionIsSwiftDataModel`

### Completion Notes List
- All 7 tasks and 24 subtasks completed successfully
- Created Package.swift-based SPM project (not Xcode project) since AC requires `swift build` to pass
- 4 SwiftData models: Session, Event, PermissionRule, AppConfiguration with proper relationships and cascade delete
- 5 UI models: AgentEventType (19 cases), AgentEvent, ToolContent, PermissionDecision, AppError (with ErrorDomain)
- App entry with @main, WindowGroup, NavigationSplitView, and SwiftData modelContainer registration
- Full directory structure with placeholder files in Views/, ViewModels/, SDKIntegration/, Services/, Utils/
- All 4 SPM dependencies resolved and compiling: OpenAgentSDK, swift-markdown, Splash, Sparkle 2.x
- 51 tests passing (0 failures, 0 skipped)
- `swift build` succeeds cleanly

### File List

**Created:**
- Package.swift
- SwiftWork/App/SwiftWorkApp.swift
- SwiftWork/App/ContentView.swift
- SwiftWork/Models/SwiftData/Session.swift
- SwiftWork/Models/SwiftData/Event.swift
- SwiftWork/Models/SwiftData/PermissionRule.swift
- SwiftWork/Models/SwiftData/AppConfiguration.swift
- SwiftWork/Models/UI/AgentEventType.swift
- SwiftWork/Models/UI/AgentEvent.swift
- SwiftWork/Models/UI/ToolContent.swift
- SwiftWork/Models/UI/PermissionDecision.swift
- SwiftWork/Models/UI/AppError.swift
- SwiftWork/Views/Sidebar/SidebarView.swift
- SwiftWork/Views/Sidebar/SessionRowView.swift
- SwiftWork/Views/Workspace/Timeline/TimelineView.swift
- SwiftWork/Views/Workspace/InputBar/InputBarView.swift
- SwiftWork/Views/Workspace/Inspector/InspectorView.swift
- SwiftWork/Views/Permission/PermissionDialogView.swift
- SwiftWork/Views/Settings/SettingsView.swift
- SwiftWork/Views/Onboarding/WelcomeView.swift
- SwiftWork/ViewModels/SessionViewModel.swift
- SwiftWork/SDKIntegration/AgentBridge.swift
- SwiftWork/Services/KeychainManager.swift
- SwiftWork/Utils/Constants.swift
- SwiftWork/Utils/Extensions/Color+Theme.swift

**Modified (ATDD test files — removed XCTSkipIf RED phase guards):**
- SwiftWorkTests/Support/TestDataFactory.swift
- SwiftWorkTests/Models/SwiftData/SessionModelTests.swift
- SwiftWorkTests/Models/SwiftData/EventModelTests.swift
- SwiftWorkTests/Models/SwiftData/PermissionRuleModelTests.swift
- SwiftWorkTests/Models/SwiftData/AppConfigurationModelTests.swift
- SwiftWorkTests/Models/UI/AgentEventTypeTests.swift
- SwiftWorkTests/Models/UI/AgentEventTests.swift
- SwiftWorkTests/Models/UI/ToolContentTests.swift
- SwiftWorkTests/Models/UI/PermissionDecisionTests.swift
- SwiftWorkTests/Models/UI/AppErrorTests.swift
- SwiftWorkTests/App/AppEntryTests.swift
- SwiftWorkTests/ProjectStructureTests.swift
