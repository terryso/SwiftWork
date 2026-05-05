# Story 5.3: Skill 调用 Timeline 卡片渲染

Status: done

## Story

As a 用户,
I want 在 Timeline 中看到 Skill 调用的可视化卡片,
so that 我可以清楚了解 Agent 使用了哪个 skill、传了什么参数、执行结果如何。

## Acceptance Criteria

1. **AC1 — Skill toolUse 卡片识别与渲染** — Given Agent 调用 `Skill(skill: "review", args: "check auth code")`, When toolUse 事件到达 Timeline, Then 渲染为 Skill 专用卡片，显示 skill 名称 "review"、参数 "check auth code"

2. **AC2 — Skill toolResult 完成状态** — Given Skill 调用卡片已渲染, When toolResult 事件到达, Then 卡片更新为完成状态，显示 skill 执行结果摘要（成功/失败）

3. **AC3 — 展开详情** — Given Skill 调用卡片已展开, When 用户查看详情, Then 显示 skill 的 promptTemplate 摘要和实际执行参数

4. **AC4 — 多个 Skill 调用视觉区分** — Given 多个 Skill 调用连续发生, When 在 Timeline 中查看, Then 每个 Skill 调用独立渲染为卡片，与普通 toolUse 卡片视觉区分（使用不同图标或标签色）

## Tasks / Subtasks

- [x] Task 1: 创建 SkillToolRenderer（ToolRenderable 实现）（AC: #1, #3, #4）
  - [x] 1.1 在 `SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/` 下新建 `SkillToolRenderer.swift`
  - [x] 1.2 实现 `ToolRenderable` 协议：`toolName = "Skill"`, `accentColor = .purple`, `icon = "sparkles"`（或 `"star.bubble"`）
  - [x] 1.3 实现 `summaryTitle(content:)`：从 input JSON 解析 `skill` 字段显示 skill 名称（如 "review"）
  - [x] 1.4 实现 `subtitle(content:)`：从 input JSON 解析 `args` 字段显示参数摘要（截断至 80 字符）
  - [x] 1.5 实现 `body(content:)`：展开时显示 skill promptTemplate 摘要 + 完整参数（input JSON）+ 结果（output）

- [x] Task 2: 在 ToolRendererRegistry 注册 SkillToolRenderer（AC: #1）
  - [x] 2.1 修改 `ToolRendererRegistry.init()` 添加 `register(SkillToolRenderer())`

- [x] Task 3: 实现 Skill toolResult 内容解析（AC: #2）
  - [x] 3.1 确认现有 `ToolContent.fromToolResultEvent()` 和 `ToolCardView` 的配对机制已能正确处理 Skill toolResult
  - [x] 3.2 在 SkillToolRenderer 的 `body(content:)` 中，对 toolResult 的 JSON 输出进行美化展示：解析 `success`、`commandName`、`prompt` 字段

- [x] Task 4: 编写测试（AC: #1-#4）
  - [x] 4.1 在 `SwiftWorkTests/` 下新建 `SkillToolRendererTests.swift`
  - [x] 4.2 测试 `summaryTitle` 从 input JSON 提取 skill 名称
  - [x] 4.3 测试 `subtitle` 从 input JSON 提取 args 参数
  - [x] 4.4 测试 `accentColor` 为 `.purple`（视觉区分）
  - [x] 4.5 测试 `icon` 为专用图标（与普通工具不同）
  - [x] 4.6 测试 toolResult JSON 解析展示（success/commandName/prompt）
  - [x] 4.7 回归测试：确认全部现有测试通过

## Dev Notes

### 核心架构理解——Skill 调用在现有管线中的位置

**关键发现：Skill 调用本质上就是一个 toolUse/toolResult 事件对，工具名为 `"Skill"`。**

当 LLM 调用 Skill tool 时，SDK 产生的事件流与普通工具调用完全相同：
```
toolUse(toolName: "Skill", toolUseId: "xxx", input: "{\"skill\":\"review\",\"args\":\"check auth code\"}")
  → toolProgress (可选)
  → toolResult(toolUseId: "xxx", content: "{\"success\":true,\"commandName\":\"review\",\"prompt\":\"...\"}", isError: false)
```

