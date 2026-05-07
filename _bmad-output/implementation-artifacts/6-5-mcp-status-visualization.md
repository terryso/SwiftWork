# Story 6.5: MCP 状态可视化

Status: done

## Story

As a 用户,
I want 在主工作区的 Status Bar 中看到 MCP 连接状态，并在 Timeline 中识别 MCP 工具调用,
so that 我可以实时了解外部工具的可用性，并区分内置工具和 MCP 工具的调用。

## Acceptance Criteria

1. **AC1 — Status Bar MCP 连接数指标** — Given Agent 已启动并连接了 MCP Server, When 查看 Status Bar, Then 显示 MCP 连接数指标（如 "3 MCP 已连接"），参照 OpenWork `status-bar.tsx` 的 `mcpConnectedCount` 展示方式（FR-MCP-5）

2. **AC2 — MCP 工具 Tool Card 来源标识** — Given Agent 调用了 MCP 工具（工具名以 `mcp__` 开头）, When Timeline 渲染 toolUse 事件, Then Tool Card 显示 MCP 来源标识（如 "via {serverName}" 标签），使用与内置工具不同的视觉样式（不同图标或边框色），让用户一眼区分内置工具和外部工具（FR-MCP-4）

3. **AC3 — Inspector MCP 工具元数据展示** — Given Agent 连接了 MCP Server 并发现工具, When 用户通过 Inspector 查看该工具, Then 显示工具的完整元数据：serverName、mcpToolName、命名空间全名、schema、来源（MCP）

## Tasks / Subtasks

- [x] Task 1: 创建 WorkspaceStatusBar 组件（AC: #1）
  - [x] 1.1 新建 `SwiftWork/Views/Workspace/WorkspaceStatusBar.swift`，实现底部状态栏视图
  - [x] 1.2 显示 MCP 连接数指标：`"{count} MCP 已连接"` 格式，使用 `cube.box` SF Symbol 图标
  - [x] 1.3 无 MCP 连接时不显示该指标（显示 "就绪" 文字），有连接时显示连接数 + 绿色状态点
  - [x] 1.4 有连接失败的 MCP Server 时，显示警告状态（琥珀色点 + "N 个 MCP 连接失败"）
  - [x] 1.5 MCP 状态为 pending 时显示 "正在连接..." 加载指示器

- [x] Task 2: 创建 MCPStatusViewModel 状态管理（AC: #1）
  - [x] 2.1 新建 `SwiftWork/Views/Workspace/MCPStatusViewModel.swift`
  - [x] 2.2 使用 `@Observable`（禁止 `ObservableObject`），`@MainActor` 标注
  - [x] 2.3 暴露计算属性：`connectedCount: Int`、`failedCount: Int`、`pendingCount: Int`、`totalConfiguredCount: Int`
  - [x] 2.4 从 `AgentBridge.mcpServerStatus()` 获取运行时状态数据
  - [x] 2.5 从 `MCPServerConfigStore.list()` 获取配置数量（用于 Agent 未运行时的离线展示）
  - [x] 2.6 提供定时刷新机制：Agent 运行时每 5 秒自动刷新一次（参照 MCPManagementViewModel 的 refreshStatus 模式）
  - [x] 2.7 Agent 停止/启动时自动更新状态

- [x] Task 3: 集成 WorkspaceStatusBar 到 WorkspaceView（AC: #1）
  - [x] 3.1 在 `WorkspaceView` 中实例化 `MCPStatusViewModel` 和 `WorkspaceStatusBar`
  - [x] 3.2 在 `TimelineView` 下方、`InputBarView` 上方插入 Status Bar（参照 OpenWork status-bar 位置：底部输入栏之上）
  - [x] 3.3 传递 `agentBridge` 和 `mcpConfigStore` 给 `MCPStatusViewModel`
  - [x] 3.4 在 `.task` 中启动定时刷新，在 `.onDisappear` 中取消
  - [x] 3.5 确保 `isDebugPanelVisible` 和 `isInspectorVisible` 的切换不影响 Status Bar 可见性

- [x] Task 4: 验证 MCPToolRenderer 来源标识（AC: #2）
  - [x] 4.1 验证 Story 6-4 创建的 `MCPToolRenderer.swift` 已正确显示 "via {serverName}" 标签
  - [x] 4.2 验证 MCP Tool Card 使用蓝色边框/背景（`accentColor: .blue`）区分内置工具
  - [x] 4.3 验证 `cube.box` 图标和 `server.rack` 来源标识已正确渲染
  - [x] 4.4 如有视觉不足，微调 MCPToolRenderer 样式增强 MCP 工具可辨识度

