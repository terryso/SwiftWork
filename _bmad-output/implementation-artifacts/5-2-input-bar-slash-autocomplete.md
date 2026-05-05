# Story 5.2: 输入框斜杠命令自动补全

Status: done

## Story

As a 用户,
I want 在输入框输入 `/` 时看到可用 skill 的自动补全列表,
so that 我可以快速发现和调用 skill，而无需记住完整的 skill 名称。

## Acceptance Criteria

1. **AC1 — 斜杠触发自动补全** — Given 输入框为空, When 用户输入 `/`, Then 在光标下方弹出浮动菜单，显示所有 userInvocable skill，每项显示 name + description 摘要

2. **AC2 — 模糊过滤** — Given 自动补全菜单已弹出, When 用户继续输入 `/co`, Then 菜单过滤为匹配 "co" 的 skill（如 "commit"），模糊匹配 name 和 alias

3. **AC3 — 键盘选择与确认** — Given 自动补全菜单已弹出, When 用户按 Up/Down 键选择一项并按 Enter, Then 输入框替换为选中的 skill 名称（如 `/commit`），自动补全关闭

4. **AC4 — Escape/点击外部关闭** — Given 自动补全菜单已弹出, When 用户按 Escape 或点击菜单外区域, Then 菜单关闭，输入文本保持不变

5. **AC5 — 不匹配时作为普通文本发送** — Given 用户输入 `/` 后跟不匹配任何 skill 的文本（如 `/hello`）, When 用户按 Enter 发送, Then `/hello` 作为普通文本发送给 Agent

6. **AC6 — 仅在行首触发** — Given 输入框已有文本 "hello ", When 用户输入 `/`, Then 不触发自动补全（仅在文本为空或仅包含空白时 `/` 在行首触发）

## Tasks / Subtasks

- [x] Task 1: 创建 SkillAutocompleteViewModel（AC: #1, #2）
  - [x] 1.1 在 `SwiftWork/Views/Workspace/InputBar/` 下新建 `SkillAutocompleteViewModel.swift`
  - [x] 1.2 定义 `@Observable` 类 `SkillAutocompleteViewModel`
  - [x] 1.3 属性：`filteredSkills: [Skill]`、`isVisible: Bool`、`selectedIndex: Int?`、`skillsSource: [Skill]`（从外部注入）
  - [x] 1.4 方法 `updateQuery(_ text: String)`：当文本以 `/` 开头时提取查询词并过滤 skills；否则隐藏菜单
  - [x] 1.5 过滤逻辑：匹配 `skill.name` 和 `skill.aliases`，支持前缀匹配和包含匹配（先排前缀匹配结果）
  - [x] 1.6 方法 `selectSkill(at index: Int) -> String?`：返回选中的 `/skillName` 字符串
  - [x] 1.7 方法 `dismiss()`：隐藏菜单，重置状态

- [x] Task 2: 创建 SkillAutocompleteMenuView（AC: #1, #3, #4）
  - [x] 2.1 在 `SwiftWork/Views/Workspace/InputBar/` 下新建 `SkillAutocompleteMenuView.swift`
  - [x] 2.2 浮动菜单使用 `.popover` 或 `.overlay` + `ZStack` 实现，位于输入框上方
  - [x] 2.3 每行显示：skill.name（粗体）+ skill.argumentHint（若有）+ skill.description（截断）
  - [x] 2.4 选中项高亮背景色（`List` 样式或自定义 `HoverBackground`）
  - [x] 2.5 菜单最大高度限制（~200pt），超出可滚动
  - [x] 2.6 键盘导航：Up/Down 切换 selectedIndex，Enter 确认选择

- [x] Task 3: 修改 InputBarView 集成自动补全（AC: #1-#6）
  - [x] 3.1 在 `InputBarView` 中添加 `@State private var autocompleteVM = SkillAutocompleteViewModel()`（或从外部注入 skillsSource）
  - [x] 3.2 监听 `inputText` 变化（`.onChange(of: inputText)`），调用 `autocompleteVM.updateQuery(inputText)`
  - [x] 3.3 当 `autocompleteVM.isVisible` 为 true 时，显示 `SkillAutocompleteMenuView`
  - [x] 3.4 选中 skill 后，将 `inputText` 替换为 `/skillName `（注意末尾空格）
  - [x] 3.5 Escape 键处理：在 `SendTextView.keyDown` 中，如果 autocompleteVM.isVisible，Escape 先关闭菜单而非传递给系统
  - [x] 3.6 确保发送逻辑（`sendMessage`）在菜单可见时先尝试选中项，否则正常发送
  - [x] 3.7 从 `agentBridge.discoveredSkills` 注入 skillsSource（仅在 agentBridge 非 nil 且 skills 非空时启用自动补全）

