# Story 5.4: Skill 管理面板

Status: done

## Story

As a 用户,
I want 在设置面板中查看所有已发现的 Skill 列表,
so that 我可以了解当前有哪些 skill 可用、它们的来源和功能描述。

## Acceptance Criteria

1. **AC1 — Settings 新增 Skills 标签页** — Given 用户打开设置面板, When 查看 Tab 选择器, Then 显示三个标签：通用 / 权限 / Skills，默认选中"通用"

2. **AC2 — Skill 列表按来源分组** — Given 用户切换到 "Skills" 标签页, When Skills 标签内容渲染, Then 显示所有已注册 skill 的列表，按来源分组（Built-in / Project / User）。分组逻辑：`baseDir == nil` → Built-in；`baseDir` 包含项目 CWD → Project；其余 → User

3. **AC3 — Skill 详情展开** — Given Skill 列表已显示, When 用户点击某个 skill 条目, Then 展开显示详细信息：name、description、aliases、whenToUse、argumentHint、toolRestrictions、baseDir、supportingFiles。折叠时只显示 name + description 摘要

4. **AC4 — Open in Finder 按钮** — Given Skill 来自文件系统（`baseDir != nil`）, When 详情展开, Then 显示 "Open in Finder" 按钮，点击后在 Finder 中打开 skill 所在目录

## Tasks / Subtasks

- [ ] Task 1: 扩展 SettingsView 标签页（AC: #1）
  - [ ] 1.1 在 `SettingsView.swift` 的 `SettingsTab` 枚举中添加 `case skills = "Skills"`
  - [ ] 1.2 在 `activeTabContent` 的 switch 中添加 `case .skills` 分支
  - [ ] 1.3 修改 `SettingsView.init` 接收 `agentBridge: AgentBridge` 参数
  - [ ] 1.4 修改 `ContentView.swift` 中创建 `SettingsView` 的两处调用，传入 `agentBridge`

- [ ] Task 2: 创建 SkillsListView（AC: #2, #3, #4）
  - [ ] 2.1 新建 `SwiftWork/Views/Settings/SkillsListView.swift`
  - [ ] 2.2 从 `agentBridge.discoveredSkills` 获取所有 skill，按来源分组
  - [ ] 2.3 实现分组 Section：Built-in（baseDir == nil）、Project（baseDir 在 CWD 下）、User（其余）
  - [ ] 2.4 实现折叠/展开交互：点击 skill 行切换展开状态
  - [ ] 2.5 展开时显示：name、description、aliases 列表、whenToUse、argumentHint、toolRestrictions 标签、baseDir 路径、supportingFiles 列表
  - [ ] 2.6 展开时为文件系统 skill 显示 "Open in Finder" 按钮，使用 `NSWorkspace.shared.open(URL)` 打开 `baseDir`

- [ ] Task 3: 创建 SkillListItemView（AC: #3）
  - [ ] 3.1 新建 `SwiftWork/Views/Settings/SkillListItemView.swift`（如果 SkillsListView 超过 300 行则拆分）
  - [ ] 3.2 折叠状态：显示 `/name`（粗体）+ description（单行截断）+ 来源标签（Built-in/Project/User）
  - [ ] 3.3 展开状态：显示完整详情字段

- [ ] Task 4: 编写测试（AC: #1-#4）
  - [ ] 4.1 新建 `SwiftWorkTests/Settings/SkillsListViewTests.swift`（如有可测试逻辑）
  - [ ] 4.2 测试 Skill 来源分组逻辑：BuiltIn / Project / User 分类正确性
  - [ ] 4.3 回归测试：确认全部现有测试通过

## Dev Notes

### 核心架构理解——Skill 数据从哪来

**AgentBridge 持有 SkillRegistry，通过 `discoveredSkills` 属性暴露 Skill 列表。**

```swift
// AgentBridge.swift:121-125
@ObservationIgnored
private var skillRegistry: SkillRegistry?

var discoveredSkills: [Skill] {
    skillRegistry?.allSkills.filter { $0.userInvocable } ?? []
}
```

关键点：
1. `discoveredSkills` 只返回 `userInvocable == true` 的 skill——但设置面板应该展示**所有** skill（包括非 userInvocable），所以需要新增一个属性或修改过滤条件
2. `SkillRegistry` 在 `AgentBridge.configure()` 中初始化并注册所有 skill（AgentBridge.swift:132-163）
3. SkillRegistry 在配置后不会再变更（没有 reload 机制）

