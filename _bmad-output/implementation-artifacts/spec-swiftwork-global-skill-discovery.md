---
title: 'SwiftWork 全局 Skill 安装与发现目录'
type: 'bugfix'
created: '2026-08-01'
status: 'done'
review_loop_iteration: 0
baseline_commit: 'b38c2005aaed8a00d55d446cd685af474ed6773a'
context:
  - '{project-root}/_bmad-output/project-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Skill 发现当前依赖会话 workspace，没有 SwiftWork 安装目录或 Codex 兼容；SkillHub 的 `@publisher/skill/SKILL.md` 结构也无法被 SDK 的单层扫描识别。

**Approach:** 新增 `~/Library/Application Support/SwiftWork/skills` 作为全局主目录，兼容 Agents、Claude Code、Codex 的用户目录，移除 workspace 扫描，并在 SwiftWork 内展开一层 `@publisher`。

## Boundaries & Constraints

**Always:**
- 全局扫描根不随 `ready/unbound/needsRepair` 或 workspace 变化；workspace 仍只控制工具 cwd 和权限。
- 低到高优先级为 `~/.config/agents/skills`、`~/.agents/skills`、`~/.claude/skills`、`~/.codex/skills`、SwiftWork 主目录；同名文件 Skill 后者覆盖。
- 仅支持 `<root>/<skill>/SKILL.md` 与 `<root>/@<publisher>/<skill>/SKILL.md`；publisher 排序展开，不无限递归。
- 主目录按需创建；缺失、不可读、空 namespace 安全跳过。
- 系统提示明确要求 `skillhub install ... --dir "<SwiftWork 主目录>"`，禁止回退到 cwd 的 `./skills`。
- 来源显示为 Built-in、SwiftWork、Claude Code、Codex、Shared Agents，不再出现 workspace Project 来源。
- 配置 Agent 与每个完整回合结束后重扫；复用 Agent 已持有的 registry，同步 SkillTool、Slash 和设置列表。

**Ask First:** 改主目录、升级/修改 OpenAgentSDK、递归超过一层 publisher、改变 Built-in 重名策略。

**Never:** 扫描 workspace 内的 Skill 目录；修改 DerivedData；依赖进程 cwd/PWD；放宽普通工具的 workspace 约束。

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| 原生/SkillHub | `foo/SKILL.md` 或 `@p/foo/SKILL.md` | 均注册 `foo` | 无效包跳过 |
| 会话切换 | workspace/state 改变 | 完整 catalog 不变 | 可用性仍可按工具需求限制 |
| 来源重名 | Claude/Codex/SwiftWork 都有 `foo` | SwiftWork 版本生效 | 记录日志 |
| 磁盘变化 | 新增、删除或覆盖 | 刷新后 registry/UI 一致 | 不留陈旧注册 |

</frozen-after-approval>

## Code Map

- `SwiftWork/Services/SkillDirectoryService.swift` -- 全局根、主目录创建、优先级、namespace 展开。
- `SwiftWork/Services/SessionWorkspaceService.swift` -- 删除 Skill 目录职责。
- `SwiftWork/SDKIntegration/AgentBridge.swift` -- 全局发现、同 registry 刷新、安装提示。
- `SwiftWork/Models/UI/SkillSource.swift`、`SwiftWork/Views/Settings/SkillsListView.swift`、`SwiftWork/Views/Settings/SkillListItemView.swift`、`SwiftWork/Views/Workspace/InputBar/InputBarView.swift` -- 全局来源与刷新 UI。
- `SwiftWorkTests/Services/SkillDirectoryServiceTests.swift`、现有 Skill 测试 -- 覆盖目录、namespace、刷新与来源。

## Tasks & Acceptance

**Execution:**
- [x] `SwiftWork/Services/SkillDirectoryService.swift` -- 实现可注入路径、确定性 namespace 展开和主目录创建。
- [x] `SwiftWork/Services/SessionWorkspaceService.swift`、`SwiftWork/SDKIntegration/AgentBridge.swift` -- 解耦发现，回合后刷新同一 registry，注入安装目标；保持工具 cwd 行为。
- [x] `SwiftWork/Models/UI/SkillSource.swift`、`SwiftWork/Views/Settings/SkillsListView.swift`、`SwiftWork/Views/Settings/SkillListItemView.swift`、`SwiftWork/Views/Workspace/InputBar/InputBarView.swift` -- 改用全局来源，去掉按键级磁盘重扫。
- [x] `SwiftWorkTests/Services/SkillDirectoryServiceTests.swift`、`SwiftWorkTests/SDKIntegration/AgentBridgeSkillTests.swift`、`SwiftWorkTests/Views/Settings/SkillSourceGroupingTests.swift` -- 覆盖矩阵、优先级、三种 workspace state、来源与 registry 增删。

