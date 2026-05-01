# Story 1.6: 应用状态恢复

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a 用户,
I want 应用重启后恢复上次的会话状态和窗口布局,
So that 我不需要每次重新选择会话和调整窗口。

## Acceptance Criteria

1. **Given** 用户正在使用某个会话 **When** 退出并重新打开应用 **Then** 自动选中上次的活跃会话，Sidebar 高亮该会话（FR6）**And** 窗口位置、大小与上次关闭时一致（NFR21）**And** Inspector Panel 的展开/折叠状态保持（NFR21）
2. **Given** 应用异常退出 **When** 重新打开应用 **Then** 恢复至最近的会话状态（NFR14）**And** 已持久化的事件历史完整保留

**覆盖的 FRs:** FR6
**覆盖的 ARCHs:** — (NFR14, NFR19, NFR21)

## Tasks / Subtasks

- [x] Task 1: 创建 AppStateManager 服务（AC: #1, #2）
  - [x] 1.1 创建 `SwiftWork/Services/AppStateManager.swift` — 统一的应用状态持久化管理器，负责保存/恢复上次活跃会话 ID、窗口 frame、Inspector 展开状态
  - [x] 1.2 定义 `AppState` 结构体：`lastActiveSessionID: UUID?`、`windowFrame: String?`（NSRect 字符串编码）、`isInspectorVisible: Bool`
  - [x] 1.3 使用 `AppConfiguration`（SwiftData KV 模型）存储应用状态键值对，键名前缀 `appState.`
  - [x] 1.4 实现 `saveAppState()` 方法：在会话切换、窗口关闭、Inspector 切换时触发保存
  - [x] 1.5 实现 `loadAppState()` 方法：应用启动时从 SwiftData 读取恢复
  - [x] 1.6 将 AppStateManager 注册到 Constants 中的键名常量

- [x] Task 2: 在 SessionViewModel 中恢复上次活跃会话（AC: #1）
  - [x] 2.1 在 `SessionViewModel.configure(modelContext:)` 中，调用 `AppStateManager.loadAppState()` 获取 `lastActiveSessionID`
  - [x] 2.2 如果 `lastActiveSessionID` 非空，在 fetchSessions 后查找匹配的 session 并设为 `selectedSession`
  - [x] 2.3 如果 `lastActiveSessionID` 对应的 session 已被删除，选择 `sessions.first`（最新的会话）
  - [x] 2.4 在 `SessionViewModel.selectSession(_:)` 中调用 `AppStateManager.saveLastActiveSessionID(_:)` 持久化

- [x] Task 3: 窗口位置和大小恢复（AC: #1, NFR21）
  - [x] 3.1 在 `SwiftWorkApp.swift` 中，为 `WindowGroup` 添加 `.defaultSize(width:height:)` 设置合理的默认窗口尺寸（1200x800）
  - [x] 3.2 创建 `WindowAccessor` NSViewRepresentable 辅助类型，用于获取底层 NSWindow 引用（仅在 macOS 上）
  - [x] 3.3 在 `ContentView` 中使用 `WindowAccessor` 监听窗口 `willClose` 通知和 `didResize` 通知，保存窗口 frame 到 AppStateManager
  - [x] 3.4 应用启动时，从 AppStateManager 读取保存的窗口 frame，通过 NSWindow.setFrame 恢复窗口位置和大小
  - [x] 3.5 确保首次启动时（无保存的窗口状态）使用 `.defaultSize` 默认值

- [x] Task 4: Inspector Panel 状态持久化（AC: #1, NFR21）
  - [x] 4.1 在 `ContentView` 中添加 `@State private var isInspectorVisible: Bool` 属性
  - [x] 4.2 应用启动时从 AppStateManager 恢复 `isInspectorVisible` 状态
  - [x] 4.3 Inspector 切换时调用 `AppStateManager.saveInspectorVisibility(_:)` 持久化
  - [x] 4.4 将 `isInspectorVisible` 传递给 `WorkspaceView`（当前 WorkspaceView 尚未使用 Inspector，预留 @Binding 接口）

- [x] Task 5: 应用生命周期集成（AC: #1, #2）
  - [x] 5.1 在 `ContentView.task` 中，配置完成后调用 `AppStateManager.loadAppState()` 并恢复所有状态
  - [x] 5.2 监听 `NSApplication.willTerminateNotification` 通知，在应用退出前保存完整状态快照
  - [x] 5.3 监听 `NSWindow.didMoveNotification` 和 `NSWindow.didResizeNotification`，节流保存窗口状态（避免频繁写入）
  - [x] 5.4 确保异常退出场景下，因为会话切换和 Inspector 切换时已实时保存，重启后仍能恢复最近状态

