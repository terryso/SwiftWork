# Story 4.3: macOS 菜单栏与快捷键

Status: review

## Story

As a macOS 用户,
I want 通过标准菜单栏和键盘快捷键操作应用,
so that 我可以高效地使用 SwiftWork 的常用功能。

## Acceptance Criteria

1. **Given** 应用运行 **When** 查看菜单栏 **Then** 显示标准 macOS 菜单结构：File（新建会话、关闭窗口）、Edit（复制、粘贴）、View（切换 Inspector、切换 Debug Panel）、Window（最小化、缩放）、Help（关于、文档）（FR45）

2. **Given** 用户按下 Cmd+N **When** 在任何界面 **Then** 创建新会话并切换到该会话（FR46）

3. **Given** 用户按下 Cmd+W **When** 在任何界面 **Then** 关闭当前窗口（FR46）

4. **Given** 用户按下 Cmd+,（逗号） **When** 在任何界面 **Then** 打开设置页面（FR46）

**覆盖的 FRs:** FR45, FR46
**覆盖的 ARCHs:** ARCH-12 (分层边界 — 菜单命令触发 ViewModel 方法)

## Tasks / Subtasks

- [x] Task 1: 在 SwiftWorkApp.swift 中添加 SwiftUI Commands（AC: #1, #2, #3, #4）
  - [x] 1.1 在 `SwiftWorkApp.swift` 的 `body` 中添加 `CommandGroup(replacing: .newItem)` 覆盖 File 菜单的「新建」命令——绑定到 `sessionViewModel.createSession()`
  - [x] 1.2 添加 `CommandGroup(after: .toolbar)` 为 View 菜单添加「切换 Inspector」（Cmd+I）和「切换 Debug Panel」（Cmd+Shift+D）命令
  - [x] 1.3 添加 `CommandGroup(replacing: .appSettings)` 覆盖设置快捷键——绑定到 `isSettingsPresented = true`
  - [x] 1.4 确保 Edit 菜单保留标准项（复制 Cmd+C、粘贴 Cmd+V、全选 Cmd+A）——SwiftUI 自动提供，无需自定义
  - [x] 1.5 确保 Window 菜单保留标准项（最小化 Cmd+M、缩放）——SwiftUI 自动提供，无需自定义

- [x] Task 2: 重构 AppState 以支持 Command 回调（AC: #2, #3, #4）
  - [x] 2.1 将 `sessionViewModel`、`settingsViewModel`、`isSettingsPresented`、`isInspectorVisible`、`isDebugPanelVisible` 从 ContentView 的 `@State` 提升到共享状态对象——使用 `@Observable` class `AppState` 或通过 `@Environment` 传递
  - [x] 2.2 在 SwiftWorkApp 中创建共享状态，通过 `.environment()` 注入到 ContentView
  - [x] 2.3 更新 ContentView 读取共享状态而非自有 `@State`——确保 menu commands 和 View 引用同一实例
  - [x] 2.4 在 SwiftWorkApp 中实现 Command closures，通过共享状态调用 ViewModel 方法

- [x] Task 3: 单元测试（AC: #1-#4）
  - [x] 3.1 新建 `SwiftWorkTests/App/MenuBarCommandsTests.swift`：
    - 测试 Cmd+N 命令调用 `sessionViewModel.createSession()` 后 sessions 数组增加
    - 测试 Cmd+, 命令将 `isSettingsPresented` 设为 true
    - 测试 Cmd+I 命令切换 `isInspectorVisible`
    - 测试 Cmd+Shift+D 命令切换 `isDebugPanelVisible`
  - [x] 3.2 更新 `SwiftWorkTests/App/AppEntryTests.swift`——验证 SwiftWorkApp body 包含 `Commands` builder
  - [x] 3.3 所有新测试通过 `swift test`，现有 567 个测试无回归

## Dev Notes

### 核心目标

为 SwiftWork 添加标准 macOS 菜单栏和键盘快捷键，覆盖 File/Edit/View/Window/Help 五个标准菜单。用户可以通过键盘快捷键执行常用操作：Cmd+N 新建会话、Cmd+W 关闭窗口、Cmd+, 打开设置、Cmd+I 切换 Inspector、Cmd+Shift+D 切换 Debug Panel。

