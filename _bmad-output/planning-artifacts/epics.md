---
stepsCompleted:
  - step-01-validate-prerequisites
  - step-02-design-epics
  - step-03-create-stories
  - step-04-final-validation
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
---

# SwiftWork - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for SwiftWork, decomposing the requirements from the PRD and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

- FR1: 用户可以创建新的 Agent 会话
- FR2: 用户可以在会话列表中查看所有历史会话（按时间排序）
- FR3: 用户可以在会话之间切换，切换时保留每个会话的事件历史
- FR4: 用户可以删除会话及其所有关联数据
- FR5: 用户可以重命名会话以方便识别
- FR6: 系统可以在应用重启后恢复上次的会话状态和窗口位置
- FR7: 系统可以将 SDK 产生的所有事件类型实时渲染为对应的 UI 组件
- FR8: 用户可以看到 Agent 的流式文本输出（逐字显示）
- FR9: 用户可以看到 Agent 的思考状态指示（Thinking 动画）
- FR10: 用户可以看到会话的最终结果摘要（包含状态、耗时、Token 用量）
- FR11: 系统可以用视觉方式区分不同类型的事件（用户消息、工具调用、工具结果、系统事件等）
- FR12: 用户可以看到错误事件的突出显示（红色高亮、错误详情）
- FR13: 系统可以在事件流过大时保持流畅滚动（通过性能优化手段确保大量事件时不卡顿）
- FR14: 用户可以看到每次工具调用的结构化卡片（工具名、输入参数、执行状态）
- FR15: 用户可以看到工具执行的实时进度（旋转指示器、已用时间）
- FR16: 用户可以展开/折叠工具调用卡片查看详细参数和完整结果
- FR17: 用户可以看到工具执行结果的摘要（成功/失败状态、截断的内容预览）
- FR18: 用户可以通过点击工具调用卡片在 Inspector Panel 中查看完整详情
- FR19: 系统可以对不同类型的工具（文件操作、Shell 命令、搜索等）展示差异化的卡片样式
- FR20: 用户可以在工具调用需要审批时收到原生弹窗通知
- FR21: 用户可以在权限弹窗中查看工具名称、操作描述和具体参数
- FR22: 用户可以选择"允许一次"（Allow Once）来授权当前操作
- FR23: 用户可以选择"始终允许"（Always Allow）来授权同类操作
- FR24: 用户可以拒绝（Deny）操作并附带原因
- FR25: 用户可以在设置中查看和修改已授权的权限规则列表
- FR26: 用户可以在设置中选择全局权限模式（自动批准、手动审批等）
- FR27: 用户可以输入和保存 LLM API Key
- FR28: 用户可以选择 Agent 使用的模型
- FR29: 用户可以在输入框中编写消息发送给 Agent
- FR30: 用户可以在 Agent 执行过程中发送追加消息
- FR31: 用户可以中断正在执行的 Agent 任务
- FR32: 用户可以在 InputBar 中使用 Shift+Enter 换行，Enter 发送
- FR34: 用户可以看到 Agent 的任务拆解计划（Plan 步骤列表）
- FR35: 用户可以看到每个计划步骤的执行状态（待执行、执行中、已完成）
- FR36: 用户可以看到计划步骤之间的依赖关系
- FR37: 用户可以通过右侧面板查看选中事件的完整详细信息（JSON 格式、耗时、Token 用量）
- FR38: 用户可以在 Debug Panel 中查看原始事件流（未经 UI 处理的 SDK 原始数据）
- FR39: 用户可以在 Debug Panel 中查看 Token 消耗的实时统计
- FR40: 用户可以在 Debug Panel 中查看工具执行的详细日志
- FR41: 用户可以展开/折叠 Inspector Panel
- FR42: 系统可以正确渲染 Agent 输出中的 Markdown 内容（标题、列表、代码块、表格、粗体/斜体）
- FR43: 系统可以对代码块进行语法高亮
- FR44: 系统可以折叠/展开长文本内容
- FR45: 用户可以通过标准 macOS 菜单栏操作应用（File/Edit/View/Window/Help）
- FR46: 用户可以通过键盘快捷键执行常用操作（Cmd+N 新建会话、Cmd+W 关闭等）
- FR47: 系统可以在 Dock 栏显示未读会话数量 badge
- FR48: 用户可以在应用设置中管理 API Key、模型选择和权限配置
- FR49: 系统可以在首次启动时引导用户完成 API Key 配置

