# Story 6.4: Agent MCP 集成与工具注册

Status: review

## Story

As a 用户,
I want Agent 启动时自动连接配置的 MCP Server，并将发现的工具注册到工具池,
so that Agent 可以使用 MCP Server 提供的外部工具来完成任务。

## Acceptance Criteria

1. **AC1 — Agent 启动时 MCP 连接** — Given 用户已配置 MCP Server 且 Agent 未运行, When 用户发送第一条消息触发 Agent 创建, Then AgentBridge 从 SwiftData 读取 MCP 配置，构建 `[String: McpServerConfig]` 字典，传入 `AgentOptions.mcpServers`，Agent 内部通过 `assembleFullToolPool()` 自动连接所有 MCP Server 并发现工具（FR-MCP-4）

2. **AC2 — MCP 工具 Tool Card 渲染** — Given Agent 已启动并连接了 MCP Server, When Agent 调用 MCP 工具, Then Timeline 中渲染为 MCP 专用 Tool Card，工具名显示为 `mcp__{serverName}__{toolName}` 命名空间格式，卡片使用 MCP 图标或 Server 来源标识区分（参照 Epic 2 ToolRenderable 协议扩展）

3. **AC3 — 运行时动态更新 MCP 工具池** — Given Agent 正在运行，用户通过 MCP 管理面板修改了配置, When 添加/删除/修改 MCP Server, Then 通过 `agent.setMcpServers()` 动态更新工具池，`McpServerUpdateResult` 报告变更结果，UI 反馈添加/移除/错误状态

4. **AC4 — MCP 连接错误不崩溃** — Given MCP Server 连接过程中发生错误, When `MCPClientManager` 标记连接为 error, Then 应用不崩溃，`mcpServerStatus()` 返回 failed 状态，MCP 管理面板和 Status Bar 反映错误状态

## Tasks / Subtasks

- [x] Task 1: 验证并完善 Agent 启动时的 MCP 配置注入（AC: #1）
  - [x] 1.1 审查 `AgentBridge.configure()` 中现有的 MCP 配置加载路径（lines 280-293），确认 `mcpConfigStore?.enabledConfigsForWorkspace()` 正确过滤 scope 和 enabled
  - [x] 1.2 确认 `MCPServerConfigStore.toSDKConfigs()` 正确转换 SwiftData 模型为 SDK `McpServerConfig`
  - [x] 1.3 添加 os_log 日志输出 MCP 连接成功/失败数量，便于调试
  - [x] 1.4 编写集成测试：模拟配置 -> Agent 创建 -> 验证 mcpServerStatus() 返回正确状态

- [x] Task 2: 创建 MCPToolRenderer 实现（AC: #2）
  - [x] 2.1 新建 `SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/MCPToolRenderer.swift`
  - [x] 2.2 实现 `ToolRenderable` 协议：`toolName` 匹配 `mcp__` 前缀模式，`icon` 使用 "cube.box" 或 "server.rack"，`accentColor` 使用蓝色调
  - [x] 2.3 实现 `summaryTitle()` 从 toolContent.toolName 解析 serverName 和实际 toolName
  - [x] 2.4 实现 `subtitle()` 显示 "via {serverName}" 标识
  - [x] 2.5 实现 `body()` 渲染 MCP 工具卡片：图标 + 命名空间工具名 + server 来源标签 + 状态指示器
  - [x] 2.6 在 `ToolRendererRegistry.init()` 中注册 MCPToolRenderer

- [x] Task 3: ToolRendererRegistry 支持前缀匹配（AC: #2）
  - [x] 3.1 在 `ToolRendererRegistry.renderer(for:)` 中添加 `mcp__` 前缀检测逻辑
  - [x] 3.2 当工具名以 `mcp__` 开头时，返回 MCPToolRenderer 实例
  - [x] 3.3 确保不影响其他已注册的静态工具名匹配

- [x] Task 4: EventMapper 增强——传递 MCP 元数据（AC: #2）
  - [x] 4.1 在 `EventMapper.map()` 的 `.toolUse` case 中，检测 `mcp__` 前缀的 toolName
  - [x] 4.2 如果是 MCP 工具，在 metadata 中添加 `isMCP: true` 和 `serverName` 解析值
  - [x] 4.3 在 `.toolResult` 和 `.toolProgress` case 中同样传递 MCP 元数据