- [x] Task 6: 编写测试（AC: 全部）
  - [x] 6.1 创建 `SwiftWorkTests/Services/AppStateManagerTests.swift` — 测试状态保存/加载
  - [x] 6.2 测试 `saveLastActiveSessionID` 后 `loadAppState` 正确返回保存的值
  - [x] 6.3 测试删除 session 后恢复逻辑（回退到 sessions.first）
  - [x] 6.4 测试窗口 frame 序列化/反序列化（NSRect -> String -> NSRect）
  - [x] 6.5 测试 Inspector 可见性持久化
  - [x] 6.6 测试首次启动时（无保存状态）返回默认值
  - [x] 6.7 在 `SwiftWorkTests/App/AppStateRestoreIntegrationTests.swift` 中编写集成测试：模拟应用重启流程
  - [x] 6.8 所有测试通过 `swift test`

## Dev Notes

### 核心架构约束

- **@Observable（非 ObservableObject）**：AppStateManager 作为 Service 层组件，被 ViewModel 消费
- **分层边界**：AppStateManager 属于 Services 层，ViewModel 调用 Service，View 不直接调用 Service
- **SwiftData 持久化**：使用已有的 `AppConfiguration` KV 模型存储应用状态，不新建 SwiftData Model
- **Swift 6.1 strict concurrency**：AppStateManager 方法需要在 `@MainActor` 上运行（操作 SwiftData ModelContext）
- **事件驱动数据流**：窗口状态变更通过 NotificationCenter 通知监听

### 前序 Story 关键上下文

Story 1-1 到 1-5 已完成以下核心实现：

**已有的持久化基础设施（直接使用，不重新创建）：**
- `AppConfiguration`（SwiftData KV 模型）：`key: String` + `value: Data`，已有 CRUD 模式
- `SettingsViewModel` 已示范如何使用 AppConfiguration 存取配置（`hasCompletedOnboarding`、`selectedModel`）
- `KeychainManager`：API Key 安全存储（本 story 不涉及）
- `SwiftDataEventStore`：事件持久化和加载（已完成，本 story 仅调用已有方法）
- `SessionViewModel`：会话 CRUD + 切换（已完整实现）
- `AgentBridge.loadEvents(for:)`：已有从 SwiftData 加载事件到内存的完整逻辑

**当前 SessionViewModel 状态切换机制（需增强）：**
- `selectSession(_:)` 设置 `selectedSession`（仅内存，不持久化）
- `configure(modelContext:)` 调用 `fetchSessions()` 加载所有会话（但不恢复选中状态）
- `createSession()` 创建后自动选中（但不保存"最后活跃会话"）

**当前 ContentView 启动流程（需增强）：**
```
ContentView.task {
    1. settingsViewModel.configure(modelContext)  // 检查 API Key、模型
    2. hasCompletedOnboarding = ...               // 决定显示引导还是主界面
    3. if onboarding: sessionViewModel.configure   // 加载会话列表
    4. if onboarding: eventStore = ...             // 创建事件存储
}
```
需要在此流程中增加第 5 步：恢复上次活跃会话、窗口状态、Inspector 状态。

### 应用状态恢复设计

**AppStateManager 设计：**
```swift
// SwiftWork/Services/AppStateManager.swift
@MainActor
@Observable
final class AppStateManager {
    // 状态键名常量
    static let lastActiveSessionIDKey = "appState.lastActiveSessionID"
    static let windowFrameKey = "appState.windowFrame"
    static let inspectorVisibleKey = "appState.inspectorVisible"

    private var modelContext: ModelContext?

    // 当前内存中的缓存
    var lastActiveSessionID: UUID?
    var windowFrame: NSRect?
    var isInspectorVisible: Bool = false

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadAppState() {
        lastActiveSessionID = loadUUID(key: Self.lastActiveSessionIDKey)
        windowFrame = loadNSRect(key: Self.windowFrameKey)
        isInspectorVisible = loadBool(key: Self.inspectorVisibleKey)
    }

    func saveLastActiveSessionID(_ id: UUID?) { ... }
    func saveWindowFrame(_ frame: NSRect) { ... }
    func saveInspectorVisibility(_ visible: Bool) { ... }

    // 内部方法：基于 AppConfiguration KV 存取
    private func saveValue(_ data: Data, forKey key: String) { ... }
    private func loadValue(forKey key: String) -> Data? { ... }
}
```

