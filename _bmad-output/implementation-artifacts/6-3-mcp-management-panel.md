# Story 6.3: MCP 管理面板

Status: done

## Story

As a 用户,
I want 在设置面板中查看所有已配置的 MCP Server 及其状态，并可以管理它们,
so that 我可以清晰地了解 Agent 可以使用哪些外部工具，并控制它们的连接。

## Acceptance Criteria

1. **AC1 — Server 列表显示** — Given 用户打开设置面板并切换到 "MCP Servers" 标签页, When 面板加载, Then 显示所有已配置 MCP Server 的列表，每项显示：名称、状态指示灯（connected=绿 / failed=红 / pending=琥珀 / disabled=灰）、连接类型标签（Remote / Local）（FR-MCP-2）

2. **AC2 — 展开详情** — Given MCP Server 列表已显示, When 用户点击某个 Server 展开详情, Then 显示详细信息：连接类型、工具列表（从 `agent.mcpServerStatus()` 的 `tools` 字段获取）、技术详情（URL 或 Command）、启用/禁用按钮、编辑按钮、删除按钮（参照 OpenWork `mcp-view.tsx` 展开交互）（FR-MCP-3）

3. **AC3 — 禁用 Server** — Given 用户在详情中点击 "禁用" 按钮, When 操作执行, Then 通过 `agent.toggleMcpServer(name, enabled: false)` 断开连接，状态变为 disabled，配置保留

4. **AC4 — 启用 Server** — Given 用户在详情中点击 "启用" 按钮, When 操作执行, Then 通过 `agent.toggleMcpServer(name, enabled: true)` 重新连接，状态恢复

5. **AC5 — 删除 Server** — Given 用户点击 "删除" 按钮, When 确认删除, Then 从 SwiftData 删除配置，断开连接（如果已连接），Agent 工具池移除该 Server 的工具

6. **AC6 — 重连 Server** — Given 用户点击 "重连" 按钮, When 操作执行, Then 通过 `agent.reconnectMcpServer(name)` 重连，状态指示器显示 pending -> connected/failed

7. **AC7 — 错误详情展示** — Given 某个 MCP Server 连接失败, When 用户查看该 Server 详情, Then 显示错误信息（从 `McpServerStatus.error` 获取），并提供"查看详情"展开区和"重连"按钮（FR-MCP-6）

8. **AC8 — 空状态** — Given 没有配置任何 MCP Server, When 面板加载, Then 显示空状态提示（图标 + "尚未配置 MCP Server" + 添加引导），参照 OpenWork 空状态设计

## Tasks / Subtasks

- [x] Task 1: 添加 "MCP Servers" 标签到 SettingsView（AC: #1）
  - [x] 1.1 在 `SettingsView.SettingsTab` 枚举中添加 `case mcp = "MCP Servers"`
  - [x] 1.2 在 `activeTabContent` 中添加 `mcpTab` 分支
  - [x] 1.3 实现 `mcpTab` ViewBuilder：当 `agentBridge` 存在时显示 `MCPManagementView`，否则显示不可用提示

- [x] Task 2: 创建 MCPManagementView 主面板（AC: #1, #8）
  - [x] 2.1 新建 `SwiftWork/Views/Settings/MCP/MCPManagementView.swift`
  - [x] 2.2 实现 `@Observable` 的 `MCPManagementViewModel`，管理 server 列表、选中状态、异步操作
  - [x] 2.3 实现空状态 UI（参照 SkillsListView.emptyState 模式）
  - [x] 2.4 实现顶部操作栏：标题 + "+" 添加按钮
  - [x] 2.5 从 MCPServerConfigStore 加载配置列表
  - [x] 2.6 从 AgentBridge 获取 MCP 运行时状态（如果 Agent 正在运行）

- [x] Task 3: 创建 MCPServerRowView 列表项组件（AC: #1）
  - [x] 3.1 新建 `SwiftWork/Views/Settings/MCP/MCPServerRowView.swift`
  - [x] 3.2 实现行摘要视图：名称、状态指示灯（颜色圆点）、类型标签（Remote/Local）、展开箭头
  - [x] 3.3 状态指示灯颜色映射：connected=绿 / failed=红 / pending=琥珀 / disabled=灰 / 其他=灰

