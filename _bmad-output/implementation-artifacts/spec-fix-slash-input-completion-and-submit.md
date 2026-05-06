---
title: 'Fix Slash Input Completion and Submit'
type: 'bugfix'
created: '2026-05-07'
status: 'done'
baseline_commit: '7223e4f5a81bd476882489255fa7b2da470c0790'
context:
  - '{project-root}/_bmad-output/project-context.md'
---

# Fix Slash Input Completion and Submit

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** 当前 slash 输入链路还有一组键盘交互回归：输入 `/` 后虽然会出现技能提示，但确认补全依赖 Enter 而不是 Tab；补全后光标停在 skill 名称中间，菜单也不会关闭；当用户在 skill 名称后输入空格和参数再按 Enter 时，消息没有正常发送出去。

**Approach:** 把 slash 菜单的交互语义收紧为“Tab 负责补全、Enter 负责发送、进入参数阶段后退出补全模式”，并修正程序化文本替换时的插入点位置，让 slash 从选中 skill 到继续输入参数再到最终发送形成稳定的单一路径。

## Boundaries & Constraints

**Always:** 保持现有 `InputBarView` + `IMESafeTextView` + `SkillAutocompleteViewModel` 的职责分层；普通多行输入、Shift+Enter 换行、上下键移动候选、点击候选补全继续有效；slash 补全插入后必须把光标放到已补全文本末尾，并让候选菜单立即退出；一旦用户已经进入“参数输入”阶段，Enter 必须恢复为发送语义。

**Ask First:** 如果实现过程中必须把 Enter 在“仅有命令、还未输入参数”时保留为补全，或者必须引入新的全局输入状态机/焦点管理对象，先问用户。

**Never:** 不回退之前已经完成的显式 slash skill 路由；不把 skill 名称写死；不为了修输入栏去改 Timeline、Session、Settings 或 Agent 执行主流程；不让 Tab 触发系统焦点切换而绕过 slash 补全。

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Tab 补全 | slash 菜单可见，存在选中项 | 用户按 Tab 后将当前选中项补全到输入框，并自动追加一个空格 | 若没有选中项，则保留默认文本视图行为 |
| 补全后插入点 | 用户刚通过 Tab 或点击完成 `/polyv-live-cli` 补全 | 光标位于 `/polyv-live-cli ` 末尾，菜单关闭 | 不允许残留旧选区导致光标落在中间 |
| 参数阶段发送 | 输入框内容为 `/polyv-live-cli 获取最新5个频道` | 用户按 Enter 后消息直接发送，而不是再次走补全 | 若 skill 不可用，沿用既有 inline error 和保留输入逻辑 |
| 参数阶段退场 | 用户已输入 `/skill ` 或 `/skill args` | slash 菜单隐藏，不继续悬浮遮挡输入 | 用户删回 slash 命令阶段时，菜单可再次出现 |

</frozen-after-approval>

## Code Map

- `SwiftWork/Views/Workspace/InputBar/InputBarView.swift` -- 输入栏把文本视图键盘事件、slash 菜单状态和发送动作接起来
- `SwiftWork/Views/Workspace/InputBar/IMESafeTextView.swift` -- AppKit 文本视图键盘拦截、程序化文本同步和光标位置恢复
- `SwiftWork/Views/Workspace/InputBar/SkillAutocompleteViewModel.swift` -- slash 是否仍处于“命令补全阶段”的判断与候选可见性
- `SwiftWorkTests/Views/Workspace/InputBar/SkillAutocompleteViewModelTests.swift` -- slash 参数阶段菜单行为回归保护
- `SwiftWorkTests/Views/Workspace/InputBar/InputBarViewTests.swift` -- 输入栏契约级回归保护

## Tasks & Acceptance

**Execution:**
- [x] `SwiftWork/Views/Workspace/InputBar/SkillAutocompleteViewModel.swift` -- 把“命令补全阶段”和“参数输入阶段”区分开；只有前者显示结果并允许补全，后者自动隐藏菜单 -- 让 Enter 不再被悬浮菜单错误劫持
- [x] `SwiftWork/Views/Workspace/InputBar/IMESafeTextView.swift` -- 新增 Tab 补全入口，并修正程序化文本更新后的插入点恢复策略，使补全后的光标固定落在文本末尾 -- 让补全行为符合命令输入习惯
- [x] `SwiftWork/Views/Workspace/InputBar/InputBarView.swift` -- 将 slash 补全确认从 Enter 改为 Tab/点击，并确保补全完成后关闭菜单、保留 Enter 发送语义 -- 把用户的补全与发送动作拆清楚
- [x] `SwiftWorkTests/Views/Workspace/InputBar/SkillAutocompleteViewModelTests.swift` + `SwiftWorkTests/Views/Workspace/InputBar/InputBarViewTests.swift` -- 增加参数阶段隐藏菜单、Tab 补全契约和补全后发送行为的回归覆盖 -- 锁住这次交互回归面

