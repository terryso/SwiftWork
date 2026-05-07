# Story 6.2: MCP 添加与编辑弹窗

Status: done

## Story

As a 用户,
I want 通过原生 macOS 弹窗添加新的 MCP Server 或编辑已有配置,
so that 我可以方便地连接外部工具服务或本地命令行工具。

## Acceptance Criteria

1. **AC1 — 添加 MCP Server 弹窗** — Given 用户在 MCP 管理面板点击 "+" 按钮, When 弹窗显示, Then 显示 AddMCPServerSheet，包含：Server 名称输入框、传输类型选择（Remote / Local）、Remote 模式的 URL 输入框、Local 模式的 Command 输入框和可选参数（参照 OpenWork `add-mcp-modal.tsx`）

2. **AC2 — Remote 类型配置** — Given 弹窗中选择了 "Remote" 类型, When 用户输入 URL 并提交, Then 创建 `McpServerConfig.sse` 或 `McpServerConfig.http` 配置，保存到 SwiftData

3. **AC3 — Local 类型配置** — Given 弹窗中选择了 "Local" 类型, When 用户输入命令（如 `npx -y @modelcontextprotocol/server-filesystem /tmp`）并提交, Then 创建 `McpServerConfig.stdio` 配置，命令和参数自动解析，保存到 SwiftData

4. **AC4 — 编辑已有配置** — Given 用户编辑一个已有的 MCP Server, When 修改配置并保存, Then 更新 SwiftData 中的配置，如果 Agent 正在运行则通过 `agent.setMcpServers()` 热更新（FR-MCP-3）

5. **AC5 — 输入验证** — Given 用户输入无效配置（空名称、空 URL/Command）, When 提交, Then 显示行内验证错误，阻止保存

## Tasks / Subtasks

- [x] Task 1: 创建 MCPTransportTypePicker 组件（AC: #1）
  - [x] 1.1 新建 `SwiftWork/Views/Settings/MCP/MCPTransportTypePicker.swift`
  - [x] 1.2 定义 `MCPTransportMode` 枚举（remote / local），作为 UI 层概念
  - [x] 1.3 实现 segmented control 风格的选择器，参照 OpenWork `add-mcp-modal.tsx` 的 remote/local 按钮样式
  - [x] 1.4 Remote 类型选中时显示 URL 输入区域；Local 类型选中时显示 Command 输入区域

- [x] Task 2: 创建 AddMCPServerSheet 弹窗（AC: #1, #2, #3, #5）
  - [x] 2.1 新建 `SwiftWork/Views/Settings/MCP/AddMCPServerSheet.swift`
  - [x] 2.2 定义 `@Observable` 的 `AddMCPServerViewModel`，管理表单状态和验证逻辑
  - [x] 2.3 实现表单字段：name（TextField）、transportMode（MCPTransportTypePicker）、url（Remote 模式）、command（Local 模式）
  - [x] 2.4 实现行内验证逻辑：name 非空、url 非空（Remote 模式）、command 非空（Local 模式）
  - [x] 2.5 实现 Local 模式下的 command 字符串解析：第一个 token 为 command，其余为 args
  - [x] 2.6 提交时调用 `MCPServerConfigStore.add()` 保存配置
  - [x] 2.7 处理 `MCPServerConfigError.duplicateName` 错误，显示行内错误提示

- [x] Task 3: 创建 EditMCPServerSheet 弹窗（AC: #4）
  - [x] 3.1 新建 `SwiftWork/Views/Settings/MCP/EditMCPServerSheet.swift`
  - [x] 3.2 复用 AddMCPServerSheet 的 ViewModel 模式，但预填充已有配置数据
  - [x] 3.3 提交时调用 `MCPServerConfigStore.replace()` 更新配置
  - [x] 3.4 如果 Agent 正在运行（`agentBridge.isRunning == true`），更新后触发 `agent.setMcpServers()` 热更新