- [x] Task 5: 运行时动态更新增强（AC: #3）
  - [x] 5.1 审查现有 `AgentBridge.updateMCPServers()` 实现（lines 225-242），确认它正确调用 `agent.setMcpServers()`
  - [x] 5.2 增强 `updateMCPServers()` 以处理 `McpServerUpdateResult`——记录 added/removed/errors
  - [x] 5.3 在 MCP 管理面板（Story 6-3 的 MCPManagementViewModel）中，添加/编辑/删除操作后自动调用 `updateMCPServers()`
  - [x] 5.4 添加 os_log 输出动态更新结果

- [x] Task 6: 错误处理与降级（AC: #4）
  - [x] 6.1 确保 Agent 创建时 MCP 连接失败不会阻塞 Agent 启动（SDK 已保证 `MCPToolDefinition.call()` 在 client 为 nil 时返回 error result，不 throw）
  - [x] 6.2 在 `AgentBridge.handleStreamMessage()` 中，如果 `.system` event 包含 MCP 错误信息，正确渲染为系统事件
  - [x] 6.3 验证 `MCPManagementViewModel.refreshStatus()` 能正确反映 failed 状态

- [x] Task 7: 编写测试（AC: #1-#4）
  - [x] 7.1 新建 `SwiftWorkTests/SDKIntegration/MCPToolRendererTests.swift`
  - [x] 7.2 测试 MCPToolRenderer：summaryTitle 解析、subtitle 生成、View 渲染
  - [x] 7.3 测试 ToolRendererRegistry 前缀匹配：`mcp__server__tool` 返回 MCPToolRenderer
  - [x] 7.4 测试 EventMapper MCP 元数据传递
  - [x] 7.5 测试 updateMCPServers 返回 McpServerUpdateResult 时的日志输出
  - [x] 7.6 回归测试：确认全部现有测试通过

## Dev Notes

### 核心架构——当前 MCP 配置注入状态

**好消息：AC1 的大部分工作已经完成。** `AgentBridge.configure()` 中（lines 280-293）已经有完整的 MCP 配置注入逻辑：

```swift
// MCP config (Story 6-1)
let mcpConfigs = (try? mcpConfigStore?.enabledConfigsForWorkspace(activeWorkspaceRoot)) ?? []
let mcpServers = mcpConfigStore?.toSDKConfigs(mcpConfigs)

let options = AgentOptions(
    ...
    mcpServers: (mcpServers?.isEmpty ?? true) ? nil : mcpServers,
    ...
)
```

SDK 的 `AgentOptions.mcpServers` 接受 `[String: McpServerConfig]?`，Agent 创建后在 `assembleFullToolPool()` 中自动连接所有 MCP Server 并发现工具。**AC1 只需验证和完善，不需要重新实现。**

### 核心架构——SDK MCP 工具命名空间

SDK 的 `MCPToolDefinition` 使用 `mcp__{serverName}__{toolName}` 格式作为工具名：

```swift
// MCPToolDefinition.swift:49-51
public var name: String {
    "mcp__\(serverName)__\(mcpToolName)"
}
```

**前置条件检查：** SDK 在创建 `MCPToolDefinition` 时会 precondition 检查 serverName 不包含 `__`。SwiftWork 的 MCPServerConfig.name 也已设为 `@Attribute(.unique)`，Story 6-1/6-2 的验证已确保 name 格式正确。

### 核心架构——MCPToolRenderer 设计

这是本 Story 的核心新增组件。MCP 工具名遵循 `mcp__serverName__toolName` 格式，因此不能像其他工具那样用静态 `toolName` 匹配，需要前缀匹配。

**方案：在 ToolRendererRegistry 中添加前缀匹配 fallback。**

```swift
// ToolRendererRegistry.swift 修改
func renderer(for toolName: String) -> (any ToolRenderable)? {
    // 1. 精确匹配（Bash, FileEdit, Skill 等内置工具）
    if let exact = renderers[toolName] {
        return exact
    }
    // 2. MCP 工具前缀匹配
    if toolName.hasPrefix("mcp__") {
        return mcpRenderer
    }
    return nil
}
```

