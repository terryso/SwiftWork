# Story 3.3: 会话管理增强

Status: done

## Story

As a 用户,
I want 删除、重命名会话，以及在 Agent 执行中发送追加消息,
so that 我可以更好地组织会话并与 Agent 进行多轮交互。

## Acceptance Criteria

1. **Given** 用户在 Sidebar 中右键点击某个会话 **When** 选择"删除" **Then** 弹出确认对话框，确认后会话及其所有关联事件从 SwiftData 中级联删除（FR4）

2. **Given** 用户在 Sidebar 中右键点击某个会话 **When** 选择"重命名" **Then** 进入内联编辑模式，用户输入新名称后按 Enter 确认，标题更新（FR5）

3. **Given** Agent 正在执行任务 **When** 用户在 InputBar 中输入追加消息并发送 **Then** 消息追加到当前会话，Agent 在当前上下文中处理追加消息（FR30）

4. **Given** 用户在 InputBar 中输入 **When** 按 Shift+Enter **Then** 插入换行而非发送消息；按 Enter 发送消息（FR32）

**覆盖的 FRs:** FR4, FR5, FR30, FR32
**覆盖的 ARCHs:** 无新增（使用已有架构模式）

## Tasks / Subtasks

- [x] Task 1: Sidebar 右键菜单——删除会话（AC: #1）
  - [x] 1.1 在 `SidebarView.swift` 的 `SessionRowView` 行上添加 `.contextMenu` 修饰符，包含"删除"菜单项
  - [x] 1.2 点击删除后弹出确认对话框（`.alert` 修饰符），提示"确定要删除会话「{title}」吗？此操作不可撤销。"
  - [x] 1.3 确认后调用 `sessionViewModel.deleteSession(_:)`——该方法已实现级联删除（SwiftData `deleteRule: .cascade`）
  - [x] 1.4 删除后自动选中列表中第一个剩余会话（已有逻辑在 `deleteSession` 中），若列表为空则显示空状态

- [x] Task 2: Sidebar 右键菜单——重命名会话（AC: #2）
  - [x] 2.1 在 context menu 中添加"重命名"菜单项
  - [x] 2.2 点击重命名后进入内联编辑模式：使用 `@State private var renamingSessionID: UUID?` 和 `@State private var renameText: String` 控制编辑状态
  - [x] 2.3 编辑模式下 `SessionRowView` 的 title 文本替换为 `TextField`，自动获取焦点，初始值为当前标题
  - [x] 2.4 按 Enter 或移除焦点时调用 `sessionViewModel.updateSessionTitle(_:title:)` 保存，退出编辑模式
  - [x] 2.5 按 Escape 取消编辑，恢复原标题

- [x] Task 3: InputBar 支持 Agent 执行中发送追加消息（AC: #3）
  - [x] 3.1 修改 `InputBarView.swift`：移除 `disabled(agentBridge.isRunning)` 对 TextField 的禁用，改为 Agent 运行时仍允许输入
  - [x] 3.2 修改 `AgentBridge.sendMessage(_:)`：移除 `if isRunning { cancelExecution() }` 的自动取消逻辑，改为在 `isRunning` 时直接发送追加消息（不取消当前任务）
  - [x] 3.3 追加消息通过 `agent.streamInput()` 的多轮队列能力处理——SDK 的 `streamInput()` 接受 `AsyncStream<String>` 输入，按顺序处理每个 turn，上下文自动延续，不会中断当前 turn
  - [x] 3.4 InputBar 的发送按钮在 Agent 运行时改为追加样式（保留停止按钮在旁边），用户可以同时看到停止和发送两个按钮
  - [x] 3.5 确保 `sendMessage` 追加时不重置 `isRunning` 状态、不清空现有事件流，只追加用户消息并启动新一轮流式消费