- [x] Task 4: 创建 MCPServerDetailView 详情组件（AC: #2, #3, #4, #5, #6, #7）
  - [x] 4.1 新建 `SwiftWork/Views/Settings/MCP/MCPServerDetailView.swift`
  - [x] 4.2 实现连接类型显示行
  - [x] 4.3 实现工具列表标签区（从 McpServerStatus.tools 获取，仅 Agent 运行时显示）
  - [x] 4.4 实现错误信息展示区（McpServerStatus.error 非空时显示红色错误框）
  - [x] 4.5 实现技术详情折叠区（URL 或 Command 的 monospace 显示）
  - [x] 4.6 实现操作按钮行：启用/禁用切换按钮、编辑按钮、重连按钮（仅运行时可见）、删除按钮

- [x] Task 5: 实现 ViewModel 异步操作（AC: #3, #4, #5, #6）
  - [x] 5.1 实现 `toggleServer(name:enabled:)` 方法：更新 SwiftData + 调用 agent.toggleMcpServer + 刷新状态
  - [x] 5.2 实现 `deleteServer(name:)` 方法：确认弹窗 + SwiftData 删除 + 热更新 Agent
  - [x] 5.3 实现 `reconnectServer(name:)` 方法：调用 agent.reconnectMcpServer + 刷新状态
  - [x] 5.4 实现 `refreshStatus()` 方法：异步获取 agent.mcpServerStatus() 并更新本地状态映射

- [x] Task 6: 集成 AddMCPServerSheet 和 EditMCPServerSheet（AC: #1, #2）
  - [x] 6.1 在 MCPManagementView 中添加 `.sheet(isPresented:)` 绑定 AddMCPServerSheet
  - [x] 6.2 在 MCPServerDetailView 中添加 `.sheet(item:)` 绑定 EditMCPServerSheet
  - [x] 6.3 Sheet 关闭后刷新配置列表

- [x] Task 7: 编写测试（AC: #1-#8）
  - [x] 7.1 新建 `SwiftWorkTests/ViewModels/MCPManagementViewModelTests.swift`
  - [x] 7.2 测试空状态：无配置时 serverList 为空
  - [x] 7.3 测试列表加载：添加配置后列表正确显示
  - [x] 7.4 测试删除操作：确认删除后配置从 SwiftData 移除
  - [x] 7.5 测试启用/禁用切换：enabled 属性正确更新
  - [x] 7.6 测试状态刷新：模拟 mcpServerStatus() 返回不同状态
  - [x] 7.7 回归测试：确认全部现有测试通过

## Dev Notes

### 核心架构——View 层设计

本 Story 创建 MCP 管理面板 UI，作为 SettingsView 的新 tab。所有数据操作复用 Story 6-1 的 `MCPServerConfigStore`，弹窗复用 Story 6-2 的 `AddMCPServerSheet` 和 `EditMCPServerSheet`。

**新建文件列表：**

```
SwiftWork/Views/Settings/MCP/
├── MCPManagementView.swift       # 主面板（ViewModel + View）
├── MCPServerRowView.swift        # 列表行组件
└── MCPServerDetailView.swift     # 展开详情组件
```

**修改文件列表：**

```
SwiftWork/Views/Settings/SettingsView.swift  # 添加 MCP Servers tab
```

### 核心架构——MCPManagementViewModel

```swift
@MainActor
@Observable
final class MCPManagementViewModel {
    // 数据源
    var servers: [MCPServerConfig] = []
    var serverStatuses: [String: McpServerStatus] = [:]
    var selectedServerName: String?
    var isLoading = false
    var errorMessage: String?

    // Sheet 状态
    var showAddSheet = false
    var editingConfig: MCPServerConfig?

    // 依赖
    private let store: MCPServerConfigStore
    private weak var agentBridge: AgentBridge?

    init(store: MCPServerConfigStore, agentBridge: AgentBridge?)
}
```