**MCPToolRenderer 实现：**

```swift
struct MCPToolRenderer: ToolRenderable {
    // 注意：MCP 工具名是动态的，不能用 static let toolName 精确匹配
    // ToolRendererRegistry 通过前缀匹配返回此渲染器
    static let toolName = "mcp__*"  // 前缀标识，非精确匹配
    static let accentColor: Color = .blue
    static let icon: String = "cube.box"

    @MainActor
    func body(content: ToolContent) -> any View {
        MCPToolExpandedContent(content: content)
    }

    func summaryTitle(content: ToolContent) -> String {
        // 从 "mcp__serverName__toolName" 提取 toolName 部分
        let parts = content.toolName.components(separatedBy: "__")
        if parts.count >= 3 {
            return parts.dropFirst(2).joined(separator: "__")
        }
        return content.toolName
    }

    func subtitle(content: ToolContent) -> String? {
        let parts = content.toolName.components(separatedBy: "__")
        if parts.count >= 2 {
            return "via \(parts[1])"
        }
        return nil
    }
}
```

**为什么不在 ToolRenderable 协议中修改：** 协议的 `static var toolName` 用于精确匹配的注册键。MCP 工具需要前缀匹配，这是 Registry 的查找策略问题，不应改变协议设计。Registry 现有的 `renderer(for:)` 方法是唯一的查找入口，添加前缀 fallback 不影响其他渲染器。

### 核心架构——EventMapper MCP 元数据

当前 `EventMapper.map()` 的 `.toolUse` case 不区分内置工具和 MCP 工具。需要增加 MCP 检测：

```swift
// EventMapper.swift 修改 .toolUse case
case .toolUse(let data):
    // Plan-related tools: remap to .plan event type
    if data.toolName == "EnterPlanMode" || data.toolName == "ExitPlanMode" || data.toolName == "TodoWrite" {
        return mapPlanToolUse(data)
    }

    var metadata: [String: any Sendable] = [
        "toolName": data.toolName,
        "toolUseId": data.toolUseId,
        "input": data.input
    ]

    // MCP 工具检测
    if data.toolName.hasPrefix("mcp__") {
        metadata["isMCP"] = true
        let parts = data.toolName.components(separatedBy: "__")
        if parts.count >= 2 {
            metadata["serverName"] = parts[1]
        }
    }

    return AgentEvent(
        type: .toolUse,
        content: data.toolName,
        metadata: metadata,
        timestamp: .now
```

同样在 `.toolProgress` case 中传递 MCP 元数据，因为 toolProgress 也使用 toolName。

### 核心架构——运行时动态更新（AC3）

`AgentBridge.updateMCPServers()` 已在 Story 6-2/6-3 中实现（lines 225-242），用于编辑/删除后热更新 Agent。本 Story 的 AC3 需要增强它以处理 `McpServerUpdateResult`：

```swift
// AgentBridge.updateMCPServers() 增强
func updateMCPServers() async {
    guard isRunning else { return }
    let configs = (try? mcpConfigStore?.enabledConfigsForWorkspace(activeWorkspaceRoot)) ?? []
    let mcpServers = mcpConfigStore?.toSDKConfigs(configs) ?? [:]
    guard let agent else { return }
    do {
        let result = try await agent.setMcpServers(mcpServers)
        os_log("SwiftWork MCP: hot-update result — added: %{public}@, removed: %{public}@, errors: %{public}@",
               log: .default, type: .info,
               result.added.description, result.removed.description, result.errors.description)
    } catch {
        os_log("SwiftWork MCP: hot-update failed: %{public}s", log: .default, type: .error, error.localizedDescription)
    }
}
```

**注意现有实现使用 fire-and-forget `_Concurrency.Task`。** 如果改为 async，需要在调用侧处理异步。建议保持 fire-and-forget 模式但在 Task 内部处理 McpServerUpdateResult。

### 与前序 Story 的依赖

**Story 6-1 提供的 API（必须使用，不得重新实现）：**