- [x] Task 4: InputBar Shift+Enter 换行支持（AC: #4）
  - [x] 4.1 将 `TextField` 替换为支持多行且可区分 Enter/Shift+Enter 的方案
  - [x] 4.2 使用 SwiftUI 的 `TextField(..., axis: .vertical)` 已支持多行，需要配合 `onSubmit` 处理——当前 `onSubmit` 在 Enter 时发送，但 macOS 上 `TextField(vertical)` 的 Enter 已经是换行
  - [x] 4.3 方案：使用 NSTextView 包装的 `Representable`，或者使用 SwiftUI `TextEditor` 配合键盘事件拦截
  - [x] 4.4 推荐方案：保留 `TextField("...", text: $inputText, axis: .vertical)` 并使用 `.onSubmit(of: .text) { sendMessage() }` + 添加一个 Cmd+Enter 发送快捷键作为备选方案。关键是确保 Enter 单行时发送（TextField vertical 模式 Enter 默认换行），需要使用 `onKeyPress` 或类似机制区分
  - [x] 4.5 最终行为：Enter 发送消息，Shift+Enter 或 Option+Enter 插入换行

- [x] Task 5: 单元测试（AC: #1-#4）
  - [x] 5.1 在 `SwiftWorkTests/ViewModels/SessionViewModelTests.swift` 中添加测试：
    - 测试 `deleteSession` 正确从 sessions 数组和 SwiftData 中移除会话及其事件
    - 测试 `updateSessionTitle` 更新标题后 sessions 列表重新排序（按 updatedAt 降序）
  - [x] 5.2 在 `SwiftWorkTests/Views/Sidebar/SidebarViewTests.swift` 中验证 context menu 存在（编译测试）
  - [x] 5.3 在 `SwiftWorkTests/SDKIntegration/AgentBridgeTests.swift` 中添加测试：
    - 测试 `sendMessage` 在 `isRunning == true` 时不取消现有任务，而是追加消息
  - [x] 5.4 所有新测试通过 `swift test`，现有测试无回归

## Dev Notes

### 核心目标

本 Story 为已有的 Sidebar 和 InputBar 添加三组增强功能：(1) Sidebar 右键菜单操作（删除、重命名），(2) Agent 运行中追加消息能力，(3) Enter/Shift+Enter 键盘行为区分。

### 已有基础（必须在此基础上扩展，不重新创建）

1. **`SidebarView.swift`**（`Views/Sidebar/`）——已有 List + ForEach + SessionRowView 结构。需要添加 `.contextMenu` 修饰符和编辑状态管理。当前无 context menu。
2. **`SessionRowView.swift`**（`Views/Sidebar/`）——当前是简单的只读展示（title + updatedAt）。需要支持内联编辑模式（`TextField` 替代 `Text`）。
3. **`SessionViewModel.swift`**（`ViewModels/`）——**已有** `deleteSession(_:)` 和 `updateSessionTitle(_:title:)` 方法，均已正确实现。本 Story 不需要修改此文件。
4. **`InputBarView.swift`**（`Views/Workspace/InputBar/`）——当前 `disabled(agentBridge.isRunning)` 阻止运行时输入。`onSubmit` 直接调用 `sendMessage()`。使用 `TextField("...", text: $inputText, axis: .vertical)`。
5. **`AgentBridge.swift`**（`SDKIntegration/`）——`sendMessage` 方法在 `isRunning` 时自动 `cancelExecution()`。需要改为追加消息逻辑。
6. **`Session.swift`**（`Models/SwiftData/`）——`@Relationship(deleteRule: .cascade)` 已配置级联删除。不需要修改。
7. **`ContentView.swift`**（`App/`）——SidebarView 在 NavigationSplitView 的 sidebar 中。不需要修改。

### 架构决策参考

**分层边界规则：**
- SidebarView 的删除和重命名操作通过 `SessionViewModel` 已有方法——View 不直接操作 SwiftData
- InputBar 的追加消息通过 `AgentBridge.sendMessage()`——View 不直接操作 SDK
- 保持 View < 300 行——如果 SidebarView 超出，考虑将 editing state 提取到辅助结构

### 关键技术注意事项

1. **SessionViewModel 不需要修改**：`deleteSession` 和 `updateSessionTitle` 方法已完整实现。SidebarView 只需调用即可。

2. **SwiftUI context menu 在 macOS 上的行为**：`.contextMenu` 在 macOS 上通过右键触发。可以包含多个按钮（删除、重命名）。这是原生行为，不需要额外依赖。

3. **内联编辑模式实现**：使用 `@State` 控制哪个 session 处于编辑状态。编辑模式下 `SessionRowView` 内部切换显示为 `TextField`。注意需要将 renaming 状态提升到 `SidebarView` 层级，因为 context menu 触发点在父级 List 的行上。

