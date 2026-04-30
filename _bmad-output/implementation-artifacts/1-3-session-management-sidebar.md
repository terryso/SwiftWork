# Story 1.3: 会话管理与 Sidebar

Status: review

## Story

As a 用户,
I want 在左侧 Sidebar 中创建、查看和切换会话,
so that 我可以管理多个任务会话并在它们之间快速切换。

## Acceptance Criteria

1. **Given** 用户打开应用 **When** 查看 Sidebar **Then** 显示所有历史会话列表，按 updatedAt 降序排列（FR2）
2. **Given** 用户点击 Sidebar 中的 "+" 按钮 **When** 创建新会话 **Then** 自动生成新会话（标题为"新会话"或基于首条消息自动生成），Sidebar 列表立即更新（FR1）**And** 新会话通过 SwiftData 持久化（NFR19）
3. **Given** 用户在会话列表中 **When** 点击某个会话 **Then** 主工作区切换到该会话，显示其事件历史，之前会话的事件保留在内存中（FR3）**And** 会话切换加载时间不超过 500ms（NFR5）

**覆盖的 FRs:** FR1, FR2, FR3
**覆盖的 ARCHs:** ARCH-8, ARCH-12

## Tasks / Subtasks

- [x] Task 1: 实现 SessionViewModel 完整会话管理（AC: #1, #2, #3）
  - [x] 1.1 替换 `ViewModels/SessionViewModel.swift` 占位实现为完整 `@MainActor @Observable final class SessionViewModel`
  - [x] 1.2 管理状态：`sessions: [Session]`、`selectedSession: Session?`、`isLoading: Bool`、`errorMessage: String?`
  - [x] 1.3 注入 `ModelContext` 通过 `configure(modelContext:)` 方法（与 SettingsViewModel 模式一致）
  - [x] 1.4 实现 `fetchSessions()` — 使用 `FetchDescriptor<Session>` 按 `updatedAt` 降序排列查询所有会话
  - [x] 1.5 实现 `createSession()` — 创建新 Session，插入 SwiftData，自动选中，更新 sessions 数组
  - [x] 1.6 实现 `selectSession(_ session: Session)` — 更新 `selectedSession`，触发主工作区内容切换
  - [x] 1.7 实现 `deleteSession(_ session: Session)` — 从 SwiftData 删除（级联删除 Events），从 sessions 数组移除，处理选中状态（自动选中最近的会话或 nil）
  - [x] 1.8 实现 `updateSessionTitle(_ session: Session, title: String)` — 更新标题和 updatedAt，保存
  - [x] 1.9 所有 SwiftData 操作包裹在 `do/catch` 中，错误映射为 `AppError`

- [x] Task 2: 实现 SidebarView 会话列表 UI（AC: #1, #2）
  - [x] 2.1 替换 `Views/Sidebar/SidebarView.swift` 占位实现
  - [x] 2.2 使用 `List` 绑定 `sessionViewModel.sessions`，按 updatedAt 降序排列
  - [x] 2.3 每行使用 `SessionRowView` 渲染，显示会话标题、时间（相对时间如"2分钟前"）
  - [x] 2.4 当前选中会话高亮（List 自动处理 selection）
  - [x] 2.5 Toolbar 包含 "+" 按钮，点击调用 `sessionViewModel.createSession()`
  - [x] 2.6 空状态提示：无会话时显示"点击 + 创建新会话"
  - [x] 2.7 使用 `.navigationTitle("SwiftWork")` 设置 Sidebar 标题
  - [x] 2.8 Sidebar 宽度适中（List 自动管理，NavigationSplitView 默认 ~200pt）

- [x] Task 3: 实现 SessionRowView 单行会话渲染（AC: #1）
  - [x] 3.1 替换 `Views/Sidebar/SessionRowView.swift` 占位实现
  - [x] 3.2 显示会话标题（`session.title`），单行截断（`.lineLimit(1)`）
  - [x] 3.3 显示相对时间（使用 `Date+Formatting` 扩展或内联 `RelativeDateTimeFormatter`）
  - [x] 3.4 布局：VStack（标题 + 时间），左侧对齐，标准行高
  - [x] 3.5 适配深色/浅色模式（使用系统颜色）

