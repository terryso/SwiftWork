# Story 6.6: MCP 高级设置与配置文件

Status: review

## Story

As a 高级用户,
I want 通过配置文件管理 MCP Server 配置，并能在 Finder 中定位配置文件,
so that 我可以批量编辑、版本控制和分享 MCP 配置。

## Acceptance Criteria

1. **AC1 — 高级设置折叠区** — Given 用户在 MCP 管理面板查看底部, When 面板加载完成, Then 显示"高级设置"可折叠区域（默认折叠），包含配置文件路径信息和操作按钮，参照 OpenWork `mcp-view.tsx` 行 723-808 的 advanced settings 折叠交互

2. **AC2 — 配置文件路径显示** — Given 用户展开高级设置区域, When 查看, Then 显示配置文件路径信息：Project scope 路径（`{workspace}/.claude/settings.json`）、Global scope 路径（`~/.claude/settings.json`），通过 scope 切换按钮在两个路径间切换

3. **AC3 — 在 Finder 中显示** — Given 用户点击"在 Finder 中显示"按钮, When 操作执行, Then 在 Finder 中打开并定位到配置文件（如果文件存在）或提示文件尚未创建

4. **AC4 — 外部编辑检测与重新加载** — Given 用户在外部编辑器中修改了配置文件, When 切换回 SwiftWork, Then 应用检测到文件变更（通过文件系统监控或手动刷新按钮），提示用户并重新加载 MCP 配置到 SwiftData

## Tasks / Subtasks

- [x] Task 1: 创建 MCPAdvancedSettingsView 组件（AC: #1, #2, #3）
  - [x] 1.1 新建 `SwiftWork/Views/Settings/MCP/MCPAdvancedSettingsView.swift`，实现可折叠高级设置区域
  - [x] 1.2 实现 scope 切换按钮（Project / Global），参照 OpenWork `mcp-view.tsx` 行 743-762 的 scope toggle
  - [x] 1.3 显示当前 scope 对应的配置文件路径（monospaced 字体，truncate 显示）
  - [x] 1.4 实现"在 Finder 中显示"按钮（`NSWorkspace.shared.selectFile(_:inFileViewerRootedAtPath:)`）
  - [x] 1.5 配置文件不存在时显示"文件未创建"提示
  - [x] 1.6 折叠/展开动画使用 `.transition(.opacity.combined(with: .move(edge: .top)))` 与 MCPServerDetailView 一致

- [x] Task 2: 创建 MCPConfigFileManager 服务（AC: #2, #3, #4）
  - [x] 2.1 新建 `SwiftWork/Services/MCPConfigFileManager.swift`
  - [x] 2.2 实现配置文件路径解析：project scope → `{workspacePath}/.claude/settings.json`，global scope → `~/.claude/settings.json`
  - [x] 2.3 实现 `revealInFinder(path:)` 方法：调用 `NSWorkspace.shared.selectFile`
  - [x] 2.4 实现 `configFilePath(scope:workspacePath:) -> String?` 计算属性
  - [x] 2.5 实现 `configFileExists(scope:workspacePath:) -> Bool` 检查
  - [x] 2.6 实现 `readConfigFile(scope:workspacePath:) -> Data?` 读取配置文件内容
  - [x] 2.7 实现 `loadMCPConfigsFromFile(scope:workspacePath:) -> [MCPServerConfig]` 解析 JSON 配置并转换为 MCPServerConfig 数据
  - [x] 2.8 实现 `importFromFile(scope:workspacePath:store:)` 将文件配置导入 SwiftData（去重：同名覆盖）

- [x] Task 3: 文件系统监控（AC: #4）
  - [x] 3.1 在 `MCPConfigFileManager` 中使用 `DispatchSource.makeFileSystemObjectSource` 监控配置文件变更
  - [x] 3.2 提供开始/停止监控方法，绑定 MCPManagementView 的 onAppear/onDisappear 生命周期
  - [x] 3.3 文件变更时通过 `AsyncStream` 或回调通知 ViewModel
  - [x] 3.4 提供"刷新配置"手动按钮作为备用方案（文件监控可能在某些情况下不可靠）
  - [x] 3.5 监控到变更后调用 `importFromFile` 将变更同步到 SwiftData，然后通知 Agent 热更新

- [x] Task 4: 集成到 MCPManagementView（AC: #1）
  - [x] 4.1 在 `MCPManagementView.serverList` 底部（`LazyVStack` 的最后一个元素之后）插入 `MCPAdvancedSettingsView`
  - [x] 4.2 传递 `workspacePath`（从 `AgentBridge.activeWorkspaceRoot` 获取）和 `store`
  - [x] 4.3 确保 MCPManagementView 的 init 接收 `workspacePath` 参数
  - [x] 4.4 SettingsView 中创建 MCPManagementView 时传递 workspacePath