- [x] Task 4: 编写测试（AC: #1-#6）
  - [x] 4.1 在 `SwiftWorkTests/Views/` 下新建 `SkillAutocompleteViewModelTests.swift`
  - [x] 4.2 测试空输入不显示菜单
  - [x] 4.3 测试 `/` 触发显示所有 userInvocable skills
  - [x] 4.4 测试 `/co` 过滤为 "commit"
  - [x] 4.5 测试别名匹配（`/ci` 匹配 commit 的 alias "ci"）
  - [x] 4.6 测试 `selectSkill` 返回正确的 `/skillName`
  - [x] 4.7 测试 `dismiss` 重置状态
  - [x] 4.8 测试非行首 `/` 不触发（"hello /" 不触发）
  - [x] 4.9 回归测试：确认全部现有测试通过

## Dev Notes

### 核心架构决策

**自动补全是纯 UI 层功能。** 所有 skill 数据来自 `AgentBridge.discoveredSkills`（Story 5-1 已暴露），不需要新增 SDKIntegration 层或 Model 层代码。

**数据流：**
```
AgentBridge.discoveredSkills → InputBarView 注入 → SkillAutocompleteViewModel.skillsSource → 过滤 → SkillAutocompleteMenuView 渲染
```

### 现有 InputBarView 分析

当前 `InputBarView.swift`（83 行）结构：
- `@State private var inputText: String` — 输入文本绑定
- `@FocusState private var isFocused: Bool` — 焦点状态
- `IMESafeTextView`（NSViewRepresentable）— 包装 NSTextView，处理 IME 和按键
- `SendTextView`（NSTextView 子类）— 拦截 Enter 键发送，Shift+Enter 换行

**关键限制：** `IMESafeTextView` 使用 `NSTextView`（AppKit），不是 SwiftUI `TextField`。这意味着：
- 无法直接使用 SwiftUI 的 `.onSubmit`、`.textInputAutocomplete` 等
- 键盘事件拦截在 `SendTextView.keyDown(with:)` 中
- 文本变化通过 `Coordinator.textDidChange` → `parent.text = tv.string` 回调

### 键盘事件处理策略

需要在两个层级处理键盘：

1. **NSTextView 层级**（`SendTextView.keyDown`）：
   - Escape：如果自动补全菜单可见，关闭菜单，`return`（不传递给系统）
   - Up/Down：如果自动补全菜单可见，移动选中项，`return`
   - Enter：如果自动补全菜单可见且有选中项，确认选择，`return`；否则正常发送

2. **SwiftUI 层级**（`InputBarView`）：
   - `.onChange(of: inputText)` 检测 `/` 触发和过滤

**实现方式：** 在 `SendTextView` 中添加回调闭包：
```swift
// SendTextView 新增
var onEscape: (() -> Bool)?  // 返回 true 表示已处理
var onArrowUp: (() -> Bool)?
var onArrowDown: (() -> Bool)?
var onEnterWithAutocomplete: (() -> Bool)?
```

然后在 `InputBarView` 中通过 `updateNSView` 注入这些回调。

### Skill 过滤逻辑

```swift
func updateQuery(_ text: String) {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.hasPrefix("/") else {
        isVisible = false
        return
    }
    let query = String(trimmed.dropFirst()).lowercased()
    if query.isEmpty {
        // "/" 刚输入，显示所有
        filteredSkills = skillsSource
    } else {
        // 模糊过滤：name 前缀匹配优先，然后 name 包含匹配，然后 alias 匹配
        filteredSkills = skillsSource.filter { skill in
            skill.name.lowercased().hasPrefix(query) ||
            skill.name.lowercased().contains(query) ||
            skill.aliases.contains { $0.lowercased().hasPrefix(query) }
        }
        // 排序：前缀匹配排前面
        filteredSkills.sort { a, b in
            let aPrefix = a.name.lowercased().hasPrefix(query)
            let bPrefix = b.name.lowercased().hasPrefix(query)
            if aPrefix != bPrefix { return aPrefix }
            return a.name < b.name
        }
    }
    selectedIndex = filteredSkills.isEmpty ? nil : 0
    isVisible = !filteredSkills.isEmpty
}
```

### 仅行首触发（AC6）

用户 AC 要求"输入框为空时输入 `/` 触发"。但更合理的 UX 是：`/` 出现在文本开头（忽略前导空白）。实现：

```swift
let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
guard trimmed.hasPrefix("/") && !trimmed.dropFirst().isEmpty || text == "/" else { ... }
```