### 已有基础（必须在此基础上扩展，不重新创建）

1. **`SwiftWorkApp.swift`**（`App/`）——`@main` 入口，当前仅包含 `WindowGroup` + `.defaultSize` + `.modelContainer`。需要添加 `.commands()` modifier 注册自定义菜单命令
2. **`ContentView.swift`**（`App/`）——持有所有关键 `@State`：`sessionViewModel`、`settingsViewModel`、`isSettingsPresented`、`isInspectorVisible`、`isDebugPanelVisible`。**问题：这些状态在 ContentView 内部，SwiftWorkApp 的 Command closures 无法直接访问。需要重构状态提升**
3. **`SessionViewModel.swift`**（`ViewModels/`）——已有 `createSession()` 方法，Cmd+N 直接调用此方法
4. **`SettingsView.swift`**（`Views/Settings/`）——设置页面已有，通过 `isSettingsPresented` 控制显示。Cmd+, 只需将此 flag 设为 true
5. **`WorkspaceView.swift`**（`Views/Workspace/`）——持有 `isInspectorVisible` 和 `isDebugPanelVisible` Binding。当前这两个 Binding 从 ContentView 传入

### 架构关键决策

**状态提升方案——`AppState` 共享对象：**

SwiftUI 的 `Command` closures 运行在 `App` 层，而当前所有交互状态（`isSettingsPresented`、`isInspectorVisible` 等）和 ViewModel 实例都在 `ContentView` 内部。为了让菜单命令能触发这些状态变更，需要将共享状态提升到 App 层。

推荐方案：创建 `AppState` `@Observable` class，包含 ViewModel 实例和 UI 状态标志：

```swift
@MainActor
@Observable
final class AppState {
    let sessionViewModel = SessionViewModel()
    let settingsViewModel = SettingsViewModel()
    var isSettingsPresented = false
    var isInspectorVisible = false
    var isDebugPanelVisible = false
    // ... 其他共享状态
}
```

在 SwiftWorkApp 中创建实例，通过 `.environment(AppState.self, appState)` 注入。ContentView 和 Commands 都引用同一个实例。

**替代方案（更轻量）：** 直接在 SwiftWorkApp 中 `@State` 持有这些 ViewModel 和状态，通过 init 参数传入 ContentView。但这种方式不如 Environment 优雅，且不利于后续扩展。

**推荐 `AppState` 方案**——它让状态所有权清晰，且与 `@Observable` + SwiftUI Environment 的模式一致。

**Command 注册方式：**

```swift
// SwiftWorkApp.swift
@main
struct SwiftWorkApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .commands {
            // File menu
            CommandGroup(replacing: .newItem) {
                Button("新建会话") {
                    appState.sessionViewModel.createSession()
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            // View menu
            CommandGroup(after: .toolbar) {
                Button("切换 Inspector") {
                    withAnimation { appState.isInspectorVisible.toggle() }
                }
                .keyboardShortcut("i", modifiers: .command)

                Button("切换 Debug Panel") {
                    withAnimation { appState.isDebugPanelVisible.toggle() }
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }

            // Settings (Cmd+,)
            CommandGroup(replacing: .appSettings) {
                Button("设置...") {
                    appState.isSettingsPresented = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
```

**SwiftUI 自动提供的标准菜单项：**
- **Edit 菜单**：复制 (Cmd+C)、粘贴 (Cmd+V)、剪切 (Cmd+X)、全选 (Cmd+A)、撤销 (Cmd+Z)、重做 (Cmd+Shift+Z)——SwiftUI 自动为 Text/TextField 提供
- **Window 菜单**：最小化 (Cmd+M)、缩放、全部前置——SwiftUI 自动提供
- **Help 菜单**：搜索——SwiftUI 自动提供

**我们只需自定义：**
- File 菜单的「新建」命令（替换默认的 New Window）
- View 菜单添加 Inspector 和 Debug Panel 切换
- 设置命令（替换默认的 Preferences...）
- Help 菜单可添加「关于 SwiftWork」和「文档链接」

### ContentView 重构影响