**重要决策：设置面板应展示 `allSkills` 还是 `userInvocableSkills`？**
- AC 要求"所有已注册 skill"，但 Story 5-2 的 autocomplete 只展示 `userInvocable` 的
- 建议在 `AgentBridge` 中新增 `allRegisteredSkills` 属性返回 `skillRegistry?.allSkills ?? []`
- 设置面板展示全部，autocomplete 展示可调用的——这是合理的区分

### Skill 来源分组逻辑

`Skill` struct（SkillTypes.swift:56-147）没有 `source` 字段。来源判断依赖 `baseDir` 属性：

| 条件 | 来源分组 |
|------|----------|
| `baseDir == nil` | Built-in（代码中注册的 BuiltInSkills） |
| `baseDir` 包含项目工作目录路径 | Project（项目 `.claude/skills/` 下发现的） |
| `baseDir` 非 nil 但不在项目目录下 | User（用户全局目录下发现的） |

**判断"项目工作目录"的方式：** 使用 `FileManager.default.currentDirectoryPath` 或从 Session 的 `workspacePath` 获取。由于 Settings 是全局面板而非会话级别，使用 `FileManager.default.currentDirectoryPath` 更简单。

```swift
// 分组示例
enum SkillSource {
    case builtIn
    case project
    case user

    static func from(_ skill: Skill) -> SkillSource {
        guard let baseDir = skill.baseDir else { return .builtIn }
        let cwd = FileManager.default.currentDirectoryPath
        return baseDir.hasPrefix(cwd) ? .project : .user
    }
}
```

### SettingsView 现有结构

当前 `SettingsView`（SettingsView.swift:1-105）使用分段选择器（`Picker` + `.segmented` 样式）切换标签页，只有两个标签：通用、权限。需要添加第三个标签 "Skills"。

**SettingsView 当前 init 签名：**
```swift
init(settingsViewModel: SettingsViewModel, permissionHandler: PermissionHandler)
init(permissionHandler: PermissionHandler)  // 无 settingsViewModel 的变体
```

需要新增 `agentBridge` 参数以访问 skill 数据。

**ContentView.swift:72** 创建 SettingsView 的位置：
```swift
SettingsView(settingsViewModel: appState.settingsViewModel, permissionHandler: agentBridge.permissionHandler)
```

只需在调用处加 `agentBridge: agentBridge` 参数。

### Skill 详细信息展示设计

每个 Skill 展开后显示的字段（来自 SkillTypes.swift:56-103）：

| 字段 | 类型 | 展示方式 |
|------|------|----------|
| name | String | `/name`（粗体标题） |
| description | String | 完整描述文本 |
| aliases | [String] | `/alias1, /alias2` 标签 |
| whenToUse | String? | "触发条件：..." |
| argumentHint | String? | "参数：[message]" |
| toolRestrictions | [ToolRestriction]? | 标签列表，nil 显示 "无限制" |
| modelOverride | String? | 模型名称 |
| baseDir | String? | 路径文本 + "Open in Finder" |
| supportingFiles | [String] | 文件列表 |
| promptTemplate | String | **不展示**（过长，且包含系统提示，对用户无意义） |

### "Open in Finder" 实现方式

```swift
// 使用 NSWorkspace 打开 Finder
if let baseDir = skill.baseDir {
    let url = URL(fileURLWithPath: baseDir)
    NSWorkspace.shared.open(url)
}
```

### 不需要修改的文件（关键）

1. **AgentBridge.swift** — 可能需要新增 `allRegisteredSkills` 属性（一行 getter），除此之外不修改
2. **SkillAutocompleteMenuView.swift** — 本 Story 不涉及 autocomplete
3. **SkillToolRenderer.swift** — 本 Story 不涉及 Timeline 渲染
4. **EventMapper.swift** — 不涉及事件映射
5. **ToolRendererRegistry.swift** — 不涉及工具注册

### 架构边界遵守

- **View 可以引用 `Skill` 类型**（来自 `OpenAgentSDK`）——Story 5-2 的 `SkillAutocompleteMenuView` 已经直接使用 `Skill` 类型
- **View 不直接访问 `SkillRegistry`**——通过 `AgentBridge` 的属性间接获取
- `SkillSource` enum 定义在 View 层（`SkillsListView.swift` 内或 Models/UI/），不是 SDK 类型
- `SettingsView` 和 `SkillsListView` 遵循 View 层规则：只依赖 ViewModel/Model 数据，不直接操作 SDK