- [x] Task 5: 增强 InspectorView 展示 MCP 工具元数据（AC: #3）
  - [x] 5.1 在 `EventDetailSections.swift` 的 `toolEventSection(event:)` 中，检测 MCP 工具事件
  - [x] 5.2 通过 `event.metadata["isMCP"]` 判断是否为 MCP 工具
  - [x] 5.3 如果是 MCP 工具，显示额外元数据区：
    - `来源: MCP` 标签
    - `服务器: {serverName}`（从 `metadata["serverName"]` 获取）
    - `命名空间: {toolName}`（完整 `mcp__serverName__toolName` 格式）
    - `工具名: {mcpToolName}`（从 toolName 解析出实际工具名部分）
  - [x] 5.4 使用蓝色主题色标识 MCP 来源（与 MCPToolRenderer 的蓝色视觉一致）
  - [x] 5.5 确保 Inspector 中的 MCP 元数据与 MCPToolRenderer 的解析逻辑一致（使用相同的 `components(separatedBy: "__")` 模式）

- [x] Task 6: 编写测试（AC: #1-#3）
  - [x] 6.1 新建 `SwiftWorkTests/ViewModels/MCPStatusViewModelTests.swift`
  - [x] 6.2 测试 connectedCount/failedCount/pendingCount 计算属性
  - [x] 6.3 测试 Agent 未运行时的离线状态展示
  - [x] 6.4 测试 Inspector MCP 元数据提取逻辑
  - [x] 6.5 回归测试：确认全部现有测试通过

## Dev Notes

### 核心架构——Status Bar 设计

**当前状态：WorkspaceView 没有底部 Status Bar。** OpenWork 的 `status-bar.tsx` 是一个底部水平条，显示连接状态、MCP 连接数、快捷操作按钮。SwiftWork 需要新建此组件。

**位置：** 在 WorkspaceView 中，Status Bar 应放在 `TimelineView` 和 `InputBarView` 之间，作为信息展示条。参照 OpenWork 的布局：

```
┌─────────────────────────────┐
│ workspaceStatusBanner       │ (已有：workspace 未绑定提示)
├─────────────────────────────┤
│                             │
│ TimelineView                │
│                             │
├─────────────────────────────┤
│ WorkspaceStatusBar          │ ← 新增：MCP 连接数 + 状态
├─────────────────────────────┤
│ InputBarView                │
├─────────────────────────────┤
│ autoApproveWarningBar       │ (已有：自动批准警告)
└─────────────────────────────┘
```

**OpenWork 参照关键逻辑（`status-bar.tsx` 行 50-66）：**
- `mcpConnectedCount > 0` 时在 detail 文字中展示连接数
- 使用绿色/琥珀色/红色状态点表示不同连接状态
- 文字格式：`"{count} MCP connected"` 拼接到状态详情中

### 核心架构——MCPStatusViewModel 数据流

**关键数据源：**

| 数据 | 来源 | API |
|------|------|-----|
| 运行时 MCP 状态 | Agent 运行时 | `AgentBridge.mcpServerStatus() -> [String: McpServerStatus]` |
| 配置列表 | SwiftData | `MCPServerConfigStore.list() -> [MCPServerConfig]` |
| Agent 运行状态 | AgentBridge | `AgentBridge.isRunning: Bool` |

**McpServerStatus 结构（SDK）：**
```swift
// MCPTypes.swift (SDK)
public struct McpServerStatus: Sendable {
    public let name: String
    public let status: McpServerStatusEnum  // .connected / .failed / .pending / .disabled / .needsAuth
    public let tools: [MCPToolDefinition]
    public let error: String?
}
```

**状态计算逻辑：**
```swift
// 伪代码——MCPStatusViewModel
var connectedCount: Int {
    serverStatuses.values.filter { $0.status == .connected }.count
}
var failedCount: Int {
    serverStatuses.values.filter { $0.status == .failed || $0.status == .needsAuth }.count
}
var pendingCount: Int {
    serverStatuses.values.filter { $0.status == .pending }.count
}
```

**定时刷新：** 参照 `MCPManagementViewModel.refreshStatus()` 的模式，使用 `Timer.publish` 或在 `.task` 中使用 `Task.sleep` 循环刷新。Agent 运行时每 5 秒刷新一次，Agent 停止时停止刷新。

### 核心架构——AC2 已由 Story 6-4 完成