4. **Agent 运行中追加消息的 SDK 行为**：SDK 的 `Agent.streamInput()` 接受 `AsyncStream<String>` 输入流，按顺序处理每个 turn。追加消息通过 `yield` 写入输入流，SDK 在当前 turn 完成后自动处理下一个。使用 `pendingTurnCount` 计数器跟踪待处理 turn 数，全部完成后关闭输入流使 `isRunning` 自动变 false。不会中断当前正在执行的 turn。

5. **Shift+Enter 与 TextField 的冲突**：最终使用 `NSTextView` 包装的 `NSViewRepresentable`（`IMESafeTextView.swift`）替代 SwiftUI `TextField`。原因：SwiftUI 的 `onKeyPress(.return, phases: .down)` 在 IME 组合状态下（如中文输入法确认候选字）会误触发发送。`SendTextView` 子类通过 `hasMarkedText()` 检测 IME 状态，仅在非组合状态时触发发送。

6. **删除确认对话框**：使用 `.alert` 绑定到 `@State private var sessionToDelete: Session?`。确认按钮调用 `deleteSession`，取消按钮清空状态。

7. **停止按钮布局调整**：当 Agent 运行时，InputBar 应同时显示停止按钮和发送按钮（而非当前的二选一）。用户可以一边看到 Agent 输出，一边准备追加消息。布局：`[TextField...] [发送] [停止]`。

### UI 设计参考

**Sidebar 右键菜单（macOS 原生风格）：**

```
┌─────────────────────────┐
│ SessionRowView           │  ← 右键点击
│ ├─ 重命名              │
│ └─ 删除                │
└─────────────────────────┘

重命名模式：
┌─────────────────────────┐
│ [TextField 编辑中_____] │  ← 内联编辑，蓝色边框
│ 3 分钟前                │
└─────────────────────────┘

删除确认：
┌─────────────────────────────────┐
│ ⚠️ 删除会话                      │
│ 确定要删除「我的项目调试」吗？     │
│ 此操作不可撤销。                  │
│ [取消]  [删除]                   │
└─────────────────────────────────┘
```

**InputBar 运行中追加模式：**

```
┌───────────────────────────────────────────────┐
│ [输入追加消息...]              [发送] [⏹停止]  │
└───────────────────────────────────────────────┘
```

### 数据流图

```
SidebarView
├── .contextMenu { 删除, 重命名 }
│   ├── 删除 → alert确认 → sessionViewModel.deleteSession(session)
│   │                       └── ModelContext.delete + save
│   │                       └── sessions.removeAll
│   │                       └── selectedSession = sessions.first
│   └── 重命名 → renamingSessionID = session.id
│                └── SessionRowView 显示 TextField
│                    └── Enter → sessionViewModel.updateSessionTitle(session, title)
│                    └── Escape → renamingSessionID = nil

InputBarView
├── TextField (不再 disabled when isRunning)
├── Enter → sendMessage() (发送)
├── Shift+Enter → 换行（默认行为）
├── 发送按钮 (isRunning 时仍可见)
└── 停止按钮 (isRunning 时可见)

AgentBridge.sendMessage
├── isRunning == false → 启动 streamInput 流（创建 AsyncStream<String>），yield 消息
└── isRunning == true → yield 追加消息到已有输入流（排队等待当前 turn 完成）
    └── 追加 userMessage 事件到 events
    └── SDK 顺序处理：当前 turn 完成 → 下一个 turn 开始
    └── pendingTurnCount 归零时关闭输入流 → isRunning = false
```

### 文件变更清单

**UPDATE（更新文件）：**
- `SwiftWork/Views/Sidebar/SidebarView.swift` -- 添加 context menu（删除/重命名）、编辑状态管理、删除确认 alert
- `SwiftWork/Views/Sidebar/SessionRowView.swift` -- 添加编辑模式参数和 TextField 切换
- `SwiftWork/Views/Workspace/InputBar/InputBarView.swift` -- 移除运行时禁用、添加发送/停止并列布局、Shift+Enter 支持
- `SwiftWork/SDKIntegration/AgentBridge.swift` -- 修改 sendMessage 支持追加消息模式