这意味着现有的 `ToolCardView` + `ToolRendererRegistry` + `ToolContent` 配对机制**已经能处理 Skill 调用**。唯一缺的是一个注册到 registry 的 `SkillToolRenderer` 来提供 Skill 专属的视觉展示。

### 数据流分析

```
SDK AsyncStream<SDKMessage>
  → EventMapper.map(.toolUse) → AgentEvent(type: .toolUse, content: "Skill", metadata: ["toolName": "Skill", "input": "..."])
  → AgentBridge 处理事件 → 配对到 toolContentMap["toolUseId"]
  → TimelineView.toolCardView(for:) 查找 toolContentMap → ToolCardView(content:content, registry:registry)
  → ToolCardView 使用 registry.renderer(for: "Skill") → SkillToolRenderer（本 Story 新增）
```

**EventMapper 中 `.toolUse` 的处理（EventMapper.swift:27-41）：**
- Skill 调用不走 plan 分支（toolName 是 `"Skill"`，不是 `"EnterPlanMode"/"ExitPlanMode"/"TodoWrite"`）
- 走通用的 `AgentEvent(type: .toolUse, content: "Skill", metadata: ["toolName": "Skill", ...])`
- `ToolContent.fromToolUseEvent()` 会从 metadata 提取 toolName="Skill"、toolUseId、input JSON

**ToolContent 的 input 字段对于 Skill 调用包含：**
```json
{"skill": "review", "args": "check auth code"}
```
注意：`ToolUseData.input` 是 JSON String（不是 Dictionary），需要 `JSONSerialization` 解析。

**ToolContent 的 output 字段对于 Skill toolResult 包含（来自 SkillTool.swift:98-128）：**
```json
{"success": true, "commandName": "review", "prompt": "...", "allowedTools": [...], "model": "...", "baseDir": "...", "supportingFiles": [...]}
```

### 不需要修改的文件（关键）

以下文件已经正确处理了 Skill 调用，**不需要修改**：

1. **EventMapper.swift** — Skill toolUse 走通用 `.toolUse` 分支，不需要特殊映射
2. **AgentEvent.swift / AgentEventType.swift** — 不需要新增事件类型
3. **ToolContent.swift** — `fromToolUseEvent()` 和 `fromToolResultEvent()` 已能正确提取 Skill 调用数据
4. **ToolCardView.swift** — 已通过 registry 查找渲染器，未注册时走 genericToolBody fallback
5. **TimelineView.swift** — `toolCardView(for:)` 已通过 toolContentMap 配对机制渲染 ToolCardView
6. **AgentBridge.swift** — toolContentMap 配对逻辑已覆盖 Skill 工具

**本 Story 只需新增一个 ToolRenderable 实现并在 registry 注册即可。**

### SkillToolRenderer 实现指南

```swift
struct SkillToolRenderer: ToolRenderable {
    static let toolName = "Skill"
    static let accentColor: Color = .purple
    static let icon: String = "sparkles"

    func summaryTitle(content: ToolContent) -> String {
        // 从 input JSON 解析 skill 字段
        guard let skillName = parseField("skill", from: content.input) else {
            return "Skill"
        }
        return "/\(skillName)"
    }

    func subtitle(content: ToolContent) -> String? {
        // 从 input JSON 解析 args 字段
        guard let args = parseField("args", from: content.input), !args.isEmpty else {
            return nil
        }
        return String(args.prefix(80))
    }

    @MainActor
    func body(content: ToolContent) -> any View {
        SkillToolExpandedContent(content: content)
    }

    private func parseField(_ field: String, from input: String) -> String? {
        guard !input.isEmpty,
              let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return json[field] as? String
    }
}
```

**`SkillToolExpandedContent`（私有子 View）：**
- 显示 skill 名称（粗体）+ 参数
- 如果 toolResult 可用，解析 JSON 展示：success 状态、commandName、prompt 摘要（前 200 字符）
- 保持文件在 300 行以内

### 视觉设计参考

Skill 卡片应与普通工具卡片视觉区分：

| 属性 | 普通工具（如 Bash） | Skill 工具 |
|------|---------------------|------------|
| 左边条颜色 | `.green`（Bash）、`.orange`（Edit）等 | `.purple` |
| 图标 | `terminal`（Bash）、`doc.text`（Read）等 | `sparkles` |
| 摘要标题格式 | 命令/文件路径 | `/skillName`（斜杠前缀） |
| 副标题 | 命令参数 | args 参数 |

