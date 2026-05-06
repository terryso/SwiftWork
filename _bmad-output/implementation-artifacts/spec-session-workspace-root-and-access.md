---
title: '会话级工作目录与访问兜底'
type: 'feature'
created: '2026-05-07T02:58:30.847+08:00'
status: 'done'
context:
  - '{project-root}/_bmad-output/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/1-4-message-input-agent-execution.md'
  - '{project-root}/_bmad-output/implementation-artifacts/5-1-sdk-skill-pipeline.md'
baseline_commit: 'df74e898ed8bfdb08cb614643bde6bffa31c91f9'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** 现在每个会话的执行上下文基本都会落到进程级根目录，因为新会话的 `workspacePath` 默认为空，Agent 和部分 UI 逻辑又会回退到 `FileManager.default.currentDirectoryPath`。结果是会话没有稳定、显式、可恢复的工作目录，用户在查看当前目录、创建文件或依赖项目级 skill 时，容易碰到目录不对或权限不通的报错；而对安装后的桌面 App 来说，也不存在天然可信的“当前项目目录”可直接拿来当默认值。

**Approach:** 参考 OpenWork 的“显式 workspace root + 按 workspace 切换上下文”思路，把工作目录升级为会话的一等配置，但不把“新建会话先选目录”做成硬前置。新会话优先继承最近一次有效 workspace；若用户是首次安装或还没有历史 workspace，则允许会话先以“未绑定 workspace”状态创建。Agent 与相关 UI 只使用会话级目录；当目录缺失、失效或尚未绑定时，依赖 workspace 的能力必须先提示绑定/修复，而不是等工具调用后再以权限错误失败。

## Boundaries & Constraints

**Always:**
- 会话最终必须进入“有明确 workspace”或“明确未绑定且受限”两种可见状态之一；不能继续静默回退到进程 cwd
- 新会话不强制先选目录：优先继承最近一次有效 workspace；没有历史 workspace 时允许先创建未绑定会话
- 旧会话 `workspacePath == nil` 时不能继续静默回退到进程 cwd；必须走可见的迁移/修复流程
- 当目录不存在、不可读写或无法恢复时，UI 必须先阻止执行并提示用户重新选择，而不是让工具调用以“无权限/路径错误”方式兜底
- 未绑定 workspace 的会话里，依赖目录的能力必须被明确限制或延后触发选择目录，而不是假装可用
- 方案应借鉴 OpenWork 的 workspace 显式建模与切换思路，但保持 SwiftWork 现有 Session / AgentBridge / 权限系统架构

**Ask First:** 无

**Never:**
- 不继续新增基于 `FileManager.default.currentDirectoryPath` 的项目根判断
- 不把“权限失败后自动重试别的目录”当成主流程
- 不要求用户每次发送消息都重复选择工作目录
- 不把会话工作目录与全局设置面板硬绑定；它必须是会话级状态

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| 新会话继承最近目录 | 用户新建会话，且存在最近一次有效 workspace | 新会话自动继承该 workspace root，用户可稍后改目录 | 若最近目录已失效，则降级为未绑定状态 |
| 首次安装无历史目录 | 用户首次安装 App 后新建会话 | 会话创建成功，但标记为未绑定 workspace | 依赖 workspace 的能力显示绑定入口，而非直接失败 |
| 新会话手动选目录 | 用户通过目录选择器挑选文件夹 | 会话保存所选目录，并立即作为 cwd / 项目上下文根目录 | 若目录校验失败，阻止保存并显示原因 |
| 打开旧会话无工作目录 | 旧 Session 的 `workspacePath` 为空 | Workspace 显示“需要绑定工作目录”的提示态；依赖 workspace 的能力不可直接执行 | 提供“使用最近目录（若有）”与“选择文件夹”入口 |
| 打开旧会话目录失效 | `workspacePath` 指向已删除或无访问权限目录 | 显示目录失效状态，Agent 不配置为该目录 | 提示重新选择目录并在修复后恢复正常 |
| Slash Skill / 项目级 Skill 判断 | skill `baseDir` 位于会话 workspace 内 | 归类为 project skill，相关解析使用会话 workspace root | 若会话无有效 workspace，则不按 project 目录推断 |
| Agent 发起文件操作 | Session 已绑定有效 workspace | `cwd` 与相关上下文都落在会话 workspace root | N/A |
| 未绑定会话触发目录能力 | Session 无有效 workspace，用户发送需要文件/终端/项目上下文的任务 | UI 先要求绑定目录或显式进入受限模式 | 不允许继续静默回退到根目录 |

</frozen-after-approval>

## Code Map