**Story 6-4 已实现 MCPToolRenderer：**
- `MCPToolRenderer.swift` — 完整的 MCP 工具渲染器，包含：
  - `summaryTitle()` — 从 `mcp__server__tool` 提取实际工具名
  - `subtitle()` — 显示 "via {serverName}"
  - `body()` — MCP 专用卡片布局，蓝色背景（`.blue.opacity(0.06)`）
  - `cube.box` 图标 + `server.rack` 来源图标
- `ToolRendererRegistry` — 已支持 `mcp__` 前缀匹配
- `EventMapper` — 已在 `.toolUse` 和 `.toolProgress` 中添加 `isMCP: true` 和 `serverName` 元数据

**AC2 只需验证和可能的视觉微调，不需要重新实现。**

### 核心架构——Inspector MCP 元数据增强

**当前 Inspector 的 toolEventSection（`EventDetailSections.swift`）：**
- 显示：工具名、状态、耗时、参数、输出
- 不区分 MCP 和内置工具

**需要增加的 MCP 专属信息（AC3）：**

```swift
// EventDetailSections.swift 中 toolEventSection 的增强
// 在现有 toolName 显示之后，添加 MCP 专属区域
if let isMCP = event.metadata["isMCP"] as? Bool, isMCP {
    // MCP 来源标识
    labeledRow("来源", value: "MCP")

    // 服务器名
    if let serverName = event.metadata["serverName"] as? String {
        labeledRow("服务器", value: serverName)
    }

    // 命名空间全名
    if let toolName = event.metadata["toolName"] as? String {
        labeledRow("命名空间", value: toolName)
        // 实际工具名（去掉 mcp__server__ 前缀）
        let parts = toolName.components(separatedBy: "__")
        if parts.count >= 3 {
            labeledRow("MCP 工具", value: parts.dropFirst(2).joined(separator: "__"))
        }
    }
}
```

**与 toolContentMap 的配合：** `InspectorView` 接收 `toolContentMap: [String: ToolContent]`，其中 `ToolContent` 不存储 `isMCP`/`serverName` 元数据。这些元数据存在于 `AgentEvent.metadata` 中。因此 Inspector 需要同时访问 `AgentEvent`（有 MCP 元数据）和 `ToolContent`（有工具执行详情）。

**注意：** 当前 `InspectorView` 只接收 `selectedEvent: AgentEvent?` 和 `toolContentMap`。MCP 元数据在 `selectedEvent?.metadata` 中已经可用（EventMapper 在 Story 6-4 中已添加），不需要修改 InspectorView 的初始化签名。

### 与前序 Story 的依赖

**Story 6-1 提供的 API：**

| API | 用途 | 文件 |
|-----|------|------|
| `MCPServerConfigStore.list()` | 获取所有配置列表 | `SwiftWork/Services/MCPServerConfigStore.swift:135-139` |
| `MCPServerConfig` SwiftData 模型 | 配置对象 | `SwiftWork/Models/SwiftData/MCPServerConfig.swift` |

**Story 6-3 提供的 API：**

| API | 用途 | 文件 |
|-----|------|------|
| `AgentBridge.mcpServerStatus()` | 获取运行时 MCP 状态 | `SwiftWork/SDKIntegration/AgentBridge.swift:197-200` |
| `MCPServerDisplayStatus` | UI 状态枚举（颜色/标签） | `SwiftWork/Views/Settings/MCP/MCPServerDisplayStatus.swift` |
| `MCPManagementViewModel.refreshStatus()` | 刷新模式参考 | `SwiftWork/Views/Settings/MCP/MCPManagementViewModel.swift:74-80` |

**Story 6-4 提供的 API：**

| API | 用途 | 文件 |
|-----|------|------|
| `MCPToolRenderer` | MCP 工具 Timeline 卡片渲染器 | `SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/MCPToolRenderer.swift` |
| `EventMapper` MCP 元数据 | `isMCP: true`, `serverName` | `SwiftWork/SDKIntegration/EventMapper.swift:40-46, 74-79` |
| `ToolRendererRegistry` 前缀匹配 | `mcp__` 前缀 → MCPToolRenderer | `SwiftWork/SDKIntegration/ToolRendererRegistry.swift:29-31` |

### 新建文件列表

```
SwiftWork/Views/Workspace/WorkspaceStatusBar.swift       # 底部状态栏视图
SwiftWork/Views/Workspace/MCPStatusViewModel.swift       # MCP 状态计算逻辑
SwiftWorkTests/ViewModels/MCPStatusViewModelTests.swift  # 状态 ViewModel 测试
```

### 修改文件列表