- [x] Task 4: 创建 MCPFormFields 共享组件（AC: #1, #2, #3）
  - [x] 4.1 新建 `SwiftWork/Views/Settings/MCP/MCPFormFields.swift`
  - [x] 4.2 抽取 Add 和 Edit 弹窗共享的表单字段为独立 View
  - [x] 4.3 包含 name 输入、transport type picker、URL/Command 动态切换区域、行内错误提示

- [x] Task 5: 编写测试（AC: #1-#5）
  - [x] 5.1 新建 `SwiftWorkTests/ViewModels/AddMCPServerViewModelTests.swift`
  - [x] 5.2 测试验证逻辑：空 name / 空 URL / 空 Command → 验证失败
  - [x] 5.3 测试 Remote 模式提交 → 正确调用 `MCPServerConfigStore.add()` 生成 sse 配置
  - [x] 5.4 测试 Local 模式提交 → 正确解析 command + args 并生成 stdio 配置
  - [x] 5.5 测试编辑模式 → 正确调用 `MCPServerConfigStore.replace()` 更新配置
  - [x] 5.6 测试重复 name → 正确处理 `duplicateName` 错误
  - [x] 5.7 回归测试：确认全部现有测试通过

## Dev Notes

### 核心架构——View 层设计

本 Story 是纯 UI 层 Story，不创建新的 Model 或 Service。所有数据操作通过 Story 6-1 创建的 `MCPServerConfigStore` 完成。

**新建文件列表：**

```
SwiftWork/Views/Settings/MCP/
├── MCPFormFields.swift            # 共享表单字段组件
├── MCPTransportTypePicker.swift   # Remote/Local 类型选择器
├── AddMCPServerSheet.swift        # 添加 MCP Server 弹窗
└── EditMCPServerSheet.swift       # 编辑 MCP Server 弹窗
```

**为什么创建 MCP 子目录：** Settings/ 下已有 5 个 View 文件，MCP 相关组件预计 4-6 个文件（Story 6-3 还会添加 MCP 管理面板），单独目录避免 Settings/ 过于拥挤。

### 核心架构——AddMCPServerViewModel

这是弹窗的核心逻辑单元。使用 `@Observable`（不是 `ObservableObject`），遵循项目 ViewModel 模式。

```swift
@MainActor
@Observable
final class AddMCPServerViewModel {
    // 表单状态
    var name = ""
    var transportMode: MCPTransportMode = .remote
    var url = ""
    var command = ""
    var isSubmitting = false
    var errorMessage: String?

    // 验证
    var isValid: Bool { /* name 非空 && (Remote: url 非空) || (Local: command 非空) */ }

    // 操作
    func submit(store: MCPServerConfigStore, scope: MCPServerScope, workspacePath: String?) throws -> MCPServerConfig
    func validate() -> Bool
    func reset()
}
```

**注意：** ViewModel 不持有 `MCPServerConfigStore` 引用。store 由调用方传入（通过 `@Environment(\.modelContext)` 或从 SettingsView 传递）。这遵循现有 SettingsViewModel 的模式——ViewModel 只管理 UI 状态和验证逻辑。

### 核心架构——MCPTransportMode UI 枚举

```swift
/// UI 层传输模式概念，映射到 SDK 的实际传输类型
enum MCPTransportMode: String, CaseIterable {
    case remote   // 映射到 TransportType.sse（默认）或 .http
    case local    // 映射到 TransportType.stdio
}
```

**为什么不用 `TransportType` 直接做 UI 选择：** SDK 有 sse/http 两种 remote 类型，但 UI 层简化为 Remote（默认用 sse）/ Local 两个选项，与 OpenWork 交互一致。如果未来需要区分 SSE vs HTTP，可以在 Remote 模式下增加子选项。

### 核心架构——Command 解析逻辑（AC3）

Local 模式下，用户输入一个完整的命令行字符串（如 `npx -y @modelcontextprotocol/server-filesystem /tmp`）。需要解析为 command + args：

```swift
private func parseCommand(_ input: String) -> (command: String, args: [String]) {
    // 简单按空格分割，不支持引号内空格（MVP 阶段）
    let tokens = input.split(separator: " ").map(String.init)
    guard let first = tokens.first else { return ("", []) }
    return (first, Array(tokens.dropFirst()))
}
```