实际上只需检查 `text` 去除前导空白后是否以 `/` 开头。如果用户输入 "hello /"，不应触发。

### 菜单位置和样式

**推荐使用 `.overlay` + `GeometryReader`**（而非 `.popover`）：
- `.popover` 在 macOS 上可能产生不必要的箭头和定位问题
- `.overlay` 提供更精确的控制

菜单应出现在输入框正上方，宽度与输入框一致，最大高度约 200pt。

**菜单行结构：**
```
┌─────────────────────────────────────────┐
│ /commit  [message]                       │  ← skill.name + argumentHint
│ Analyze changes and suggest commit msg   │  ← description（截断1行）
├─────────────────────────────────────────┤
│ /review  ·  /review-pr, /cr             │  ← name + aliases
│ Review code changes for issues           │
├─────────────────────────────────────────┤
│ /simplify                                │
│ Review code for simplification opps      │
└─────────────────────────────────────────┘
```

### 不需要新建文件（总结）

**新建文件：**
1. `SwiftWork/Views/Workspace/InputBar/SkillAutocompleteViewModel.swift` — 自动补全状态管理
2. `SwiftWork/Views/Workspace/InputBar/SkillAutocompleteMenuView.swift` — 菜单 UI
3. `SwiftWorkTests/Views/SkillAutocompleteViewModelTests.swift` — 单元测试

**修改文件：**
1. `SwiftWork/Views/Workspace/InputBar/InputBarView.swift` — 集成自动补全
2. `SwiftWork/Views/Workspace/InputBar/IMESafeTextView.swift` — 添加键盘回调（Escape/Up/Down/Enter）

### Skill struct 关键属性（SDK 类型）

```swift
public struct Skill: Sendable {
    public let name: String           // "commit", "review", "simplify", "debug", "test"
    public let description: String    // 人类可读描述
    public let aliases: [String]      // ["ci"] for commit, ["cr"] for review, etc.
    public let userInvocable: Bool    // true = 用户可调用
    public let argumentHint: String?  // "[message]" for commit
    // ... 其他属性本 Story 不需要
}
```

`AgentBridge.discoveredSkills` 返回 `[Skill]`，已过滤 `userInvocable == true`。

### 300 行 View 限制

`InputBarView.swift` 当前 83 行，修改后预计 130-150 行（新增 overlay + onChange + 回调绑定）。不超过 300 行限制。

`SkillAutocompleteMenuView.swift` 预计 100-150 行。不超过限制。

### 与后续 Story 的关系

- **Story 5.3**（Skill Timeline 卡片渲染）依赖本 Story 的 `/skillName` 触发逻辑，但本 Story 不涉及 Timeline 渲染
- **Story 5.4**（Skill 管理面板）与 `discoveredSkills` 数据共享，但不依赖本 Story

### Epic 4 回顾学习要点

1. **状态变更路径**：本 Story 涉及 `SkillAutocompleteViewModel` 的状态变更（isVisible、selectedIndex、filteredSkills），需在 Dev Notes 中明确所有变更路径
2. **300 行 View 限制**：拆分 `SkillAutocompleteMenuView` 为独立文件，避免 InputBarView 超限
3. **View 不直接引用 SDK 类型**：`Skill` 类型来自 SDK 但通过 `AgentBridge.discoveredSkills` 间接获取，View 层不直接 import SDK——这符合架构边界规则吗？

**关于架构边界：** `Skill` 是 SDK 定义的公开类型（`OpenAgentSDK` 模块），`AgentBridge.discoveredSkills: [Skill]` 返回 SDK 类型。View 层直接消费 `[Skill]` 意味着 View import 了 SDK 类型。严格来说违反了 "View 不直接引用 SDKIntegration 或 SwiftData Models" 的规则，但 `Skill` 是纯数据 struct（无行为），且通过 `AgentBridge`（SDKIntegration 层）传递，这在实际中是可接受的折衷。如果严格遵守，可以创建 UI 中间模型 `SkillItem`（只包含 name、description、aliases、argumentHint），但 Story 5-1 的 Dev Notes 和代码已经让 `discoveredSkills` 直接返回 `[Skill]`，本 Story 应沿用这个设计。

### 测试策略

- `SkillAutocompleteViewModel` 是纯逻辑 ViewModel，可直接实例化测试
- 不需要 mock AgentBridge——直接构造 `[Skill]` 测试数据
- 测试文件命名：`SkillAutocompleteViewModelTests.swift`
- 回归测试：确认全部 601+ 测试通过

### Project Structure Notes