**当前 ContentView 持有的 @State 变量需要迁移到 AppState：**
- `sessionViewModel` → `appState.sessionViewModel`
- `settingsViewModel` → `appState.settingsViewModel`
- `isSettingsPresented` → `appState.isSettingsPresented`
- `isInspectorVisible` → `appState.isInspectorVisible`
- `isDebugPanelVisible` → `appState.isDebugPanelVisible`

**仍留在 ContentView 的 @State（局部 UI 状态）：**
- `hasCompletedOnboarding`——仅 ContentView 使用
- `mainWindow`——WindowAccessor 回调，仅 ContentView 使用
- `notificationObservers`——生命周期监听，仅 ContentView 使用
- `eventStore`——可考虑移到 AppState，但不是必须
- `appStateManager`——可考虑移到 AppState

**ContentView 需要 `@Environment(AppState.self)` 读取共享状态。** 注意 `@Environment` 变量不能有默认 `@State` 包装，需要从环境中读取。迁移时需要注意：
- `@State private var sessionViewModel` → `@Environment(AppState.self) private var appState`，通过 `appState.sessionViewModel` 访问
- 传递给子 View 的参数签名不变（子 View 仍接收具体的 ViewModel/Binding）
- `.sheet(isPresented:)` 需要绑定到 `appState.isSettingsPresented`

### 关于菜单栏与 SwiftUI 的注意事项

1. **`CommandGroup(replacing: .newItem)`** —— 覆盖 File 菜单的「New」项。默认 macOS SwiftUI 应用会在 File 菜单显示「New Window」(Cmd+N)，我们将其替换为「新建会话」
2. **`CommandGroup(replacing: .appSettings)`** —— 覆盖应用菜单的「Settings...」(Cmd+,)。SwiftUI macOS 应用自动在应用菜单（第一个菜单，显示应用名称）添加「Settings...」，我们保留此行为但确保绑定正确
3. **Cmd+W 关闭窗口** —— SwiftUI `WindowGroup` 自动处理 Cmd+W，无需自定义。这是标准行为
4. **`CommandGroup(after: .toolbar)`** —— 在 View 菜单的 Toolbar 分组之后添加自定义项
5. **`CommandGroup(replacing: .help)`** —— 可选，用于自定义 Help 菜单
6. **菜单项文字使用中文** —— 与应用其他 UI 保持一致

### 与前后 Story 的关系

- **Story 4-2（应用设置页面）**——4-2 实现了 SettingsView 的多 Tab 设置页面。本 Story 添加 Cmd+, 快捷键打开该设置页面。4-2 已通过 Sidebar 齿轮按钮打开设置，本 Story 只是增加菜单栏/快捷键入口
- **Story 4-1（Debug Panel）**——4-1 添加了 DebugView。本 Story 添加 Cmd+Shift+D 快捷键切换 Debug Panel
- **Story 3-4（Inspector Panel）**——3-4 添加了 InspectorView。本 Story 添加 Cmd+I 快捷键切换 Inspector
- **Story 1-3（会话管理 Sidebar）**——1-3 实现了 SidebarView 和 `sessionViewModel.createSession()`。本 Story 的 Cmd+N 调用同一方法

### 前序 Story 学习（Story 4-2 应用设置页面）

- 4-2 模式：ContentView 持有 `@State private var isSettingsPresented`，通过 `.sheet` 弹出。本 Story 需要将此状态提升到共享 AppState
- 4-2 模式：SettingsViewModel 通过参数传入 SettingsView。状态提升后，传入方式不变
- 4-2 模式：723 个测试全部通过。本 Story 的重构必须保持所有现有测试通过
- 4-2 Review Finding：`loadCurrentConfig()` 未在设置页面打开时调用——已修复。本 Story 不需要修改此逻辑

### 文件变更清单

**NEW（新建文件）：**
- `SwiftWork/App/AppState.swift` -- 共享应用状态对象，持有 ViewModel 和 UI 状态标志
- `SwiftWorkTests/App/MenuBarCommandsTests.swift` -- 菜单命令快捷键测试