- `SwiftWork/Models/SwiftData/Session.swift` -- 会话级 workspace root 的持久化模型入口；需要承载“已设置 / 未绑定 / 待修复”相关状态所需字段或约束
- `SwiftWork/ViewModels/SessionViewModel.swift` -- 新建会话、切换会话、更新会话工作目录的入口
- `SwiftWork/Views/Sidebar/SidebarView.swift` -- 新建会话与切换目录的用户入口最接近这里
- `SwiftWork/Views/Workspace/WorkspaceView.swift` -- 无有效 workspace 时的阻塞态、修复入口、Agent 重配置触发点
- `SwiftWork/SDKIntegration/AgentBridge.swift` -- AgentOptions.cwd、Slash Skill ToolContext.cwd 的真实来源
- `SwiftWork/Models/UI/SkillSource.swift` -- 项目级 skill 与用户级 skill 的归类不能再依赖进程 cwd
- `SwiftWork/Services/` 下新增 workspace 解析/校验服务 -- 统一做最近 workspace 记录、路径标准化、存在性检查、访问性判断与恢复逻辑
- `SwiftWorkTests/ViewModels/SessionViewModelTests.swift` -- 覆盖会话创建、迁移与目录更新行为
- `SwiftWorkTests/SDKIntegration/AgentBridgeTests.swift` -- 覆盖会话 workspace root 传递给 Agent 与 Slash Skill 的行为
- `SwiftWorkTests/Views/Workspace/` 相关测试 -- 覆盖无目录/失效目录阻塞态与修复路径

## Tasks & Acceptance

**Execution:**
- [x] `SwiftWork/Services/` 下新增 workspace 解析服务 -- 统一封装“最近有效 workspace 继承 / 手动选择目录 / 路径标准化 / 可访问性校验 / 失效判定” -- 避免 SessionViewModel、WorkspaceView、AgentBridge 各自猜目录
- [x] `SwiftWork/Models/SwiftData/Session.swift` -- 补齐会话工作目录所需的数据表达，并定义旧数据迁移策略 -- 让 `nil` workspacePath 不再是长期合法稳定态，同时支持未绑定会话
- [x] `SwiftWork/ViewModels/SessionViewModel.swift` -- 新建会话优先继承最近有效 workspace；没有历史 workspace 时创建未绑定会话；提供更新/修复 workspace 的方法 -- 兼顾桌面 App 冷启动体验与正确性
- [x] `SwiftWork/Views/Sidebar/SidebarView.swift` -- 为新会话与现有会话暴露目录选择/切换入口 -- 让用户能主动控制 workspace root
- [x] `SwiftWork/Views/Workspace/WorkspaceView.swift` -- 增加“未绑定工作目录 / 目录失效”状态与修复操作；对依赖 workspace 的能力给出前置提示 -- 把失败前移到可理解的 UI
- [x] `SwiftWork/SDKIntegration/AgentBridge.swift` -- 所有 `cwd` 相关配置统一改用已解析的会话 workspace root；当会话未绑定 workspace 时，不再静默回退到进程 cwd，并明确降级相关能力 -- 保证 Agent、Slash Skill 与文件工具上下文一致
- [x] `SwiftWork/Models/UI/SkillSource.swift` -- 改为基于会话/活动 workspace root 判断 project skill -- 避免 skill 分组仍然跟错目录
- [x] `SwiftWorkTests/...` -- 为新会话继承最近目录、首次安装未绑定会话、旧会话迁移、目录失效阻塞、Agent cwd 传递、skill source 归类补测试 -- 防止此类回归

**Acceptance Criteria:**
- Given 用户已有最近一次有效 workspace，when 新建会话，then 新会话默认继承该目录，而不是依赖进程 cwd
- Given 用户首次安装 App 或没有任何历史 workspace，when 新建会话，then 会话可以被创建但处于未绑定状态，且不会静默落到根目录
- Given 旧会话没有 `workspacePath`，when 用户打开该会话，then UI 显示可操作的绑定工作目录入口，并且在绑定前不会启动依赖该目录的 Agent 上下文
- Given 会话目录已失效或不可访问，when 用户进入 Workspace，then UI 明确显示失效状态并要求修复，而不是在后续文件操作时才报权限错误
- Given Session 具有有效 workspace root，when Agent 发起普通工具调用或 Slash Skill 调用，then `cwd` 与相关上下文都使用该会话目录
- Given Session 处于未绑定 workspace 状态，when 用户触发文件、终端或 project-scope skill 相关任务，then UI 先要求绑定目录或进入明确的受限路径，而不是继续假装这些能力可用
- Given 某个 skill 的 `baseDir` 位于会话 workspace root 下，when UI 对 skill 做来源归类，then 它被判定为 project skill，而不是继续按进程 cwd 判断
- Given 用户修复了失效目录，when Workspace 重新配置 Agent，then 后续工具调用恢复正常且不需要重新创建会话

## Spec Change Log

## Design Notes

### 借鉴 OpenWork 的部分

OpenWork 没有“默认先落到根目录，再在权限报错后补救”的现成方案；它采用的是更前置的设计：

1. workspace root 是显式输入，而不是隐式依赖进程 cwd
2. 运行时按 workspace 切换目录，而不是把所有会话绑到同一个根
3. 文件与工具操作都约束在 workspace 作用域内

SwiftWork 最应该借的是这个方向，而不是复刻它的 sandbox/docker 细节。

### 推荐状态机

把会话工作目录视为一个小型状态机即可：

- `ready`：目录存在且可用，可正常配置 Agent
- `unbound`：会话尚未绑定目录，允许存在，但 workspace 相关能力必须被前置拦截
- `needsRepair`：目录路径失效、移动或不可访问，必须重选