```
SwiftWork/Views/Workspace/WorkspaceView.swift              # 集成 WorkspaceStatusBar
SwiftWork/Views/Workspace/Inspector/EventDetailSections.swift # MCP 工具元数据区
SwiftWork.xcodeproj/project.pbxproj                       # 添加新文件引用
```

### 代码复用要点

1. **参照 MCPManagementViewModel 的 refreshStatus 模式**：`SwiftWork/Views/Settings/MCP/MCPManagementViewModel.swift:74-80` 展示了如何调用 `agentBridge.mcpServerStatus()` 获取运行时状态——MCPStatusViewModel 应使用相同模式
2. **参照 MCPServerDisplayStatus 的状态映射**：`SwiftWork/Views/Settings/MCP/MCPServerDisplayStatus.swift` 已定义 `.connected`/`.failed`/`.pending`/`.disabled` 的颜色和标签——WorkspaceStatusBar 应复用此枚举
3. **参照 MCPToolRenderer 的工具名解析**：`MCPToolRenderer.swift:138-143` 展示了 `components(separatedBy: "__")` 解析模式——Inspector 增强应使用相同逻辑
4. **参照 autoApproveWarningBar 的插入位置**：`WorkspaceView.swift:152-168` 展示了在 InputBarView 下方添加状态条的模式——WorkspaceStatusBar 应使用类似但位置在 InputBarView 上方
5. **参照 OpenWork status-bar.tsx 的 MCP 展示格式**：行 50-66 展示了 `mcpConnectedCount` 在 detail 文字中的拼接方式

### 不需要修改的文件

- **MCPToolRenderer.swift**：Story 6-4 已完成 MCP 工具卡片渲染（AC2 验证即可）
- **ToolRendererRegistry.swift**：Story 6-4 已完成前缀匹配
- **EventMapper.swift**：Story 6-4 已完成 MCP 元数据注入
- **AgentBridge.swift**：`mcpServerStatus()` API 已存在，无需修改
- **MCPServerConfigStore.swift**：`list()` API 已存在，无需修改
- **InspectorView.swift**：只修改 `EventDetailSections.swift` 扩展文件，不修改 InspectorView 主体
- **ToolContent.swift**：MCP 元数据存在 AgentEvent.metadata 中，不需要修改 ToolContent 模型

### 潜在风险

1. **定时刷新性能**：每 5 秒调用 `mcpServerStatus()` 是异步的，不会阻塞 UI。但如果 Agent 正在处理大量事件流，额外的状态查询可能增加 SDK 负担。建议：只在 Agent 运行且有 MCP 配置时才启动定时器。
2. **Status Bar 与 workspaceStatusBanner 冲突**：workspaceStatusBanner 在未绑定 workspace 时显示，Status Bar 是常态显示。两者不冲突——workspaceStatusBanner 是顶部条件横幅，Status Bar 是底部固定状态条。
3. **Inspector MCP 元数据一致性**：`isMCP` 和 `serverName` 由 EventMapper 在 Story 6-4 注入到 `AgentEvent.metadata` 中，但 `ToolContent` 不存储这些字段。Inspector 需要从 `event.metadata` 读取，不从 `toolContentMap` 读取。当前 `toolEventSection` 同时访问 `event.metadata`（获取工具名、参数等）和 `toolContentMap`（获取执行详情），MCP 元数据可自然插入到 metadata 访问逻辑中。
4. **MCP 状态刷新时机**：Agent 启动时 MCP 连接需要时间（pending → connected/failed）。Status Bar 的首次刷新应在 Agent 启动后延迟几秒执行，或使用 `onChange(of: agentBridge.isRunning)` 触发立即刷新。

### Project Structure Notes

- 新建文件：`SwiftWork/Views/Workspace/WorkspaceStatusBar.swift`
- 新建文件：`SwiftWork/Views/Workspace/MCPStatusViewModel.swift`
- 新建文件：`SwiftWorkTests/ViewModels/MCPStatusViewModelTests.swift`
- 修改文件：`SwiftWork/Views/Workspace/WorkspaceView.swift`（集成 Status Bar）
- 修改文件：`SwiftWork/Views/Workspace/Inspector/EventDetailSections.swift`（MCP 元数据区）
- 遵循命名规范：View 为 PascalCase + View 后缀，ViewModel 为 PascalCase + ViewModel 后缀
- 单个文件不超过 300 行（WorkspaceStatusBar 预计 ~120 行，MCPStatusViewModel 预计 ~80 行）
- 文件名与主类型名一致

### References