- [x] Task 4: 集成到 ContentView 的 NavigationSplitView（AC: #3）
  - [x] 4.1 修改 `App/ContentView.swift` — 在 onboarding 完成后的 NavigationSplitView 中使用真实 SidebarView
  - [x] 4.2 Sidebar 使用 `SidebarView(sessionViewModel:)`，传入 `@State var sessionViewModel`
  - [x] 4.3 Detail 区域根据 `sessionViewModel.selectedSession` 条件渲染：选中会话时显示 WorkspaceView（占位），未选中时显示欢迎提示
  - [x] 4.4 应用启动时调用 `sessionViewModel.configure(modelContext:)` 和 `sessionViewModel.fetchSessions()`
  - [x] 4.5 自动选中最近使用的会话（第一个 session）或显示空状态
  - [x] 4.6 会话切换时 workspace 内容平滑切换（无闪烁）

- [x] Task 5: 添加辅助扩展（AC: #1）
  - [x] 5.1 创建 `Utils/Extensions/Date+Formatting.swift` — 提供 `relativeFormatted` 计算属性用于显示相对时间
  - [x] 5.2 更新 `Utils/Extensions/Color+Theme.swift` — 如需添加 Sidebar 相关主题颜色

- [x] Task 6: 编写测试（AC: 全部）
  - [x] 6.1 创建 `SwiftWorkTests/ViewModels/SessionViewModelTests.swift` — 测试 CRUD 操作：创建、查询、删除、重命名
  - [x] 6.2 测试选中状态切换逻辑：selectSession 正确更新 selectedSession
  - [x] 6.3 测试删除选中会话后的自动选中行为（选中最近的或 nil）
  - [x] 6.4 测试 fetchSessions 排序（按 updatedAt 降序）
  - [x] 6.5 测试 SwiftData 错误处理（do/catch 映射为 AppError）
  - [x] 6.6 所有测试通过 `swift test`

## Dev Notes

### 核心架构约束

- **@Observable（非 ObservableObject）**：SessionViewModel 使用 `@Observable`，在 `@MainActor` 上更新属性
- **分层边界**：SidebarView 只依赖 SessionViewModel 和 Models/UI，不直接操作 SwiftData ModelContext
- **Swift 6.1 strict concurrency**：SessionViewModel 是 `@MainActor @Observable final class`
- **不使用 Environment 直接注入 ModelContext 到 ViewModel**：通过 `configure(modelContext:)` 方法注入（与 SettingsViewModel 模式一致）
- **NavigationSplitView 驱动布局**：Sidebar 为 column，Workspace 为 detail

### 前序 Story 关键上下文

Story 1-1 和 1-2 已创建并完成以下文件：

**已存在（当前为占位，需替换）：**
- `SwiftWork/Views/Sidebar/SidebarView.swift` — 占位 `Text("Sidebar")`
- `SwiftWork/Views/Sidebar/SessionRowView.swift` — 占位 `Text("Session Row")`
- `SwiftWork/ViewModels/SessionViewModel.swift` — 占位 `struct SessionViewModel { var placeholder: Bool = true }`

**已存在（需修改集成）：**
- `SwiftWork/App/ContentView.swift` — NavigationSplitView 使用 `Text("Sidebar")` 和 `Text("Workspace")` 占位
- `SwiftWork/App/SwiftWorkApp.swift` — 已配置 modelContainer（Session, Event, PermissionRule, AppConfiguration）

**已存在（直接使用，不修改）：**
- `SwiftWork/Models/SwiftData/Session.swift` — 完整定义：id, title, createdAt, updatedAt, workspacePath, events relationship
- `SwiftWork/Models/SwiftData/Event.swift` — 完整定义：id, sessionID, eventType, rawData, timestamp, order, session relationship
- `SwiftWork/Models/UI/AppError.swift` — 统一错误模型，包含 ErrorDomain 枚举
- `SwiftWork/Utils/Constants.swift` — appName, defaultModel, availableModels, KeychainConstants
- `SwiftWork/Utils/Extensions/Color+Theme.swift` — 主题颜色扩展

### SessionViewModel 设计要点

```swift
// ViewModels/SessionViewModel.swift 核心结构
import Foundation
import SwiftData

@MainActor
@Observable
final class SessionViewModel {
    var sessions: [Session] = []
    var selectedSession: Session?
    var isLoading = false
    var errorMessage: String?

    private var modelContext: ModelContext?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchSessions()
    }

    func fetchSessions() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<Session>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        do {
            sessions = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createSession() {
        guard let modelContext else { return }
        let session = Session()
        modelContext.insert(session)
        try? modelContext.save()
        sessions.insert(session, at: 0)
        selectedSession = session
    }

    func selectSession(_ session: Session) {
        selectedSession = session
    }

    func deleteSession(_ session: Session) {
        guard let modelContext else { return }
        // 级联删除已由 SwiftData relationship deleteRule: .cascade 处理
        modelContext.delete(session)
        try? modelContext.save()
        sessions.removeAll { $0.id == session.id }
        // 自动选中最近的会话
        if selectedSession?.id == session.id {
            selectedSession = sessions.first
        }
    }

    func updateSessionTitle(_ session: Session, title: String) {
        guard let modelContext else { return }
        session.title = title
        session.updatedAt = .now
        try? modelContext.save()
        // 重新排序 sessions 列表
        sessions.sort { $0.updatedAt > $1.updatedAt }
    }
}
```