### NonFunctional Requirements

- NFR1: 应用冷启动到可交互状态不超过 2 秒（在 Apple Silicon Mac 上）
- NFR2: SDK 事件从产出到 UI 渲染完成的端到端延迟不超过 100ms
- NFR3: 流式文本渲染的逐字输出间隔不超过 50ms，无可见卡顿
- NFR4: 100+ 轮会话的事件列表滚动帧率不低于 60fps（需虚拟化渲染）
- NFR5: 会话切换的加载时间不超过 500ms
- NFR6: LLM API Key 必须通过 macOS Keychain 存储，禁止明文持久化
- NFR7: 所有与 LLM API 的通信必须通过 HTTPS 加密
- NFR8: 本地会话数据存储必须使用 macOS 原生文件权限保护
- NFR9: Tool Result 中的敏感信息（API Key、密码）必须在 UI 中默认遮罩，用户可手动展开
- NFR10: 权限审批操作必须记录审计日志（工具名、操作内容、用户决策、时间戳）
- NFR11: 应用在 SDK 事件流异常断开时不得崩溃，必须显示友好的连接中断提示
- NFR12: 应用在长时间运行（8小时+）后无内存泄漏，内存占用增长不超过 20%
- NFR13: 单个会话包含 1000+ 事件时，应用仍可正常操作，无 UI 冻结
- NFR14: 应用异常退出后重启，可恢复至最近的会话状态
- NFR15: 支持 macOS 14 (Sonoma) 及以上版本
- NFR16: Apple Silicon (ARM64) 原生运行，Intel Mac 通过 Rosetta 兼容
- NFR17: 完整支持 macOS 深色模式和浅色模式，跟随系统设置自动切换
- NFR18: 支持标准 macOS 窗口管理行为（全屏、分屏、Stage Manager）
- NFR19: 会话数据和事件历史通过本地持久化机制持久化，应用重启后可恢复
- NFR20: 用户配置（API Key、模型选择、权限规则）通过系统安全存储和配置管理机制持久化
- NFR21: 窗口位置和 Inspector 展开状态在应用重启后保持

### Additional Requirements

- ARCH-1: 使用 Xcode macOS App 模板（SwiftUI Lifecycle）作为 Starter Template，Epic 1 Story 1 必须是项目初始化
- ARCH-2: Swift 6.1+，利用 strict concurrency；使用 `@Observable`（非 `ObservableObject`）
- ARCH-3: SwiftData 作为持久化引擎，4 个模型：Session、Event、PermissionRule、AppConfiguration
- ARCH-4: 事件存储策略——Event 使用 `rawData: Data` 存储 SDK 事件完整 JSON，append-only，分页加载大会话
- ARCH-5: AgentBridge 封装 Agent 创建/配置，暴露 EventPublisher；事件流通过 AsyncStream<SDKMessage>
- ARCH-6: 权限引擎——PermissionEngine 评估工具调用权限，支持 globalMode、持久化 rules、会话级 sessionOverrides
- ARCH-7: 错误处理策略——SDK 事件流断开显示提示、API 限流显示错误卡片、未知事件用 `@unknown default` 降级
- ARCH-8: 状态管理使用 Observation 框架（`@Observable`），所有 ViewModel 遵循
- ARCH-9: ToolRenderable 协议 + ToolRendererRegistry 实现可扩展工具卡片渲染
- ARCH-10: Timeline 渲染使用 LazyVStack，超 500 事件启用虚拟化窗口
- ARCH-11: API Key 通过 KeychainManager 存取，禁止明文存储
- ARCH-12: 分层架构边界——Views 只依赖 ViewModel 和 Models/UI，不直接引用 SDKIntegration 或 SwiftData Models
- ARCH-13: SPM 依赖：open-agent-sdk-swift、swift-markdown、Splash、Sparkle 2.x
- ARCH-14: GitHub Actions CI/CD（Xcode build + test + archive）
- ARCH-15: 跨组件依赖链：SDKMessage → EventMapper → TimelineView（核心数据流）

### UX Design Requirements

_No UX Design document available._

### FR Coverage Map

