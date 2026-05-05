# Epic 5: Skill 系统（可扩展能力注入）

Status: draft

## Epic

As a 用户,
I want 通过斜杠命令调用预定义和自定义 Skill，并在 UI 中管理和浏览可用 Skill,
so that 我可以快速复用常见工作流（commit、review、debug 等），并通过 SKILL.md 文件扩展 Agent 能力。

## Motivation

SDK 已提供完整的 Skill 基础设施（SkillRegistry、SkillLoader、SkillTool、BuiltInSkills），
但 SwiftWork 的 AgentBridge 创建 Agent 时未配置任何 skill 参数，导致这些能力完全不可用。

SwiftWork 作为本地桌面 App，Skill 模式与 OpenWork 的云端共享不同：
- **来源**：本地文件系统（`~/.claude/skills/` + `$PWD/.claude/skills/`），无需服务端
- **管理**：只读浏览 + 文件系统编辑，不需要内置编辑器
- **触发**：用户通过 `/skill-name` 斜杠命令 + LLM 主动调用双通道

## Stories

---

### Story 5.1: SDK Skill 管线打通

Status: pending

#### Story

As a 用户,
I want Agent 启动时自动发现并加载本地 Skill,
so that LLM 可以通过 SkillTool 调用已注册的 skill，skill 列表自动注入系统提示。

#### Acceptance Criteria

1. **Given** 用户配置了 API Key 并发送第一条消息 **When** AgentBridge 创建 AgentOptions **Then** `skillDirectories` 设置为 `nil`（使用 SDK 默认目录），`skillRegistry` 通过 `autoDiscoverSkills()` 自动填充（AC1）

2. **Given** 项目目录下存在 `.claude/skills/*/SKILL.md` **When** Agent 启动 **Then** SkillLoader 扫描并注册所有发现的 skill，日志输出发现数量（AC2）

3. **Given** SkillRegistry 中有已注册 skill **When** Agent 发送系统提示 **Then** `formatSkillsForPrompt()` 的输出被包含在提示中，LLM 可以看到可用 skill 列表（AC3）

4. **Given** LLM 调用 `Skill(skill: "commit")` **When** skill 存在于 registry **Then** SkillTool 返回 skill 的 promptTemplate 和元数据，LLM 按模板执行（AC4）

5. **Given** LLM 调用 `Skill(skill: "nonexistent")` **When** skill 不存在 **Then** SkillTool 返回错误信息，不崩溃（AC5）

6. **Given** BuiltInSkills（commit/review/simplify/debug/test）**When** Agent 启动 **Then** 这些预置 skill 也被注册到 registry，与文件系统发现的 skill 共存（AC6）

#### Tasks

- [ ] Task 1: 修改 AgentBridge 启用 Skill 发现（AC: #1, #2, #6）
  - [ ] 1.1 在 `AgentBridge.swift` 的 `configure()` 方法中，创建 `SkillRegistry` 实例
  - [ ] 1.2 注册 `BuiltInSkills.allCases`（commit、review、simplify、debug、test）到 registry
  - [ ] 1.3 设置 `AgentOptions.skillDirectories = nil`（使用 SDK 默认路径）
  - [ ] 1.4 调用 `options.autoDiscoverSkills()` 在创建 agent 之前
  - [ ] 1.5 将 registry 存储为 AgentBridge 的属性，供 UI 层读取
  - [ ] 1.6 添加 `@Published var discoveredSkills: [Skill]` 属性（通过 `skillRegistry.userInvocableSkills`）

- [ ] Task 2: 验证 SkillTool 注入（AC: #3, #4, #5）
  - [ ] 2.1 确认 `autoDiscoverSkills()` 自动注入 SkillTool 到 tools 数组
  - [ ] 2.2 确认 `formatSkillsForPrompt()` 输出被 SDK 用于系统提示构建
  - [ ] 2.3 手动测试：发送 "list available skills" 给 Agent，验证 LLM 能列出 skill
  - [ ] 2.4 手动测试：发送 "/commit" 给 Agent，验证 LLM 调用 SkillTool 执行 commit skill

#### Dependencies

- SDK 0.1.0+（SkillLoader、SkillRegistry、SkillTool 已实现）

---

### Story 5.2: 输入框斜杠命令自动补全

Status: pending

#### Story

As a 用户,
I want 在输入框输入 `/` 时看到可用 skill 的自动补全列表,
so that 我可以快速发现和调用 skill，而无需记住完整的 skill 名称。

#### Acceptance Criteria

1. **Given** 输入框为空 **When** 用户输入 `/` **Then** 在光标下方弹出浮动菜单，显示所有 user-invocable skill，每项显示 name + description 摘要（AC1）

2. **Given** 自动补全菜单已弹出 **When** 用户继续输入 `/co` **Then** 菜单过滤为匹配 "co" 的 skill（如 "commit"），模糊匹配 name 和 alias（AC2）

3. **Given** 自动补全菜单已弹出 **When** 用户按 ↑↓ 键选择一项并按 Enter **Then** 输入框替换为选中的 skill 名称（如 `/commit`），自动补全关闭（AC3）

