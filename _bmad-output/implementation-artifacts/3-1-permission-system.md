# Story 3.1: 权限系统实现

Status: review

## Story

As a 用户,
I want Agent 执行需要审批的操作时弹出原生权限对话框,
so that 我可以审查并决定是否允许 Agent 执行该操作。

## Acceptance Criteria

1. **Given** Agent 要执行一个需要审批的工具调用 **When** PermissionHandler 评估结果为 `.requiresApproval` **Then** 弹出原生 macOS Sheet 对话框，显示工具名称、操作描述、具体参数（FR20, FR21）

2. **Given** 权限对话框弹出 **When** 用户点击 "Allow Once" **Then** 当前工具调用被授权执行，下次同类操作仍需审批（FR22）

3. **Given** 权限对话框弹出 **When** 用户点击 "Always Allow" **Then** 当前调用被授权，且该工具+模式被持久化为 PermissionRule，后续同类操作自动通过（FR23）

4. **Given** 权限对话框弹出 **When** 用户点击 "Deny" **Then** 工具调用被拒绝，Agent 收到拒绝反馈，可继续执行其他任务（FR24）

5. **Given** 任何权限决策发生 **When** 用户做出选择 **Then** 审计日志记录工具名、操作内容、用户决策、时间戳（NFR10）

**覆盖的 FRs:** FR20, FR21, FR22, FR23, FR24
**覆盖的 NFRs:** NFR10
**覆盖的 ARCHs:** ARCH-6, ARCH-7

## Tasks / Subtasks

- [x] Task 1: 实现 PermissionHandler（权限评估引擎）（AC: #1, #2, #3, #4）
  - [x] 1.1 创建 `SwiftWork/SDKIntegration/PermissionHandler.swift`，定义 `PermissionHandler: @Observable, @MainActor`
  - [x] 1.2 实现三种全局模式枚举 `GlobalPermissionMode`：`.autoApprove` / `.manualReview` / `.denyAll`
  - [x] 1.3 实现 `evaluate(toolName:input:) -> PermissionDecision` 方法：
    - `.denyAll` 模式 → 直接返回 `.denied`
    - `.autoApprove` 模式 → 直接返回 `.approved`
    - `.manualReview` 模式 → 检查持久化 rules，匹配则返回对应决策；检查 sessionOverrides，匹配则返回对应决策；否则返回 `.requiresApproval`
  - [x] 1.4 实现 `addSessionOverride(toolName:decision:)` 方法——会话级临时授权（Allow Once）
  - [x] 1.5 实现 `addPersistentRule(toolName:pattern:decision:)` 方法——持久化 PermissionRule（Always Allow）
  - [x] 1.6 注入 SwiftData `ModelContext` 用于 PermissionRule 查询和持久化
  - [x] 1.7 实现 `matchRule(toolName:input:rules:)` 私有方法——按 toolName 精确匹配 rules 列表

- [x] Task 2: 实现审计日志（AC: #5）
  - [x] 2.1 创建 `SwiftWork/Models/UI/PermissionAuditEntry.swift`，定义 `struct PermissionAuditEntry: Sendable`
  - [x] 2.2 字段：`toolName: String`、`input: String`、`decision: PermissionDecision`（简化为 .approved/.denied）、`timestamp: Date`、`sessionOverride: Bool`
  - [x] 2.3 在 `PermissionHandler` 中维护 `auditLog: [PermissionAuditEntry]` 数组（内存中，不持久化）
  - [x] 2.4 每次 `evaluate` 或用户决策后追加审计条目