### Story 5-1/5-2/5-3 关键学习

1. `autoDiscoverSkills()` 是 SDK internal——`discoveredSkills` 通过 `allSkills.filter { $0.userInvocable }` 实现
2. `Skill` struct 来自 `OpenAgentSDK`，View 层可直接使用（5-2 已确认此模式）
3. Skill tool 名称在 SDK 中为 `"Skill"`（SkillTool.swift:36）
4. `BuiltInSkills.test` 的 `isAvailable()` 在 xcodebuild 环境 CWD 可能不是项目根目录
5. Story 5-2 的 `SkillAutocompleteMenuView` 使用 `Skill` 类型——本 Story 同样直接使用
6. Story 5-3 的 `SkillToolRenderer` 使用 `.purple` + `sparkles` 图标区分 Skill——设置面板可使用相同视觉语言

### 300 行 View 限制

- `SkillsListView.swift`：分组逻辑 + Section 渲染 + 详情展示，预计 150-200 行
- 如果超过 250 行，将 `SkillListItemView`（折叠/展开行）拆为独立文件
- `SkillSource` enum 和分组逻辑可放在 `SkillsListView.swift` 顶部（私有类型）或独立文件

### 测试策略

- `SkillsListView` 主要是 SwiftUI View，难以进行纯逻辑单元测试
- 可测试的部分：`SkillSource.from(_:)` 分组逻辑（纯函数，输入 Skill 输出枚举）
- 回归测试：确认全部现有测试通过（当前 ~629+ 测试）
- 手动验收：在设置面板中验证分组、展开、Open in Finder 功能

### Project Structure Notes

- 新建文件在 `SwiftWork/Views/Settings/` 目录下，与 `SettingsView.swift`、`APIKeySettingsView.swift` 并列
- 修改 `SwiftWork/Views/Settings/SettingsView.swift`，添加 Skills 标签页
- 修改 `SwiftWork/App/ContentView.swift`，传入 agentBridge 参数
- 可能修改 `SwiftWork/SDKIntegration/AgentBridge.swift`，新增 `allRegisteredSkills` 属性
- 测试文件在 `SwiftWorkTests/Settings/` 下
- 所有文件遵循项目命名规范（PascalCase + View 后缀）

### References

- [Source: SwiftWork/Views/Settings/SettingsView.swift — 当前设置页面结构，SettingsTab 枚举 + 分段选择器]
- [Source: SwiftWork/App/ContentView.swift:72 — SettingsView 创建位置，需传入 agentBridge]
- [Source: SwiftWork/SDKIntegration/AgentBridge.swift:118-126 — Skill System 属性，discoveredSkills getter]
- [Source: SwiftWork/SDKIntegration/AgentBridge.swift:131-163 — configure() 中 SkillRegistry 初始化和注册流程]
- [Source: open-agent-sdk-swift/Types/SkillTypes.swift:56-147 — Skill struct 完整定义，baseDir/aliases/toolRestrictions/supportingFiles 等属性]
- [Source: open-agent-sdk-swift/Tools/SkillRegistry.swift:180-184 — allSkills 属性，返回全部注册 skill]
- [Source: open-agent-sdk-swift/Tools/SkillRegistry.swift:216-225 — registerDiscoveredSkills()，文件系统发现逻辑]
- [Source: SwiftWork/Views/Workspace/InputBar/SkillAutocompleteMenuView.swift — Skill 类型在 View 层使用的范例]
- [Source: SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/SkillToolRenderer.swift — Skill 视觉设计参考（.purple + sparkles）]
- [Source: _bmad-output/implementation-artifacts/5-3-skill-timeline-card-rendering.md — Story 5-3 Dev Notes，Skill 数据流分析]
- [Source: _bmad-output/implementation-artifacts/5-2-input-bar-slash-autocomplete.md — Story 5-2 Dev Notes，Skill 类型架构边界]
- [Source: _bmad-output/planning-artifacts/epics.md — Story 5.4 AC 定义，FR-SKILL-4]
- [Source: _bmad-output/planning-artifacts/architecture.md — Decision 11 项目结构，Views/Settings/ 目录]

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