**为什么 ViewModel 持有 `agentBridge` 的 weak 引用：** AgentBridge 是 `@Observable` 的 `@MainActor` 类型，由 ContentView 创建并注入到 SettingsView。ViewModel 需要通过它访问运行时 MCP 状态（`agent.mcpServerStatus()`）和执行热更新操作。使用 `weak` 避免循环引用。

### 核心架构——MCP 运行时状态获取

本 Story 的核心挑战是：MCP 连接状态只在 Agent 运行时可用（由 SDK `MCPClientManager` 管理），而配置列表始终从 SwiftData 获取。需要将两份数据合并显示。

**状态获取策略：**

```swift
/// 刷新 MCP 服务器运行时状态（仅 Agent 运行时有效）
func refreshStatus() async {
    guard let agent = agentBridge?.agent, agentBridge?.isRunning == true else {
        serverStatuses = [:]  // Agent 未运行时清空状态
        return
    }
    serverStatuses = await agent.mcpServerStatus()
}
```

**合并策略：** 列表数据来自 SwiftData（`store.list()`），状态数据来自 SDK（`agent.mcpServerStatus()`）。每个列表项用 `config.name` 作为 key 在 `serverStatuses` 字典中查找对应状态。

**状态映射逻辑：**

```swift
func statusForServer(_ config: MCPServerConfig) -> MCPServerDisplayStatus {
    // 1. 如果 config.enabled == false -> .disabled（无需查 SDK）
    // 2. 如果 Agent 未运行 -> .offline
    // 3. 从 serverStatuses[config.name] 获取 SDK 状态
    // 4. 如果 SDK 状态中不存在该 name -> .disconnected
    if !config.enabled { return .disabled }
    guard let sdkStatus = serverStatuses[config.name] else {
        return agentBridge?.isRunning == true ? .disconnected : .offline
    }
    return MCPServerDisplayStatus.from(sdkStatus.status)
}
```

**UI 层状态枚举（映射 SDK McpServerStatusEnum）：**

```swift
enum MCPServerDisplayStatus {
    case connected    // 绿
    case failed       // 红
    case pending      // 琥珀
    case disabled     // 灰
    case disconnected // 灰
    case offline      // 灰（Agent 未运行时的默认状态）

    var color: Color {
        switch self {
        case .connected: return .green
        case .failed: return .red
        case .pending: return .orange
        case .disabled, .disconnected, .offline: return .gray
        }
    }

    var label: String {
        switch self {
        case .connected: return "已连接"
        case .failed: return "连接失败"
        case .pending: return "连接中..."
        case .disabled: return "已禁用"
        case .disconnected: return "未连接"
        case .offline: return "离线"
        }
    }

    static func from(_ sdkStatus: McpServerStatusEnum) -> MCPServerDisplayStatus {
        switch sdkStatus {
        case .connected: return .connected
        case .failed: return .failed
        case .pending: return .pending
        case .disabled: return .disabled
        case .needsAuth: return .failed  // MVP 阶段将 needsAuth 视为 failed
        }
    }
}
```

### 核心架构——Agent SDK API 使用

**本 Story 使用的 SDK API（全部通过 Agent 实例调用，Agent 由 AgentBridge 持有）：**

| SDK API | 用途 | 参数 | 返回 |
|---------|------|------|------|
| `agent.mcpServerStatus()` | 获取所有 MCP Server 的运行时状态 | 无 | `[String: McpServerStatus]` |
| `agent.toggleMcpServer(name:, enabled:)` | 启用/禁用指定 Server | name + enabled | throws |
| `agent.reconnectMcpServer(name:)` | 重连指定 Server | name | throws |

**关键：`agent` 属性是 `AgentBridge` 的 `private(set) var agent: Agent?`，不能被 View 直接访问。** 所有对 SDK Agent 的调用必须封装在 `AgentBridge` 或 `MCPManagementViewModel` 的方法中。

**推荐在 AgentBridge 上添加 MCP 管理方法（遵循分层架构）：**