- [x] Task 3: 集成 SDK canUseTool 回调（AC: #1, #2, #3, #4）
  - [x] 3.1 在 `AgentBridge.configure()` 中通过 `agent.setCanUseTool` 注册权限回调
  - [x] 3.2 回调逻辑：调用 `PermissionHandler.evaluate()` 获取 `PermissionDecision`
  - [x] 3.3 当 `PermissionDecision` 为 `.approved` 时返回 `CanUseToolResult.allow()`
  - [x] 3.4 当 `PermissionDecision` 为 `.denied` 时返回 `CanUseToolResult.deny(reason)`
  - [x] 3.5 当 `PermissionDecision` 为 `.requiresApproval` 时：发布待审批请求到 `@Published` 属性，await 用户响应，根据用户选择返回对应 `CanUseToolResult`

- [x] Task 4: 实现权限对话框 UI（AC: #1, #2, #3, #4）
  - [x] 4.1 重写 `SwiftWork/Views/Permission/PermissionDialogView.swift` 为完整权限弹窗
  - [x] 4.2 使用 macOS 原生 `Sheet` 呈现（不使用 popover/alert）
  - [x] 4.3 对话框布局——参照 OpenWork `permission-approval-modal.tsx` 交互模式：
    - 标题区：Shield 图标 + 工具类型标签（Bash/FileEdit/Read 等）+ 操作描述
    - 详情区：参数键值对展示（command/filepath/pattern 等关键参数）
    - 可展开的完整 JSON 元数据区域（<details> 折叠）
    - 底部三个按钮：Deny（红色） / Allow Once（主按钮） / Always Allow（轮廓按钮）
  - [x] 4.4 实现工具类型标签映射：Bash→"终端命令"、Edit→"文件编辑"、Read→"文件读取" 等
  - [x] 4.5 实现参数详情行提取：从 input JSON 中提取 command/filepath/pattern/query 等关键字段
  - [x] 4.6 用户选择后回调 `PermissionHandler` 更新决策（Allow Once → sessionOverride；Always Allow → persistentRule；Deny → deny）

- [x] Task 5: 连接 PermissionDialogView 与 AgentBridge（AC: #1, #2, #3, #4）
  - [x] 5.1 在 `AgentBridge` 中添加 `pendingPermissionRequest: PendingPermissionRequest?` 属性
  - [x] 5.2 创建 `SwiftWork/Models/UI/PendingPermissionRequest.swift`——封装 toolName、input、continuation（CheckedContinuation）
  - [x] 5.3 在 canUseTool 回调中：当需要审批时，用 `withCheckedContinuation` 挂起，设置 `pendingPermissionRequest`，等待用户操作
  - [x] 5.4 用户操作后：resume continuation 返回 SDK 期望的 `CanUseToolResult`
  - [x] 5.5 在 `WorkspaceView` 中通过 `.sheet(item:)` 绑定 `agentBridge.pendingPermissionRequest`，弹出 `PermissionDialogView`

- [x] Task 6: 单元测试（AC: #1-#5）
  - [x] 6.1 创建 `SwiftWorkTests/SDKIntegration/PermissionHandlerTests.swift`
  - [x] 6.2 测试三种全局模式：autoApprove 直接批准、denyAll 直接拒绝、manualReview 进入评估
  - [x] 6.3 测试 manualReview 模式下的 rules 匹配：持久化规则命中返回对应决策
  - [x] 6.4 测试 manualReview 模式下的 sessionOverrides 匹配
  - [x] 6.5 测试无匹配规则时返回 `.requiresApproval`
  - [x] 6.6 测试 `addSessionOverride` 仅对当前会话生效
  - [x] 6.7 测试 `addPersistentRule` 写入 SwiftData PermissionRule
  - [x] 6.8 测试审计日志：每次决策后 auditLog 正确追加条目
  - [x] 6.9 创建 `SwiftWorkTests/Models/UI/PendingPermissionRequestTests.swift` 测试数据模型
  - [x] 6.10 所有新测试通过 `swift test`

## Dev Notes

### 核心目标：实现 SDK 工具调用的权限拦截与用户审批 UI