**关键：复用 AppConfiguration KV 模式。**
参照 SettingsViewModel 中的 `hasCompletedOnboarding` 和 `selectedModel` 存取模式，AppStateManager 使用相同的 `FetchDescriptor<AppConfiguration>` + `#Predicate { $0.key == "xxx" }` 模式。

### 窗口状态恢复方案

**macOS SwiftUI 窗口状态恢复的复杂性：**

SwiftUI 的 `WindowGroup` 默认不恢复窗口位置和大小。macOS 系统级状态恢复（System Settings > General > "Close windows when quitting an application"）只对 AppKit Lifecycle 生效，SwiftUI Lifecycle 需要自行处理。

**方案选择：NSWindow frame 持久化**
1. 在 ContentView 中嵌入 `WindowAccessor`（NSViewRepresentable）获取底层 NSWindow
2. 监听 `NSWindow.didMoveNotification` 和 `NSWindow.didResizeNotification`，节流保存 frame 到 AppStateManager
3. 监听 `NSWindow.willCloseNotification`，保存最终 frame
4. 启动时从 AppStateManager 读取 frame 并通过 `NSWindow.setFrame(_:display:)` 恢复

**WindowAccessor 实现：**
```swift
// SwiftWork/Utils/WindowAccessor.swift
struct WindowAccessor: NSViewRepresentable {
    let onWindowUpdate: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            onWindowUpdate(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            onWindowUpdate(nsView.window)
        }
    }
}
```

**NSRect 序列化方案：**
使用 `NSStringFromRect(frame)` 和 `NSRectFromString(str)` 进行序列化，这是 macOS 原生方法，稳定可靠。

**窗口恢复时序：**
```
ContentView.task {
    1. configure(modelContext)              // 初始化所有 ViewModel
    2. loadAppState()                       // 从 SwiftData 读取状态
    3. restoreWindowFrame()                 // 通过 NSWindow.setFrame 恢复窗口
    4. restoreSelectedSession()             // 恢复会话选中
}
```

**节流保存策略：**
窗口拖动和 resize 会频繁触发通知。使用 `Task { try? await Task.sleep(for: .milliseconds(500)) }` 节流，避免每次像素变化都写入 SwiftData。仅在最终停止 500ms 后保存。

### Inspector Panel 状态

**当前状态：** InspectorView 是空壳（仅显示 "Inspector" 文本），WorkspaceView 未使用 Inspector。

**本 story 范围：**
- 在 ContentView 中维护 `isInspectorVisible` 状态并持久化
- 预留 `@Binding var isInspectorVisible: Bool` 接口给 WorkspaceView（但 WorkspaceView 暂不实现 Inspector 布局，那是 Story 3-4 的范围）
- 确保 Inspector 状态在应用重启后恢复

**不做的：**
- 不实现 Inspector 的实际内容（Story 3-4）
- 不实现 Inspector 的展开/折叠动画（Story 3-4）
- 不修改 WorkspaceView 的布局结构

### 异常退出恢复策略

**正常退出路径：**
- `NSApplication.willTerminateNotification` 触发时保存完整状态快照
- 会话切换时实时保存 `lastActiveSessionID`（每次 selectSession 调用时保存）
- Inspector 切换时实时保存 `isInspectorVisible`
- 窗口 frame 节流保存（500ms 延迟）

**异常退出路径（Crash、Force Quit）：**
- `lastActiveSessionID` — 已在每次会话切换时实时保存，崩溃前最近的切换已持久化
- 事件历史 — 已在 Story 1-4 中通过 `appendAndPersist` 实时持久化，崩溃前所有事件已在 SwiftData 中
- 窗口 frame — 节流保存可能有最多 500ms 的丢失，但这是可接受的
- Inspector 可见性 — 已在每次切换时实时保存

**结论：** 通过"实时保存关键状态 + 退出时完整快照"策略，异常退出场景下也能恢复最近的有用状态。

### 与 SettingsViewModel 的复用模式

**AppConfiguration KV 存取的统一模式（已在 SettingsViewModel 中验证）：**
```swift
// 读取
let descriptor = FetchDescriptor<AppConfiguration>(
    predicate: #Predicate { $0.key == "someKey" }
)
if let config = try? context.fetch(descriptor).first {
    let value = String(data: config.value, encoding: .utf8)
}

// 写入
if let existing = try? context.fetch(descriptor).first {
    existing.value = Data(newValue.utf8)
    existing.updatedAt = .now
} else {
    let config = AppConfiguration(key: "someKey", value: Data(newValue.utf8))
    context.insert(config)
}
try? context.save()
```