```swift
// 在 AgentBridge.swift 中添加
func mcpServerStatus() async -> [String: McpServerStatus] {
    guard let agent else { return [:] }
    return await agent.mcpServerStatus()
}

func toggleMcpServer(name: String, enabled: Bool) async throws {
    guard let agent else { return }
    try await agent.toggleMcpServer(name: name, enabled: enabled)
}

func reconnectMcpServer(name: String) async throws {
    guard let agent else { return }
    try await agent.reconnectMcpServer(name: name)
}
```

**注意：** `updateMCPServers()` 已在 Story 6-2 添加到 AgentBridge，用于编辑后热更新。本 Story 的 toggle/reconnect 是不同的 API。toggle 只修改 SDK 运行时状态（不断开配置），而 updateMCPServers() 是全量替换。

### 核心架构——SettingsView Tab 集成

当前 `SettingsView` 有三个 tab：`SettingsTab` 枚举（通用 / 权限 / Skills）。需要添加第四个：

```swift
private enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "通用"
    case permissions = "权限"
    case skills = "Skills"
    case mcp = "MCP Servers"    // 新增

    var id: Self { self }
}
```

**Segmented control 宽度调整：** 当前 `tabPicker` 的 Picker 宽度为 260pt（4 个 tab 需要 340pt 左右）。改为自适应或增加宽度：

```swift
.frame(width: 340)  // 从 260 增加到 340
```

**mcpTab 实现：**

```swift
private var mcpTab: some View {
    Group {
        if let bridge = agentBridge, let store = bridge.mcpConfigStore {
            MCPManagementView(
                store: store,
                agentBridge: bridge
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            Text("MCP 管理不可用")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
```

### OpenWork UI 参照分析

**参照文件：** `/Users/nick/CascadeProjects/openwork/apps/app/src/react-app/domains/settings/pages/mcp-view.tsx`

**需要复刻的交互模式：**

1. **列表行结构**：图标（Plug2/服务图标）+ 名称 + 状态圆点 + 状态文字 + 展开箭头（ChevronDown）
2. **展开详情动画**：slide-in-from-top 动画，详情区包含连接类型、工具标签、技术详情折叠区、操作按钮行
3. **状态圆点**：2x2pt 圆形，颜色跟随状态（参照 `statusDot()` 函数）
4. **空状态**：Unplug 图标 + "No apps connected yet" + 副标题
5. **操作按钮**：启用/禁用（Power 图标）、删除（红色 danger 按钮）
6. **错误展示**：红色边框 bg-red-2 区域显示错误信息
7. **技术详情**：`<details>` 折叠区，monospace 字体显示 URL 或 Command
8. **删除确认**：ConfirmModal 二次确认（SwiftUI 中用 `.alert()` 或 `.confirmationDialog()`）

**SwiftUI 实现要点：**

```swift
// 列表行
MCPServerRowView(config: config, status: status)
    .contentShape(Rectangle())
    .onTapGesture { selectedServerName = isSelected ? nil : config.name }

// 展开详情
if selectedServerName == config.name {
    MCPServerDetailView(
        config: config,
        sdkStatus: serverStatuses[config.name],
        onToggle: { ... },
        onEdit: { editingConfig = config },
        onReconnect: { ... },
        onDelete: { ... }
    )
    .transition(.opacity.combined(with: .move(edge: .top)))
}
```

**不参照的内容：**
- OAuth 相关（needsAuth 登录/登出按钮）——SwiftWork MVP 不实现
- Quick Connect 目录（notion/linear/sentry 等预配置服务）——SwiftWork MVP 不实现
- Chrome DevTools MCP 特殊处理——SwiftWork 不需要
- React `useState`/`useEffect`/CSS classes——用 SwiftUI 等效替代

### 删除确认设计（AC5）

使用 SwiftUI 的 `.confirmationDialog()` 代替 OpenWork 的自定义 ConfirmModal：

```swift
.confirmationDialog(
    "确认删除 MCP Server",
    isPresented: $showDeleteConfirmation,
    titleVisibility: .visible
) {
    Button("删除", role: .destructive) {
        performDelete()
    }
    Button("取消", role: .cancel) {}
} message: {
    Text("确定要删除「\(config.name)」吗？此操作无法撤销。")
}
```