UI 与 AgentBridge 都只消费解析后的状态，不直接猜测路径。

### 新会话为什么不该强制先选目录

安装后的桌面 App 并没有天然可信的“当前项目目录”，所以“每次先弹目录选择器”会把正确性问题变成高频打扰。更合理的顺序是：

1. 有最近有效 workspace 时直接继承，覆盖大多数持续工作流
2. 没有历史时允许先创建会话，避免首次启动就被模态流程打断
3. 只有当用户真的触发 workspace 相关能力时，才要求补齐目录

这样既修掉错误 cwd，又不会把每个新会话都变成一次目录配置向导。

### 为什么不继续用进程 cwd 兜底

进程 cwd 只代表“应用从哪里被启动”，不代表“当前会话属于哪个项目”。一旦未来支持多个 workspace、Finder 打开的目录、外部项目或 project-scope MCP/Skill 配置，进程 cwd 会天然与会话上下文脱节；因此它最多只能作为“创建新会话时的默认候选值”，不能再作为运行时真相来源。

## Verification

**Commands:**
- `swift build` -- expected: 构建通过，新增 workspace 解析与 UI 改动无编译错误
- `swift test` -- expected: 现有测试通过，且新增会话目录/Agent cwd/skill source 相关测试通过

**Manual checks (if no CLI):**
- 已有最近 workspace 时创建新会话，确认默认继承该目录且文件操作都落在它下面
- 首次安装或清空历史后创建新会话，确认不会被强制弹目录选择器，但触发文件/终端相关能力时会被要求绑定目录
- 打开一个 `workspacePath == nil` 的旧会话，确认看到绑定目录阻塞态或未绑定提示，而不是直接进入错误 cwd
- 让会话目录失效后重新进入该会话，确认出现修复入口而不是在“查看当前目录/创建文件”时才失败

## Suggested Review Order

**Workspace state model**

- 先看工作目录状态机与 bookmark/兜底目录规则。
  [`SessionWorkspaceService.swift:3`](../../SwiftWork/Services/SessionWorkspaceService.swift#L3)

- 这里决定旧路径、bookmark 恢复和 repair 判定。
  [`SessionWorkspaceService.swift:58`](../../SwiftWork/Services/SessionWorkspaceService.swift#L58)

- 这里把状态映射成实际 cwd，避免回退到进程 cwd。
  [`SessionWorkspaceService.swift:97`](../../SwiftWork/Services/SessionWorkspaceService.swift#L97)

**Session lifecycle**

- 新会话继承最近有效 workspace，否则保持 unbound。
  [`SessionViewModel.swift:46`](../../SwiftWork/ViewModels/SessionViewModel.swift#L46)

- 目录绑定与保存失败回滚都在这里收口。
  [`SessionViewModel.swift:120`](../../SwiftWork/ViewModels/SessionViewModel.swift#L120)

- 旧会话可直接继承最近目录完成修复。
  [`SessionViewModel.swift:142`](../../SwiftWork/ViewModels/SessionViewModel.swift#L142)

**Workspace UI gating**

- 先看 Workspace 顶部 banner 如何表达 unbound/repair 状态。
  [`WorkspaceView.swift:133`](../../SwiftWork/Views/Workspace/WorkspaceView.swift#L133)

- 当前会话改目录后，这里会即时重配 Agent 上下文。
  [`WorkspaceView.swift:121`](../../SwiftWork/Views/Workspace/WorkspaceView.swift#L121)

- 这里是刷新 workspace 状态并重建 Agent 的入口。
  [`WorkspaceView.swift:175`](../../SwiftWork/Views/Workspace/WorkspaceView.swift#L175)

- 用户在 Workspace 内手动选择目录的交互在这里。
  [`WorkspaceView.swift:261`](../../SwiftWork/Views/Workspace/WorkspaceView.swift#L261)

**Agent and skill scoping**

- Agent 配置现在显式接收 workspace state，而不是猜 cwd。
  [`AgentBridge.swift:183`](../../SwiftWork/SDKIntegration/AgentBridge.swift#L183)

- 这里限制 unbound/repair 状态下可用工具集合。
  [`AgentBridge.swift:693`](../../SwiftWork/SDKIntegration/AgentBridge.swift#L693)

- 这里定义哪些 skill 必须绑定 workspace 才能使用。
  [`AgentBridge.swift:710`](../../SwiftWork/SDKIntegration/AgentBridge.swift#L710)

- 这里把项目级 skill 归类从进程 cwd 改到会话 workspace。
  [`SkillSource.swift:15`](../../SwiftWork/Models/UI/SkillSource.swift#L15)

**Regression coverage**

- 这个测试覆盖 bookmark 路径优先于陈旧存储路径。
  [`SessionWorkspaceServiceTests.swift:38`](../../SwiftWorkTests/Services/SessionWorkspaceServiceTests.swift#L38)

- 这个测试覆盖 workspace 更新失败时保持原绑定。
  [`SessionViewModelTests.swift:216`](../../SwiftWorkTests/ViewModels/SessionViewModelTests.swift#L216)