AppStateManager 应将此模式封装为通用的 `saveValue(_:forKey:)` 和 `loadValue(forKey:)` 方法，避免重复代码。

### 文件变更清单

**NEW（新建文件）：**
- `SwiftWork/Services/AppStateManager.swift` — 应用状态持久化管理器
- `SwiftWork/Utils/WindowAccessor.swift` — NSWindow 引用获取辅助
- `SwiftWorkTests/Services/AppStateManagerTests.swift` — 单元测试
- `SwiftWorkTests/App/AppStateRestoreIntegrationTests.swift` — 集成测试

**UPDATE（更新文件）：**
- `SwiftWork/App/SwiftWorkApp.swift` — 添加 `.defaultSize(width:height:)` 设置默认窗口尺寸
- `SwiftWork/App/ContentView.swift` — 集成 AppStateManager、窗口状态恢复、Inspector 状态恢复、WindowAccessor
- `SwiftWork/ViewModels/SessionViewModel.swift` — 在 selectSession 中持久化 lastActiveSessionID，在 configure 中恢复选中会话
- `SwiftWork/Utils/Constants.swift` — 添加 AppState 键名常量
- `SwiftWork.xcodeproj/project.pbxproj` — 添加新文件引用

**UNCHANGED（不修改）：**
- `SwiftWork/SDKIntegration/AgentBridge.swift` — 事件加载机制已完成
- `SwiftWork/Services/EventStore.swift` — 事件持久化已完成
- `SwiftWork/Views/Workspace/WorkspaceView.swift` — Inspector 布局在 Story 3-4 实现
- `SwiftWork/Views/Workspace/Inspector/InspectorView.swift` — 空壳不变
- `SwiftWork/Views/Sidebar/SidebarView.swift` — 会话列表渲染不变
- `SwiftWork/ViewModels/SettingsViewModel.swift` — 配置管理不变

### 性能注意事项

- AppStateManager 的 `loadAppState()` 在启动时调用一次，从 SwiftData 读取 3 个 KV 记录，延迟可忽略不计
- 窗口状态保存使用节流策略（500ms），不会影响 resize/drag 性能
- 每次会话切换写入一条 AppConfiguration 记录，O(1) 操作
- 窗口恢复时调用 `NSWindow.setFrame` 一次，无性能影响
- 不使用 UserDefaults（架构决策要求使用 SwiftData 统一持久化），但 UserDefaults 也是可选方案

### Xcode 项目配置注意

新建文件后需要：
1. 在 Xcode 中确认新文件已添加到 `SwiftWork` target 的 Compile Sources
2. `WindowAccessor.swift` 使用 AppKit（`NSView`、`NSWindow`），确保 import AppKit 正确
3. 运行 `swift build` 验证编译通过

### 测试要点

**AppStateManagerTests：**
- save/load lastActiveSessionID 正确性
- save/load windowFrame（NSRect 序列化）
- save/load inspectorVisible
- 删除 session 后恢复回退逻辑
- 首次启动（无保存状态）返回 nil/false 默认值
- 覆盖写入（同一 key 第二次 save 覆盖第一次）

**AppStateRestoreIntegrationTests：**
- 模拟完整启动流程：configure -> fetchSessions -> loadAppState -> restoreSelectedSession
- 验证 selectedSession 与 lastActiveSessionID 一致
- 验证 deleted session 场景回退到 sessions.first

### 与前序 Story 的依赖关系

本 story 是 Epic 1 的最后一个 story，完成后 Epic 1 的"SDK->UI 闭环"目标完全达成：
- Story 1-1：项目初始化与数据层（AppConfiguration 模型已就绪）
- Story 1-2：首次启动引导（onboarding 流程已完成）
- Story 1-3：会话管理与 Sidebar（SessionViewModel 已完整实现）
- Story 1-4：消息输入与 Agent 执行（AgentBridge、事件持久化已完成）
- Story 1-5：Timeline 事件流渲染（TimelineView、EventViews 已完成）
- **Story 1-6：应用状态恢复（本 story，补齐应用重启体验）**

### Project Structure Notes

