---
title: '权限规则删除按钮 & 自动批准模式警告指示器'
type: 'bugfix'
created: '2026-05-05'
status: 'done'
baseline_commit: '0f6a299'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** 权限配置弹窗（Settings → 权限）中已授权规则没有可见的删除入口（仅靠 macOS 隐式 Delete 键/右键），用户无法直观删除规则。同时，选择「自动批准」模式后缺乏醒目的风险提示，主界面也无任何指示当前处于高风险权限模式。

**Approach:** 在 `PermissionRulesView` 每条规则行添加可见的删除按钮（trash icon）。在 `PermissionRulesView` 全局模式选择区添加自动批准警告横幅。在 `WorkspaceView` 工具栏添加权限模式指示器图标，当模式为 autoApprove 时以醒目样式持续提醒。

## Boundaries & Constraints

**Always:** 使用 `@Observable` 模式，不引入 `ObservableObject`；所有 UI 更新在 `@MainActor`；通过 `permissionHandler` 操作权限数据，不绕过现有删除逻辑。

**Ask First:** 无。

**Never:** 不修改 `PermissionHandler` 核心评估逻辑；不修改 `PermissionCardView`（Timeline 内联审批卡片）；不引入新的 SwiftData 模型。

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| 删除单条规则 | 用户点击规则行的 trash 按钮 | 弹出确认对话框，确认后规则从列表消失并从 SwiftData 删除 | 取消则无变化 |
| 删除最后一条规则 | rules 列表仅剩 1 条，删除后为空 | 列表切换为空状态提示文案 | N/A |
| 切换到自动批准 | 用户选择「自动批准」分段 | 模式下方出现橙色警告横幅；工具栏权限图标变为橙色 | N/A |
| 切换回手动审批 | 用户选择「手动审批」 | 警告横幅消失；工具栏权限图标恢复为普通样式 | N/A |
| 全部拒绝模式 | 用户选择「全部拒绝」 | 无警告横幅；工具栏权限图标显示为红色/锁定 | N/A |

</frozen-after-approval>

## Code Map

- `SwiftWork/Views/Permission/PermissionRulesView.swift` -- 权限规则列表视图，需添加删除按钮和警告横幅
- `SwiftWork/Views/Workspace/WorkspaceView.swift` -- 主工作区视图，需在输入框下方添加权限模式风险提示条
- `SwiftWork/SDKIntegration/PermissionHandler.swift` -- 权限引擎（只读访问 `globalMode`，已有 `deleteRule` 方法）
- `SwiftWork/Models/SwiftData/PermissionRule.swift` -- SwiftData 权限规则模型（不修改）

## Tasks & Acceptance

**Execution:**
- [x] `SwiftWork/Views/Permission/PermissionRulesView.swift` -- 在每条 `ruleRow` 中添加可见的 trash 图标按钮，点击触发现有 `deleteRule` 逻辑（复用已有 `ruleToDelete` + `showDeleteConfirmation` 确认弹窗）；在 `globalModeSection` 中当 `globalMode == .autoApprove` 时显示橙色警告横幅（`exclamationmark.triangle` + 风险文案）
- [x] `SwiftWork/Views/Workspace/WorkspaceView.swift` -- 在 InputBarView 下方添加权限模式风险提示条：仅在 `globalMode == .autoApprove` 时显示，橙色背景横幅，包含 `exclamationmark.triangle` 图标 + "自动批准已开启" 文案，点击可打开 Settings 权限页。通过 `agentBridge.permissionHandler.globalMode` 读取当前模式

**Acceptance Criteria:**
- Given 权限规则列表有 N 条规则，当 用户点击任一规则行的 trash 按钮，then 弹出确认对话框，确认后规则被删除，列表更新为 N-1 条
- Given 权限规则列表为空，当 查看规则区域，then 显示空状态提示文案
- Given 全局权限模式为自动批准，当 打开设置权限页，then 模式选择下方显示橙色警告横幅
- Given 全局权限模式为自动批准，当 查看 Workspace 输入框下方，then 显示橙色风险提示条"自动批准已开启"，点击可跳转设置
- Given 全局权限模式为手动审批或全部拒绝，当 查看 Workspace 输入框下方，then 无风险提示条

## Spec Change Log

## Design Notes

**规则行删除按钮：** 在 `ruleRow` 的 HStack 末尾、`Spacer()` 后添加一个小的 trash 图标按钮（`.controlSize(.small)`），颜色为 `.secondary`，hover 时变红。复用已有的 `ruleToDelete` + `showDeleteConfirmation` alert 逻辑，不需要新增状态。

**自动批准警告横幅：** 在 `globalModeSection` 的 mode description 之后，条件渲染一个 `HStack` 横幅（橙色背景 `Color.orange.opacity(0.1)` + 圆角 + padding），包含 `exclamationmark.triangle.fill` 图标和警告文案"自动批准模式下所有工具调用无需确认，请确保你信任当前 Agent 的行为"。

**工作区权限风险提示条：** 在 `WorkspaceView` 的 `VStack` 中，`InputBarView` 下方添加条件渲染的风险提示条。仅在 `agentBridge.permissionHandler.globalMode == .autoApprove` 时显示。使用 `HStack` 布局：橙色背景 (`Color.orange.opacity(0.1)`) + 圆角 + `exclamationmark.triangle.fill` 图标 + "自动批准已开启 — 所有工具调用无需确认" 文案。整条可点击，通过回调打开 Settings 权限页。提示条高度紧凑（约 24px），不影响输入区视觉重心。

## Verification

**Commands:**
- `cd /Users/nick/CascadeProjects/swiftwork && xcodebuild -scheme SwiftWork -configuration Debug build 2>&1 | tail -5` -- expected: BUILD SUCCEEDED

**Manual checks:**
- 打开 Settings → 权限，确认规则行有可见 trash 按钮，点击可删除
- 切换到「自动批准」，确认出现警告横幅；切换到其他模式横幅消失
- 在 Workspace 输入框下方确认：autoApprove 时显示橙色提示条，其他模式时无提示条

## Suggested Review Order

**权限规则删除按钮**

- 每条规则行末尾添加 trash 按钮，复用已有确认弹窗
  [`PermissionRulesView.swift:156`](../../SwiftWork/Views/Permission/PermissionRulesView.swift#L156)

- 已有确认弹窗和 deleteRule 逻辑（按钮复用此流程）
  [`PermissionRulesView.swift:116`](../../SwiftWork/Views/Permission/PermissionRulesView.swift#L116)

**自动批准模式警告**

- Settings 权限页模式选择下方的警告横幅
  [`PermissionRulesView.swift:50`](../../SwiftWork/Views/Permission/PermissionRulesView.swift#L50)

- Workspace 输入框下方可点击的风险提示条
  [`WorkspaceView.swift:119`](../../SwiftWork/Views/Workspace/WorkspaceView.swift#L119)

- onOpenSettings 回调传入，点击提示条打开设置
  [`ContentView.swift:47`](../../SwiftWork/App/ContentView.swift#L47)