**Acceptance Criteria:**
- Given 任意 workspace/state，when 配置 Agent，then 完整文件 Skill catalog 只来自固定全局根且不随会话变化。
- Given 主目录存在 `@publisher/foo/SKILL.md`，when 重扫，then Settings、Slash 和 SkillTool 都可用 `foo`。
- Given Agent 安装 Skill，when 读取系统提示，then 使用 SwiftWork 主目录及显式 `--dir`。
- Given 磁盘增删或覆盖 Skill，when 重扫，then registry/UI 无陈旧状态。

## Spec Change Log

## Design Notes

不修改锁定的 SDK 0.9.0。服务输出 `[root, root/@a, ...]` 复用其单层扫描；刷新时 `clear` 并重填 Agent 已持有的同一 `SkillRegistry`。

## Verification

**Commands:**
- `swift test --filter SkillDirectoryServiceTests` -- expected: 目录/namespace/优先级通过。
- `swift test --filter AgentBridgeSkillTests` -- expected: 解耦、刷新、提示通过。
- `swift test && swift build` -- expected: 全量回归与 Swift 6.1 构建通过。

## Suggested Review Order

**Registry 与回合刷新**

- 从 Agent 配置入口理解固定全局 catalog 与同一 registry 复用。
  [`AgentBridge.swift:325`](../../SwiftWork/SDKIntegration/AgentBridge.swift#L325)

- 动态 SkillTool 避免重扫后模型继续看到陈旧或不可用 Skill。
  [`AgentBridge.swift:56`](../../SwiftWork/SDKIntegration/AgentBridge.swift#L56)

- 原子清空并重填 registry，同步 Settings、Slash 与 SkillTool。
  [`AgentBridge.swift:831`](../../SwiftWork/SDKIntegration/AgentBridge.swift#L831)

- 正常、异常和取消回合都在终止边界补齐磁盘重扫。
  [`AgentBridge.swift:577`](../../SwiftWork/SDKIntegration/AgentBridge.swift#L577)

**目录与安装契约**

- 单一服务定义根优先级、按需创建和一层 namespace 展开。
  [`SkillDirectoryService.swift:20`](../../SwiftWork/Services/SkillDirectoryService.swift#L20)

- 固定用户目录包含 SwiftWork、Codex、Claude 与 Shared Agents。
  [`SkillSource.swift:4`](../../SwiftWork/Models/UI/SkillSource.swift#L4)

- workspace 服务只保留 cwd 与绑定职责，不再决定 Skill 发现。
  [`SessionWorkspaceService.swift:121`](../../SwiftWork/Services/SessionWorkspaceService.swift#L121)

- 安装提示固定显式 `--dir`，且不放宽普通 workspace 操作。
  [`AgentBridge.swift:1045`](../../SwiftWork/SDKIntegration/AgentBridge.swift#L1045)

**设置与输入体验**

- 来源分类改为固定全局来源，不再生成 Project 分组。
  [`SkillSource.swift:31`](../../SwiftWork/Models/UI/SkillSource.swift#L31)

- 设置页按来源分组并消费可观察的实时 catalog。
  [`SkillsListView.swift:19`](../../SwiftWork/Views/Settings/SkillsListView.swift#L19)

- 输入框仅响应内存 revision，不再按键触发磁盘扫描。
  [`InputBarView.swift:97`](../../SwiftWork/Views/Workspace/InputBar/InputBarView.swift#L97)

**回归覆盖**

- 直接包、一层 publisher、深层排除与覆盖优先级。
  [`SkillDirectoryServiceTests.swift:51`](../../SwiftWorkTests/Services/SkillDirectoryServiceTests.swift#L51)

- 三种 workspace state、registry 增删及动态 Tool 描述。
  [`AgentBridgeSkillTests.swift:759`](../../SwiftWorkTests/SDKIntegration/AgentBridgeSkillTests.swift#L759)

- 设置来源名称与边界安全的路径归类。
  [`SkillSourceGroupingTests.swift:77`](../../SwiftWorkTests/Views/Settings/SkillSourceGroupingTests.swift#L77)
