# Story 3.2: 权限配置与规则管理

Status: done

## Story

As a 用户,
I want 在设置中查看和管理权限规则，以及选择全局权限模式,
so that 我可以精细化控制 Agent 的行为边界。

## Acceptance Criteria

1. **Given** 用户打开设置页面 **When** 导航到权限管理区域 **Then** 显示 PermissionRulesView，列出所有已授权的权限规则（工具名、模式、决策）（FR25）

2. **Given** 用户查看权限规则列表 **When** 点击某条规则并选择删除 **Then** 规则从列表和 SwiftData 中移除，后续同类操作将重新要求审批

3. **Given** 用户打开设置页面 **When** 查看全局权限模式选项 **Then** 可选择"自动批准"、"手动审批"、"全部拒绝"模式（FR26） **And** 模式选择立即生效，影响后续所有工具调用的评估逻辑

**覆盖的 FRs:** FR25, FR26
**覆盖的 ARCHs:** ARCH-6

## Tasks / Subtasks

- [x] Task 1: 实现 PermissionRulesView（权限规则列表 UI）（AC: #1, #2）
  - [x] 1.1 创建 `SwiftWork/Views/Permission/PermissionRulesView.swift`——使用 `@Query` 从 SwiftData 查询所有 PermissionRule，按 createdAt 降序排列
  - [x] 1.2 列表行显示：工具类型标签（Bash→"终端命令"等，复用 `PermissionHandler.toolTypeLabel`）、模式（pattern）、决策（`.allow`→绿色"允许"、`.deny`→红色"拒绝"）、创建时间
  - [x] 1.3 每行提供删除按钮（红色垃圾桶图标或滑动删除），点击后弹出确认对话框，确认后从 SwiftData 删除并刷新列表
  - [x] 1.4 空状态：列表为空时显示"暂无权限规则。在手动审批模式下，Agent 工具调用时可通过'始终允许'创建规则。" 提示
  - [x] 1.5 限制：View 不直接操作 SwiftData——通过回调方法让父 View/ViewModel 调用 PermissionHandler 处理删除

- [x] Task 2: 扩展 PermissionHandler 支持规则删除和全局模式持久化（AC: #2, #3）
  - [x] 2.1 添加 `deleteRule(_ rule: PermissionRule)` 方法——从 cachedRules 中移除、从 ModelContext 中删除、调用 save
  - [x] 2.2 添加 `deleteRule(at indexSet: IndexSet)` 方法——批量删除（支持 SwiftUI List 的 `onDelete`）
  - [x] 2.3 持久化 globalMode：将当前 `globalMode` 保存到 `AppConfiguration`（key: `"globalPermissionMode"`），应用启动时恢复
  - [x] 2.4 添加 `persistGlobalMode()` 私有方法——写入 AppConfiguration
  - [x] 2.5 在 `setModelContext()` 中加载已保存的 globalMode（从 AppConfiguration 读取并恢复）
  - [x] 2.6 在 `globalMode` 的 `didSet` 中调用 `persistGlobalMode()`（仅当 modelContext 已配置时）

- [x] Task 3: 实现全局权限模式切换 UI（AC: #3）
  - [x] 3.1 在 PermissionRulesView 顶部添加 Picker 控件，绑定 `PermissionHandler.globalMode`
  - [x] 3.2 三个选项：自动批准（`.autoApprove`）、手动审批（`.manualReview`）、全部拒绝（`.denyAll`）
  - [x] 3.3 每个选项附带简要说明文字（如手动审批："每次工具调用都需要用户审批"）
  - [x] 3.4 模式切换立即生效——Picker 的 `onChange` 无需额外操作（`globalMode` 的 `didSet` 自动持久化）
  - [x] 3.5 模式旁显示当前活跃模式的含义提示（使用 `.help()` modifier）

- [x] Task 4: 重写 SettingsView 集成权限配置（AC: #1, #3）
  - [x] 4.1 将 SettingsView 从 stub（当前仅 `Text("Settings")`）重写为带 Tab 或 Section 的设置页面
  - [x] 4.2 添加"权限管理"区域（Section 或 Tab），内嵌 PermissionRulesView
  - [x] 4.3 SettingsView 需要接收 `PermissionHandler` 实例（通过 init 参数），以便 PermissionRulesView 访问
  - [x] 4.4 SettingsView 通过 `.modelContainer` 环境自动注入 SwiftData，PermissionRulesView 使用 `@Query` 查询 PermissionRule
  - [x] 4.5 确保 SettingsView 不超过 300 行——如果权限管理区域过大，拆分为独立的 SettingsPermissionSection View