FR1: Epic 1 - 创建新的 Agent 会话
FR2: Epic 1 - 查看所有历史会话列表
FR3: Epic 1 - 会话之间切换并保留事件历史
FR4: Epic 3 - 删除会话及其关联数据
FR5: Epic 3 - 重命名会话
FR6: Epic 1 - 应用重启后恢复会话状态和窗口位置
FR7: Epic 1 - SDK 事件实时渲染为 UI 组件
FR8: Epic 1 - Agent 流式文本输出（逐字显示）
FR9: Epic 1 - Agent 思考状态指示（Thinking 动画）
FR10: Epic 1 - 会话最终结果摘要
FR11: Epic 2 - 视觉方式区分不同类型事件
FR12: Epic 2 - 错误事件突出显示
FR13: Epic 2 - 大量事件时保持流畅滚动
FR14: Epic 2 - 工具调用结构化卡片
FR15: Epic 2 - 工具执行实时进度
FR16: Epic 2 - 展开/折叠工具调用卡片
FR17: Epic 2 - 工具执行结果摘要
FR18: Epic 2 - 点击工具卡片查看 Inspector 详情
FR19: Epic 2 - 不同工具类型差异化卡片样式
FR20: Epic 3 - 工具调用审批原生弹窗
FR21: Epic 3 - 权限弹窗显示工具信息
FR22: Epic 3 - Allow Once 授权
FR23: Epic 3 - Always Allow 授权
FR24: Epic 3 - Deny 拒绝操作
FR25: Epic 3 - 设置中管理权限规则
FR26: Epic 3 - 全局权限模式选择
FR27: Epic 1 - 输入和保存 API Key
FR28: Epic 1 - 选择 Agent 模型
FR29: Epic 1 - 输入框发送消息给 Agent
FR30: Epic 3 - Agent 执行中发送追加消息
FR31: Epic 1 - 中断 Agent 任务
FR32: Epic 3 - InputBar 快捷键（Shift+Enter 换行）
FR34: Epic 3 - 任务拆解计划可视化
FR35: Epic 3 - 计划步骤执行状态
FR36: Epic 3 - 计划步骤依赖关系
FR37: Epic 3 - Inspector Panel 查看事件详情
FR38: Epic 4 - Debug Panel 原始事件流
FR39: Epic 4 - Debug Panel Token 消耗统计
FR40: Epic 4 - Debug Panel 工具执行日志
FR41: Epic 3 - Inspector Panel 展开/折叠
FR42: Epic 2 - Markdown 内容渲染
FR43: Epic 2 - 代码块语法高亮
FR44: Epic 2 - 长文本折叠/展开
FR45: Epic 4 - macOS 菜单栏操作
FR46: Epic 4 - 键盘快捷键
FR47: Epic 4 - Dock Badge 未读会话数
FR48: Epic 4 - 应用设置管理
FR49: Epic 1 - 首次启动 API Key 引导

## Epic List

### Epic 1: 首次启动与基础交互（SDK→UI 闭环）
用户可以打开应用、配置 API Key、创建会话、发送消息给 Agent、看到事件流实时渲染——验证"事件驱动 UI"核心假设。
**FRs covered:** FR1, FR2, FR3, FR6, FR7, FR8, FR9, FR10, FR27, FR28, FR29, FR31, FR49
**ARCHs covered:** ARCH-1, ARCH-2, ARCH-3, ARCH-4, ARCH-5, ARCH-8, ARCH-11, ARCH-12, ARCH-13, ARCH-15

### Epic 2: Agent 执行可视化（Tool Card 体验）
用户可以看到 Agent 每一步操作的结构化可视化——Tool 调用卡片、执行进度、结果摘要、Markdown 渲染——从"一坨文本"变为"可理解的执行过程"。
**FRs covered:** FR11, FR12, FR13, FR14, FR15, FR16, FR17, FR18, FR19, FR42, FR43, FR44
**ARCHs covered:** ARCH-9, ARCH-10

### Epic 3: 权限控制与会话管理（用户掌控力）
用户可以审批/拒绝 Agent 的操作、管理会话列表（删除/重命名）、查看执行计划、通过 Inspector 检查事件详情——获得对 Agent 行为的完整控制力。
**FRs covered:** FR4, FR5, FR20, FR21, FR22, FR23, FR24, FR25, FR26, FR30, FR32, FR34, FR35, FR36, FR37, FR41
**ARCHs covered:** ARCH-6, ARCH-7