**args 编码：** 解析后的 `[String]` 需要 JSON 编码为 `Data` 存入 `MCPServerConfig.args`：

```swift
let argsData = args.isEmpty ? nil : try? JSONEncoder().encode(args)
```

### 核心架构——编辑模式热更新（AC4）

编辑保存后，如果 Agent 正在运行，需要通过 SDK 热更新 MCP 配置：

```swift
// 在 EditMCPServerSheet 的保存逻辑中
try store.replace(config, ...)

// 热更新 Agent
if let agent = agentBridge.agent, agentBridge.isRunning {
    let configs = try store.enabledConfigsForWorkspace(agentBridge.activeWorkspaceRoot)
    let mcpServers = store.toSDKConfigs(configs)
    agent.setMcpServers(mcpServers)
}
```

**关键：** `agent.setMcpServers()` 是 SDK 提供的动态更新 API。但当前 Story 6-1 的 `AgentBridge` 还没有暴露 `agent` 属性为 public。需要检查 `AgentBridge` 的 `agent` 访问级别。

**检查发现：** 查看 `AgentBridge.swift`，`agent` 属性访问级别需要确认。如果为 `private`，需要添加一个 `updateMCPServers()` 方法封装热更新逻辑，遵循分层架构（View → ViewModel/AgentBridge → SDK）。

**推荐方案：** 在 `AgentBridge` 上添加一个方法：

```swift
func updateMCPServers() {
    guard let agent, isRunning else { return }
    let configs = (try? mcpConfigStore?.enabledConfigsForWorkspace(activeWorkspaceRoot)) ?? []
    let mcpServers = mcpConfigStore?.toSDKConfigs(configs) ?? [:]
    agent.setMcpServers(mcpServers.isEmpty ? nil : mcpServers)
}
```

这样 View 层不直接访问 SDK `Agent` 类型，遵循架构分层规则。

### OpenWork 参照分析

**参照文件：** `/Users/nick/CascadeProjects/openwork/apps/app/src/react-app/domains/connections/modals/add-mcp-modal.tsx`

**交互要点（需要复刻）：**

1. **弹窗结构**：标题区（标题 + 副标题 + 关闭按钮）→ 内容区（表单字段）→ 底部操作区（取消 + 提交按钮）
2. **类型切换**：Remote / Local 两个按钮，选中状态高亮背景色
3. **Remote 模式**：URL 输入框 + OAuth 可选复选框（SwiftWork MVP 不实现 OAuth，跳过此区域）
4. **Local 模式**：Command 输入框 + 提示文本
5. **行内错误**：红色背景错误提示条
6. **提交中状态**：按钮显示 spinner + disabled

**SwiftUI 实现方式：**

```swift
// 使用 .sheet() modifier 弹出
.sheet(isPresented: $showAddSheet) {
    AddMCPServerSheet(
        store: mcpConfigStore,
        scope: currentScope,
        workspacePath: workspacePath,
        onSave: { config in
            // 刷新列表
        }
    )
    .frame(minWidth: 460, minHeight: 320)
}
```

**不参照的 React 组件实现：** `useState`、`onClick` handler、CSS class（`bg-dls-active`、`rounded-lg` 等）→ 全部用 SwiftUI 原生等效替代。

### 行内验证设计（AC5）

不使用 macOS 原生弹窗（`NSAlert`）显示错误。参照 OpenWork 的行内错误条模式：

```swift
if let error = viewModel.errorMessage {
    HStack {
        Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(.red)
        Text(error)
            .font(.caption)
            .foregroundStyle(.red)
    }
    .padding(8)
    .background(Color.red.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 6))
}
```

验证规则：
- name: trim 后非空
- Remote 模式: url trim 后非空
- Local 模式: command trim 后非空

### 与 Story 6-1 的依赖关系

**Story 6-1 提供的 API（必须使用，不得重新实现）：**