- [x] Task 5: 连接 SettingsView 到应用入口（AC: #1, #3）
  - [x] 5.1 在 ContentView 中添加 SettingsView 的打开方式（macOS 标准方式：Cmd+, 或菜单栏 Window > Settings）
  - [x] 5.2 使用 `@Environment(\.modelContext)` 传递给 SettingsView
  - [x] 5.3 传递 `agentBridge.permissionHandler` 给 SettingsView，使权限规则和模式可管理
  - [x] 5.4 确保 SettingsView 打开时不会中断当前 Agent 执行

- [x] Task 6: 单元测试（AC: #1-#3）
  - [x] 6.1 在 `SwiftWorkTests/SDKIntegration/PermissionHandlerTests.swift` 中添加测试：
    - 测试 `deleteRule` 正确从 cachedRules 和 ModelContext 中移除规则
    - 测试 `deleteRule(at:)` 批量删除
    - 测试 `globalMode` 持久化到 AppConfiguration 并在重新加载后恢复
    - 测试 globalMode didSet 触发 persistGlobalMode
  - [x] 6.2 创建 `SwiftWorkTests/Views/Permission/PermissionRulesViewTests.swift`（如果可行）或验证 View 通过 `@Testable` 导入正确编译
  - [x] 6.3 所有新测试通过 `swift test`，现有测试无回归

## Dev Notes

### 核心目标：在设置页面中提供权限规则管理和全局模式切换

本 Story 基于 Story 3-1 创建的 PermissionHandler 评估引擎，添加**用户可见的配置界面**。开发者需要在 SettingsView 中嵌入 PermissionRulesView（规则列表）和全局模式切换器。

### 已有基础（必须在此基础上扩展，不重新创建）

1. **`PermissionHandler.swift`**（`SDKIntegration/`）——已实现 `globalMode` 属性、`evaluate()` 方法、`addPersistentRule()` 方法、`reloadRules()` 方法、`cachedRules` 缓存。本 Story 需要添加 `deleteRule()` 方法和 `globalMode` 持久化。
2. **`PermissionRule.swift`**（`Models/SwiftData/`）——SwiftData 模型，含 `id`、`toolName`、`pattern`、`decision`（`.allow` / `.deny`）、`createdAt`。不需要修改。
3. **`PermissionDecision.swift`**（`Models/UI/`）——三态枚举。不需要修改。
4. **`SettingsView.swift`**（`Views/Settings/`）——当前是 stub（仅 `Text("Settings")`），需要完整重写为设置页面。
5. **`SettingsViewModel.swift`**（`ViewModels/`）——已有 API Key、模型选择管理。不需要修改本文件（权限管理不通过 SettingsViewModel，直接用 PermissionHandler）。
6. **`AppConfiguration.swift`**（`Models/SwiftData/`）——KV 配置模型，用于存储 `globalPermissionMode`。不需要修改。
7. **`ContentView.swift`**（`App/`）——已有 `agentBridge` 和 `agentBridge.permissionHandler` 引用。需要添加 SettingsView 的打开方式。

### 架构决策参考

**权限引擎设计（ARCH-6）：**
```
PermissionEngine（概念名）= PermissionHandler（实现文件名）
├── globalMode: PermissionMode (autoApprove / manualReview / denyAll)
├── rules: [PermissionRule] (持久化)
├── sessionOverrides: [ToolName: Decision] (会话级临时授权)
└── func evaluate(toolCall: ToolCall) -> PermissionDecision
```

**分层边界规则：**
- SettingsView 是 View 层，只依赖 ViewModel 和 Models/UI
- PermissionRulesView 可以通过 `@Query` 直接查询 SwiftData PermissionRule（View 层查询只读数据是允许的）
- 规则删除操作必须通过 PermissionHandler（不直接操作 ModelContext）
- 全局模式修改通过 PermissionHandler.globalMode 属性（`didSet` 自动持久化）

### 关键技术注意事项

1. **PermissionRulesView 使用 `@Query`**：SwiftUI 的 `@Query` 属性包装器可以直接在 View 中查询 SwiftData 模型。这适用于只读展示。删除操作通过 PermissionHandler 方法回调。

2. **globalMode 持久化方案**：使用 `AppConfiguration` KV 模型存储，key 为 `"globalPermissionMode"`，value 为 `Data(GlobalPermissionMode.rawValue.utf8)`。读取时使用 `GlobalPermissionMode(rawValue:)` 初始化。这与 `selectedModel` 的存储模式一致（参见 SettingsViewModel.configure）。