### Epic 4: 调试面板与应用外壳（开发者工具体验）
用户可以调试 Agent 行为（原始事件流、Token 统计、工具日志）、管理应用设置（API Key、模型、权限）、使用 macOS 原生集成（菜单栏、快捷键、Dock Badge）。
**FRs covered:** FR38, FR39, FR40, FR45, FR46, FR47, FR48
**ARCHs covered:** ARCH-14

## Epic 1: 首次启动与基础交互（SDK→UI 闭环）

用户可以打开应用、配置 API Key、创建会话、发送消息给 Agent、看到事件流实时渲染——验证"事件驱动 UI"核心假设。

### Story 1.1: 项目初始化与数据层搭建

As a 开发者,
I want 创建 Xcode 项目并建立完整的数据层和项目结构,
So that 后续 Story 可以在此基础上构建 UI 和 SDK 集成功能。

**Acceptance Criteria:**

**Given** 开发者打开项目目录
**When** 使用 Xcode 打开 SwiftWork.xcodeproj
**Then** 项目使用 SwiftUI Lifecycle，最低部署目标为 macOS 14 (Sonoma)
**And** 通过 SPM 添加了 open-agent-sdk-swift、swift-markdown、Splash、Sparkle 2.x 依赖
**And** 目录结构符合 Architecture Decision 11（App/、Views/、ViewModels/、SDKIntegration/、Models/、Services/、Utils/）
**And** SwiftData 模型已定义：Session（id, title, createdAt, updatedAt, workspacePath, events）、Event（id, sessionID, eventType, rawData, timestamp, order）、PermissionRule（id, toolName, pattern, decision, createdAt）、AppConfiguration（id, key, value, updatedAt）
**And** App 入口 SwiftWorkApp.swift 使用 NavigationSplitView 布局（Sidebar + Workspace）
**And** 项目可通过 `swift build` 成功编译

**FRs:** — (基础设施)
**ARCHs:** ARCH-1, ARCH-2, ARCH-3, ARCH-4, ARCH-13

### Story 1.2: 首次启动引导与 Agent 配置

As a 新用户,
I want 首次打开应用时被引导完成 API Key 配置和模型选择,
So that 我可以立即开始使用 Agent 而不需要手动寻找设置入口。

**Acceptance Criteria:**

**Given** 用户首次启动 SwiftWork
**When** 应用检测到未配置 API Key
**Then** 显示 WelcomeView 引导页面，包含 API Key 输入框和模型选择器
**And** 用户输入 API Key 后点击保存，Key 通过 KeychainManager 存入 macOS Keychain（NFR6）
**And** 用户可以从下拉列表中选择 Agent 使用的模型
**And** 配置完成后自动跳转到主界面
**And** 非首次启动时直接显示主界面，跳过引导

**Given** 用户已完成首次配置
**When** 应用启动
**Then** 自动从 Keychain 读取 API Key 并配置 Agent
**And** 应用启动到可交互状态不超过 2 秒（NFR1）

**FRs:** FR27, FR28, FR49
**ARCHs:** ARCH-11

### Story 1.3: 会话管理与 Sidebar

As a 用户,
I want 在左侧 Sidebar 中创建、查看和切换会话,
So that 我可以管理多个任务会话并在它们之间快速切换。

**Acceptance Criteria:**

**Given** 用户打开应用
**When** 查看 Sidebar
**Then** 显示所有历史会话列表，按 updatedAt 降序排列（FR2）

**Given** 用户点击 Sidebar 中的 "+" 按钮
**When** 创建新会话
**Then** 自动生成新会话（标题为"新会话"或基于首条消息自动生成），Sidebar 列表立即更新（FR1）
**And** 新会话通过 SwiftData 持久化（NFR19）

**Given** 用户在会话列表中
**When** 点击某个会话
**Then** 主工作区切换到该会话，显示其事件历史，之前会话的事件保留在内存中（FR3）
**And** 会话切换加载时间不超过 500ms（NFR5）

**FRs:** FR1, FR2, FR3
**ARCHs:** ARCH-8, ARCH-12

### Story 1.4: 消息输入与 Agent 执行

As a 用户,
I want 在输入框中输入消息并发送给 Agent，以及中断正在执行的任务,
So that 我可以与 Agent 交互并控制执行过程。