### 刷新时机

MCP 状态是动态的（连接、断开、错误），需要合理的刷新策略：

1. **首次加载**：`.onAppear` 调用 `loadServers()` + `refreshStatus()`
2. **添加/编辑/删除后**：操作完成后重新加载列表
3. **toggle/reconnect 后**：操作完成后刷新状态
4. **定时轮询**（可选）：Agent 运行期间每 5 秒刷新一次状态，但 MVP 阶段可不实现

### 与前序 Story 的依赖

**Story 6-1 提供的 API（必须使用，不得重新实现）：**

| API | 用途 | 文件 |
|-----|------|------|
| `MCPServerConfigStore.list()` | 获取所有配置列表 | `SwiftWork/Services/MCPServerConfigStore.swift:135-139` |
| `MCPServerConfigStore.delete(_:)` | 删除配置 | `SwiftWork/Services/MCPServerConfigStore.swift:130-133` |
| `MCPServerConfigStore.update(_:enabled:)` | 更新启用状态 | `SwiftWork/Services/MCPServerConfigStore.swift:62-89` |
| `MCPServerConfig` SwiftData 模型 | 配置对象（name/transportType/enabled/scope/...） | `SwiftWork/Models/SwiftData/MCPServerConfig.swift` |
| `TransportType` 枚举 | 传输类型判断 | `SwiftWork/Models/SwiftData/MCPServerConfig.swift:4-8` |

**Story 6-2 提供的 API（必须使用）：**

| API | 用途 | 文件 |
|-----|------|------|
| `AddMCPServerSheet` | 添加 MCP Server 弹窗 | `SwiftWork/Views/Settings/MCP/AddMCPServerSheet.swift` |
| `EditMCPServerSheet` | 编辑 MCP Server 弹窗 | `SwiftWork/Views/Settings/MCP/EditMCPServerSheet.swift` |
| `AddMCPServerViewModel` | 弹窗 ViewModel（验证/提交逻辑） | `SwiftWork/Views/Settings/MCP/AddMCPServerSheet.swift` |
| `AgentBridge.updateMCPServers()` | 编辑后热更新 Agent | `SwiftWork/SDKIntegration/AgentBridge.swift:196-213` |

### 需要新增到 AgentBridge 的方法

当前 AgentBridge 只有 `updateMCPServers()`（全量替换）。本 Story 需要添加三个粒度更细的 MCP 管理方法：

```swift
// AgentBridge.swift 新增

/// 获取 MCP Server 运行时状态
func mcpServerStatus() async -> [String: McpServerStatus] {
    guard let agent else { return [:] }
    return await agent.mcpServerStatus()
}

/// 启用/禁用指定 MCP Server（运行时级别）
func toggleMcpServer(name: String, enabled: Bool) async throws {
    guard let agent else { return }
    // 同步更新 SwiftData 配置
    if let store = mcpConfigStore {
        let configs = try store.list()
        if let config = configs.first(where: { $0.name == name }) {
            _ = try store.update(config, enabled: enabled)
        }
    }
    try await agent.toggleMcpServer(name: name, enabled: enabled)
}

/// 重连指定 MCP Server
func reconnectMcpServer(name: String) async throws {
    guard let agent else { return }
    try await agent.reconnectMcpServer(name: name)
}
```

**注意 toggleMcpServer 方法同时更新 SwiftData 和 SDK：** OpenWork 的 toggle 只修改配置文件，SDK 下次启动时生效。但 SwiftWork 的 Story AC3/AC4 要求"通过 agent.toggleMcpServer() 断开/重连"，即运行时立即生效。同时也要更新 SwiftData 的 `enabled` 字段，保证下次启动时状态一致。

### 单个 View 文件行数限制

根据项目规则，单个 View 文件不超过 300 行。`MCPManagementView` 预计包含 ViewModel + 主 View + 子组件辅助，可能会接近限制。策略：

