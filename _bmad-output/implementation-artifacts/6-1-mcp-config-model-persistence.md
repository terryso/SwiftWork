# Story 6.1: MCP 配置模型与持久化

Status: review

## Story

As a 用户,
I want 我配置的 MCP Server 信息被安全地持久化，重启后自动恢复,
so that 我不需要每次打开应用都重新配置 MCP Server。

## Acceptance Criteria

1. **AC1 — SwiftData 持久化模型** — Given 用户通过 UI 添加了一个 MCP Server 配置, When 配置保存, Then MCP Server 配置通过 SwiftData 持久化，包含字段：name（唯一标识）、transportType（stdio / sse / http）、command（stdio 模式）、url（sse/http 模式）、args（stdio 参数）、env（环境变量）、headers（HTTP 头）、enabled（启用状态）、scope（project / global）、createdAt、updatedAt

2. **AC2 — 应用重启自动恢复** — Given 用户配置了 MCP Server, When 重启应用, Then 所有 MCP Server 配置自动恢复到上次保存的状态（NFR19）

3. **AC3 — 项目级 scope 隔离** — Given 用户在项目级配置中添加了 MCP Server, When 切换到另一个项目 workspace, Then 项目级 MCP Server 配置随 workspace 切换，全局配置保持不变

4. **AC4 — 配置转 SDK McpServerConfig** — Given SwiftData 中有 MCP 配置记录, When AgentBridge 创建 Agent, Then 能将持久化配置正确转换为 SDK 的 `[String: McpServerConfig]` 字典，传入 `AgentOptions.mcpServers`

## Tasks / Subtasks

- [x] Task 1: 创建 MCPServerConfig SwiftData 模型（AC: #1）
  - [x] 1.1 新建 `SwiftWork/Models/SwiftData/MCPServerConfig.swift`
  - [x] 1.2 定义 `TransportType` 枚举（stdio / sse / http），Codable + String rawValue
  - [x] 1.3 定义 `MCPServerScope` 枚举（project / global），Codable + String rawValue
  - [x] 1.4 定义 `@Model final class MCPServerConfig`，包含所有必需字段
  - [x] 1.5 使用 `@Attribute(.unique)` 标注 `name` 字段保证唯一性
  - [x] 1.6 在 `SwiftWorkApp.swift` 的 `modelContainer` 中注册新模型

- [x] Task 2: 创建 MCPServerConfigStore 服务（AC: #1, #2, #3）
  - [x] 2.1 新建 `SwiftWork/Services/MCPServerConfigStore.swift`
  - [x] 2.2 实现 CRUD 方法：add / update / delete / list / list(scope:)
  - [x] 2.3 实现 `listForScope(workspacePath:)` 方法：返回 global + 当前 workspace 的 project scope 配置
  - [x] 2.4 实现 `toSDKConfig()` 方法：将 SwiftData 模型转换为 SDK `McpServerConfig` 枚举
  - [x] 2.5 处理 stdio 的 command + args 解析逻辑
  - [x] 2.6 处理 sse/http 的 url + headers 组装逻辑
  - [x] 2.7 错误处理：捕获 SwiftData 操作异常，不 crash

- [x] Task 3: 集成到 AgentBridge.configure()（AC: #4）
  - [x] 3.1 在 `AgentBridge` 中添加 `@ObservationIgnored private var mcpConfigStore: MCPServerConfigStore?` 属性
  - [x] 3.2 修改 `configure()` 方法，从 MCPServerConfigStore 读取配置
  - [x] 3.3 将转换后的 `[String: McpServerConfig]` 传入 `AgentOptions.mcpServers`
  - [x] 3.4 添加 MCP 配置数量日志输出（参照 Skill 的日志模式）

- [x] Task 4: 编写测试（AC: #1-#4）
  - [x] 4.1 新建 `SwiftWorkTests/Services/MCPServerConfigStoreTests.swift`
  - [x] 4.2 测试 SwiftData CRUD：添加、查询、更新、删除配置
  - [x] 4.3 测试 scope 过滤：global 配置在所有 workspace 可见，project 配置仅在对应 workspace 可见
  - [x] 4.4 测试 toSDKConfig() 转换：stdio/sse/http 三种类型正确映射到 SDK 枚举
  - [x] 4.5 测试 name 唯一约束：重复 name 应报错或更新
  - [x] 4.6 测试 enabled 过滤：disabled 的配置不参与 SDK 转换
  - [x] 4.7 回归测试：确认全部现有测试通过

## Dev Notes