**Acceptance Criteria:**

**Given** 用户在 InputBarView 中输入消息
**When** 按 Enter 键
**Then** 消息发送给 Agent，InputBar 清空，Timeline 开始显示事件流（FR29）
**And** 消息作为 `.userMessage` 事件渲染在 Timeline 顶部

**Given** Agent 正在执行任务
**When** 用户点击 InputBar 旁的停止按钮
**Then** Agent 任务被取消（Task.cancel()），AsyncStream 正确清理（FR31）
**And** Timeline 显示"任务已取消"的状态提示

**Given** Agent 执行过程中发生错误
**When** SDK 事件流断开或 API 返回错误
**Then** 应用不崩溃，在 Timeline 中显示友好的错误提示（NFR11）
**And** 用户可以重新发送消息

**FRs:** FR29, FR31
**ARCHs:** ARCH-5, ARCH-7, ARCH-15

### Story 1.5: Timeline 事件流渲染

As a 用户,
I want 看到 Agent 的实时事件流以文本形式渲染在 Timeline 中,
So that 我可以实时观察 Agent 的思考和执行过程。

**Acceptance Criteria:**

**Given** 用户发送消息后 Agent 开始响应
**When** SDK 产生各类 SDKMessage 事件
**Then** EventMapper 将每个 SDKMessage 映射为 AgentEvent，TimelineView 实时渲染（FR7）
**And** 事件渲染延迟不超过 100ms（NFR2）

**Given** Agent 正在生成文本响应
**When** 接收到 `.partialMessage` 事件
**Then** 文本以逐字方式流式显示，无可见卡顿（FR8, NFR3）

**Given** Agent 正在处理请求
**When** 接收到思考相关事件
**Then** 显示 Thinking 动画指示器（旋转动画 + "思考中..." 文本）（FR9）

**Given** Agent 完成任务
**When** 接收到 `.result` 事件
**Then** Timeline 底部显示结果摘要卡片，包含状态（成功/失败）、耗时、Token 用量（FR10）

**Given** 接收到未知的 SDKMessage 类型
**When** `@unknown default` 触发
**Then** 渲染为"未知事件"占位卡片，应用不崩溃

**FRs:** FR7, FR8, FR9, FR10
**ARCHs:** ARCH-5, ARCH-7, ARCH-8, ARCH-15

### Story 1.6: 应用状态恢复

As a 用户,
I want 应用重启后恢复上次的会话状态和窗口布局,
So that 我不需要每次重新选择会话和调整窗口。

**Acceptance Criteria:**

**Given** 用户正在使用某个会话
**When** 退出并重新打开应用
**Then** 自动选中上次的活跃会话，Sidebar 高亮该会话（FR6）
**And** 窗口位置、大小与上次关闭时一致（NFR21）
**And** Inspector Panel 的展开/折叠状态保持（NFR21）

**Given** 应用异常退出
**When** 重新打开应用
**Then** 恢复至最近的会话状态（NFR14）
**And** 已持久化的事件历史完整保留

**FRs:** FR6
**ARCHs:** — (NFR14, NFR19, NFR21)

---

## Epic 2: Agent 执行可视化（Tool Card 体验）

用户可以看到 Agent 每一步操作的结构化可视化——Tool 调用卡片、执行进度、结果摘要、Markdown 渲染——从"一坨文本"变为"可理解的执行过程"。

### Story 2.1: Tool 可视化基础架构

As a 开发者,
I want 建立可扩展的工具卡片渲染系统,
So that 每种工具类型可以注册自己的 SwiftUI 渲染器，新增工具类型时无需修改核心 Timeline 逻辑。

**Acceptance Criteria:**

**Given** 项目已初始化
**When** 实现 ToolRenderable 协议和 ToolRendererRegistry
**Then** 协议定义 `toolName`、`body(content:)` 方法
**And** Registry 支持注册和查找 ToolRenderable 实现
**And** TimelineView 通过 Registry 查找渲染器，未注册的工具使用默认渲染

**FRs:** FR14 (基础), FR19 (基础)
**ARCHs:** ARCH-9

### Story 2.2: Tool Card 完整体验

As a 用户,
I want 看到 Tool 调用的结构化卡片，包括参数、进度、结果，并可展开查看详情,
So that 我可以清晰理解 Agent 执行了什么操作以及结果如何。