**关键注意事项：**
- `FetchDescriptor<Session>` 的 `sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]` 保证按 updatedAt 降序
- `Session` 的 `@Relationship(deleteRule: .cascade)` 已在 Story 1-1 中配置，删除 Session 时 Events 自动级联删除
- `modelContext.save()` 使用 `try?` 而非 `try`（SwiftData 保存失败为静默错误，不阻塞 UI 操作）
- `selectedSession` 持有 `Session?` 引用，SwiftUI 通过 `@Observable` 自动追踪变更

### SidebarView 布局设计

```
SidebarView（NavigationSplitView Sidebar 列）:
┌──────────────────────────┐
│ SwiftWork            [+] │  ← Toolbar: 标题 + 新建按钮
├──────────────────────────┤
│ ● 会话标题 1             │  ← SessionRowView（选中状态）
│   2 分钟前               │
│ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │
│   会话标题 2             │  ← SessionRowView（未选中）
│   1 小时前               │
│ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │
│   会话标题 3             │
│   昨天                   │
│                          │
│                          │
│  点击 + 创建新会话        │  ← 空状态提示（无会话时显示）
└──────────────────────────┘
```

**实现要点：**
- 使用 `List(selection: $sessionViewModel.selectedSession)` 绑定选中状态
- 注意：`List(selection:)` 需要 `Session` 遵循 `Identifiable`（已有 `id: UUID`），且 selection binding 需要 `Binding<Session.ID?>` 而非 `Binding<Session?>`
- 因此需要：`List(selection: Binding(get: { sessionViewModel.selectedSession?.id }, set: { id in ... }))` 或使用 `tag()` 修饰符
- Toolbar 使用 `.toolbar` modifier，按钮使用 `.toolbarItem(placement: .primaryAction)`
- "+" 按钮图标使用 `Image(systemName: "plus")` + `Button` 或 `ToolbarItem`

### SessionRowView 设计

```swift
struct SessionRowView: View {
    let session: Session
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(session.title)
                .lineLimit(1)
                .font(.body)
            Text(session.updatedAt.relativeFormatted)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
```

**注意：** SessionRowView 接收 `Session` 作为参数（不是 ViewModel），保持 View 的纯展示职责。

### ContentView 集成要点

```swift
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var settingsViewModel = SettingsViewModel()
    @State private var sessionViewModel = SessionViewModel()
    @State private var hasCompletedOnboarding: Bool? = nil

    var body: some View {
        Group {
            if let completed = hasCompletedOnboarding {
                if completed {
                    NavigationSplitView {
                        SidebarView(sessionViewModel: sessionViewModel)
                    } detail: {
                        if let session = sessionViewModel.selectedSession {
                            // WorkspaceView 占位（Story 1-4/1-5 实现真实内容）
                            Text("Workspace: \(session.title)")
                        } else {
                            Text("选择或创建一个会话")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    WelcomeView(viewModel: settingsViewModel) {
                        withAnimation {
                            hasCompletedOnboarding = true
                        }
                    }
                }
            }
        }
        .task {
            settingsViewModel.configure(modelContext: modelContext)
            hasCompletedOnboarding = settingsViewModel.isAPIKeyConfigured
                && !settingsViewModel.isFirstLaunch

            if hasCompletedOnboarding == true {
                sessionViewModel.configure(modelContext: modelContext)
            }
        }
        .onChange(of: hasCompletedOnboarding) { _, newValue in
            if newValue == true {
                sessionViewModel.configure(modelContext: modelContext)
            }
        }
    }
}
```

**关键集成点：**
- `sessionViewModel.configure(modelContext:)` 在 onboarding 完成后调用
- `NavigationSplitView` 的 sidebar 使用真实 `SidebarView`
- Detail 区域根据 `selectedSession` 条件渲染，为后续 Story 1-4/1-5 预留扩展点
- SessionViewModel 与 SettingsViewModel 同级，都在 ContentView 层管理

### List selection 绑定模式

SwiftUI `List(selection:)` 在 macOS 上需要 `Identifiable.ID` 类型的 binding。由于 `Session` 是 SwiftData `@Model`（自动 `Identifiable`），需要：