### 核心架构——SwiftData 模型设计

**新建文件**：`SwiftWork/Models/SwiftData/MCPServerConfig.swift`

本 Story 创建一个新的 SwiftData 模型来持久化 MCP Server 配置。参照现有模型模式（Session、Event、PermissionRule、AppConfiguration），所有字段使用 `var` 属性，主键为 `@Attribute(.unique) var id: UUID`。

**模型字段设计（映射到 AC1 的字段列表）：**

```swift
@Model
final class MCPServerConfig {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var name: String          // 唯一标识，也是 SDK 连接的 key
    var transportType: TransportType               // stdio / sse / http
    var command: String?                           // stdio 模式的命令
    var url: String?                               // sse/http 模式的 URL
    var args: Data?                                // stdio 参数，JSON 编码 [String]
    var env: Data?                                 // 环境变量，JSON 编码 [String: String]
    var headers: Data?                             // HTTP 头，JSON 编码 [String: String]
    var enabled: Bool                              // 启用状态
    var scope: MCPServerScope                      // project / global
    var workspacePath: String?                     // project scope 时绑定的工作目录
    var createdAt: Date
    var updatedAt: Date
}
```

**为什么 args/env/headers 用 `Data?` 而不是 `[String]?`：**
SwiftData 对复杂类型（Array、Dictionary）的支持在不同 macOS 版本有差异。使用 JSON 编码的 `Data` 是最安全的方案，与 Event 模型的 `rawData: Data` 模式一致。

**TransportType 枚举：**

```swift
enum TransportType: String, Codable, Sendable {
    case stdio
    case sse
    case http
}
```

**MCPServerScope 枚举：**

```swift
enum MCPServerScope: String, Codable, Sendable {
    case project
    case global
}
```

### 核心架构——MCPServerConfigStore 服务

**新建文件**：`SwiftWork/Services/MCPServerConfigStore.swift`

这是一个纯数据服务，封装 SwiftData 对 MCPServerConfig 的 CRUD 操作。参照 `KeychainManager` 的服务层模式——无外部业务层依赖，只依赖系统框架。

**关键方法：**

```swift
@MainActor
final class MCPServerConfigStore {
    let modelContext: ModelContext

    func add(name:, transportType:, command:, url:, args:, env:, headers:, enabled:, scope:, workspacePath:) throws -> MCPServerConfig
    func update(_ config: MCPServerConfig, ...) throws
    func delete(_ config: MCPServerConfig) throws
    func list() throws -> [MCPServerConfig]
    func list(scope: MCPServerScope, workspacePath: String?) throws -> [MCPServerConfig]
    func enabledConfigsForWorkspace(_ workspacePath: String?) throws -> [MCPServerConfig]
    func toSDKConfigs(_ configs: [MCPServerConfig]) -> [String: McpServerConfig]
}
```

**scope 过滤逻辑（AC3）：**

```swift
func enabledConfigsForWorkspace(_ workspacePath: String?) throws -> [MCPServerConfig] {
    let all = try list()
    return all.filter { config in
        guard config.enabled else { return false }
        switch config.scope {
        case .global:
            return true                    // 全局配置对所有 workspace 可见
        case .project:
            return config.workspacePath == workspacePath  // 只匹配当前 workspace
        }
    }
}
```

### 核心架构——toSDKConfig() 转换逻辑

这是本 Story 的核心转换方法，将 SwiftData 持久化模型转换为 SDK 的 `McpServerConfig` 枚举。

**SDK 的 McpServerConfig 枚举（Source: MCPConfig.swift）：**

```swift
public enum McpServerConfig: Sendable, Equatable {
    case stdio(McpStdioConfig)           // command, args?, env?
    case sse(McpTransportConfig)         // url, headers?   (typealias for McpTransportConfig)
    case http(McpTransportConfig)        // url, headers?
    case sdk(McpSdkServerConfig)         // 不在 SwiftWork UI 范围内
    case claudeAIProxy(McpClaudeAIProxyConfig)  // 不在 SwiftWork UI 范围内
}
```

**转换逻辑：**