**UNCHANGED（不修改——零回归风险）：**
- `SwiftWork/ViewModels/SessionViewModel.swift` -- deleteSession 和 updateSessionTitle 已完整实现
- `SwiftWork/Models/SwiftData/Session.swift` -- 级联删除已配置
- `SwiftWork/Models/SwiftData/Event.swift` -- 事件模型不变
- `SwiftWork/App/ContentView.swift` -- 应用入口不变
- `SwiftWork/Views/Workspace/WorkspaceView.swift` -- Workspace 容器不变
- 所有 Timeline、EventView、Permission、Settings 组件不变

### 与前后 Story 的关系

- **Story 3-2（权限配置与规则管理）**：3-2 修改了 SidebarView 的 toolbar（添加了设置齿轮按钮）。本 Story 修改 SidebarView 的 List 内容区域（添加 context menu），不影响 toolbar。注意合并时保持 toolbar 代码不变。
- **Story 1-3（会话管理与 Sidebar）**：本 Story 是 1-3 的增强，直接在 1-3 创建的 SidebarView 和 SessionViewModel 上扩展。
- **Story 1-4（消息输入与 Agent 执行）**：本 Story 增强 InputBarView 和 AgentBridge.sendMessage 的行为，从"运行时禁用"改为"运行时可追加"。
- **Story 3-4（Inspector Panel）**：不受影响。3-4 关注右侧面板，与 Sidebar 操作无关。

### 前序 Story 学习（Story 3-2）

- Story 3-2 发现：ATDD 测试中 `let (handler, _, context) = makeHandlerWithContainer()` 的 tuple 解构会释放 ModelContainer，导致 ModelContext 夘效。本 Story 的测试应使用实例变量存储 ModelContainer。
- Story 3-2 模式：View 文件超过 300 行应拆分子 View。SidebarView 当前 55 行，添加 context menu 后预计 120-150 行，安全。
- Story 3-2 模式：删除操作使用 `.alert` 确认，参考 PermissionRulesView 的 `ruleToDelete` + `showDeleteConfirmation` 模式。

### Project Structure Notes