`.purple` 和 `sparkles` 图标让 Skill 调用在 Timeline 中一目了然。

### ToolContent.summaryTitle 的注意点

`ToolContent` 有自己的 `summaryTitle` 计算属性（ToolContent.swift:88-112），它尝试解析 input JSON 中的 `command`、`file_path`、`pattern` 字段。对于 Skill 工具的 input（`{"skill":"review","args":"..."}`），这些字段都不存在，所以会 fallback 到 `toolName`（即 `"Skill"`）。

但 `ToolCardView.resolvedSummaryTitle` 优先使用 `renderer.summaryTitle(content:)`，所以只要 `SkillToolRenderer.summaryTitle` 返回 `/review`，ToolCardView 就会显示 `/review` 而非 `"Skill"`。

### Story 5-1/5-2 关键学习

1. `autoDiscoverSkills()` 是 SDK internal 方法——`discoveredSkills` 通过 `allSkills.filter { $0.userInvocable }` 实现
2. `Skill` struct 来自 `OpenAgentSDK`，View 层通过 `AgentBridge.discoveredSkills` 间接获取
3. Skill tool 名称在 SDK 中为 `"Skill"`（SkillTool.swift:36）
4. `BuiltInSkills.test` 的 `isAvailable()` 在 xcodebuild 环境 CWD 可能不是项目根目录
5. Story 5-2 的 `SkillAutocompleteViewModel` 使用了 `Skill` 类型——本 Story 也需要处理 `Skill` 类型，但只在 input JSON 解析层面，不直接引用 `SkillRegistry`

### 300 行 View 限制

- `SkillToolRenderer.swift` 预计 60-80 行（简洁协议实现 + parseField helper）
- `SkillToolExpandedContent`（私有 struct）嵌入同文件，预计 60-80 行
- 总计约 140-160 行，远低于 300 行限制

### 测试策略

- `SkillToolRendererTests.swift` 直接实例化 `SkillToolRenderer`，构造 `ToolContent` 测试数据
- 不需要 mock AgentBridge、EventMapper 或 registry
- 测试要点：summaryTitle 解析、subtitle 解析、颜色/图标正确性
- 回归测试：确认全部测试通过（当前 ~629+ 测试）

### Project Structure Notes

- 新建文件在 `SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/` 下，与现有 BashToolRenderer 等并列
- 修改 `SwiftWork/SDKIntegration/ToolRendererRegistry.swift`，在 init() 中添加一行 register
- 测试文件在 `SwiftWorkTests/` 下
- 所有文件遵循项目命名规范

### References

- [Source: SwiftWork/SDKIntegration/ToolRenderable.swift — ToolRenderable 协议定义，必须实现的方法和属性]
- [Source: SwiftWork/SDKIntegration/ToolRendererRegistry.swift:8-15 — 现有注册列表，需添加 SkillToolRenderer]
- [Source: SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/BashToolRenderer.swift — 现有渲染器实现范例]
- [Source: SwiftWork/Views/Workspace/Timeline/EventViews/ToolCardView.swift — 统一卡片容器，通过 registry.renderer() 查找渲染器]
- [Source: SwiftWork/Models/UI/ToolContent.swift — ToolContent 数据模型，fromToolUseEvent/fromToolResultEvent 配对机制]
- [Source: SwiftWork/SDKIntegration/EventMapper.swift:27-41 — toolUse 事件映射，Skill 走通用分支]
- [Source: open-agent-sdk-swift/Tools/Advanced/SkillTool.swift:34-130 — Skill tool 定义，toolName="Skill"，input schema 含 skill+args 字段，output JSON 含 success+commandName+prompt 字段]
- [Source: open-agent-sdk-swift/Types/SkillTypes.swift — Skill struct 定义，name/description/aliases/promptTemplate 等属性]
- [Source: _bmad-output/implementation-artifacts/5-2-input-bar-slash-autocomplete.md — Story 5-2 Dev Notes，Skill 类型架构边界讨论]
- [Source: _bmad-output/planning-artifacts/epics.md — Story 5.3 AC 定义，FR-SKILL-3]
- [Source: _bmad-output/planning-artifacts/architecture.md — Decision 9 ToolRenderable 协议，ARCH-9 ToolRendererRegistry]

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