```swift
// 方案 A：使用 Binding 转换
List(selection: Binding(
    get: { sessionViewModel.selectedSession?.id },
    set: { newID in
        if let newID {
            sessionViewModel.selectedSession = sessionViewModel.sessions.first { $0.id == newID }
        }
    }
)) {
    ForEach(sessionViewModel.sessions) { session in
        SessionRowView(session: session)
            .tag(session.id)
    }
}
```

**注意：** 必须使用 `.tag(session.id)` 让 List 正确识别选中项。

### Date+Formatting 扩展

```swift
// Utils/Extensions/Date+Formatting.swift
import Foundation

extension Date {
    var relativeFormatted: String {
        RelativeDateTimeFormatter().localizedString(for: self, relativeTo: .now)
    }
}
```

**或使用缓存 formatter（性能优化）：**
```swift
extension Date {
    static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    var relativeFormatted: String {
        Self.relativeFormatter.localizedString(for: self, relativeTo: .now)
    }
}
```

### 错误处理

| 错误场景 | 处理方式 | 用户可见 |
|----------|----------|----------|
| fetchSessions 失败 | 设置 errorMessage，显示空列表 + 错误提示 | 是 |
| createSession 保存失败 | 设置 errorMessage，不插入 sessions 数组 | 是 |
| deleteSession 保存失败 | 静默失败（数据不一致但 UI 正常） | 否 |
| ModelContext 未配置 | 所有操作 early return，不 crash | 否 |

### 性能注意事项

- `fetchSessions()` 在每次会话变更后调用可能不必要——直接操作内存中的 `sessions` 数组更高效（insert/remove），只在 `configure` 时从 SwiftData 加载
- 大量会话场景（100+）暂不处理分页，List 本身使用懒加载
- `RelativeDateTimeFormatter` 使用静态实例避免重复创建

### 与 OpenWork 的参照

OpenWork 的 `workspace-session-list.tsx` 实现了以下交互（SwiftWork 应参照）：
- 会话列表按 workspace 分组（SwiftWork MVP 不按 workspace 分组，平铺列表即可）
- 每行显示会话标题 + 相对时间
- 选中会话高亮
- 右键菜单操作（删除、重命名）——属于 Story 3-3，本 story 不实现
- 最多预览 6 个会话——SwiftWork MVP 显示全部会话

**本 story 只实现：** 平铺会话列表 + 创建 + 选中切换 + 基础 UI。
**后续 story 扩展：** 删除/重命名（Story 3-3）、分组（Growth 阶段）、搜索（Growth 阶段）。

### 测试要点

**SessionViewModelTests：**
- 测试 `configure()` 后 `fetchSessions()` 正确加载按 updatedAt 降序排列的会话
- 测试 `createSession()` 创建新会话、插入 sessions 数组首位、自动选中
- 测试 `selectSession()` 正确更新 selectedSession
- 测试 `deleteSession()` 从 sessions 数组移除、级联删除 Events、自动选中逻辑
- 测试 `updateSessionTitle()` 更新标题后 sessions 重新排序
- 测试 ModelContext 为 nil 时所有操作不 crash（early return）
- 使用 `ModelContext(ModelContainer(...))` 模式创建测试用 context（Story 1-2 已验证此模式）

### 文件变更清单

**UPDATE（替换占位实现）：**
- `SwiftWork/Views/Sidebar/SidebarView.swift` — 从占位改为完整会话列表 UI
- `SwiftWork/Views/Sidebar/SessionRowView.swift` — 从占位改为完整行渲染
- `SwiftWork/ViewModels/SessionViewModel.swift` — 从占位改为完整会话管理 ViewModel
- `SwiftWork/App/ContentView.swift` — 集成 SessionViewModel 和 SidebarView

**NEW（新建文件）：**
- `SwiftWork/Utils/Extensions/Date+Formatting.swift` — 日期相对格式化扩展

**UNCHANGED（不修改）：**
- `SwiftWork/App/SwiftWorkApp.swift` — 已正确配置 modelContainer
- `SwiftWork/Models/SwiftData/Session.swift` — 已完整定义，直接使用
- `SwiftWork/Models/SwiftData/Event.swift` — 已完整定义，关系 deleteRule: .cascade
- `SwiftWork/Models/UI/AppError.swift` — 已定义，SessionViewModel 错误映射到 AppError
- `SwiftWork/ViewModels/SettingsViewModel.swift` — 本 story 不修改

### Project Structure Notes