```swift
func toSDKConfig(_ config: MCPServerConfig) -> (String, McpServerConfig)? {
    switch config.transportType {
    case .stdio:
        guard let command = config.command, !command.isEmpty else { return nil }
        let args = (config.args.flatMap { try? JSONDecoder().decode([String].self, from: $0) })
        let env = (config.env.flatMap { try? JSONDecoder().decode([String: String].self, from: $0) })
        return (config.name, .stdio(McpStdioConfig(command: command, args: args, env: env)))

    case .sse:
        guard let url = config.url, !url.isEmpty else { return nil }
        let headers = (config.headers.flatMap { try? JSONDecoder().decode([String: String].self, from: $0) })
        return (config.name, .sse(McpTransportConfig(url: url, headers: headers)))

    case .http:
        guard let url = config.url, !url.isEmpty else { return nil }
        let headers = (config.headers.flatMap { try? JSONDecoder().decode([String: String].self, from: $0) })
        return (config.name, .http(McpTransportConfig(url: url, headers: headers)))
    }
}
```

### 集成到 AgentBridge.configure()

当前 `AgentBridge.configure()` 在 `SwiftWork/SDKIntegration/AgentBridge.swift:193-247` 创建 `AgentOptions`。需要：

1. 注入 `MCPServerConfigStore` 实例（通过 `configure()` 参数或 init）
2. 读取当前 workspace 的 enabled MCP 配置
3. 转换为 `[String: McpServerConfig]` 传入 `AgentOptions.mcpServers`

```swift
// 在 configure() 中，创建 options 之前：
let mcpConfigs = (try? mcpConfigStore?.enabledConfigsForWorkspace(activeWorkspaceRoot)) ?? []
let mcpServers = Dictionary(uniqueKeysWithValues: mcpConfigs.compactMap { toSDKConfig($0) })

let options = AgentOptions(
    apiKey: apiKey,
    model: model,
    // ...现有参数
    mcpServers: mcpServers.isEmpty ? nil : mcpServers
)
```

**注意**：`AgentOptions.mcpServers` 类型为 `[String: McpServerConfig]?`，如果为 nil 则不启动 MCP 连接。空字典 `[:]` 也可能导致不必要的初始化，建议在配置为空时传 nil。

### AgentOptions.mcpServers 字段确认

SDK `AgentOptions`（AgentTypes.swift）有 `mcpServers: [String: McpServerConfig]?` 字段。传入后 SDK 内部通过 `assembleFullToolPool()` 自动连接所有 MCP Server 并发现工具。SwiftWork 不需要手动管理 MCP 连接——只需把配置字典传给 SDK。

### SwiftData 模型注册

在 `SwiftWorkApp.swift` 中，`modelContainer` 需要包含新模型：

```swift
@main
struct SwiftWorkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Session.self,
            Event.self,
            PermissionRule.self,
            AppConfiguration.self,
            MCPServerConfig.self  // <-- 新增
        ])
    }
}
```

### 不需要修改的文件

- **View 层**：本 Story 不涉及 UI，MCP 管理面板在 Story 6-3 实现
- **EventMapper**：MCP 工具调用事件走已有的 `.toolUse` / `.toolResult` 通道，无需特殊处理
- **ToolRendererRegistry**：MCP 工具的 Tool Card 渲染在 Story 6-4/6-5 扩展

### JSON 编码/解码辅助方法

为简化 args/env/headers 的 Data 编解码，在 MCPServerConfig 上添加辅助方法：

```swift
extension MCPServerConfig {
    var decodedArgs: [String]? {
        args.flatMap { try? JSONDecoder().decode([String].self, from: $0) }
    }
    var decodedEnv: [String: String]? {
        env.flatMap { try? JSONDecoder().decode([String: String].self, from: $0) }
    }
    var decodedHeaders: [String: String]? {
        headers.flatMap { try? JSONDecoder().decode([String: String].self, from: $0) }
    }
}
```

### 与后续 Story 的关系

本 Story 为 Epic 6 的基础 Story：
- **Story 6.2**（MCP 添加与编辑弹窗）依赖 MCPServerConfigStore.add/update 方法
- **Story 6.3**（MCP 管理面板）依赖 MCPServerConfigStore.list/delete 方法
- **Story 6.4**（Agent MCP 集成）依赖 AgentBridge 传入 mcpServers 配置
- **Story 6.5**（MCP 状态可视化）依赖 Agent.mcpServerStatus() API
- **Story 6.6**（高级设置）依赖 MCPServerConfig.scope 字段

### Story 5-1 回顾要点（适用于本 Story）

1. **状态变更路径**：每个涉及持久化的操作，必须在 Dev Notes 列出所有状态变更路径
2. **SDK internal API 问题**：如果发现 SDK 有 internal API 不可访问，参考 Story 5-1 的变通方案
3. **日志输出**：参照 Skill 的 `os_log` 模式输出 MCP 配置数量

### Project Structure Notes