3. **SettingsView 打开方式**：macOS 标准方式是 Cmd+, 或菜单栏。当前项目未实现菜单栏（属于 Epic 4 Story 4.3），因此本 Story 先用简单的按钮或 sheet 方式打开设置。可在 Sidebar 底部添加设置按钮（齿轮图标），点击后以 sheet 或 navigation destination 打开 SettingsView。

4. **不影响现有功能**：默认 globalMode 保持 `.autoApprove`。SettingsView 是新 UI，不影响 Timeline、Sidebar、InputBar 等现有组件。

5. **PermissionHandler 的 deleteRule 需要刷新 cachedRules**：删除后从 cachedRules 数组中移除对应条目，同时从 ModelContext 删除并 save。不需要手动 reloadRules()（那样会重新查询所有规则，效率低）。

6. **View 文件不超过 300 行**：如果 SettingsView 因嵌入多个 Section 超过 300 行，将权限管理区域拆分为 `SettingsPermissionSection.swift`（放在 `Views/Settings/` 目录下）。

7. **`@Query` 排序**：`@Query(sort: \PermissionRule.createdAt, order: .reverse)` 按创建时间降序排列，最新规则在顶部。

### UI 设计参考

**PermissionRulesView 布局（macOS 原生风格）：**

```
┌──────────────────────────────────────────────────┐
│ 全局权限模式                                       │
│ ┌──────────────────────────────────────────────┐ │
│ │ ○ 自动批准  ○ 手动审批  ○ 全部拒绝            │ │
│ └──────────────────────────────────────────────┘ │
│                                                  │
│ 权限规则（3 条）                                   │
│ ┌──────────────────────────────────────────────┐ │
│ │ 终端命令  rm *            允许  2026-05-02  [🗑]│ │
│ │ 文件编辑  *.swift         允许  2026-05-01  [🗑]│ │
│ │ 文件读取  *               拒绝  2026-05-01  [🗑]│ │
│ └──────────────────────────────────────────────┘ │
│                                                  │
│ 暂无规则时显示空状态提示                            │
└──────────────────────────────────────────────────┘
```

- 工具类型标签复用 `PermissionHandler.toolTypeLabel(_:)` 静态方法
- 决策标签：`.allow`→绿色圆形+文字"允许"，`.deny`→红色圆形+文字"拒绝"
- 删除按钮使用 SF Symbol `trash`，点击后 `Alert` 确认
- 全局模式使用 `Picker` with `.segmented` style 或 Radio buttons

### 数据流图

```
SettingsView
    ├── 传入: PermissionHandler 实例
    │
    ├── PermissionRulesView
    │   ├── @Query var rules: [PermissionRule]  // 只读查询
    │   ├── 显示规则列表
    │   └── 删除按钮 → permissionHandler.deleteRule(rule)
    │
    └── 全局模式 Picker
        └── 绑定: permissionHandler.globalMode
            └── didSet → persistGlobalMode() → AppConfiguration

PermissionHandler
    ├── globalMode (didSet → persistGlobalMode)
    ├── deleteRule() → 从 cachedRules 移除 + ModelContext.delete + save
    └── reloadRules() → 在 setModelContext 时恢复 globalMode
```

### 文件变更清单

**NEW（新建文件）：**
- `SwiftWork/Views/Permission/PermissionRulesView.swift` -- 权限规则列表 + 全局模式切换 UI

**UPDATE（更新文件）：**
- `SwiftWork/SDKIntegration/PermissionHandler.swift` -- 添加 deleteRule 方法、globalMode 持久化
- `SwiftWork/Views/Settings/SettingsView.swift` -- 从 stub 重写为设置页面（含权限管理区域）
- `SwiftWork/App/ContentView.swift` -- 添加 SettingsView 打开方式（传入 permissionHandler）
- `SwiftWork.xcodeproj/project.pbxproj` -- 新文件引用

**UNCHANGED（不修改——零回归风险）：**
- `SwiftWork/Models/SwiftData/PermissionRule.swift` -- 已有模型，直接使用
- `SwiftWork/Models/UI/PermissionDecision.swift` -- 已有枚举，直接使用
- `SwiftWork/Models/UI/PermissionAuditEntry.swift` -- 审计日志模型不变
- `SwiftWork/Models/UI/PendingPermissionRequest.swift` -- 请求封装不变
- `SwiftWork/Views/Permission/PermissionDialogView.swift` -- 权限弹窗不变
- `SwiftWork/SDKIntegration/AgentBridge.swift` -- SDK 集成不变
- `SwiftWork/ViewModels/SettingsViewModel.swift` -- API Key/模型管理不变
- `SwiftWork/Views/Workspace/WorkspaceView.swift` -- Workspace 不变
- 所有 Timeline、EventView、Sidebar、InputBar 组件不变