**Acceptance Criteria:**

**Given** Agent 调用了某个工具
**When** Timeline 渲染 `.toolUse` 事件
**Then** 显示 ToolCallView 卡片，包含工具名（如 Bash、FileEdit）、输入参数摘要、执行状态指示器（FR14）

**Given** 工具正在执行中
**When** 接收到 `.toolProgress` 事件
**Then** 卡片显示旋转进度指示器和已用时间（FR15）

**Given** 工具执行完成
**When** 接收到 `.toolResult` 事件
**Then** ToolResultView 显示成功（绿色）/ 失败（红色）状态和结果摘要（截断预览）（FR17）
**And** 工具调用卡片默认折叠显示摘要，点击展开显示完整参数和结果（FR16）

**Given** 用户点击某个工具调用卡片
**When** 卡片被选中
**Then** Inspector Panel 展开显示该事件的完整详情（FR18）

**FRs:** FR14, FR15, FR16, FR17, FR18
**ARCHs:** ARCH-9

### Story 2.3: 事件类型视觉系统

As a 用户,
I want 通过颜色和图标直观区分不同类型的事件和工具,
So that 我可以快速扫描 Timeline 理解 Agent 的执行状态。

**Acceptance Criteria:**

**Given** Timeline 中有多种类型的事件
**When** 渲染事件列表
**Then** 不同事件类型有差异化的视觉样式：用户消息（蓝色左侧气泡）、工具调用（灰色卡片）、工具结果（绿色/红色卡片）、系统事件（浅灰色）、错误（红色高亮）（FR11, FR12）

**Given** 工具调用属于不同类型（文件操作、Shell 命令、搜索等）
**When** 渲染 ToolCallView
**Then** 不同工具类型展示差异化的卡片样式：Bash（终端图标）、FileEdit（文件图标）、Search（搜索图标）（FR19）

**Given** 事件包含错误
**When** 渲染错误事件
**Then** 错误卡片使用红色边框和背景高亮，显示错误详情（FR12）

**FRs:** FR11, FR12, FR19
**ARCHs:** — (Color+Theme.swift)

### Story 2.4: Markdown 渲染与代码高亮

As a 用户,
I want Agent 的文本输出能正确渲染 Markdown 和代码高亮,
So that 我可以舒适地阅读 Agent 的分析和代码建议。

**Acceptance Criteria:**

**Given** Agent 输出包含 Markdown 内容
**When** Timeline 渲染文本事件
**Then** MarkdownRenderer 正确渲染标题（H1-H3）、列表、粗体/斜体、行内代码、链接、表格（FR42）

**Given** Agent 输出包含代码块
**When** 渲染代码块
**Then** CodeHighlighter 使用 Splash 对代码进行语法高亮，支持常见语言（Swift、Python、JavaScript、Bash）（FR43）

**Given** 事件内容超过一定长度
**When** 渲染长文本
**Then** 默认折叠显示前 N 行，点击"展开"显示完整内容（FR44）

**FRs:** FR42, FR43, FR44
**ARCHs:** — (swift-markdown, Splash)

### Story 2.5: Timeline 性能优化

As a 用户,
I want 在长时间会话中 Timeline 依然保持流畅滚动,
So that 我不会因为事件数量增多而体验到卡顿。

**Acceptance Criteria:**

**Given** 会话包含 500+ 个事件
**When** 用户滚动 Timeline
**Then** 使用 LazyVStack 懒加载渲染，滚动帧率不低于 60fps（NFR4, FR13）
**And** 空闲内存占用不超过 100MB，活跃内存不超过 300MB

**Given** 会话包含 1000+ 个事件
**When** 加载会话
**Then** 通过分页加载和虚拟化窗口策略，UI 不冻结（NFR13）
**And** 仅渲染可视区域 ± buffer 范围内的事件

**Given** 长时间运行会话（8小时+）
**When** 持续使用
**Then** 无内存泄漏，内存占用增长不超过 20%（NFR12）

**FRs:** FR13
**ARCHs:** ARCH-10

---

## Epic 3: 权限控制与会话管理（用户掌控力）

用户可以审批/拒绝 Agent 的操作、管理会话列表（删除/重命名）、查看执行计划、通过 Inspector 检查事件详情——获得对 Agent 行为的完整控制力。