- `SidebarView.swift` 和 `SessionRowView.swift` 保持在 `Views/Sidebar/` 目录
- `InputBarView.swift` 保持在 `Views/Workspace/InputBar/` 目录
- 测试文件：`SwiftWorkTests/ViewModels/SessionViewModelTests.swift`（已有或新建）和 `SwiftWorkTests/Views/Sidebar/SidebarViewTests.swift`（新建）
- 遵循 View 只依赖 ViewModel 和 Models/UI 的分层规则

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.3: 会话管理增强]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 2: 数据模型设计 -- Session 与 Event 级联删除]
- [Source: _bmad-output/project-context.md#SwiftData 模型规则]
- [Source: _bmad-output/implementation-artifacts/3-2-permission-config-rules.md -- 前序 Story dev notes 和 learning]
- [Source: SwiftWork/Views/Sidebar/SidebarView.swift -- 当前 Sidebar 实现]
- [Source: SwiftWork/Views/Sidebar/SessionRowView.swift -- 当前 SessionRow 实现]
- [Source: SwiftWork/ViewModels/SessionViewModel.swift -- deleteSession 和 updateSessionTitle 已实现]
- [Source: SwiftWork/Views/Workspace/InputBar/InputBarView.swift -- 当前 InputBar 实现]
- [Source: SwiftWork/SDKIntegration/AgentBridge.swift -- sendMessage 当前在 isRunning 时自动取消]
- [Source: SwiftWork/Models/SwiftData/Session.swift -- cascade delete rule 已配置]
- [Source: SwiftWork/Views/Permission/PermissionRulesView.swift -- 删除确认 alert 模式参考]
- [Source: SwiftWork/Views/Workspace/WorkspaceView.swift -- InputBar 与 AgentBridge 的集成方式]

### ATDD Artifacts

- Checklist: `_bmad-output/test-artifacts/atdd-checklist-3-3-session-management-enhanced.md`
- Unit tests (Sidebar): `SwiftWorkTests/Views/Sidebar/SidebarViewTests.swift` (13 tests)
- Unit tests (InputBar): `SwiftWorkTests/Views/Workspace/InputBar/InputBarViewTests.swift` (10 tests)
- Unit tests (AgentBridge follow-up): `SwiftWorkTests/SDKIntegration/AgentBridgeTests.swift` (+7 tests)
- TDD Phase: RED -- 1 test intentionally fails (testSendMessageWhileRunningNoCancellationEvent)

## Dev Agent Record

### Agent Model Used

GLM-5.1

### Debug Log References

None.

### Completion Notes List

- Task 1: Added `.contextMenu` modifier to SidebarView's ForEach rows with "重命名" and "删除" menu items. Delete triggers a confirmation alert (`sessionToDelete` state) that calls `sessionViewModel.deleteSession(_:)` on confirm.
- Task 2: Added inline rename mode via `renamingSessionID` / `renameText` state in SidebarView. SessionRowView now accepts `isRenaming`, `renameText` binding, `onCommitRename`, and `onCancelRename` parameters. TextField with `@FocusState` auto-focuses on rename; Enter commits via `updateSessionTitle`, Escape cancels via `onExitCommand`.
- Task 3: Removed `disabled(agentBridge.isRunning)` from InputBarView TextField. Changed AgentBridge.sendMessage to use `agent.streamInput()` with `AsyncStream<String>` — follow-up messages are queued via `yield`, processed sequentially by SDK after current turn completes. `pendingTurnCount` tracks queued turns, auto-closes input stream when all turns complete. InputBar shows both Send and Stop buttons when running.
- Task 4: Replaced SwiftUI TextField + `onKeyPress` with `IMESafeTextView` (NSTextView wrapper via NSViewRepresentable). `SendTextView` subclass overrides `keyDown` to check `hasMarkedText()` for IME safety. Enter sends, Shift/Option+Enter inserts newline, IME composing Enter confirms candidate (no send).
- Task 5: All 30 ATDD tests pass (13 SidebarView + 10 InputBarView + 7 AgentBridge follow-up). Full suite: 589 tests, 0 failures.
- SessionViewModel was NOT modified (deleteSession and updateSessionTitle were already implemented).

### File List

**MODIFIED:**
- `SwiftWork/Views/Sidebar/SidebarView.swift` -- Added context menu (delete/rename), delete confirmation alert, rename state management
- `SwiftWork/Views/Sidebar/SessionRowView.swift` -- Added inline editing mode with TextField, FocusState, commit/cancel handlers
- `SwiftWork/Views/Workspace/InputBar/InputBarView.swift` -- Replaced TextField+onKeyPress with IMESafeTextView; concurrent send+stop layout
- `SwiftWork/SDKIntegration/AgentBridge.swift` -- Replaced per-message `agent.stream()` with `agent.streamInput()` multi-turn queue; added `pendingTurnCount` tracking
- `SwiftWork/Views/Workspace/InputBar/IMESafeTextView.swift` -- NEW: NSTextView wrapper with `hasMarkedText()` IME safety for Enter/Shift+Enter

### Review Findings

- [x] [Review][Patch] AgentBridge: isRunning 竞态条件 — 并发 Task 提前设为 false [AgentBridge.swift:220] — Fixed: isRunning = false 移入 generation 保护的分支内，stream 循环增加 generation guard。
- [x] [Review][Patch] AgentBridge: streamingText 在并发 Task 间交错 [AgentBridge.swift:193-199] — Fixed: stream 循环增加 `guard self.activeTaskGeneration == myGeneration else { break }`，旧 generation 的 Task 自动退出，不再追加交错事件。
- [x] [Review][Patch] AgentBridge: currentTask 引用被覆盖，旧 Task 不可取消 [AgentBridge.swift:182] — Fixed: 旧 generation Task 在循环头部检测 generation mismatch 后 break 退出，不再追加事件到 events 数组。
- [x] [Review][Patch] InputBarView: 冗余三元表达式 [InputBarView.swift:37] — Fixed: 简化为 `.padding(.trailing, 4)`。
- [x] [Checkpoint][Patch] InputBarView: IME 冲突风险 — `onKeyPress(.return, phases: .down)` 在中文输入法下会把"确认候选字"误判为发送 — Fixed: 替换为 NSTextView 包装器 `IMESafeTextView`，通过 `hasMarkedText()` 检测 IME 组合状态。
- [x] [Checkpoint][Rework] AgentBridge: 追加消息中断旧 turn — 原实现用 `agent.stream()` 每次开新 turn 导致旧 turn 被截断 — Fixed: 重构为 `agent.streamInput()` + `AsyncStream<String>` 队列模式，追加消息排队等待当前 turn 完成后顺序处理。