- AppStateManager 放在 `Services/` 目录，符合架构分层（Services 不依赖业务层）
- WindowAccessor 放在 `Utils/` 目录，作为通用辅助类型
- 测试文件按层级分目录：`SwiftWorkTests/Services/` 和 `SwiftWorkTests/App/`
- 遵循命名规范：Service 无后缀（如 KeychainManager）、辅助类型 PascalCase

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.6: 应用状态恢复]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 2: 数据模型设计 — AppConfiguration KV 模型]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 8: 状态管理 — @Observable]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 11: 项目结构 — Services/]
- [Source: _bmad-output/project-context.md#Anti-Patterns — @Observable 非 ObservableObject]
- [Source: _bmad-output/project-context.md#持久化 — SwiftData 持久化]
- [Source: _bmad-output/implementation-artifacts/1-5-timeline-event-stream.md — 前序 Story 上下文]
- [Source: SwiftWork/Models/SwiftData/AppConfiguration.swift — KV 持久化模型]
- [Source: SwiftWork/ViewModels/SettingsViewModel.swift — AppConfiguration 使用模式参考]
- [Source: SwiftWork/ViewModels/SessionViewModel.swift — 会话管理，需增加状态恢复]
- [Source: SwiftWork/App/ContentView.swift — 启动流程，需增加状态恢复]
- [Source: SwiftWork/App/SwiftWorkApp.swift — App 入口，需增加 defaultSize]
- [Source: Apple Documentation — Customizing window styles and state-restoration behavior in macOS]

## Dev Agent Record

### Agent Model Used

GLM-5.1

### Debug Log References

No issues encountered during implementation.

### Completion Notes List

- Implemented AppStateManager as @Observable @MainActor service using AppConfiguration KV pattern
- AppStateManager provides save/load for lastActiveSessionID (UUID), windowFrame (NSRect), and isInspectorVisible (Bool)
- NSRect serialization uses NSStringFromRect/NSRectFromString for reliable macOS-native round-trip
- WindowAccessor (NSViewRepresentable) provides NSWindow reference for frame restoration
- SessionViewModel gains appStateManager reference to persist session selection on selectSession()
- ContentView integrates full lifecycle: loadAppState on startup, throttled window save on move/resize, final snapshot on willTerminate
- Inspector visibility persisted via onChange handler
- Session restore includes fallback to sessions.first when saved session was deleted
- All 277 tests pass (0 failures) including 14 AppStateManagerTests + 7 AppStateRestoreIntegrationTests + 4 WindowAccessorTests

### File List

NEW:
- SwiftWork/Services/AppStateManager.swift
- SwiftWork/Utils/WindowAccessor.swift

UPDATED:
- SwiftWork/App/ContentView.swift
- SwiftWork/App/SwiftWorkApp.swift
- SwiftWork/Utils/Constants.swift
- SwiftWork/ViewModels/SessionViewModel.swift

TEST (pre-existing, now passing):
- SwiftWorkTests/Services/AppStateManagerTests.swift
- SwiftWorkTests/App/AppStateRestoreIntegrationTests.swift
- SwiftWorkTests/Utils/WindowAccessorTests.swift

### Review Findings

- [x] [Review][Patch] Window frame restoration race condition — mainWindow is nil when restoreWindowFrame() called because WindowAccessor defers via DispatchQueue.main.async. Fixed by adding onChange(of: mainWindow) to restore frame once window reference arrives. Also extracted configureAndRestoreState() to eliminate duplicated init code. [ContentView.swift]
- [x] [Review][Patch] NotificationCenter observers never removed (memory leak) — listenForAppLifecycle() added four observers with no removeObserver. Fixed by tracking observers in @State array and cleaning up in onDisappear. [ContentView.swift]
- [x] [Review][Patch] AppStateKeys enum in Constants.swift unused by AppStateManager — AppStateManager defined its own duplicate string constants. Fixed by referencing AppStateKeys.* constants. [AppStateManager.swift, Constants.swift]
- [x] [Review][Patch] SessionViewModel.appStateManager publicly settable — Fixed by making it private(set) with a setAppStateManager() method. [SessionViewModel.swift]
- [x] [Review][Patch] WindowAccessor.updateNSView fires on every render pass — Fixed by adding Coordinator to track lastWindow reference and only calling onWindowUpdate when it actually changes. [WindowAccessor.swift]
- [x] [Review][Patch] createSession() does not persist lastActiveSessionID — New session was auto-selected but ID not saved. If app crashes before manual selection, restore points to wrong session. Fixed by adding appStateManager?.saveLastActiveSessionID(session.id) in createSession(). [SessionViewModel.swift]
- [x] [Review][Defer] loadNSRect treats zero rect as nil (minimized window edge case) — deferred, pre-existing design choice; extremely unlikely in practice