### Story 3.1: 权限系统实现

As a 用户,
I want Agent 执行需要审批的操作时弹出原生权限对话框,
So that 我可以审查并决定是否允许 Agent 执行该操作。

**Acceptance Criteria:**

**Given** Agent 要执行一个需要审批的工具调用
**When** PermissionEngine 评估结果为 `.requiresApproval`
**Then** 弹出原生 macOS Sheet 对话框，显示工具名称、操作描述、具体参数（FR20, FR21）

**Given** 权限对话框弹出
**When** 用户点击 "Allow Once"
**Then** 当前工具调用被授权执行，下次同类操作仍需审批（FR22）

**Given** 权限对话框弹出
**When** 用户点击 "Always Allow"
**Then** 当前调用被授权，且该工具+模式被持久化为 PermissionRule，后续同类操作自动通过（FR23）

**Given** 权限对话框弹出
**When** 用户点击 "Deny"
**Then** 工具调用被拒绝，Agent 收到拒绝反馈，可继续执行其他任务（FR24）

**Given** 任何权限决策发生
**When** 用户做出选择
**Then** 审计日志记录工具名、操作内容、用户决策、时间戳（NFR10）

**FRs:** FR20, FR21, FR22, FR23, FR24
**ARCHs:** ARCH-6, ARCH-7

### Story 3.2: 权限配置与规则管理

As a 用户,
I want 在设置中查看和管理权限规则，以及选择全局权限模式,
So that 我可以精细化控制 Agent 的行为边界。

**Acceptance Criteria:**

**Given** 用户打开设置页面
**When** 导航到权限管理区域
**Then** 显示 PermissionRulesView，列出所有已授权的权限规则（工具名、模式、决策）（FR25）

**Given** 用户查看权限规则列表
**When** 点击某条规则并选择删除
**Then** 规则从列表和 SwiftData 中移除，后续同类操作将重新要求审批

**Given** 用户打开设置页面
**When** 查看全局权限模式选项
**Then** 可选择"自动批准"、"手动审批"、"全部拒绝"模式（FR26）
**And** 模式选择立即生效，影响后续所有工具调用的评估逻辑

**FRs:** FR25, FR26
**ARCHs:** ARCH-6

### Story 3.3: 会话管理增强

As a 用户,
I want 删除、重命名会话，以及在 Agent 执行中发送追加消息,
So that 我可以更好地组织会话并与 Agent 进行多轮交互。

**Acceptance Criteria:**

**Given** 用户在 Sidebar 中右键点击某个会话
**When** 选择"删除"
**Then** 弹出确认对话框，确认后会话及其所有关联事件从 SwiftData 中级联删除（FR4）

**Given** 用户在 Sidebar 中右键点击某个会话
**When** 选择"重命名"
**Then** 进入内联编辑模式，用户输入新名称后按 Enter 确认，标题更新（FR5）

**Given** Agent 正在执行任务
**When** 用户在 InputBar 中输入追加消息并发送
**Then** 消息追加到当前会话，Agent 在当前上下文中处理追加消息（FR30）

**Given** 用户在 InputBar 中输入
**When** 按 Shift+Enter
**Then** 插入换行而非发送消息；按 Enter 发送消息（FR32）

**FRs:** FR4, FR5, FR30, FR32

### Story 3.4: Inspector Panel

As a 用户,
I want 通过右侧面板查看选中事件的详细信息,
So that 我可以深入了解 Agent 每一步操作的完整数据。

**Acceptance Criteria:**

**Given** 用户点击 Timeline 中的任意事件
**When** 事件被选中
**Then** Inspector Panel 显示该事件的完整详情：JSON 格式的原始数据、执行耗时、Token 用量（FR37）

**Given** Inspector Panel 当前处于展开状态
**When** 用户点击 Inspector 切换按钮
**Then** Panel 折叠收起，Workspace 区域扩展到全宽（FR41）

**Given** Inspector Panel 当前处于折叠状态
**When** 用户点击切换按钮
**Then** Panel 展开，恢复之前的宽度

**FRs:** FR37, FR41

### Story 3.5: 执行计划可视化

As a 用户,
I want 看到 Agent 的任务拆解计划和执行进度,
So that 我可以理解 Agent 的工作方式和当前进展。

**Acceptance Criteria:**