本 Story 是 Epic 3 的第一个 Story。核心工作是在 SDK 的 `canUseTool` 回调机制和用户之间搭建完整的权限审批管线：`SDK Agent 调用工具 → canUseTool 回调 → PermissionHandler 评估 → 弹窗 UI（如需） → 用户决策 → 返回 SDK`。

### 已有基础（必须在此基础上扩展，不重新创建）

1. **`PermissionDecision.swift`**（`Models/UI/`）——已定义三态枚举 `.approved` / `.denied(reason:)` / `.requiresApproval(toolName:description:parameters:)`。直接使用，不修改。
2. **`PermissionRule.swift`**（`Models/SwiftData/`）——已定义 SwiftData 模型 `PermissionRule`，含 `toolName`、`pattern`、`decision: Decision`（`.allow` / `.deny`）、`createdAt`。直接使用，不修改。
3. **`PermissionDialogView.swift`**（`Views/Permission/`）——当前是占位 stub（仅 `Text("Permission Dialog")`），需要完整重写。
4. **`AgentBridge.swift`**（`SDKIntegration/`）——当前 `configure()` 方法创建 Agent 时使用 `permissionMode: .default`，无 canUseTool 回调。需要添加回调集成。
5. **测试文件** `SwiftWorkTests/Models/UI/PermissionDecisionTests.swift` 和 `SwiftWorkTests/Models/SwiftData/PermissionRuleModelTests.swift`——已存在，不修改。

### SDK 权限集成关键 API

**`CanUseToolFn` 类型签名：**
```swift
public typealias CanUseToolFn = @Sendable (ToolProtocol, Any, ToolContext) async -> CanUseToolResult?
```

**注册回调：**
```swift
agent.setCanUseTool { tool, input, context in
    // 返回 .allow() 或 .deny(reason) 或 .allowWithInput(updatedInput)
}
```

**关键注意：** `CanUseToolFn` 是 `@Sendable` 闭包，运行在非 MainActor 的 SDK 内部线程。必须在闭包内 `await MainActor.run {}` 来与 UI 交互（弹窗需要 MainActor）。

**`ToolProtocol` 提供的信息：**
- `tool.name: String` —— 工具名（Bash、Read、Write、Edit 等）
- `tool.description: String` —— 工具描述
- `tool.isReadOnly: Bool` —— 是否只读工具
- `input: Any` —— 工具输入（通常是 Dictionary 或 String）

**`CanUseToolResult` 构造方法：**
- `CanUseToolResult.allow()` —— 允许执行
- `CanUseToolResult.deny("reason")` —— 拒绝执行
- `CanUseToolResult(behavior: .allow, updatedInput: modifiedInput)` —— 允许但修改输入

### 权限评估流程图

```
SDK Agent 要调用工具
    │
    │  canUseTool(tool, input, context) 回调
    ▼
PermissionHandler.evaluate(toolName: tool.name, input: input)
    │
    ├── GlobalPermissionMode.autoApprove → .approved
    │
    ├── GlobalPermissionMode.denyAll → .denied(reason: "全部拒绝模式")
    │
    └── GlobalPermissionMode.manualReview
        │
        ├── 查找持久化 PermissionRule 匹配 → 对应 .approved 或 .denied
        │
        ├── 查找 sessionOverrides 匹配 → .approved（会话临时）
        │
        └── 无匹配 → .requiresApproval(toolName, description, parameters)
            │
            │  弹出 PermissionDialogView (macOS Sheet)
            │  await 用户操作
            ▼
        用户决策:
        ├── Allow Once  → sessionOverrides 记录 → .approved
        ├── Always Allow → PermissionRule 持久化 → .approved
        └── Deny        → .denied(reason)
```

### Continuation 模式：canUseTool 回调与 UI 弹窗的桥接

`canUseTool` 回调是 `async` 的，但 UI 弹窗需要用户手动操作（非 async）。桥接方案：