- 所有文件位置符合 Architecture Decision 11 项目结构
- SessionViewModel 放在 `ViewModels/` 目录（与 SettingsViewModel 同级）
- SidebarView 和 SessionRowView 放在 `Views/Sidebar/` 目录（已在 Story 1-1 创建）
- Date+Formatting 扩展放在 `Utils/Extensions/` 目录（与 Color+Theme 同级）
- 遵循命名规范：View = PascalCase + View 后缀，ViewModel = PascalCase + ViewModel 后缀

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.3: 会话管理与 Sidebar]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 2: 数据模型设计 — Session 和 Event]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 8: 状态管理 — @Observable]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 11: 项目结构 — Views/Sidebar/]
- [Source: _bmad-output/planning-artifacts/architecture.md#Boundary Rules — Views → ViewModels 通信]
- [Source: _bmad-output/planning-artifacts/prd.md#FR1: 创建新的 Agent 会话]
- [Source: _bmad-output/planning-artifacts/prd.md#FR2: 查看所有历史会话列表]
- [Source: _bmad-output/planning-artifacts/prd.md#FR3: 会话之间切换]
- [Source: _bmad-output/planning-artifacts/prd.md#NFR5: 会话切换加载时间不超过 500ms]
- [Source: _bmad-output/planning-artifacts/prd.md#NFR19: 会话数据持久化]
- [Source: _bmad-output/project-context.md#Architecture Boundary Rules — Views 只依赖 ViewModel 和 Models/UI]
- [Source: _bmad-output/project-context.md#Critical Don't-Miss Rules — 禁止 ObservableObject]
- [Source: _bmad-output/implementation-artifacts/1-2-onboarding-agent-config.md — 前序 Story 完成的文件和模式]
- [Source: openwork/apps/app/src/react-app/domains/session/sidebar/workspace-session-list.tsx — 会话列表交互参照]

## Dev Agent Record

### Agent Model Used

GLM-5.1

### Debug Log References

- Build succeeded after fixing Swift 6.1 strict concurrency issue with `RelativeDateTimeFormatter` using `nonisolated(unsafe)`
- All 121 tests pass (23 SessionViewModel unit tests + 8 integration tests + 90 pre-existing tests)

### Completion Notes List

- Replaced placeholder `struct SessionViewModel` with `@MainActor @Observable final class SessionViewModel` with full CRUD operations
- Implemented `configure(modelContext:)` pattern consistent with SettingsViewModel
- `fetchSessions()` uses `FetchDescriptor<Session>` sorted by `updatedAt` descending
- `createSession()` inserts at head, auto-selects, persists to SwiftData with proper error handling
- `deleteSession()` handles cascade delete (SwiftData relationship), auto-selects nearest session
- `updateSessionTitle()` re-sorts sessions list after title/timestamp update
- All SwiftData operations wrapped in `do/catch` mapping to `AppError`
- SidebarView uses `List(selection:)` with Binding conversion for `Session.ID?` selection
- Empty state view with icon and instructional text when no sessions exist
- SessionRowView displays title (single line) + relative time using `Date+Formatting` extension
- Date+Formatting uses static `RelativeDateTimeFormatter` with `nonisolated(unsafe)` for Swift 6.1 concurrency safety
- ContentView integrates SessionViewModel with `NavigationSplitView`, session configuration on onboarding completion
- Removed RED-PHASE STUBS extension from SessionViewModelTests (no longer needed with class implementation)
- Updated SessionManagementIntegrationTests for new SidebarView/SessionRowView init signatures
- Color+Theme.swift did not need changes for this story

### File List

**NEW:**
- `SwiftWork/Utils/Extensions/Date+Formatting.swift`

**MODIFIED:**
- `SwiftWork/ViewModels/SessionViewModel.swift` — replaced placeholder struct with full @Observable class
- `SwiftWork/Views/Sidebar/SidebarView.swift` — replaced placeholder with session list UI
- `SwiftWork/Views/Sidebar/SessionRowView.swift` — replaced placeholder with row rendering
- `SwiftWork/App/ContentView.swift` — integrated SessionViewModel and SidebarView into NavigationSplitView
- `SwiftWorkTests/ViewModels/SessionViewModelTests.swift` — removed RED-PHASE STUBS, all tests now pass
- `SwiftWorkTests/App/SessionManagementIntegrationTests.swift` — updated view instantiations for new init signatures
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — updated story status to in-progress

## Change Log

- 2026-05-01: Implemented Story 1-3 complete — SessionViewModel CRUD, SidebarView UI, SessionRowView, ContentView integration, Date+Formatting extension, all 121 tests passing