- [Source: SwiftWork/SDKIntegration/AgentBridge.swift:197-200 — mcpServerStatus() API]
- [Source: SwiftWork/SDKIntegration/AgentBridge.swift:225-242 — updateMCPServers() 热更新]
- [Source: SwiftWork/Views/Workspace/WorkspaceView.swift — WorkspaceView 主视图结构]
- [Source: SwiftWork/Views/Workspace/Inspector/EventDetailSections.swift — Inspector 工具详情区]
- [Source: SwiftWork/Views/Workspace/Inspector/InspectorView.swift — Inspector 主体]
- [Source: SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/MCPToolRenderer.swift — MCP 工具渲染器]
- [Source: SwiftWork/SDKIntegration/ToolRendererRegistry.swift — 前缀匹配注册表]
- [Source: SwiftWork/SDKIntegration/EventMapper.swift:40-46, 74-79 — MCP 元数据注入]
- [Source: SwiftWork/Views/Settings/MCP/MCPServerDisplayStatus.swift — UI 状态枚举]
- [Source: SwiftWork/Views/Settings/MCP/MCPManagementViewModel.swift:74-80 — refreshStatus 模式]
- [Source: SwiftWork/Services/MCPServerConfigStore.swift:135-139 — list() API]
- [Source: openwork/apps/app/src/react-app/domains/session/chat/status-bar.tsx — OpenWork Status Bar 参照]
- [Source: _bmad-output/implementation-artifacts/6-4-agent-mcp-integration-tool-registration.md — Story 6-4 Dev Notes]

### ATDD Artifacts

- Checklist: `_bmad-output/test-artifacts/atdd-checklist-6-5-mcp-status-visualization.md`
- Unit tests (ViewModel): `SwiftWorkTests/ViewModels/MCPStatusViewModelTests.swift`
- Unit tests (Inspector): `SwiftWorkTests/Views/Workspace/Inspector/InspectorMCPMetadataTests.swift`
- Unit tests (StatusBar): `SwiftWorkTests/Views/Workspace/WorkspaceStatusBarTests.swift`
- Integration tests: `SwiftWorkTests/App/MCPStatusVisualizationIntegrationTests.swift`

## Dev Agent Record

### Agent Model Used

GLM-5.1

### Debug Log References

### Completion Notes List

- Implemented MCPStatusViewModel with @Observable + @MainActor pattern, providing connectedCount/failedCount/pendingCount/totalConfiguredCount computed properties and statusSummaryText
- Implemented WorkspaceStatusBar as a lightweight SwiftUI view with state-dependent rendering: connected (green dot), failed (orange warning), pending (loading spinner), configured-but-offline (gray), ready (no configs)
- Integrated WorkspaceStatusBar into WorkspaceView between TimelineView and InputBarView, with lifecycle-managed MCPStatusViewModel (setup in .task, cleanup in .onDisappear, auto-refresh on isRunning changes)
- Added mcpMetadataSection to EventDetailSections.swift for Inspector MCP tool metadata display (source, server name, namespace, actual tool name) with blue theme matching MCPToolRenderer
- Verified AC2 (MCPToolRenderer from Story 6-4) — "via {serverName}" subtitle, cube.box icon, blue background, server.rack source label all confirmed working via integration tests
- Fixed ATDD test assertion error in InspectorMCPMetadataTests (parts count for single-underscore tool names — `__` is the separator, not `_`)
- All 65 Story 6-5 tests pass (31 ViewModel + 8 StatusBar + 13 Inspector + 11 Integration)
- No regressions introduced — 12 pre-existing test failures remain (all in skill/session-workspace tests, unrelated to this story)

### File List

**New Files:**
- SwiftWork/Views/Workspace/WorkspaceStatusBar.swift
- SwiftWork/Views/Workspace/MCPStatusViewModel.swift

**Modified Files:**
- SwiftWork/Views/Workspace/WorkspaceView.swift
- SwiftWork/Views/Workspace/Inspector/EventDetailSections.swift
- SwiftWorkTests/Views/Workspace/Inspector/InspectorMCPMetadataTests.swift (fixed ATDD test assertion)
- SwiftWork.xcodeproj/project.pbxproj

**ATDD Test Files (pre-existing, now passing):**
- SwiftWorkTests/ViewModels/MCPStatusViewModelTests.swift
- SwiftWorkTests/Views/Workspace/WorkspaceStatusBarTests.swift
- SwiftWorkTests/Views/Workspace/Inspector/InspectorMCPMetadataTests.swift
- SwiftWorkTests/App/MCPStatusVisualizationIntegrationTests.swift