| API | 用途 | 文件 |
|-----|------|------|
| `MCPServerConfigStore.list()` | 获取所有配置列表 | `SwiftWork/Services/MCPServerConfigStore.swift:135-139` |
| `MCPServerConfigStore.enabledConfigsForWorkspace(_:)` | 按 scope 过滤已启用配置 | `SwiftWork/Services/MCPServerConfigStore.swift:149-160` |
| `MCPServerConfigStore.toSDKConfigs(_:)` | 转换 SwiftData -> SDK McpServerConfig | `SwiftWork/Services/MCPServerConfigStore.swift:164-168` |
| `MCPServerConfig` SwiftData 模型 | 配置对象 | `SwiftWork/Models/SwiftData/MCPServerConfig.swift` |
| `TransportType` 枚举 | 传输类型 | `SwiftWork/Models/SwiftData/MCPServerConfig.swift:4-8` |

**Story 6-2 提供的 API（必须使用）：**

| API | 用途 | 文件 |
|-----|------|------|
| `AgentBridge.updateMCPServers()` | 编辑后热更新 Agent | `SwiftWork/SDKIntegration/AgentBridge.swift:225-242` |
| `AddMCPServerSheet` / `EditMCPServerSheet` | 添加/编辑弹窗 | `SwiftWork/Views/Settings/MCP/` |

**Story 6-3 提供的 API（必须使用）：**

| API | 用途 | 文件 |
|-----|------|------|
| `AgentBridge.mcpServerStatus()` | 获取运行时状态 | `SwiftWork/SDKIntegration/AgentBridge.swift:197-200` |
| `AgentBridge.toggleMcpServer()` | 启用/禁用 | `SwiftWork/SDKIntegration/AgentBridge.swift:204-215` |
| `AgentBridge.reconnectMcpServer()` | 重连 | `SwiftWork/SDKIntegration/AgentBridge.swift:218-221` |
| `MCPManagementViewModel` | MCP 管理面板 ViewModel | `SwiftWork/Views/Settings/MCP/MCPManagementViewModel.swift` |
| `MCPServerDisplayStatus` | UI 状态枚举 | `SwiftWork/Views/Settings/MCP/MCPServerDisplayStatus.swift` |

### SDK API 参考

**本 Story 使用的 SDK API（通过 Agent 实例调用）：**

| SDK API | 用途 | 位置 |
|---------|------|------|
| `AgentOptions.mcpServers` | Agent 创建时注入 MCP 配置 | `MCPTypes.swift` / `AgentTypes.swift:257` |
| `Agent.mcpServerStatus()` | 获取运行时状态 | `Agent.swift:671-676` |
| `Agent.setMcpServers(_:)` | 动态替换 MCP 配置 | `Agent.swift:718-732` |
| `MCPToolDefinition.name` | 命名空间工具名 `mcp__{server}__{tool}` | `MCPToolDefinition.swift:49-51` |
| `McpServerUpdateResult` | 动态更新结果（added/removed/errors） | `MCPTypes.swift:129-142` |
| `McpServerStatus` | 服务器状态（name/status/tools/error） | `MCPTypes.swift:80-121` |
| `McpServerConfig` | 传输配置枚举（stdio/sse/http/sdk/claudeAIProxy） | `MCPConfig.swift:8-20` |

**关键 SDK 保证（无需额外处理）：**
- `MCPToolDefinition.call()` 在 mcpClient 为 nil 时返回 error result，不 throw——Agent 不会因 MCP 连接失败而崩溃
- `assembleFullToolPool()` 自动处理所有 MCP Server 的连接和工具发现
- `setMcpServers()` 会 shutdown 旧 manager 并创建新 manager，确保连接不泄漏
- serverName 包含 `__` 时会 precondition 失败——Story 6-1/6-2 已在 UI 层验证 name 格式

### 新建文件列表

```
SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/MCPToolRenderer.swift  # MCP 工具渲染器
SwiftWorkTests/SDKIntegration/MCPToolRendererTests.swift                            # 渲染器测试
```

### 修改文件列表

```
SwiftWork/SDKIntegration/ToolRendererRegistry.swift   # 添加 MCP 前缀匹配
SwiftWork/SDKIntegration/EventMapper.swift            # 添加 MCP 元数据
SwiftWork/SDKIntegration/AgentBridge.swift            # 增强 updateMCPServers 日志
SwiftWork.xcodeproj/project.pbxproj                  # 添加新文件引用
```