**Acceptance Criteria:**
- [x] Given slash 候选菜单可见且有选中项, when 用户按 Tab, then 当前 skill 会被补全到输入框并自动追加空格
- [x] Given 用户刚完成 skill 补全, when 输入框文本被程序化写回, then 插入点位于补全文本末尾且候选菜单已关闭
- [x] Given 用户已经输入 `/skill 参数...`, when 用户按 Enter, then 输入栏执行发送而不是再次尝试补全
- [x] Given 用户已经进入参数输入阶段, when slash 文本后存在空格, then 候选菜单隐藏；当用户删回纯 `/skill` 命令阶段时，候选菜单可重新出现
- [x] Given 用户输入普通文本或 Shift+Enter 换行, when 提交或编辑消息, then 现有非 slash 输入行为保持不变

## Design Notes

- 这次修的是**键盘契约**，不是 slash 路由本身。建议把“是否仍在补全命令名”判断尽量收敛到 `SkillAutocompleteViewModel`，让 `InputBarView` 只负责在 Tab/点击时应用选中结果，在 Enter 时继续调用既有 `sendMessage()`.
- 程序化补全文本时，需要显式覆盖 `NSTextView` 的选区恢复逻辑；沿用旧选区会把光标放回用户输入前的位置，正是当前“光标卡在 skill 中间”的根因。

## Verification

**Commands:**
- `swift build` -- expected: 输入栏与文本视图改动后仍可正常编译
- `swift test` -- expected: 现有测试继续通过，并新增覆盖 Tab 补全、参数阶段隐藏菜单与 Enter 发送

## Suggested Review Order

**Keyboard contract**

- 先看输入栏如何把 Tab 补全和 Enter 发送彻底拆开。
  [`InputBarView.swift:15`](../../SwiftWork/Views/Workspace/InputBar/InputBarView.swift#L15)

- 这里定义 Tab 接管候选补全，而 Enter 只负责发送。
  [`IMESafeTextView.swift:201`](../../SwiftWork/Views/Workspace/InputBar/IMESafeTextView.swift#L201)

- 这里把补全动作收敛成统一入口，保证菜单立即关闭。
  [`InputBarView.swift:156`](../../SwiftWork/Views/Workspace/InputBar/InputBarView.swift#L156)

**Caret placement**

- 先看程序化补全文本后，如何显式请求把光标放到文本末尾。
  [`InputBarView.swift:166`](../../SwiftWork/Views/Workspace/InputBar/InputBarView.swift#L166)

- 这里实现选区覆盖，避免沿用旧选区把光标留在 skill 中间。
  [`IMESafeTextView.swift:4`](../../SwiftWork/Views/Workspace/InputBar/IMESafeTextView.swift#L4)

- 这里把选区请求应用到 NSTextView，并在完成后清空一次性状态。
  [`IMESafeTextView.swift:118`](../../SwiftWork/Views/Workspace/InputBar/IMESafeTextView.swift#L118)

**Autocomplete phase gating**

- 这里把 slash 菜单限制在“纯命令补全阶段”，进入参数后立即退场。
  [`SkillAutocompleteViewModel.swift:52`](../../SwiftWork/Views/Workspace/InputBar/SkillAutocompleteViewModel.swift#L52)

- 这里定义命令阶段判定，删回纯 `/skill` 时可重新打开菜单。
  [`SkillAutocompleteViewModel.swift:126`](../../SwiftWork/Views/Workspace/InputBar/SkillAutocompleteViewModel.swift#L126)

**Regression coverage**

- 先看参数阶段隐藏菜单与删回命令阶段重开的回归保护。
  [`SkillAutocompleteViewModelTests.swift:356`](../../SwiftWorkTests/Views/Workspace/InputBar/SkillAutocompleteViewModelTests.swift#L356)

- 这里锁住光标落尾、Tab 补全和 Enter 不再被补全劫持。
  [`InputBarViewTests.swift:226`](../../SwiftWorkTests/Views/Workspace/InputBar/InputBarViewTests.swift#L226)