```swift
// 在 AgentBridge 中
var pendingPermissionRequest: PendingPermissionRequest?

// canUseTool 回调内部（非 MainActor 上下文）
func handlePermission(tool: ToolProtocol, input: Any, context: ToolContext) async -> CanUseToolResult? {
    let decision = await MainActor.run {
        permissionHandler.evaluate(toolName: tool.name, input: input)
    }

    switch decision {
    case .approved:
        return .allow()
    case .denied(let reason):
        return .deny(reason)
    case .requiresApproval(let toolName, let description, let parameters):
        // 在 MainActor 上弹窗并等待用户决策
        return await MainActor.run {
            await withCheckedContinuation { continuation in
                self.pendingPermissionRequest = PendingPermissionRequest(
                    toolName: toolName,
                    description: description,
                    parameters: parameters,
                    input: input,
                    continuation: continuation
                )
            }
        }
    }
}

// 用户点击按钮后调用
func resolvePermission(_ result: PermissionDialogResult) {
    guard let request = pendingPermissionRequest else { return }
    pendingPermissionRequest = nil

    switch result {
    case .allowOnce:
        permissionHandler.addSessionOverride(toolName: request.toolName)
        request.continuation.resume(returning: .allow())
    case .alwaysAllow:
        permissionHandler.addPersistentRule(toolName: request.toolName, pattern: "*", decision: .allow)
        request.continuation.resume(returning: .allow())
    case .deny:
        request.continuation.resume(returning: .deny("用户拒绝"))
    }
}
```

### PermissionDialogView UI 设计参考

**参照 OpenWork `permission-approval-modal.tsx` 的交互模式（不参考 React/CSS 实现）：**

布局结构（macOS Sheet 原生风格）：
```
┌──────────────────────────────────────────────┐
│ ┌────┐                                      │
│ │ 🛡️ │  [工具类型标签] 请求执行操作          │
│ └────┘  [操作描述文本]                        │
│                                              │
│ ┌──────────────────────────────────────────┐ │
│ │ 权限类型                                  │ │
│ │ Bash（终端命令）                          │ │
│ ├──────────────────────────────────────────┤ │
│ │ 作用域                                    │ │
│ │ rm -rf /tmp/build                        │ │
│ ├──────────────────────────────────────────┤ │
│ │ 参数详情                                  │ │
│ │ 命令:  rm -rf /tmp/build                 │ │
│ │ 工作目录:  /Users/nick/project           │ │
│ ├──────────────────────────────────────────┤ │
│ │ ▶ 详细信息（折叠/展开 JSON）              │ │
│ └──────────────────────────────────────────┘ │
│                                              │
│ [拒绝]    [允许一次]    [始终允许]            │
└──────────────────────────────────────────────┘
```

**关键 UI 细节：**
- 使用 macOS 原生 `Sheet`（`.sheet(item:)` modifier），不使用 NSAlert
- Shield 图标（SF Symbol: `shield.checkered` 或 `shield.fill`）
- 工具类型标签映射：Bash→"终端命令"、Edit/Write→"文件编辑"、Read→"文件读取"、Grep/Glob→"文件搜索"、其他→工具原始名
- 参数提取优先级（参照 OpenWork metadataDetailKeys）：command → description → cwd → filepath → path → pattern → query
- Deny 按钮红色系、Allow Once 主色调按钮、Always Allow 轮廓按钮
- Sheet 宽度约 480pt，内容自适应高度

### 关键技术注意事项

1. **`@Sendable` 闭包与 MainActor**：`CanUseToolFn` 是 `@Sendable` 闭包，运行在 SDK 内部线程。PermissionHandler 的 `evaluate` 方法需要标记 `@MainActor`，在回调内部通过 `await MainActor.run {}` 调用。

2. **Continuation 生命周期**：`withCheckedContinuation` 必须确保恰好 resume 一次。用户关闭 Sheet 时（Escape 键或点击外部）视为 Deny 处理，避免 continuation 泄漏。