4. **Given** 自动补全菜单已弹出 **When** 用户按 Escape 或点击菜单外区域 **Then** 菜单关闭，输入文本保持不变（AC4）

5. **Given** 用户输入 `/` 后跟不匹配任何 skill 的文本（如 `/hello`）**When** 用户按 Enter 发送 **Then** `/hello` 作为普通文本发送给 Agent（AC5）

6. **Given** 用户选择了 `/commit` 并按 Enter **When** 消息发送 **Then** 发送的是 `commit` 的 promptTemplate 或者 `/commit` 文本（取决于 LLM 侧处理方式），Agent 开始执行（AC6）

#### Tasks

- [ ] Task 1: 创建 SkillAutocompleteView 组件（AC: #1, #2）
  - [ ] 1.1 创建 `SwiftWork/Views/Workspace/InputBar/SkillAutocompleteView.swift`
  - [ ] 1.2 使用 SwiftUI `Overlay` 或 `Popover` 定位在输入框上方
  - [ ] 1.3 接收 `[Skill]` 列表和 `filterText: String` 参数
  - [ ] 1.4 根据 filterText 过滤 skill（匹配 name 和 aliases，不区分大小写）
  - [ ] 1.5 每行显示：skill name（等宽字体）+ description（截断到一行）
  - [ ] 1.6 最大显示 8 项，超出时可滚动
  - [ ] 1.7 遵守 macOS 设计规范：圆角、阴影、半透明背景

- [ ] Task 2: 修改 InputBarView 集成自动补全（AC: #1, #2, #3, #4, #5, #6）
  - [ ] 2.1 在 InputBarView 中添加 `@State var showSkillAutocomplete: Bool = false`
  - [ ] 2.2 在 `onChange(of: inputText)` 中检测 `/` 开头，设置 showSkillAutocomplete
  - [ ] 2.3 提取 `/` 后面的文本作为 filterText 传递给 SkillAutocompleteView
  - [ ] 2.4 用户选择 skill 时：替换输入框内容为 `/skillName`（或直接替换为 skill.promptTemplate 的精简版本）
  - [ ] 2.5 Escape 键关闭菜单，点击外部关闭菜单
  - [ ] 2.6 不匹配任何 skill 时 showSkillAutocomplete = false，输入作为普通文本

- [ ] Task 3: 键盘导航支持（AC: #3, #4）
  - [ ] 3.1 ↑↓ 键在 SkillAutocompleteView 中移动高亮项
  - [ ] 3.2 Enter 键确认选择
  - [ ] 3.3 Escape 键关闭

#### Dependencies

- Story 5.1（需要 AgentBridge 暴露 discoveredSkills）
- InputBarView 当前实现

---

### Story 5.3: Skill 调用 Timeline 卡片渲染

Status: pending

#### Story

As a 用户,
I want 在 Timeline 中看到 Skill 调用的可视化卡片,
so that 我可以清楚了解 Agent 使用了哪个 skill、传了什么参数、执行结果如何。

#### Acceptance Criteria

1. **Given** Agent 调用 `Skill(skill: "review", args: "check auth code")` **When** toolUse 事件到达 Timeline **Then** 渲染为 Skill 专用卡片，显示 skill 名称 "review"、参数 "check auth code"（AC1）

2. **Given** Skill 调用卡片已渲染 **When** toolResult 事件到达 **Then** 卡片更新为完成状态，显示 skill 执行结果摘要（成功/失败）（AC2）

3. **Given** Skill 调用卡片已展开 **When** 用户查看详情 **Then** 显示 skill 的 promptTemplate 摘要和实际执行参数（AC3）

4. **Given** 多个 Skill 调用连续发生 **When** 在 Timeline 中查看 **Then** 每个 Skill 调用独立渲染为卡片，与普通 toolUse 卡片视觉区分（使用不同图标或标签色）（AC4）

#### Tasks

- [ ] Task 1: 创建 SkillToolRenderer（AC: #1, #2, #3, #4）
  - [ ] 1.1 创建 `SwiftWork/Views/Workspace/Timeline/EventViews/SkillToolView.swift`
  - [ ] 1.2 实现 `ToolRenderable` 协议（或等效注册方式）
  - [ ] 1.3 卡片标题行：闪电图标 + skill 名称 + 状态标签（running/completed/error）
  - [ ] 1.4 参数区域：显示 args 文本
  - [ ] 1.5 展开详情：显示 promptTemplate 前 200 字符摘要 + toolRestrictions
  - [ ] 1.6 与 ToolRendererRegistry 集成，注册 toolName = "Skill" 的渲染器

- [ ] Task 2: 在 EventMapper 中识别 Skill 工具调用（AC: #1）
  - [ ] 2.1 确保 EventMapper 对 `toolUse` 事件的 toolName 字段不做特殊处理
  - [ ] 2.2 ToolRendererRegistry 根据 toolName = "Skill" 路由到 SkillToolView

#### Dependencies

- Story 5.1（SkillTool 被注册）
- 现有 ToolRenderable 协议和 ToolRendererRegistry

---

### Story 5.4: Skill 管理面板

Status: pending

#### Story