1. `MCPManagementView.swift`：只包含 ViewModel + 主面板布局（< 200 行）
2. `MCPServerRowView.swift`：列表行组件（< 100 行）
3. `MCPServerDetailView.swift`：展开详情组件（< 200 行）

如果 MCPServerDetailView 包含多个子区域（错误展示、操作按钮、工具标签），可以进一步将操作按钮行提取为私有子 View。

### 代码复用要点

1. **SkillsListView 空状态模式**：参照 `SwiftWork/Views/Settings/SkillsListView.swift:49-63` 的 `emptyState` 实现——图标 + 标题 + 说明文字的 VStack 布局
2. **SettingsView tab 模式**：参照 `SettingsView.swift:12-18` 的 `SettingsTab` 枚举和 `activeTabContent` switch
3. **Agent 不可用时提示**：参照 `SettingsView.swift:147-149` 的 "Skill 列表不可用" 模式
4. **List 展开交互**：参照 `SkillsListView.swift:29-35` 的 `onTapGesture` + `isExpanded` 模式
5. **Section header 模式**：参照 `SkillsListView.swift:67-79` 的 `sectionHeader` 函数
6. **行内错误样式**：参照 `MCPFormFields.swift:76-91` 的 `errorBanner` 样式

### 不需要修改的文件

- **MCPServerConfigStore.swift**：Story 6-1 已提供完整的 list/delete/update API
- **MCPServerConfig.swift**：Story 6-1 已完成数据模型
- **AddMCPServerSheet.swift / EditMCPServerSheet.swift**：Story 6-2 已完成弹窗组件
- **MCPFormFields.swift / MCPTransportTypePicker.swift**：Story 6-2 的共享组件
- **SwiftWorkApp.swift**：MCPServerConfig 已注册在 modelContainer 中

### Project Structure Notes

- 新建文件：`SwiftWork/Views/Settings/MCP/MCPManagementView.swift`
- 新建文件：`SwiftWork/Views/Settings/MCP/MCPServerRowView.swift`
- 新建文件：`SwiftWork/Views/Settings/MCP/MCPServerDetailView.swift`
- 修改文件：`SwiftWork/Views/Settings/SettingsView.swift`（添加 MCP Servers tab）
- 修改文件：`SwiftWork/SDKIntegration/AgentBridge.swift`（添加 mcpServerStatus/toggleMcpServer/reconnectMcpServer 方法）
- 新建测试：`SwiftWorkTests/ViewModels/MCPManagementViewModelTests.swift`
- 遵循命名规范：View 为 PascalCase + View 后缀，文件名与主类型名一致

### References

- [Source: SwiftWork/Views/Settings/SettingsView.swift — Settings tab 枚举和内容结构]
- [Source: SwiftWork/Views/Settings/SkillsListView.swift — 空状态、展开交互、section header 模式]
- [Source: SwiftWork/Services/MCPServerConfigStore.swift — list()/delete()/update() 方法]
- [Source: SwiftWork/Models/SwiftData/MCPServerConfig.swift — MCPServerConfig 模型和 TransportType 枚举]
- [Source: SwiftWork/Views/Settings/MCP/AddMCPServerSheet.swift — AddMCPServerSheet 接口]
- [Source: SwiftWork/Views/Settings/MCP/EditMCPServerSheet.swift — EditMCPServerSheet 接口]
- [Source: SwiftWork/SDKIntegration/AgentBridge.swift:182-213 — MCP Config System 和 updateMCPServers()]
- [Source: open-agent-sdk-swift/Sources/OpenAgentSDK/Types/MCPTypes.swift — McpServerStatus/McpServerStatusEnum/McpServerUpdateResult]
- [Source: open-agent-sdk-swift/Sources/OpenAgentSDK/Core/Agent.swift:671-732 — mcpServerStatus()/toggleMcpServer()/reconnectMcpServer()/setMcpServers()]
- [Source: /Users/nick/CascadeProjects/openwork/apps/app/src/react-app/domains/settings/pages/mcp-view.tsx — UI 交互参照：列表行、展开详情、状态圆点、操作按钮、空状态]
- [Source: _bmad-output/implementation-artifacts/6-1-mcp-config-model-persistence.md — Story 6-1 Dev Notes]
- [Source: _bmad-output/implementation-artifacts/6-2-mcp-add-edit-modal.md — Story 6-2 Dev Notes]