3. **SwiftData 查询 PermissionRule**：PermissionHandler 需要注入 `ModelContext` 来查询和持久化 PermissionRule。在 `AgentBridge.configureEvents()` 或单独的初始化方法中注入。

4. **input 参数类型**：SDK 的 `CanUseToolFn` 中 `input: Any`，实际类型取决于工具。大多数工具的 input 是 `[String: Any]` 字典。需要在 PermissionHandler 中安全处理 `Any` 类型（用 `as? [String: Any]` 尝试转换）。

5. **不影响现有功能**：默认 `GlobalPermissionMode` 应为 `.autoApprove`（与当前无权限检查行为一致）。只有用户手动切换到 `.manualReview` 时才启用审批弹窗。这确保不破坏 Story 1-1 到 2-5 已有功能的体验。

6. **PermissionDecision 命名冲突**：SDK 已有 `PermissionDecision`（`HookTypes.swift`），本项目也有自定义 `PermissionDecision`（`Models/UI/`）。两者不同——SDK 的是 allow/deny/ask，本项目的是 approved/denied/requiresApproval。在 PermissionHandler 中只使用本项目的 `PermissionDecision`，SDK 回调返回 `CanUseToolResult`。

### 文件变更清单

**NEW（新建文件）：**
- `SwiftWork/SDKIntegration/PermissionHandler.swift` -- 权限评估引擎（evaluate、sessionOverrides、persistent rules 查询）
- `SwiftWork/Models/UI/PermissionAuditEntry.swift` -- 审计日志条目模型
- `SwiftWork/Models/UI/PendingPermissionRequest.swift` -- 待审批请求封装（含 continuation）
- `SwiftWorkTests/SDKIntegration/PermissionHandlerTests.swift` -- PermissionHandler 单元测试
- `SwiftWorkTests/Models/UI/PendingPermissionRequestTests.swift` -- 请求模型测试

**UPDATE（更新文件）：**
- `SwiftWork/Views/Permission/PermissionDialogView.swift` -- 从 stub 重写为完整权限弹窗 UI
- `SwiftWork/SDKIntegration/AgentBridge.swift` -- 添加 canUseTool 回调集成、pendingPermissionRequest 属性、resolvePermission 方法
- `SwiftWork/Views/Workspace/WorkspaceView.swift` -- 添加 `.sheet(item:)` 绑定弹出 PermissionDialogView

**UNCHANGED（不修改——零回归风险）：**
- `SwiftWork/Models/UI/PermissionDecision.swift` -- 已有枚举，直接使用
- `SwiftWork/Models/SwiftData/PermissionRule.swift` -- 已有 SwiftData 模型，直接使用
- `SwiftWork/SDKIntegration/EventMapper.swift` -- 事件映射不变
- `SwiftWork/SDKIntegration/EventSerializer.swift` -- 序列化不变
- `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` -- Timeline 不变
- 所有 EventView 子视图不变

### 与后续 Story 的关系

- **Story 3-2（权限配置与规则管理）**：本 Story 创建 PermissionHandler 的评估逻辑和 PermissionDialogView 的弹窗。Story 3-2 将添加 PermissionRulesView（规则列表 UI）和全局模式切换 UI（设置页面集成）。PermissionHandler 的 `globalMode` 和 `rules` 查询方法在本 Story 中实现，Story 3-2 只需添加 UI 管理。
- **Story 3-4（Inspector Panel）**：Inspector 可能需要展示权限审计日志。`PermissionHandler.auditLog` 在本 Story 中实现，Story 3-4 添加 UI 展示。

### Project Structure Notes