- 新建文件：`SwiftWork/Models/SwiftData/MCPServerConfig.swift`
- 新建文件：`SwiftWork/Services/MCPServerConfigStore.swift`
- 修改文件：`SwiftWork/App/SwiftWorkApp.swift`（注册新 SwiftData 模型）
- 修改文件：`SwiftWork/SDKIntegration/AgentBridge.swift`（注入 MCP 配置）
- 新建测试：`SwiftWorkTests/Services/MCPServerConfigStoreTests.swift`
- 遵循命名规范：SwiftData Model 为 PascalCase 单数无后缀

### References

- [Source: SwiftWork/Models/SwiftData/Session.swift — 现有 SwiftData 模型模式]
- [Source: SwiftWork/Models/SwiftData/PermissionRule.swift — 枚举属性 + Codable 模式]
- [Source: SwiftWork/Models/SwiftData/AppConfiguration.swift — KV 配置模式]
- [Source: SwiftWork/SDKIntegration/AgentBridge.swift:193-247 — 当前 configure() 实现]
- [Source: open-agent-sdk-swift/Sources/OpenAgentSDK/Types/MCPConfig.swift — SDK McpServerConfig 枚举、McpStdioConfig、McpTransportConfig]
- [Source: open-agent-sdk-swift/Sources/OpenAgentSDK/Types/AgentTypes.swift — AgentOptions.mcpServers 字段]
- [Source: open-agent-sdk-swift/Sources/OpenAgentSDK/Tools/MCP/MCPClientManager.swift — SDK MCP 连接管理]
- [Source: open-agent-sdk-swift/Sources/OpenAgentSDK/Types/MCPTypes.swift — McpServerStatus、McpServerUpdateResult、McpServerStatusEnum]
- [Source: _bmad-output/implementation-artifacts/5-1-sdk-skill-pipeline.md — Epic 5 Story 1 实现模式和 Dev Notes]
- [Source: _bmad-output/planning-artifacts/epics.md — Epic 6 Story 6.1 AC 定义]

## Dev Agent Record

### Agent Model Used

GLM-5.1

### Debug Log References

- SwiftData `#Predicate` does not support captured enum values of custom types — `list(scope:)` uses post-fetch filtering instead
- SwiftData `@Attribute(.unique)` does not automatically throw on constraint violation — manual uniqueness check added in `add()`

### Completion Notes List

- MCPServerConfig SwiftData model created with all required fields (id, name, transportType, command, url, args, env, headers, enabled, scope, workspacePath, createdAt, updatedAt)
- TransportType enum (stdio/sse/http) and MCPServerScope enum (project/global) defined as Codable + Sendable String rawValues
- MCPServerConfigStore service implements full CRUD with manual name uniqueness enforcement via MCPServerConfigError.duplicateName
- Scope filtering: enabledConfigsForWorkspace() returns global configs + matching project configs, excludes disabled ones
- SDK conversion: toSDKConfigs() converts MCPServerConfig to SDK McpServerConfig enum, skipping invalid configs (stdio without command, sse/http without URL)
- JSON helper extensions (decodedArgs, decodedEnv, decodedHeaders) on MCPServerConfig for Data field access
- AgentBridge.configure() now reads MCP configs from store and passes them to AgentOptions.mcpServers
- All 34 ATDD tests pass (6 pre-existing test failures in unrelated test suites confirmed by running against clean branch)

### File List

**New files:**
- SwiftWork/Models/SwiftData/MCPServerConfig.swift
- SwiftWork/Services/MCPServerConfigStore.swift
- SwiftWorkTests/Services/MCPServerConfigStoreTests.swift

**Modified files:**
- SwiftWork/App/SwiftWorkApp.swift (registered MCPServerConfig in modelContainer)
- SwiftWork/SDKIntegration/AgentBridge.swift (added mcpConfigStore property + MCP config loading in configure())
- SwiftWork.xcodeproj/project.pbxproj (added new files to build targets)

### ATDD Artifacts

- Checklist: `_bmad-output/test-artifacts/atdd-checklist-6-1-mcp-config-model-persistence.md`
- Unit/Integration tests: `SwiftWorkTests/Services/MCPServerConfigStoreTests.swift` (34 tests, all passing)

### Change Log

- 2026-05-07: Story 6-1 created — MCP config model persistence foundation for Epic 6
- 2026-05-07: ATDD red-phase tests generated — 34 tests across 4 ACs
- 2026-05-07: Implementation complete — MCPServerConfig model, MCPServerConfigStore service, AgentBridge integration, all 34 tests passing
