---
title: '权限规则新增与编辑'
type: 'feature'
created: '2026-05-05'
status: 'done'
baseline_commit: '10998eacb1d8ff45fca3ad6206dfbd0dd3c88ebb'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** PermissionRulesView 只支持查看和删除权限规则，用户无法主动新增或编辑规则。"始终允许"按钮保持会话级授权，不会写入持久规则，因此用户需要一种手动管理持久权限规则的途径。

**Approach:** 在 PermissionRulesView 中新增模板驱动的规则创建表单（Sheet），支持内联编辑已有规则的 pattern 和 decision，更新空状态文案。

## Boundaries & Constraints

**Always:**
- 新增/编辑必须使用模板预设（全部允许、路径前缀、精确匹配、自定义），不暴露裸 pattern 输入作为唯一选项
- 规则变更后立即持久化到 SwiftData
- 遵循现有 `@Observable` + `@Bindable` 模式，不用 `ObservableObject`
- "始终允许"保持会话级，不改动 PermissionCardView 的逻辑

**Ask First:** 无

**Never:**
- 不修改 PermissionRule 数据模型（保持 toolName / pattern / decision / createdAt 四字段）
- 不修改 PermissionHandler.evaluate() 的匹配逻辑
- 不改动 PermissionCardView 或 AgentBridge 中的审批流程
- 不引入规则优先级或排序机制

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| 新增规则（全部允许） | 选工具 "Bash"，模板选 "全部允许" | 创建 PermissionRule(toolName:"Bash", pattern:"*", decision:.allow) | N/A |
| 新增规则（路径前缀） | 选工具 "Edit"，模板选 "路径前缀"，输入 "/Users/nick/Projects/" | 创建 PermissionRule(toolName:"Edit", pattern:"/Users/nick/Projects/*", decision:.allow) | 空路径时禁用确认按钮 |
| 新增规则（自定义） | 选工具 "Bash"，模板选 "自定义"，输入 "git *" | 创建 PermissionRule(toolName:"Bash", pattern:"git *", decision:.allow) | 空 pattern 时禁用确认按钮 |
| 新增重复规则 | 已存在 Bash + "*" + allow | 仍然创建（允许多条规则匹配同一工具） | N/A |
| 编辑规则 pattern | 点击已有规则，修改 pattern | 原地更新 SwiftData 记录 | 空 pattern 时禁用保存 |
| 编辑规则 decision | 切换 allow ↔ deny | 原地更新 | N/A |
| 删除规则 | 已有功能 | 不变 | N/A |
| 空状态 | 无规则 | 显示引导文案，提示点击 "+" 新增 | N/A |

</frozen-after-approval>

## Code Map

- `SwiftWork/Views/Permission/PermissionRulesView.swift` -- 主改文件，新增 "+" 按钮、AddRuleSheet、内联编辑
- `SwiftWork/SDKIntegration/PermissionHandler.swift` -- 新增 updateRule() 方法，已有 addPersistentRule() 和 deleteRule()
- `SwiftWork/Models/SwiftData/PermissionRule.swift` -- 不改，参考模型结构
- `SwiftWork/Views/Settings/SettingsView.swift` -- 不改，PermissionRulesView 的容器

## Tasks & Acceptance

**Execution:**
- [ ] `SwiftWork/SDKIntegration/PermissionHandler.swift` -- 新增 `updateRule(_:toolName:pattern:decision:)` 方法 -- 编辑规则需要持久化变更
- [ ] `SwiftWork/Views/Permission/PermissionRulesView.swift` -- 添加工具栏 "+" 按钮弹出 AddRuleSheet；AddRuleSheet 包含工具选择器、模板选择器、decision 选择器、确认按钮；规则行点击进入内联编辑模式（修改 pattern + decision）；更新空状态文案

**Acceptance Criteria:**
- Given 无规则，when 点击 "+"，then 弹出新增表单，包含工具选择、模板选择、决策选择
- Given 新增表单，when 选择 "全部允许" 模板并确认，then 创建 pattern="*" 的规则并出现在列表中
- Given 已有规则，when 点击规则行，then 进入编辑模式，可修改 pattern 和 decision
- Given 编辑模式，when 修改后点击保存，then 持久化到 SwiftData，列表更新
- Given 编辑模式，when 点击取消，then 恢复原值，退出编辑
- Given 新增表单，when pattern 输入为空，then 确认按钮禁用

## Spec Change Log

## Design Notes

**模板选择器设计：**
```
┌─────────────────────────────────┐
│ 新增权限规则                      │
│                                 │
│ 工具: [Bash ▾]                  │
│                                 │
│ 匹配范围:                        │
│ ○ 全部允许                      │
│ ○ 路径/命令前缀   [/Users/___]  │
│ ○ 精确匹配        [________]    │
│ ● 自定义          [git push*]   │
│                                 │
│ 决策: ○ 允许  ○ 拒绝             │
│                                 │
│           [取消]  [确认]         │
└─────────────────────────────────┘
```
选择 "全部允许" 时隐藏输入框；选择其他模板时显示对应输入框。路径前缀模板自动追加 `*` 后缀。

**内联编辑：** 点击规则行切换编辑态——pattern 变为 TextField，decision 变为 Picker，显示保存/取消按钮。使用 `withAnimation` 过渡。

## Verification

**Commands:**
- `cd /Users/nick/CascadeProjects/swiftwork && swift build` -- expected: build succeeds with no errors

**Manual checks:**
- 打开设置 → 权限 tab，验证 "+" 按钮可见
- 点击 "+" 验证模板选择器和确认流程
- 点击已有规则验证编辑模式
- 新增/编辑后重启 App，验证规则持久化

## Suggested Review Order

**规则持久化**

- 新增 updateRule() 支持编辑规则后持久化到 SwiftData
  [`PermissionHandler.swift:113`](../../SwiftWork/SDKIntegration/PermissionHandler.swift#L113)

**模板驱动新增**

- PatternTemplate 枚举定义四种匹配模板及解析逻辑
  [`PermissionRulesView.swift:6`](../../SwiftWork/Views/Permission/PermissionRulesView.swift#L6)
- AddRuleSheet 完整新增表单：工具选择器 + 模板单选 + 决策选择器
  [`PermissionRulesView.swift:265`](../../SwiftWork/Views/Permission/PermissionRulesView.swift#L265)
- 模板选择器中 RadioButton + 条件 TextField 布局
  [`PermissionRulesView.swift:327`](../../SwiftWork/Views/Permission/PermissionRulesView.swift#L327)

**内联编辑**

- 规则行点击编辑按钮切换编辑态，withAnimation 过渡
  [`PermissionRulesView.swift:224`](../../SwiftWork/Views/Permission/PermissionRulesView.swift#L224)
- EditRuleRow 内联编辑：pattern TextField + decision Picker + 保存/取消
  [`PermissionRulesView.swift:372`](../../SwiftWork/Views/Permission/PermissionRulesView.swift#L372)

**Review 修复**

- 删除规则时清理 editingRuleId 防止 use-after-delete
  [`PermissionRulesView.swift:170`](../../SwiftWork/Views/Permission/PermissionRulesView.swift#L170)
- 移除 EditRuleRow 的键盘快捷键防止与 alert 冲突
  [`PermissionRulesView.swift:401`](../../SwiftWork/Views/Permission/PermissionRulesView.swift#L401)