- `PermissionHandler.swift` 放在 `SwiftWork/SDKIntegration/` -- 它是 SDK 集成层组件，封装权限评估逻辑
- `PermissionAuditEntry.swift` 放在 `SwiftWork/Models/UI/` -- 它是 UI 层模型，不涉及 SwiftData
- `PendingPermissionRequest.swift` 放在 `SwiftWork/Models/UI/` -- UI 层中间模型，封装弹窗数据和 continuation
- `PermissionDialogView.swift` 保持在 `SwiftWork/Views/Permission/` -- 权限 UI 目录
- 遵循单文件不超过 300 行规则。如果 AgentBridge 因权限集成超过 300 行，将权限相关方法提取到 `AgentBridge+Permission.swift` 扩展文件
- `PermissionHandlerTests.swift` 放在 `SwiftWorkTests/SDKIntegration/` -- 与其他 SDKIntegration 测试同目录

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.1: 权限系统实现]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 5: 权限引擎设计]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 7: 错误处理策略]
- [Source: _bmad-output/project-context.md#权限系统]
- [Source: _bmad-output/project-context.md#权限回调集成]
- [Source: _bmad-output/project-context.md#OpenWork ToolCallView 交互模式]
- [Source: _bmad-output/implementation-artifacts/2-5-timeline-performance.md -- 前序 Story 上下文和 dev agent record]
- [Source: open-agent-sdk-swift/Sources/OpenAgentSDK/Types/PermissionTypes.swift -- CanUseToolFn、CanUseToolResult、PermissionPolicy]
- [Source: open-agent-sdk-swift/Sources/OpenAgentSDK/Core/Agent.swift#setCanUseTool -- 回调注册 API]
- [Source: open-agent-sdk-swift/Sources/OpenAgentSDK/Types/ToolTypes.swift#ToolProtocol -- 工具协议定义]
- [Source: openwork/apps/app/src/react-app/domains/session/chat/permission-approval-modal.tsx -- UI 交互参照]
- [Source: SwiftWork/Models/UI/PermissionDecision.swift -- 已有权限决策枚举]
- [Source: SwiftWork/Models/SwiftData/PermissionRule.swift -- 已有 SwiftData 权限规则模型]
- [Source: SwiftWork/SDKIntegration/AgentBridge.swift -- 当前 Agent 配置和事件管理]

## Dev Agent Record

### Agent Model Used

GLM-5.1

### Debug Log References

- Build succeeded with strict concurrency (Swift 6.1)
- Fixed `nonisolated(unsafe)` for input dict crossing actor boundaries
- Fixed pattern matching for wildcard rules (e.g., "rm *" matching "rm -rf /tmp/build")
- Used `@Bindable` in WorkspaceView for sheet binding with @Observable

### Completion Notes List

- PermissionHandler implements three global modes (autoApprove/manualReview/denyAll) with evaluate() method
- Audit log (PermissionAuditEntry) records every decision with toolName, input, simplified decision, timestamp, sessionOverride flag
- SDK canUseTool callback integrated in AgentBridge via setupPermissionCallback(), handles Sendable/MainActor boundary
- PendingPermissionRequest uses CheckedContinuation to bridge async SDK callback with user-driven UI
- PermissionDialogView provides macOS native Sheet with shield icon, tool type labels, parameter display, expandable JSON, and three action buttons
- WorkspaceView binds .sheet(item:) to agentBridge.pendingPermissionRequest via @Bindable
- Default mode is autoApprove for backward compatibility (no behavior change for existing users)
- All 29 new tests pass, full regression suite (427 tests) passes with 0 failures

### File List

**NEW:**
- SwiftWork/SDKIntegration/PermissionHandler.swift
- SwiftWork/Models/UI/PermissionAuditEntry.swift
- SwiftWork/Models/UI/PendingPermissionRequest.swift
- SwiftWorkTests/SDKIntegration/PermissionHandlerTests.swift
- SwiftWorkTests/Models/UI/PendingPermissionRequestTests.swift

**UPDATED:**
- SwiftWork/SDKIntegration/AgentBridge.swift
- SwiftWork/Views/Permission/PermissionDialogView.swift
- SwiftWork/Views/Workspace/WorkspaceView.swift
- SwiftWork.xcodeproj/project.pbxproj