### 代码复用要点

1. **参照 SkillToolRenderer 模式**：`SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/SkillToolRenderer.swift` 展示了如何为特殊工具类型创建自定义渲染器——MCPToolRenderer 应遵循相同结构
2. **参照 ToolContent.summaryTitle 的 JSON 解析模式**：`SwiftWork/Models/UI/ToolContent.swift:88-112` 展示了如何从 input JSON 提取摘要标题
3. **参照 AgentBridge.configure() 的 MCP 注入路径**：`SwiftWork/SDKIntegration/AgentBridge.swift:280-293` 已完成 AC1 的核心逻辑
4. **参照 AgentBridge.updateMCPServers()**：`SwiftWork/SDKIntegration/AgentBridge.swift:225-242` 已实现运行时热更新

### 不需要修改的文件

- **MCPServerConfigStore.swift**：Story 6-1 已提供完整的 CRUD 和 SDK 转换 API
- **MCPServerConfig.swift**：数据模型已完成
- **AddMCPServerSheet/EditMCPServerSheet/MCPFormFields**：Story 6-2 弹窗组件已完成
- **MCPManagementView/ViewModel/DetailView**：Story 6-3 管理面板已完成
- **MCPServerDisplayStatus.swift**：Story 6-3 UI 状态枚举已完成

### 潜在风险

1. **MCP 连接阻塞 Agent 启动**：SDK 的 `assembleFullToolPool()` 是异步的，每个 MCP Server 连接有超时。如果配置了多个不可达的 Server，可能增加 Agent 启动延迟。但 SDK 内部已有超时机制，不需要 SwiftWork 额外处理。
2. **`mcp__` 前缀冲突**：如果未来有内置工具以 `mcp__` 开头，会与 MCPToolRenderer 冲突。但根据 SDK 的命名空间约定，内置工具不会使用此前缀，风险极低。
3. **动态更新时短暂工具不可用**：`setMcpServers()` 会 shutdown 旧 manager 再创建新 manager，期间所有 MCP 工具暂时不可用。这是 SDK 的设计限制，SwiftWork 不需要额外处理。

### Project Structure Notes

- 新建文件：`SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/MCPToolRenderer.swift`
- 新建文件：`SwiftWorkTests/SDKIntegration/MCPToolRendererTests.swift`
- 修改文件：`SwiftWork/SDKIntegration/ToolRendererRegistry.swift`（添加前缀匹配）
- 修改文件：`SwiftWork/SDKIntegration/EventMapper.swift`（添加 MCP 元数据）
- 修改文件：`SwiftWork/SDKIntegration/AgentBridge.swift`（增强 updateMCPServers 日志）
- 遵循命名规范：View/Renderer 为 PascalCase，文件名与主类型名一致
- 单个文件不超过 300 行

### References

- [Source: SwiftWork/SDKIntegration/AgentBridge.swift:280-293 — MCP 配置注入路径]
- [Source: SwiftWork/SDKIntegration/AgentBridge.swift:225-242 — updateMCPServers() 热更新]
- [Source: SwiftWork/SDKIntegration/AgentBridge.swift:197-221 — MCP 管理方法（mcpServerStatus/toggle/reconnect）]
- [Source: SwiftWork/SDKIntegration/ToolRendererRegistry.swift — 渲染器注册表]
- [Source: SwiftWork/SDKIntegration/EventMapper.swift — SDKMessage -> AgentEvent 映射]
- [Source: SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/SkillToolRenderer.swift — 自定义渲染器参考]
- [Source: SwiftWork/Models/UI/ToolContent.swift — ToolContent 模型和 summaryTitle 解析]
- [Source: SwiftWork/Services/MCPServerConfigStore.swift:149-188 — scope 过滤和 SDK 转换]
- [Source: SwiftWork/Models/SwiftData/MCPServerConfig.swift — SwiftData MCP 配置模型]
- [Source: open-agent-sdk-swift/Sources/OpenAgentSDK/Tools/MCP/MCPToolDefinition.swift — MCP 工具定义和命名空间]
- [Source: open-agent-sdk-swift/Sources/OpenAgentSDK/Types/MCPTypes.swift — McpServerStatus/McpServerUpdateResult]
- [Source: open-agent-sdk-swift/Sources/OpenAgentSDK/Types/MCPConfig.swift — McpServerConfig/McpStdioConfig/McpTransportConfig]
- [Source: open-agent-sdk-swift/Sources/OpenAgentSDK/Core/Agent.swift:621-732 — assembleFullToolPool/mcpServerStatus/setMcpServers]
- [Source: _bmad-output/implementation-artifacts/6-1-mcp-config-model-persistence.md — Story 6-1 Dev Notes]
- [Source: _bmad-output/implementation-artifacts/6-2-mcp-add-edit-modal.md — Story 6-2 Dev Notes]
- [Source: _bmad-output/implementation-artifacts/6-3-mcp-management-panel.md — Story 6-3 Dev Notes]