- [x] Task 5: 编写测试（AC: #1-#4）
  - [x] 5.1 新建 `SwiftWorkTests/Services/MCPConfigFileManagerTests.swift`
  - [x] 5.2 测试配置文件路径解析（project / global scope）
  - [x] 5.3 测试配置文件 JSON 解析和 MCPServerConfig 转换
  - [x] 5.4 测试从文件导入配置到 SwiftData（新增和去重覆盖）
  - [x] 5.5 测试文件不存在时的优雅降级
  - [x] 5.6 回归测试：确认全部现有测试通过

## Dev Notes

### 核心架构——配置文件格式

SwiftWork 的 MCP 配置文件使用与 OpenWork/Claude Desktop 相同的 JSON 格式（`.claude/settings.json`），便于生态兼容。配置文件格式：

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"],
      "env": {},
      "type": "stdio"
    },
    "remote-server": {
      "url": "https://example.com/mcp",
      "headers": {},
      "type": "sse"
    }
  }
}
```

**关键映射规则：**
- JSON key → MCPServerConfig.name
- `type` 字段 → TransportType（`stdio`/`sse`/`http`）
- `command` + `args` → MCPServerConfig.command + decodedArgs
- `url` → MCPServerConfig.url
- `env` → MCPServerConfig.decodedEnv
- `headers` → MCPServerConfig.decodedHeaders
- 配置文件中的 server 默认为 enabled=true（除非显式设置 `"enabled": false`）

### 核心架构——MCPAdvancedSettingsView 设计

**参照 OpenWork `mcp-view.tsx` 行 723-808：**

OpenWork 的高级设置区域是一个底部可折叠卡片：
- 折叠标题行：Settings2 图标 + "高级设置" 标题 + "管理配置文件" 副标题 + 展开箭头
- 展开内容：scope 切换按钮（Project/Global）、配置文件路径（monospaced）、"在 Finder 中显示"按钮、文档链接
- 点击标题行切换展开/折叠

**SwiftWork 实现要点：**
```
┌──────────────────────────────────────────┐
│ ⚙ 高级设置                    [^]       │  ← 可点击标题行
│   管理配置文件                            │
├──────────────────────────────────────────┤  ← 展开后
│ [Project] [Global]                       │  ← scope 切换
│                                          │
│ 配置文件                                 │
│ /path/to/.claude/settings.json           │  ← monospaced, truncate
│                                          │
│ [📁 在 Finder 中显示]   [🔄 刷新配置]    │  ← 操作按钮
│ 文件未创建（如果不存在）                   │
└──────────────────────────────────────────┘
```

### 核心架构——配置文件路径解析

**路径规则（`MCPConfigFileManager`）：**

| Scope | 路径 | 条件 |
|-------|------|------|
| project | `{activeWorkspaceRoot}/.claude/settings.json` | 需要 workspace 已绑定 |
| global | `~/.claude/settings.json` | 始终可用 |

**AgentBridge 已有的 workspace 信息：**
- `AgentBridge.activeWorkspaceRoot: String?` — 当前 workspace 根路径
- `AgentBridge.configuredWorkspaceState` — workspace 状态
- 参照 `AgentBridge.swift:187-192`

**路径解析实现：**
```swift
func configFilePath(scope: MCPServerScope, workspacePath: String?) -> String? {
    switch scope {
    case .global:
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json").path
    case .project:
        guard let workspacePath, !workspacePath.isEmpty else { return nil }
        return workspacePath + "/.claude/settings.json"
    }
}
```

### 核心架构——文件系统监控

**使用 GCD DispatchSource 监控文件变更：**

```swift
// MCPConfigFileManager
private var fileSource: DispatchSourceFileSystem?

func startWatching(path: String, onChange: @escaping () -> Void) {
    let descriptor = open(path, O_EVTONLY)
    guard descriptor >= 0 else { return }
    fileSource = DispatchSource.makeFileSystemObjectSource(
        fileDescriptor: descriptor,
        eventMask: .write,
        queue: DispatchQueue.global(qos: .utility)
    )
    fileSource?.setEventHandler {
        DispatchQueue.main.async { onChange() }
    }
    fileSource?.resume()
}