As a 用户,
I want 在设置或独立面板中查看所有已发现的 Skill 列表,
so that 我可以了解当前有哪些 skill 可用、它们的来源和功能描述。

#### Acceptance Criteria

1. **Given** 用户打开设置面板 **When** 切换到 "Skills" 标签页 **Then** 显示所有已注册 skill 的列表，按来源分组（Built-in / Project / User）（AC1）

2. **Given** Skill 列表已显示 **When** 用户点击某个 skill **Then** 展开显示详细信息：name、description、aliases、whenToUse、argumentHint、toolRestrictions、baseDir、supportingFiles（AC2）

3. **Given** Skill 详情已展开 **When** 用户查看 toolRestrictions **Then** 显示 skill 限制使用的工具列表（如 bash, read, glob, grep）（AC3）

4. **Given** Skill 来自文件系统 **When** 用户点击 "Open in Finder" 按钮 **Then** 在 Finder 中打开 skill 所在目录（AC4）

5. **Given** Skill 来自文件系统 **When** 用户查看 supportingFiles **Then** 显示引用文件列表（references/ 等），点击可在 Finder 中定位（AC5）

#### Tasks

- [ ] Task 1: 创建 SkillsListView 组件（AC: #1）
  - [ ] 1.1 创建 `SwiftWork/Views/Settings/SkillsListView.swift`
  - [ ] 1.2 从 AgentBridge.discoveredSkills 读取 skill 列表
  - [ ] 1.3 按来源分组：Built-in（baseDir == nil）vs Project（baseDir 含 PWD）vs User（baseDir 含 HOME）
  - [ ] 1.4 每行显示：skill name + description 摘要 + 来源标签
  - [ ] 1.5 使用 `List` + `DisclosureGroup` 实现可展开详情

- [ ] Task 2: 创建 SkillDetailView 组件（AC: #2, #3, #4, #5）
  - [ ] 2.1 展示 skill 完整信息（name、description、aliases、whenToUse）
  - [ ] 2.2 展示 argumentHint（如 "[message]" 表示需要参数）
  - [ ] 2.3 展示 toolRestrictions 列表（tag 形式）
  - [ ] 2.4 baseDir 存在时显示 "Open in Finder" 按钮（`NSWorkspace.shared.selectFile`）
  - [ ] 2.5 supportingFiles 列表，每项可点击在 Finder 中定位

- [ ] Task 3: 集成到 SettingsView（AC: #1）
  - [ ] 3.1 在 SettingsView 的 TabView 中添加 "Skills" 标签页
  - [ ] 3.2 传入 AgentBridge 的 skillRegistry 属性

#### Dependencies

- Story 5.1（需要 discoveredSkills 数据）
- 现有 SettingsView 结构

---

## FR / NFR Coverage

| Requirement | Story |
|---|---|
| FR-SKILL-1: Agent 启动时自动发现并加载 Skill | 5.1 |
| FR-SKILL-2: 用户通过 `/` 斜杠命令触发 Skill | 5.2 |
| FR-SKILL-3: Timeline 渲染 Skill 调用卡片 | 5.3 |
| FR-SKILL-4: 用户可以浏览和管理已注册的 Skill | 5.4 |

## Architecture Notes

```
数据流：

文件系统 SKILL.md
    ↓ SkillLoader.discoverSkills()
SkillRegistry (SDK)
    ↓ AgentBridge 持有 registry
    ├── SkillTool → LLM 可主动调用
    ├── formatSkillsForPrompt() → 系统提示注入
    ├── InputBarView → 斜杠命令自动补全
    └── SkillsListView → 管理面板展示

UI 层新增文件：
SwiftWork/Views/Workspace/InputBar/SkillAutocompleteView.swift  (Story 5.2)
SwiftWork/Views/Workspace/Timeline/EventViews/SkillToolView.swift  (Story 5.3)
SwiftWork/Views/Settings/SkillsListView.swift  (Story 5.4)

SDK 集成修改：
SwiftWork/SDKIntegration/AgentBridge.swift  (Story 5.1 — 添加 skill 配置)
SwiftWork/Views/Workspace/InputBar/InputBarView.swift  (Story 5.2 — 添加自动补全)
SwiftWork/Views/Settings/SettingsView.swift  (Story 5.4 — 添加标签页)
```

## Dependency on SDK

- `SkillRegistry` — 线程安全的 skill 注册中心
- `SkillLoader` — 文件系统 skill 发现
- `SkillTool` / `createSkillTool()` — LLM 可调用的 Skill 工具
- `BuiltInSkills` — 预置 skill（commit、review、simplify、debug、test）
- `ToolRestriction` — 工具限制枚举
- `AgentOptions.skillRegistry` / `skillDirectories` / `skillNames`
- `AgentOptions.autoDiscoverSkills()`

全部已在 SDK 0.1.0 中实现，无需 SDK 侧修改。

## Out of Scope

- Skill 编辑器（用户通过文件系统编辑 SKILL.md，不需要内置编辑器）
- 云端 Skill 共享（OpenWork 的 Skill Hub / Marketplace 模式）
- Skill 版本管理和更新
- Skill 导入/导出
- 自定义 skill 创建向导