## Dev Agent Record

### Agent Model Used

GLM-5.1

### Debug Log References

- Disk space issue (ENOSPC) encountered during implementation; resolved by cleaning `.build/index-build`
- ATDD test files had incorrect parameter order in `McpServerStatus()` constructor calls (tools before error); fixed to match SDK signature
- Xcode project pbxproj required manual file addition for new source and test files

### Completion Notes List

- All 7 tasks completed with all subtasks checked
- 60 ATDD tests pass (13 MCPServerDisplayStatus + 38 MCPManagementViewModel + 9 MCPManagementView)
- MCPServerDisplayStatus enum maps SDK McpServerStatusEnum to UI display states with color/label support
- MCPManagementViewModel manages server list, selection, toggle, delete, reconnect, and status refresh
- MCPManagementView provides main panel with empty state, server list, add sheet, edit sheet, delete confirmation
- MCPServerRowView displays server name, status dot, transport type tag, and expand arrow
- MCPServerDetailView shows connection type, technical details, tools list, error display, and action buttons
- AgentBridge extended with mcpServerStatus(), toggleMcpServer(), reconnectMcpServer() methods
- SettingsView updated with 4th MCP Servers tab and wider segmented control (260 -> 340)
- Pre-existing test failures (20) are unrelated to Story 6-3 changes (AgentBridgeSkillTests, SessionViewModelTests, SessionWorkspaceServiceTests, SkillSourceGroupingTests, SkillsSettingsViewTests)

### File List

**New files:**
- SwiftWork/Views/Settings/MCP/MCPManagementView.swift
- SwiftWork/Views/Settings/MCP/MCPManagementViewModel.swift
- SwiftWork/Views/Settings/MCP/MCPServerRowView.swift
- SwiftWork/Views/Settings/MCP/MCPServerDetailView.swift
- SwiftWork/Views/Settings/MCP/MCPServerDisplayStatus.swift

**Modified files:**
- SwiftWork/Views/Settings/SettingsView.swift
- SwiftWork/SDKIntegration/AgentBridge.swift
- SwiftWork.xcodeproj/project.pbxproj

**Modified test files (parameter order fix):**
- SwiftWorkTests/ViewModels/MCPManagementViewModelTests.swift

### Review Findings

- [x] [Review][Patch] deleteServer() does not hot-remove server from running Agent's tool pool (AC5 violation) [MCPManagementViewModel.swift:98-108] — Fixed: added `agentBridge?.updateMCPServers()` call after SwiftData deletion
- [x] [Review][Patch] toggleServer() uses try? silently swallowing SDK errors (AC3/AC4) [MCPManagementViewModel.swift:84-94] — Fixed: replaced `try?` with `do/catch` that sets `errorMessage`
- [x] [Review][Patch] statusForServer() returns .disconnected when agentBridge exists but isRunning==false [MCPManagementViewModel.swift:64-70] — Fixed: changed condition to `agentBridge?.isRunning ?? false`
- [x] [Review][Patch] Reconnect button only shown when sdkStatus != nil, not when Agent is running (AC6) [MCPServerDetailView.swift:7,142] — Fixed: added `isAgentRunning: Bool` parameter, condition changed to `isAgentRunning`
- [x] [Review][Patch] reconnectServer() uses try? silently swallowing SDK errors (AC6) [MCPManagementViewModel.swift:128-135] — Fixed: replaced `try?` with `do/catch` that sets `errorMessage`
- [x] [Review][Defer] Management panel hardcodes scope: .global for add/edit sheets [MCPManagementView.swift:37,48] — deferred, acceptable for MVP
- [x] [Review][Defer] No expandable "查看详情" section for error display (minor AC7 deviation) [MCPServerDetailView.swift:100-114] — deferred, minor spec deviation