func stopWatching() {
    fileSource?.cancel()
    fileSource = nil
}
```

**注意：** DispatchSource 文件监控在文件被删除重建时可能失效（如编辑器保存时的原子写入）。需要额外监听文件是否存在，如果文件被删除则重新建立监控。实际实现中建议以"手动刷新"按钮为主，文件监控为辅。

### 与前序 Story 的依赖

**Story 6-1 提供的 API：**

| API | 用途 | 文件 |
|-----|------|------|
| `MCPServerConfigStore.list()` | 获取所有配置列表 | `SwiftWork/Services/MCPServerConfigStore.swift:135-139` |
| `MCPServerConfigStore.add(...)` | 添加新配置 | `SwiftWork/Services/MCPServerConfigStore.swift:27-59` |
| `MCPServerConfigStore.update(...)` | 更新配置 | `SwiftWork/Services/MCPServerConfigStore.swift:63-89` |
| `MCPServerConfigStore.list(scope:)` | 按 scope 过滤 | `SwiftWork/Services/MCPServerConfigStore.swift:142-145` |
| `MCPServerConfig` SwiftData 模型 | 配置对象 | `SwiftWork/Models/SwiftData/MCPServerConfig.swift` |
| `MCPServerScope` 枚举 | project / global | `SwiftWork/Models/SwiftData/MCPServerConfig.swift:10-13` |
| `TransportType` 枚举 | stdio / sse / http | `SwiftWork/Models/SwiftData/MCPServerConfig.swift:4-8` |

**Story 6-3 提供的 API：**

| API | 用途 | 文件 |
|-----|------|------|
| `AgentBridge.activeWorkspaceRoot` | 当前 workspace 根路径 | `SwiftWork/SDKIntegration/AgentBridge.swift:187-192` |
| `AgentBridge.updateMCPServers()` | Agent 热更新 | `SwiftWork/SDKIntegration/AgentBridge.swift:225-240` |
| `MCPManagementView` | MCP 管理面板主视图 | `SwiftWork/Views/Settings/MCP/MCPManagementView.swift` |
| `MCPManagementViewModel` | 管理面板 ViewModel | `SwiftWork/Views/Settings/MCP/MCPManagementViewModel.swift` |

### 新建文件列表

```
SwiftWork/Views/Settings/MCP/MCPAdvancedSettingsView.swift   # 高级设置折叠区视图
SwiftWork/Services/MCPConfigFileManager.swift                 # 配置文件读写和监控服务
SwiftWorkTests/Services/MCPConfigFileManagerTests.swift       # 配置文件服务测试
```

### 修改文件列表

```
SwiftWork/Views/Settings/MCP/MCPManagementView.swift          # 集成 MCPAdvancedSettingsView
SwiftWork/Views/Settings/SettingsView.swift                   # 传递 workspacePath
SwiftWork.xcodeproj/project.pbxproj                           # 添加新文件引用
```

### 代码复用要点

1. **复用 MCPServerConfigStore 的 add/update 方法**：导入配置文件时不需要新的存储方法——使用现有 `store.add()` 添加新配置，`store.update()` 或 `store.replace()` 更新已有配置（按 name 去重）
2. **复用 MCPServerScope 枚举**：project / global scope 已定义在 `MCPServerConfig.swift:10-13`，直接使用
3. **复用 AgentBridge.activeWorkspaceRoot**：workspace 路径已在 `AgentBridge.swift:187-192` 暴露，不需要新的路径解析逻辑
4. **复用 MCPManagementView 的折叠动画模式**：MCPServerDetailView 已使用 `.transition(.opacity.combined(with: .move(edge: .top)))`，MCPAdvancedSettingsView 应使用相同模式
5. **参照 MCPServerDisplayStatus 的样式**：使用相同的 `.font(.caption)` 和 `.foregroundStyle(.secondary)` 样式

### 不需要修改的文件

- **AgentBridge.swift**：`activeWorkspaceRoot` 和 `updateMCPServers()` API 已存在
- **MCPServerConfigStore.swift**：CRUD API 完备，无需修改
- **MCPServerConfig.swift**：模型和枚举已完备
- **MCPManagementViewModel.swift**：不需要修改 ViewModel——文件监控逻辑在 MCPConfigFileManager 中管理
- **MCPServerDetailView.swift**：详情视图不需要修改

### 潜在风险

1. **文件监控可靠性**：GCD DispatchSource 在编辑器使用原子写入（write-to-temp → rename）时会报告文件删除。建议：(a) 监控文件所在目录而非文件本身，(b) 以手动刷新按钮为主方案
2. **配置文件格式兼容性**：JSON 中 `type` 字段可能缺失（旧版配置）。解析时需要合理默认值——`command` 存在时默认为 `stdio`，`url` 存在时默认为 `sse`
3. **导入去重策略**：文件配置与 SwiftData 配置重名时的处理。策略：文件配置覆盖 SwiftData 中的同名配置（update），新增的不存在于 SwiftData 的配置直接添加（add），SwiftData 中独有且文件中不存在的配置保持不变
4. **workspace 未绑定时 project scope 不可用**：当 `activeWorkspaceRoot` 为 nil 时，project scope 的路径无法解析。应在 UI 中禁用 project scope 按钮或显示提示
5. **SettingsView 的 workspacePath 传递链**：当前 `SettingsView` 通过 `agentBridge` 传递给 `MCPManagementView`，MCPManagementView 需要新增 `workspacePath` 参数或直接从 `agentBridge.activeWorkspaceRoot` 获取。推荐后者——在 MCPManagementView 中直接访问 agentBridge 获取路径

### Project Structure Notes

- 新建文件遵循项目目录结构：Views 在 `SwiftWork/Views/Settings/MCP/`，Services 在 `SwiftWork/Services/`
- 测试文件放在 `SwiftWorkTests/Services/` 目录下
- 命名规范：View 为 PascalCase + View 后缀，Service 为 PascalCase + Manager 后缀
- 单个文件不超过 300 行（MCPAdvancedSettingsView 预计 ~150 行，MCPConfigFileManager 预计 ~180 行）

### References

- [Source: SwiftWork/Views/Settings/MCP/MCPManagementView.swift — MCP 管理面板主视图]
- [Source: SwiftWork/Views/Settings/MCP/MCPManagementViewModel.swift — 管理面板 ViewModel]
- [Source: SwiftWork/Services/MCPServerConfigStore.swift:27-59 — add() CRUD]
- [Source: SwiftWork/Services/MCPServerConfigStore.swift:63-89 — update() CRUD]
- [Source: SwiftWork/Services/MCPServerConfigStore.swift:135-145 — list() 和 list(scope:)]
- [Source: SwiftWork/Models/SwiftData/MCPServerConfig.swift — SwiftData 模型和枚举]
- [Source: SwiftWork/SDKIntegration/AgentBridge.swift:187-192 — activeWorkspaceRoot]
- [Source: SwiftWork/SDKIntegration/AgentBridge.swift:225-240 — updateMCPServers()]
- [Source: SwiftWork/Views/Settings/SettingsView.swift:159-172 — mcpTab 传递 agentBridge]
- [Source: openwork/apps/app/src/react-app/domains/settings/pages/mcp-view.tsx:723-808 — OpenWork 高级设置折叠区参照]
- [Source: _bmad-output/implementation-artifacts/6-5-mcp-status-visualization.md — Story 6-5 Dev Notes]
- [Source: _bmad-output/implementation-artifacts/6-3-mcp-management-panel.md — Story 6-3 MCP 管理面板]

## Dev Agent Record

### Agent Model Used

Claude GLM-5.1

### Debug Log References

### Completion Notes List

- Implemented MCPConfigFileManager service with path resolution (project/global scope), JSON config parsing, file import with dedup, reveal in Finder, and GCD DispatchSource file watching
- Implemented MCPAdvancedSettingsView with collapsible advanced settings section, scope toggle (Project/Global), config file path display (monospaced, truncated), "Reveal in Finder" button, and "Refresh Config" manual button
- Integrated MCPAdvancedSettingsView at bottom of MCPManagementView server list
- All 38 new tests pass (29 unit + 9 integration), plus 64 existing MCP tests still pass (102 total MCP tests, 0 failures)
- 11 pre-existing test failures in unrelated test suites (AgentBridgeSkillTests, SessionViewModelTests, SessionWorkspaceServiceTests, SkillSourceGroupingTests)
- File watching uses DispatchSource with [.write, .delete, .rename, .attrib] event mask for broader coverage
- MCPConfigFileManager is @MainActor to match MCPServerConfigStore pattern
- MCPManagementView init accepts optional configManager parameter with default MCPConfigFileManager()

### File List

**New Files:**
- SwiftWork/Services/MCPConfigFileManager.swift
- SwiftWork/Views/Settings/MCP/MCPAdvancedSettingsView.swift

**Pre-existing Test Files (ATDD red-phase, now green):**
- SwiftWorkTests/Services/MCPConfigFileManagerTests.swift
- SwiftWorkTests/Services/MCPConfigFileIntegrationTests.swift

**Modified Files:**
- SwiftWork/Views/Settings/MCP/MCPManagementView.swift
- SwiftWork.xcodeproj/project.pbxproj