### 与前后 Story 的关系

- **Story 3-1（权限系统实现）**：本 Story 直接使用 3-1 创建的 PermissionHandler 的 `globalMode`、`cachedRules`、`reloadRules()` 方法。3-1 已实现评估逻辑和 PermissionDialogView 弹窗，本 Story 只添加配置管理 UI。
- **Story 3-3（会话管理增强）**：不受影响。3-3 关注 Sidebar 的删除/重命名操作和追加消息功能。
- **Story 4-2（应用设置页面）**：本 Story 创建了基础的 SettingsView。4-2 将扩展 SettingsView 添加 API Key 管理、模型选择等更多设置项。注意保持 SettingsView 的扩展性（使用 Section 组织内容）。

### Project Structure Notes

- `PermissionRulesView.swift` 放在 `SwiftWork/Views/Permission/` -- 权限 UI 目录，与 PermissionDialogView 同级
- `SettingsView.swift` 保持在 `SwiftWork/Views/Settings/` -- 设置页面目录
- 如果 SettingsView 超过 300 行，拆分权限管理区域为 `SwiftWork/Views/Settings/SettingsPermissionSection.swift`
- 遵循 View 只依赖 ViewModel 和 Models/UI 的分层规则
- 删除操作通过 PermissionHandler 方法（不在 View 中直接操作 ModelContext）

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.2: 权限配置与规则管理]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 5: 权限引擎设计]
- [Source: _bmad-output/project-context.md#权限系统]
- [Source: _bmad-output/implementation-artifacts/3-1-permission-system.md -- 前序 Story 上下文和 dev agent record]
- [Source: SwiftWork/SDKIntegration/PermissionHandler.swift -- 当前权限评估引擎实现]
- [Source: SwiftWork/Models/SwiftData/PermissionRule.swift -- SwiftData 权限规则模型]
- [Source: SwiftWork/Models/SwiftData/AppConfiguration.swift -- KV 配置模型（用于存储 globalMode）]
- [Source: SwiftWork/Views/Settings/SettingsView.swift -- 当前 stub 待重写]
- [Source: SwiftWork/Views/Settings/SettingsViewModel.swift -- API Key/模型管理模式参考]
- [Source: SwiftWork/App/ContentView.swift -- 应用入口，agentBridge.permissionHandler 已可用]
- [Source: SwiftWork/Utils/Constants.swift -- 应用常量（可添加权限相关常量）]

## Dev Agent Record

### Agent Model Used

GLM-5.1

### Debug Log References

- Fixed critical test crash: ATDD tests used tuple destructuring `let (handler, _, context) = makeHandlerWithContainer()` which released the `ModelContainer` via `_`, making the `ModelContext` invalid. Fixed by storing container as instance variable `testContainer` in test classes.

### Completion Notes List

- Implemented `deleteRule(_:)` and `deleteRule(at:)` on PermissionHandler for single and batch rule deletion
- Added `globalMode` persistence via AppConfiguration with `persistGlobalMode()` and `loadPersistedGlobalMode()` methods
- Used `didSet` on `globalMode` with `isModelContextConfigured` guard to avoid persisting during load
- Created PermissionRulesView with `@Query` for rule list, segmented Picker for mode, empty state, and swipe-to-delete with confirmation dialog
- Rewrote SettingsView from stub to TabView with PermissionRulesView embedded
- Added settings gear button to ContentView sidebar toolbar, opening SettingsView as sheet
- Fixed 3 ATDD test files to keep ModelContainer alive via instance variable pattern
- All 560 tests pass with 0 failures, 0 regressions

### File List

**NEW:**
- SwiftWork/Views/Permission/PermissionRulesView.swift

**UPDATED:**
- SwiftWork/SDKIntegration/PermissionHandler.swift
- SwiftWork/Views/Settings/SettingsView.swift
- SwiftWork/App/ContentView.swift
- SwiftWork.xcodeproj/project.pbxproj

**TEST FIXES:**
- SwiftWorkTests/SDKIntegration/PermissionHandlerConfigTests.swift
- SwiftWorkTests/Views/Permission/PermissionRulesViewTests.swift
- SwiftWorkTests/Views/Settings/SettingsViewIntegrationTests.swift

## Change Log

- 2026-05-02: Story 3-2 implementation complete - permission config rules and settings UI
- 2026-05-02: Code review passed - 3 patches applied (unused import, single-tab TabView, double-delete guard), 1 deferred (silent error swallowing), 1 dismissed