| API | 用途 | 文件 |
|-----|------|------|
| `MCPServerConfigStore.add(name:transportType:command:url:args:env:headers:enabled:scope:workspacePath:)` | 添加新配置 | `SwiftWork/Services/MCPServerConfigStore.swift:27-59` |
| `MCPServerConfigStore.replace(_:name:transportType:...)` | 全量更新配置（编辑模式） | `SwiftWork/Services/MCPServerConfigStore.swift:93-120` |
| `MCPServerConfigStore.list()` | 获取配置列表（用于 name 唯一性检查） | `SwiftWork/Services/MCPServerConfigStore.swift:127-131` |
| `MCPServerConfigError.duplicateName` | 重复 name 错误 | `SwiftWork/Services/MCPServerConfigStore.swift:6-14` |
| `TransportType` 枚举 (.stdio / .sse / .http) | SwiftData 模型的传输类型 | `SwiftWork/Models/SwiftData/MCPServerConfig.swift:4-8` |
| `MCPServerScope` 枚举 (.project / .global) | 配置作用域 | `SwiftWork/Models/SwiftData/MCPServerConfig.swift:10-13` |
| `MCPServerConfig` SwiftData 模型 | 持久化配置对象 | `SwiftWork/Models/SwiftData/MCPServerConfig.swift:16-69` |

**Store 实例获取路径：**

```swift
// ContentView 中已创建并注入到 AgentBridge
agentBridge.mcpConfigStore = MCPServerConfigStore(modelContext: modelContext)

// SettingsView 可以通过 agentBridge.mcpConfigStore 访问
// 或者直接用 @Environment(\.modelContext) 创建新实例
```

### SettingsView 集成

当前 `SettingsView` 有三个 tab：通用 / 权限 / Skills。Story 6-2 的 Add/Edit Sheet 由 Story 6-3 的 MCP 管理面板触发。**本 Story 只负责 Sheet 本身的实现，不修改 SettingsView 的 tab 结构。**

Story 6-3 会添加 "MCP Servers" tab 并集成 "+" 按钮，该按钮触发 `AddMCPServerSheet`。

本 Story 需要确保 Sheet 组件可以独立使用：

```swift
// Story 6-3 的 MCP 管理面板会这样使用
AddMCPServerSheet(
    store: mcpConfigStore,
    scope: .global,
    workspacePath: workspacePath,
    onSave: { _ in refreshList() }
)
```

### AgentBridge.updateMCPServers() 方法

需要在 `AgentBridge` 上新增此方法以支持编辑后的热更新。这是本 Story 唯一对非 View 层的修改：

```swift
// 在 AgentBridge.swift 中添加
func updateMCPServers() {
    guard isRunning else { return }
    let configs = (try? mcpConfigStore?.enabledConfigsForWorkspace(activeWorkspaceRoot)) ?? []
    let mcpServers = mcpConfigStore?.toSDKConfigs(configs)
    agent?.setMcpServers((mcpServers?.isEmpty ?? true) ? nil : mcpServers)
    os_log("SwiftWork MCP: hot-updated to %d configs", log: .default, type: .info, configs.count)
}
```

**注意：** 需要检查 `agent` 属性的访问级别。当前为 `private(set) var agent: Agent?`，所以 `updateMCPServers()` 方法必须在 `AgentBridge` 内部实现（这是正确的分层——View 不应直接操作 SDK Agent）。

### Project Structure Notes

- 新建目录：`SwiftWork/Views/Settings/MCP/`（MCP 相关 View 组件）
- 新建文件：`SwiftWork/Views/Settings/MCP/MCPTransportTypePicker.swift`
- 新建文件：`SwiftWork/Views/Settings/MCP/AddMCPServerSheet.swift`
- 新建文件：`SwiftWork/Views/Settings/MCP/EditMCPServerSheet.swift`
- 新建文件：`SwiftWork/Views/Settings/MCP/MCPFormFields.swift`
- 修改文件：`SwiftWork/SDKIntegration/AgentBridge.swift`（添加 `updateMCPServers()` 方法）
- 新建测试：`SwiftWorkTests/ViewModels/AddMCPServerViewModelTests.swift`
- 遵循命名规范：View 为 PascalCase + View/Sheet 后缀