**Given** Agent 生成了任务执行计划
**When** 接收到 Plan 相关事件
**Then** PlanView 显示步骤列表，每个步骤显示序号和描述（FR34）

**Given** Plan 步骤列表已渲染
**When** Agent 开始执行某个步骤
**Then** 该步骤状态变为"执行中"（显示旋转指示器），已完成步骤显示勾号（FR35）

**Given** 计划包含有依赖关系的步骤
**When** 渲染 PlanView
**Then** 通过缩进或连线方式显示步骤之间的依赖关系（FR36）

**FRs:** FR34, FR35, FR36

---

## Epic 4: 调试面板与应用外壳（开发者工具体验）

用户可以调试 Agent 行为（原始事件流、Token 统计、工具日志）、管理应用设置（API Key、模型、权限）、使用 macOS 原生集成（菜单栏、快捷键、Dock Badge）。

### Story 4.1: Debug Panel

As a SDK 评估者或问题排查者,
I want 在 Debug Panel 中查看原始事件流、Token 统计和工具日志,
So that 我可以完整审计 Agent 的每一次决策和执行细节。

**Acceptance Criteria:**

**Given** 用户打开 Debug Panel
**When** Agent 正在或已经执行任务
**Then** 显示未经 UI 处理的 SDK 原始 JSON 事件流，每条事件包含时间戳和事件类型（FR38）

**Given** Debug Panel 中的 Token 统计区域
**When** 会话包含 LLM 调用
**Then** 实时显示 Token 消耗统计：输入 Token、输出 Token、总计、估算费用（FR39）

**Given** Debug Panel 中的工具日志区域
**When** Agent 执行了工具调用
**Then** 显示每个工具的执行日志：调用时间、参数、耗时、返回状态、结果摘要（FR40）

**FRs:** FR38, FR39, FR40

### Story 4.2: 应用设置页面

As a 用户,
I want 在设置页面中管理 API Key、模型选择和权限配置,
So that 我可以随时调整 Agent 的行为和配置。

**Acceptance Criteria:**

**Given** 用户通过菜单栏或快捷键打开设置
**When** SettingsView 显示
**Then** 包含 API Key 管理区域（显示/隐藏/更新 Key）、模型选择下拉列表、权限配置入口（FR48）

**Given** 用户在设置中更新 API Key
**When** 点击保存
**Then** 新 Key 通过 KeychainManager 更新到 Keychain，下次 Agent 调用立即生效（NFR6）

**Given** 用户在设置中切换模型
**When** 选择新模型
**Then** 下次发送消息时使用新模型，当前进行中的会话不受影响

**FRs:** FR48

### Story 4.3: macOS 菜单栏与快捷键

As a macOS 用户,
I want 通过标准菜单栏和键盘快捷键操作应用,
So that 我可以高效地使用 SwiftWork 的常用功能。

**Acceptance Criteria:**

**Given** 应用运行
**When** 查看菜单栏
**Then** 显示标准 macOS 菜单结构：File（新建会话、关闭窗口）、Edit（复制、粘贴）、View（切换 Inspector、切换 Debug Panel）、Window（最小化、缩放）、Help（关于、文档）（FR45）

**Given** 用户按下 Cmd+N
**When** 在任何界面
**Then** 创建新会话并切换到该会话（FR46）

**Given** 用户按下 Cmd+W
**When** 在任何界面
**Then** 关闭当前窗口（FR46）

**Given** 用户按下 Cmd+,（逗号）
**When** 在任何界面
**Then** 打开设置页面（FR46）

**FRs:** FR45, FR46

### Story 4.4: Dock Badge 与窗口管理

As a macOS 用户,
I want 在 Dock 栏看到未读会话数，应用窗口行为符合 macOS 标准,
So that 我可以像使用其他 macOS 应用一样使用 SwiftWork。

**Acceptance Criteria:**

**Given** 有未读的 Agent 完成通知
**When** 应用不在前台
**Then** Dock 图标上显示未读会话数量 badge（FR47）

**Given** 用户调整窗口大小或位置
**When** 关闭并重新打开应用
**Then** 窗口恢复到上次的位置和大小（NFR18, NFR21）

**Given** 用户使用全屏、分屏或 Stage Manager
**When** 应用在不同窗口模式下运行
**Then** UI 正确适配，布局不变形（NFR18）

**FRs:** FR47