**UPDATE（更新文件）：**
- `SwiftWork/App/SwiftWorkApp.swift` -- 添加 `.commands()` modifier 注册菜单命令，注入 AppState
- `SwiftWork/App/ContentView.swift` -- 从 @State 迁移到 @Environment(AppState)，保留局部 UI 状态
- `SwiftWorkTests/App/AppEntryTests.swift` -- 验证 SwiftWorkApp 包含 Commands

**UNCHANGED（不修改——零回归风险）：**
- `SwiftWork/Views/Sidebar/SidebarView.swift` -- createSession() 接口不变
- `SwiftWork/ViewModels/SessionViewModel.swift` -- 方法签名不变
- `SwiftWork/ViewModels/SettingsViewModel.swift` -- 方法签名不变
- `SwiftWork/Views/Settings/SettingsView.swift` -- 接收参数不变
- `SwiftWork/Views/Workspace/WorkspaceView.swift` -- Binding 传入方式不变（只是来源从 ContentView @State 变为 AppState 属性）
- `SwiftWork/Views/Workspace/Inspector/DebugView.swift` -- 不修改
- `SwiftWork/Views/Workspace/Inspector/InspectorView.swift` -- 不修改

### Project Structure Notes

- `AppState.swift` 放在 `SwiftWork/App/` 目录（与 SwiftWorkApp.swift 并列）——它属于应用层状态管理
- 测试文件放在 `SwiftWorkTests/App/` 目录（已有 AppEntryTests.swift）
- 不引入新的 SPM 依赖
- 不引入新的 SwiftData Model
- 遵循 View 只依赖 ViewModel 和 Models/UI 的分层规则
- AppState 是 App 层的对象，不在 Views/ViewModels/ 目录中

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 4.3: macOS 菜单栏与快捷键]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 11: 项目结构 — App/ 目录]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 8: 状态管理 — @Observable]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 12: 部署与更新 — macOS 标准]
- [Source: _bmad-output/project-context.md#Architecture Boundary Rules]
- [Source: _bmad-output/project-context.md#Framework-Specific Rules — SwiftUI]
- [Source: _bmad-output/implementation-artifacts/4-2-app-settings.md -- 前序 Story dev notes]
- [Source: SwiftWork/App/SwiftWorkApp.swift -- 当前 @main 入口]
- [Source: SwiftWork/App/ContentView.swift -- 当前状态持有方式]
- [Source: SwiftWork/ViewModels/SessionViewModel.swift -- createSession() 方法]
- [Source: SwiftWork/Views/Workspace/WorkspaceView.swift -- Inspector/Debug Panel Binding]

## Dev Agent Record

### Agent Model Used

GLM-5.1

### Debug Log References

- No blocking issues encountered
- All ATDD tests passed on first run after implementation
- Full regression suite: 567 tests passed, 0 failures

### Completion Notes List

- Created AppState.swift as @MainActor @Observable final class with sessionViewModel, settingsViewModel, isSettingsPresented, isInspectorVisible, isDebugPanelVisible
- Refactored ContentView to use @Environment(AppState.self) instead of @State for shared properties, using explicit Binding wrappers for .sheet and WorkspaceView bindings
- Added .commands modifier to SwiftWorkApp with CommandGroup(replacing: .newItem), CommandGroup(after: .toolbar), CommandGroup(replacing: .appSettings)
- Added testSwiftWorkAppIncludesCommands to AppEntryTests.swift
- Edit/Window/Help menus rely on SwiftUI default behavior — no custom code needed
- All 18 ATDD tests (MenuBarCommandsTests + AppStateIntegrationTests) + 3 AppEntryTests pass
- Full suite: 567 tests, 0 failures, 0 regressions

### File List

**NEW:**
- SwiftWork/App/AppState.swift

**MODIFIED:**
- SwiftWork/App/SwiftWorkApp.swift
- SwiftWork/App/ContentView.swift
- SwiftWorkTests/App/AppEntryTests.swift
- SwiftWork.xcodeproj/project.pbxproj

**EXISTING (pre-created by TEA Agent):**
- SwiftWorkTests/App/MenuBarCommandsTests.swift
- SwiftWorkTests/App/AppStateIntegrationTests.swift

### Change Log

- 2026-05-03: Story 4-3 implementation complete — AppState created, ContentView migrated to @Environment(AppState), SwiftWorkApp commands registered, all ATDD tests green