### 不需要修改的文件

- **SettingsView.swift**：Story 6-3 负责 MCP tab 集成
- **MCPServerConfig.swift**：Story 6-1 已完成，本 Story 只消费其 API
- **MCPServerConfigStore.swift**：Story 6-1 已完成，本 Story 只消费其 `add()` 和 `replace()` 方法
- **SwiftWorkApp.swift**：无需修改（MCPServerConfig 已注册在 modelContainer 中）

### 代码复用要点

1. **PermissionDialogView 样式参照**：行内错误提示样式参照 `PermissionDialogView.swift` 的 `detailSection` 圆角矩形背景模式
2. **SettingsView Sheet 模式**：参照 `ContentView.swift:68-74` 的 `.sheet()` 使用模式
3. **SkillsListView 空状态**：参照 `SkillsListView.swift:49-63` 的 emptyState 设计模式（本 Story 不实现空状态，但 Story 6-3 会参照）

### References

- [Source: SwiftWork/Services/MCPServerConfigStore.swift — add() 方法（第 27-59 行）、replace() 方法（第 93-120 行）]
- [Source: SwiftWork/Models/SwiftData/MCPServerConfig.swift — TransportType、MCPServerScope、MCPServerConfig 模型]
- [Source: SwiftWork/Views/Settings/SettingsView.swift — Settings 页面结构和 tab 模式]
- [Source: SwiftWork/Views/Permission/PermissionDialogView.swift — 原生弹窗样式参照]
- [Source: SwiftWork/SDKIntegration/AgentBridge.swift:182-258 — MCP 配置加载和 Agent 创建]
- [Source: SwiftWork/App/ContentView.swift:68-74 — .sheet() 使用模式、第 123 行 mcpConfigStore 注入]
- [Source: /Users/nick/CascadeProjects/openwork/apps/app/src/react-app/domains/connections/modals/add-mcp-modal.tsx — UI 交互参照]
- [Source: open-agent-sdk-swift/Sources/OpenAgentSDK/Types/MCPConfig.swift — SDK McpServerConfig 枚举]
- [Source: _bmad-output/implementation-artifacts/6-1-mcp-config-model-persistence.md — Story 6-1 完整 Dev Notes 和实现记录]

## Dev Agent Record

### Agent Model Used

GLM-5.1 (via Claude Code)

### Debug Log References

- Build succeeded with 0 errors
- 34/34 ATDD tests pass (31 AddMCPServerViewModelTests + 3 MCPTransportModeTests)
- 1022/1022 full regression suite passes

### Completion Notes List

- Implemented MCPTransportMode enum (remote/local) as UI-layer concept in MCPTransportTypePicker.swift
- Created AddMCPServerViewModel with full form state, validation, command parsing, submit/submitEdit/populateFromConfig/reset methods
- Created MCPFormFields as shared form component reused by both Add and Edit sheets
- Created AddMCPServerSheet with header/form/footer layout, inline error display, keyboard shortcuts
- Created EditMCPServerSheet with pre-population from existing config and Agent hot-update trigger
- Added AgentBridge.updateMCPServers() method using async Task to call SDK's agent.setMcpServers()
- All 5 acceptance criteria (AC1-AC5) verified through ATDD tests

### File List

**New files:**
- SwiftWork/Views/Settings/MCP/MCPTransportTypePicker.swift
- SwiftWork/Views/Settings/MCP/MCPFormFields.swift
- SwiftWork/Views/Settings/MCP/AddMCPServerSheet.swift
- SwiftWork/Views/Settings/MCP/EditMCPServerSheet.swift

**Modified files:**
- SwiftWork/SDKIntegration/AgentBridge.swift (added updateMCPServers() method)
- _bmad-output/implementation-artifacts/sprint-status.yaml (status: in-progress)

**Test files (pre-existing from ATDD red phase):**
- SwiftWorkTests/ViewModels/AddMCPServerViewModelTests.swift (34 tests, all green)

### Change Log

- 2026-05-07: Implemented Story 6-2 MCP add/edit modal — all tasks complete, all tests passing