- 新建文件均在 `SwiftWork/Views/Workspace/InputBar/` 下，符合现有目录结构
- 测试文件在 `SwiftWorkTests/Views/` 下
- 遵循命名规范：`SkillAutocompleteViewModel.swift`、`SkillAutocompleteMenuView.swift`
- ViewModel 使用 `@Observable`，不使用 `ObservableObject`

### References

- [Source: SwiftWork/Views/Workspace/InputBar/InputBarView.swift — 当前 InputBar 实现]
- [Source: SwiftWork/Views/Workspace/InputBar/IMESafeTextView.swift — NSTextView 包装，SendTextView.keyDown 按键处理]
- [Source: SwiftWork/SDKIntegration/AgentBridge.swift:123-125 — discoveredSkills 计算属性]
- [Source: open-agent-sdk-swift/Sources/OpenAgentSDK/Types/SkillTypes.swift — Skill struct, BuiltInSkills, 属性定义]
- [Source: _bmad-output/implementation-artifacts/5-1-sdk-skill-pipeline.md — Story 5-1 Dev Notes, AgentBridge 修改详情]
- [Source: _bmad-output/planning-artifacts/epics.md — Story 5.2 AC 定义]
- [Source: _bmad-output/planning-artifacts/architecture.md — 分层边界规则、300行限制]

### Story 5-1 关键学习

1. `autoDiscoverSkills()` 是 SDK internal 方法，不可从外部调用——`discoveredSkills` 通过手动 `registerDiscoveredSkills()` + `allSkills.filter { $0.userInvocable }` 实现
2. `BuiltInSkills.test` 的 `isAvailable()` 检查 CWD 中是否有测试框架文件，在 xcodebuild 环境 CWD 可能不是项目根目录——所以 `discoveredSkills` 用 `allSkills.filter { $0.userInvocable }` 而非 `userInvocableSkills`（后者会额外调用 `isAvailable`）
3. Story 5-1 有 Review Findings 中提到 `clearEvents()` 和 `trimOldEvents()` 的 continuation 泄露问题——本 Story 不涉及这些代码路径，但需要注意

## Dev Agent Record

### Agent Model Used

Claude GLM-5.1

### Debug Log References

No blocking issues encountered.

### Completion Notes List

- Task 1: Created `SkillAutocompleteViewModel` with `@Observable` pattern. Implements `updateQuery()` for slash-trigger and fuzzy filtering (prefix match priority, then contains match, then alias match), `selectSkill(at:)` for keyboard selection, `moveSelection(down:)` with wrap-around, and `dismiss()`. All properties follow the story spec exactly.
- Task 2: Created `SkillAutocompleteMenuView` with floating overlay design. Shows skill name (bold), argumentHint, aliases, and truncated description. Selected item gets accent color highlight. Max height 200pt with scroll. Tap gesture for mouse selection. Private `SkillRowView` subview keeps file under 300-line limit.
- Task 3: Modified `InputBarView` to integrate autocomplete. Added `onChange(of: inputText)` to trigger ViewModel filtering. Added `onAppear` to inject `discoveredSkills` from `agentBridge`. Menu appears above input bar via VStack. Modified `SendTextView` (in `IMESafeTextView.swift`) to support callback closures for Escape, Up/Down arrows, and Enter with autocomplete. All callbacks return Bool to indicate whether the event was consumed. `sendMessage()` dismisses autocomplete before sending. Autocomplete only enabled when `agentBridge.discoveredSkills` is non-empty.
- Task 4: ATDD tests (28 tests) were already written. Fixed Skill init argument order (promptTemplate must come after aliases in SDK API). All 28 tests pass covering AC#1-#6. Full regression suite passes (629 tests, 0 failures).
- Added all new files to Xcode project (project.pbxproj): 2 source files + 1 test file, with proper group structure and build phase entries.

### File List

**New files:**
- SwiftWork/Views/Workspace/InputBar/SkillAutocompleteViewModel.swift
- SwiftWork/Views/Workspace/InputBar/SkillAutocompleteMenuView.swift

**Modified files:**
- SwiftWork/Views/Workspace/InputBar/InputBarView.swift
- SwiftWork/Views/Workspace/InputBar/IMESafeTextView.swift
- SwiftWorkTests/Views/Workspace/InputBar/SkillAutocompleteViewModelTests.swift (fixed Skill init arg order)
- SwiftWork.xcodeproj/project.pbxproj (added 3 new files to project)

## Change Log

- 2026-05-05: Story 5-2 implementation complete. Created SkillAutocompleteViewModel + SkillAutocompleteMenuView + InputBarView integration + IMESafeTextView keyboard callbacks. All 6 ACs satisfied. 28 ATDD tests pass. 629 total tests pass with 0 regressions.