## Dev Agent Record

### Agent Model Used

GLM-5.1

### Debug Log References

No runtime issues encountered during development.

### Completion Notes List

- Task 1: Verified `AgentBridge.configure()` MCP config injection path is complete. os_log already present for MCP config count. Integration tests confirmed: configure() loads MCP configs, handles nil/empty store, filters by scope+enabled, and converts to SDK format via `toSDKConfigs()`.
- Task 2: Created `MCPToolRenderer.swift` with full `ToolRenderable` conformance: blue accent color, "cube.box" icon, `summaryTitle()` extracts tool name from `mcp__server__tool` namespace, `subtitle()` shows "via {serverName}", `body()` renders MCP-specific card with server source label and status indicators.
- Task 3: Added MCP prefix matching fallback in `ToolRendererRegistry.renderer(for:)`. Exact match takes priority (Bash, FileEdit, etc.), then `mcp__` prefix returns the shared `MCPToolRenderer` instance. Unregistered non-MCP tools still return nil.
- Task 4: Enhanced `EventMapper.map()` to detect `mcp__` prefix in both `.toolUse` and `.toolProgress` cases, adding `isMCP: true` and `serverName` to metadata. Non-MCP tools are unaffected.
- Task 5: Enhanced `AgentBridge.updateMCPServers()` to log `McpServerUpdateResult` (added/removed/errors). Added `updateMCPServers()` calls in `MCPManagementViewModel.onAddSheetDismiss()` and `onEditSheetDismiss()`.
- Task 6: Verified error handling: SDK guarantees MCP connection failures don't block Agent startup. `handleStreamMessage()` already renders `.system` events. `MCPManagementViewModel.refreshStatus()` correctly maps `McpServerStatus` to `MCPServerDisplayStatus`.
- Task 7: All 35 Story 6-4 tests pass (21 MCPToolRendererTests + 14 AgentBridgeMCPIntegrationTests). Regression suite: 90 related tests (EventMapper, ToolRenderer, Registry) pass with 0 failures. 20 pre-existing failures in unrelated tests (AgentBridgeSkillTests, SessionViewModelTests, SessionWorkspaceServiceTests, SkillSourceGroupingTests) confirmed to exist before Story 6-4 changes.

### File List

#### New Files
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/MCPToolRenderer.swift`

#### Modified Files
- `SwiftWork/SDKIntegration/ToolRendererRegistry.swift`
- `SwiftWork/SDKIntegration/EventMapper.swift`
- `SwiftWork/SDKIntegration/AgentBridge.swift`
- `SwiftWork/Views/Settings/MCP/MCPManagementViewModel.swift`
- `SwiftWork.xcodeproj/project.pbxproj`

#### Existing Test Files (ATDD Red Phase, now green)
- `SwiftWorkTests/SDKIntegration/MCPToolRendererTests.swift`
- `SwiftWorkTests/SDKIntegration/AgentBridgeMCPIntegrationTests.swift`

## Change Log

- 2026-05-07: Story 6-4 implementation complete — MCPToolRenderer with prefix matching, EventMapper MCP metadata, updateMCPServers McpServerUpdateResult logging, MCPManagementViewModel hot-update on add/edit. All 35 new tests pass, 0 regressions in related tests.
