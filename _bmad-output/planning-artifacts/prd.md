---
stepsCompleted:
  - step-01-init
  - step-02-discovery
  - step-02b-vision
  - step-02c-executive-summary
  - step-03-success
  - step-04-journeys
  - step-05-domain
  - step-06-innovation
  - step-07-project-type
  - step-08-scoping
  - step-09-functional
  - step-10-nonfunctional
  - step-11-polish
  - step-12-complete
inputDocuments:
  - docs/openwork-design.md
workflowType: 'prd'
documentCounts:
  briefs: 0
  research: 0
  brainstorming: 0
  projectDocs: 1
  projectContext: 0
projectType: 'greenfield'
classification:
  projectType: 'desktop_app'
  domain: 'developer_tool'
  complexity: 'medium'
  projectContext: 'greenfield'
releaseMode: 'phased'
---

# Product Requirements Document - SwiftWork

**Author:** Nick
**Date:** 2026-05-01

## Executive Summary

SwiftWork 是 [OpenWork](https://github.com/different-ai/openwork)（React + Tauri 的开源 Agent 桌面客户端）的 macOS 原生复刻版本，基于 SwiftUI 构建并深度集成 [open-agent-sdk-swift](https://github.com/terryso/open-agent-sdk-swift)。它不是另一个 ChatGPT 包装器，而是一个**事件驱动的 Agent 执行可视化平台**——让开发者看到 Agent 在做什么、为什么这样做、以及每一步的结果。

> **UI 参照**：SwiftWork 的 UI 布局和交互流程参照 OpenWork 设计，包括 Sidebar 会话列表、主工作区的 Timeline 事件流、右侧 Inspector Panel、底部 InputBar、权限审批对话框、Debug Panel 等。核心差异在于：SwiftWork 将 OpenWork 的 Web 渲染方案替换为 SwiftUI 原生组件，并将 OpenWork 基于服务端的 SSE 事件流替换为 open-agent-sdk-swift 的本地 `SDKMessage` 事件模型。

目标用户是需要与 AI Agent 协作完成代码编写、文件操作、系统管理等任务的 macOS 开发者。核心使用场景包括：代码项目的自动化修改、多步骤任务的编排执行、以及对 Agent 行为的实时审计与调试。

SwiftWork 解决的根本问题是：现有 Agent 客户端（包括 OpenWork）以聊天界面为中心，掩盖了 Agent 的执行过程。开发者需要的是**可观测性**——能看到 Tool 调用的输入输出、执行计划的拆解步骤、子任务的并行状态、以及 Hook 的触发时机。

### What Makes This Special

- **原生性能与系统集成**：OpenWork 使用 React + Tauri（Web 渲染），SwiftWork 使用 SwiftUI 原生渲染，零 WebView 开销。可直接集成 macOS 菜单栏、通知中心、Spotlight、文件系统权限。
- **SDK 事件模型即 UI 模型**：open-agent-sdk-swift 的 `SDKMessage` 枚举包含 18 种事件类型（`.toolUse`、`.toolResult`、`.toolProgress`、`.hookStarted`、`.taskStarted` 等），每一种都直接映射为一个 SwiftUI 视图组件。不是把 JSON 塞进文本气泡，而是让 Tool 成为 UI 的一等公民。
- **可解释性即产品力**：Debug Panel 不是附加功能，而是核心差异化。SDK 提供的 Hook 事件链、Task 生命周期、Token 消耗追踪让开发者能完整回溯 Agent 的每一次决策。
- **Swift 生态原生体验**：利用 Swift Concurrency（async/await、AsyncStream）处理事件流，SwiftData 管理本地持久化，Observation 框架驱动 UI 更新——整个技术栈与 Apple 平台最佳实践一致。

## Project Classification

| 维度 | 分类 |
|------|------|
| 项目类型 | Desktop App（macOS 原生） |
| 领域 | Developer Tool（开发者工具） |
| 复杂度 | Medium（中等） |
| 项目上下文 | Greenfield（绿地项目） |

## Success Criteria

### User Success

- **"Aha" 时刻**：用户第一次看到 Agent 执行 Tool 调用时，Timeline 不是显示一坨文本，而是展示为结构化的卡片——显示工具名、输入参数、执行耗时、结果摘要。用户立即感知到"这不是聊天机器人，这是执行引擎"。
- **核心完成场景**：用户在 30 秒内完成"打开应用 → 选择/创建会话 → 发送任务 → 看到 Agent 开始执行"的完整流程。首次启动到 Agent 开始响应不超过 60 秒（含 API Key 配置）。
- **信任建立**：用户能通过 Debug Panel 回溯 Agent 的每一次决策路径，包括为什么选择了某个工具、执行了什么命令、消耗了多少 Token。透明度建立信任。
- **效率提升**：对于重复性任务（代码重构、批量文件修改），用户能通过模板/历史会话一键重新执行，而非每次重新描述需求。

### Business Success

- **3 个月目标**：SwiftWork 能稳定完成 OpenWork 核心流程的复刻（会话管理、流式事件展示、权限审批、工具可视化），作为个人生产力工具日常可用。
- **6 个月目标**：开源发布，吸引 open-agent-sdk-swift 社区用户试用，获得至少 10 个有效的用户反馈。
- **关键指标**：DAU（每日活跃使用天数 > 20 天/月 = 工具已融入工作流）、会话完成率（> 80% 的会话达到 `result.success` 状态）、首次使用到第二次使用的间隔（< 3 天 = 产品有价值）。

### Technical Success

- **SDK 集成完整性**：覆盖 `SDKMessage` 全部 18 种事件类型的 UI 渲染，无遗漏
- **性能基线**：冷启动 < 2s、事件渲染延迟 < 100ms、空闲内存 < 100MB、活跃内存 < 300MB（详细指标见 Measurable Outcomes 表格和 Non-Functional Requirements 章节）

### Measurable Outcomes

| 指标 | 目标值 | 衡量方式 |
|------|--------|----------|
| 冷启动时间 | < 2s | Instruments Time Profiler |
| 事件渲染延迟 | < 100ms | 从 SDK 事件到 SwiftUI 渲染完成 |
| 内存占用（空闲） | < 100MB | Xcode Memory Graph |
| 会话完成率 | > 80% | SDK `ResultData.subtype == .success` |
| SDK 事件覆盖率 | 100%（18/18） | SDKMessage 枚举 case 覆盖 |
| 首次使用到可交互 | < 60s | 计时测试 |

## Product Scope

> 详细范围定义见 **Project Scoping & Phased Development** 章节。本节概述 MVP/Growth/Vision 的边界。

### MVP 核心假设

验证"事件驱动的原生 Agent UI 是否比聊天界面更有价值"。MVP 必须让用户完成：打开应用 → 创建会话 → 发送任务 → 看到 Agent 的结构化执行过程。

### Growth（Post-MVP）

Debug Panel、PlanView、Skills 管理、MCP 连接管理、模板系统、会话搜索、多 Agent 可视化、Hook 事件可视化。

### Vision（Future）

Agent Timeline Replay、协作模式、自动化工作流（Cron）、团队管理、插件生态、iOS/iPadOS 适配。

## User Journeys

### Journey 1: 日常开发者——"从需求到代码"

**角色**：陈明，全栈开发者，每天需要处理大量代码修改任务

**故事**：
陈明打开 SwiftWork，Sidebar 显示他之前的会话列表。他点击 "+" 创建新会话，在 InputBar 输入"重构 UserController，把所有数据库查询改成使用 Repository 模式"。

Timeline 立即开始渲染事件流：先是 `.partialMessage` 显示 Agent 正在思考，然后 `.toolUse` 卡片弹出——Agent 正在读取 `UserController.swift`。卡片上显示文件路径和读取状态，不需要展开就能看到关键信息。

接下来 Agent 连续读取了 5 个相关文件，每次都是一张结构化的 Tool Card。陈明点击其中一张卡片，右侧 Inspector Panel 展开显示完整的文件内容和读取耗时。然后 `.toolUse` 显示 Agent 开始写入修改后的文件，`.toolResult` 确认写入成功。

最终 `.result` 事件显示任务完成，Timeline 底部展示最终摘要和 Token 用量统计。陈明在 3 分钟内完成了原本需要 30 分钟的手动重构。

**揭示的能力需求**：会话管理、Timeline 事件流渲染、Tool Card 可视化、Inspector Panel、流式响应、Markdown 结果摘要

### Journey 2: 谨慎的开发者——"权限与控制"

**角色**：林薇，安全意识强的后端开发者，不允许 Agent 在未经确认的情况下执行写操作

**故事**：
林薇配置 SwiftWork 为"手动审批"模式。她让 Agent 分析并修复一个性能问题。Agent 读取了几个文件（这些操作自动通过），但当它要执行 `bash` 命令运行测试时，弹出了原生的权限对话框。

对话框清晰显示：工具名称 `Bash`、要执行的命令 `npm test -- --filter=user-service`、以及操作描述。林薇点击"Allow Once"。

Agent 继续执行，又触发了 `FileEdit` 工具要修改 `user-service.ts`。再次弹出权限对话框，这次显示要修改的文件路径和具体改动内容。林薇审查后点击"Always Allow for this file"。

任务完成后，林薇打开 Debug Panel 查看完整的执行日志，确认 Agent 没有执行任何未经授权的操作。

**揭示的能力需求**：权限系统（Allow Once / Always Allow / Deny）、权限对话框 UI、Debug Panel、操作审计日志、配置管理

### Journey 3: SDK 评估者——"五分钟体验"

**角色**：张鹏，正在评估 open-agent-sdk-swift 是否值得采用的技术负责人

**故事**：
张鹏从 GitHub 了解到 SwiftWork 是 SDK 的参考实现。他下载安装后，首次启动进入简洁的欢迎界面，输入 API Key 后立即可以开始使用。

他输入一个简单的测试任务，观察 Timeline 的行为。他注意到每一个 `SDKMessage` 事件类型都有对应的 UI 渲染——`.toolProgress` 显示旋转的加载动画和已用时间，`.toolResult` 用不同颜色区分成功和失败，`.result` 展示完整的统计信息。

他打开 Debug Panel，看到原始的 JSON 事件流和 Token 消耗的实时图表。他点击 Inspector 中的某个 Tool Call，看到完整的请求参数和响应数据。

5 分钟后，张鹏得出结论：SDK 的事件模型设计合理，文档齐全，参考实现完整——决定在团队项目中采用。

**揭示的能力需求**：首次启动引导、API Key 配置、SDK 事件类型的完整覆盖、Debug Panel 的原始数据展示、Inspector 的详细信息视图、清晰的视觉设计

### Journey 4: 问题排查者——"出了问题怎么办"

**角色**：王浩，遇到 Agent 执行异常，需要排查原因

**故事**：
王浩让 Agent 执行一个复杂任务，但中途执行失败了。Timeline 上 `.result` 事件显示红色，`subtype` 为 `errorDuringExecution`。

王浩没有慌——他点击 Timeline 上的失败标记，Inspector Panel 立即显示错误详情：哪个 Tool 调用失败、错误消息是什么、API 返回了什么。

他向下滚动 Timeline 找到失败的 `.toolResult`（红色高亮），点击展开看到完整的错误堆栈。然后他打开 Debug Panel 查看完整的事件序列，发现是 API 限流导致的失败。

王浩修改了任务描述（添加了"请分步骤执行"），重新发送，这次成功了。

**揭示的能力需求**：错误状态可视化（红色高亮）、错误详情展示、Debug Panel 事件序列回放、会话内重新提交、`result.subtype` 的多种终止状态展示

### Journey Requirements Summary

| 旅程 | 揭示的核心能力 |
|------|---------------|
| 日常开发者 | 会话管理、Timeline、Tool Card、Inspector、流式渲染 |
| 谨慎开发者 | 权限系统、权限 UI、Debug Panel、审计日志 |
| SDK 评估者 | 首次引导、事件全覆盖、Debug 原始数据、视觉设计 |
| 问题排查者 | 错误可视化、错误详情、事件回放、重新提交 |

## Domain-Specific Requirements

### 安全与隐私

- **API Key 管理**：用户的 LLM API Key 必须存储在 macOS Keychain 中，不得以明文形式保存在配置文件或 UserDefaults 中
- **本地优先**：所有会话数据默认存储在本地（SwiftData/SQLite），不上传任何用户数据到第三方服务器
- **文件系统权限**：Agent 对文件系统的操作必须受 macOS 沙盒约束，或通过用户显式授权的目录访问
- **敏感信息过滤**：Tool Result 中可能包含 API Key、密码等敏感信息，UI 展示时应提供遮罩选项

### 开发者体验约束

- **SDK 版本兼容**：SwiftWork 必须明确声明支持的 open-agent-sdk-swift 最低版本，并在 README 中说明
- **事件模型稳定性**：SDK 的 `SDKMessage` 枚举如果新增 case，SwiftWork 应有优雅的降级处理（显示为"未知事件"而非崩溃）
- **调试友好**：所有 UI 组件必须能通过 Accessibility Inspector 检查，方便开发者理解视图层级
- **Swift 包管理**：项目必须通过 Swift Package Manager 管理依赖，支持 `swift build` 和 `swift test`

### 性能约束

- **大文件渲染**：Tool Result 可能返回超大文本（如完整文件内容），Timeline 渲染必须使用懒加载，避免一次性加载所有内容
- **长时间会话**：超过 100 轮的会话必须支持虚拟化滚动，不能将所有事件都保留在内存中
- **并发事件处理**：SDK 可能同时发出多个事件（如并行 Tool 调用），UI 必须正确处理并发事件队列

### 平台约束

- **macOS 14+ (Sonoma)**：最低支持版本，需要 `@Observable`、`NavigationSplitView`、SwiftData 等 API（详细平台要求见 Desktop App Specific Requirements 章节）
- **窗口管理**：支持 macOS 原生窗口行为（全屏、分屏、Stage Manager）

## Innovation & Novel Patterns

### Detected Innovation Areas

SwiftWork 的核心创新是**"SDK 事件模型即 UI 原型"**——不是先设计 UI 再适配数据，而是让 SDK 的类型系统直接驱动 UI 组件的生成。

传统 Agent 客户端的架构是：
```
LLM Response → JSON 解析 → Message List → 渲染为聊天气泡
```

SwiftWork 的架构是：
```
SDKMessage (enum) → switch case → 每个 case 对应一个 SwiftUI View
```

这意味着：
1. **类型安全的事件驱动 UI**：`SDKMessage` 的 18 个枚举 case 在编译时就能保证 UI 覆盖完整性。如果 SDK 新增一个事件类型，Swift 编译器会立即报错（`switch` 必须穷举），而不是运行时才发现漏了某个事件。
2. **Tool 是一等 UI 组件**：`.toolUse` 事件不是被渲染成"Agent 调用了 xxx 工具"的文本，而是一个交互式卡片——可展开查看参数、可点击查看详情、可折叠节省空间。
3. **`ToolRenderable` 协议驱动的可扩展渲染**：每种 Tool 类型可以注册自己的 SwiftUI 渲染器。当 SDK 新增 Tool 时，只需新增一个 `ToolRenderable` 实现，无需修改核心 Timeline 逻辑。

### Market Context & Competitive Landscape

- **OpenWork**（对标产品）：React + Tauri，Web 渲染层增加开销，UI 交互受限于 Web 技术栈。优势是跨平台和社区生态。
- **Claude Desktop**：闭源，聊天界面为中心，不展示执行过程。SwiftWork 的差异化在于"可见的执行过程"。
- **Cursor / Windsurf**：IDE 内集成的 AI，不是独立的 Agent 客户端。SwiftWork 定位为通用 Agent 桌面端，不绑定特定 IDE。
- **Aider / Claude Code CLI**：命令行工具，无 GUI。SwiftWork 为同一能力提供可视化界面。

### Validation Approach

创新假设需要通过 MVP 验证：
1. **假设**：开发者更偏好事件驱动的 Agent UI 而非聊天界面
   - **验证方式**：让 5 个开发者使用 SwiftWork 完成任务，观察他们是否主动点击 Tool Card 查看详情，还是只看最终回答
2. **假设**：原生性能差异可被用户感知
   - **验证方式**：同一任务在 OpenWork 和 SwiftWork 上执行，测量并对比用户感知的响应速度
3. **假设**：Debug Panel 是杀手级功能
   - **验证方式**：记录 Debug Panel 的使用频率和停留时间

### Risk Mitigation

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| SDK 事件模型变更导致 UI 崩溃 | 高 | 使用 `switch` 穷举 + `@unknown default` 降级处理 |
| 原生开发速度慢于 Web 方案 | 中 | 严格 MVP 范围控制，先跑通核心流程再迭代 |
| macOS 市场覆盖有限 | 低 | 首期聚焦 macOS 开发者群体，后续评估跨平台 |
| SDK 依赖过重 | 中 | 通过协议层抽象 SDK 接口，保留未来替换的可能性 |

## Desktop App Specific Requirements

### Platform Support

- **目标平台**：macOS 14 Sonoma 及以上（利用 `@Observable`、`NavigationSplitView`、SwiftData 等 API）
- **架构支持**：Apple Silicon (ARM64) 原生优先，Intel (x86_64) 通过 Universal Binary 或 Rosetta 兼容
- **不做跨平台**：MVP 阶段专注 macOS，不投入 Linux/Windows 适配。SwiftUI 的跨平台能力留作 Vision 阶段选项

### System Integration

| 集成点 | 优先级 | 说明 |
|--------|--------|------|
| 菜单栏 | MVP | 标准菜单结构（File/Edit/View/Window/Help） |
| Dock 栏 | MVP | 显示未读会话数 badge |
| 通知中心 | Growth | Agent 完成长时间任务时推送系统通知 |
| Spotlight | Vision | 通过 Spotlight Index 让历史会话可搜索 |
| 文件系统 | MVP | Agent 工作目录选择、文件拖放支持 |
| 快捷键 | MVP | 标准 macOS 快捷键（Cmd+N 新建会话、Cmd+W 关闭等） |
| 窗口状态 | MVP | 记住窗口位置、大小、Inspector 展开状态 |

### Update Strategy

- **Sparkle 框架**：使用 Sparkle 实现 macOS 原生自动更新体验
- **更新检查频率**：每次启动时检查，用户可在设置中关闭
- **版本管理**：遵循语义化版本（SemVer），重大更新需用户确认

### Offline Capabilities

- **离线浏览**：已加载的会话历史在离线状态下可浏览
- **离线编辑**：InputBar 可在离线状态下编写消息，联网后自动发送
- **离线不可用**：Agent 执行依赖 API 调用，核心功能需要网络连接

### Technical Architecture

**UI 参照映射（OpenWork → SwiftWork）：**

| OpenWork 组件 | SwiftWork 对应 | 说明 |
|--------------|----------------|------|
| `SessionPage` (React) | `SessionView` (SwiftUI) | 主工作区 |
| `WorkspaceSessionList` (Sidebar) | `SidebarView` | 会话列表 |
| Event Timeline | `TimelineView` | 核心事件流，从 SSE → AsyncStream |
| `Composer` | `InputBarView` | 输入栏 |
| `PermissionApprovalModal` | `PermissionView` | 权限审批（Web Modal → 原生 Sheet） |
| `DebugPanel` | `DebugView` | 调试面板 |
| Inspector | `InspectorView` | 右侧详情面板 |
| `Markdown` renderer | `MarkdownRenderer` | Markdown 渲染 |
| Model Picker | `ModelPickerView` | 模型选择 |

**SwiftWork 分层架构：**

```
SwiftWork App
├── App Layer (SwiftUI)
│   ├── SidebarView (会话列表)
│   ├── WorkspaceView
│   │   ├── TimelineView (核心：事件驱动 UI)
│   │   ├── InputBarView
│   │   └── InspectorView
│   └── SettingsView
├── ViewModel Layer (Observation)
│   ├── SessionViewModel (会话管理)
│   ├── TimelineViewModel (事件流处理)
│   └── SettingsViewModel
├── SDK Integration Layer
│   ├── AgentBridge (封装 Agent 创建和配置)
│   ├── EventMapper (SDKMessage → UI Model)
│   └── PermissionHandler (权限请求/响应)
├── Data Layer (SwiftData)
│   ├── Session (会话持久化)
│   ├── Event (事件持久化)
│   └── Configuration (设置持久化)
└── Utils
    ├── MarkdownRenderer
    ├── CodeHighlighter
    └── KeychainManager
```

### Key Dependencies

| 依赖 | 用途 | 地址 |
|------|------|------|
| OpenWork | UI 参照源项目（本地克隆） | 本地路径：`/Users/nick/CascadeProjects/openwork`，GitHub：https://github.com/different-ai/openwork |
| open-agent-sdk-swift | Agent 核心能力 SDK | GitHub：https://github.com/terryso/open-agent-sdk-swift，SPM 集成 |
| swift-markdown | Markdown 渲染 | Apple 官方 |
| Splash | 代码高亮 | 开源 (JohnSundell) |
| Sparkle | 自动更新 | 开源 |
| SwiftData | 本地数据持久化 | 系统框架 |
| ChatGPTUI | 用户输入气泡和最终回答展示的参考实现 | GitHub：https://github.com/alfianlosari/ChatGPTUI |

> **注意**：OpenWork 是 SwiftWork 的 UI 复刻参照源，开发过程中需要频繁对照其 React 组件的交互行为。ChatGPTUI 仅作为用户消息气泡和最终回答展示的 UI 参考，不作为主 UI 框架。SwiftWork 的核心 UI（Timeline、Tool Card、Inspector 等）必须自研，因为这些是产品差异化的根基。

## Project Scoping & Phased Development

### MVP Strategy & Philosophy

**MVP 方法**：问题解决型 MVP——用最小功能集验证"事件驱动的原生 Agent UI 是否比聊天界面更有价值"这个核心假设。

**资源需求**：1 名全栈 Swift 开发者（Nick），利用 open-agent-sdk-swift 避免 Agent 核心能力的重复建设。

**MVP 原则**：
- 能用 SDK 的绝不高造轮子
- UI 先跑通再打磨（先文本列表，再美化卡片）
- 每个 Phase 结束时必须可运行、可演示

### Phase 1: SDK→UI 闭环（Week 1）

**目标**：证明 SDK 事件能驱动 UI 渲染

**Must-Have：**
- Agent 创建和配置（API Key、模型选择）
- `stream()` 事件流接入，`AsyncStream` → SwiftUI 绑定
- TimelineView 极简版（文本列表渲染所有事件类型）
- InputBar 基础输入
- 会话创建和切换

**验证标准**：用户能输入任务，看到 Agent 的事件流实时渲染在 Timeline 上。

### Phase 2: Agent 可视化（Week 2）

**目标**：让用户"看到 Agent 在干什么"

**Must-Have：**
- ToolCallView 结构化卡片（工具名、参数、耗时、状态指示器）
- ToolResultView（成功/失败状态、结果摘要）
- ThinkingView（思考中动画）
- 流式文本渲染（`.partialMessage` 逐字显示）
- 事件类型覆盖：`.userMessage`、`.partialMessage`、`.assistant`、`.toolUse`、`.toolResult`、`.toolProgress`、`.result`

**验证标准**：用户能清晰看到 Agent 的每一步操作，而非一坨文本。

### Phase 3: 产品关键能力（Week 3）

**目标**：接近可日常使用的状态

**Must-Have：**
- 权限对话框 UI（Allow Once / Always Allow / Deny）
- Inspector Panel（点击事件查看详细信息）
- Sidebar 会话管理（列表、创建、删除、重命名）
- Markdown 渲染（代码块、列表、表格）
- PlanView（执行计划可视化）
- 错误状态可视化（红色高亮、错误详情）

**验证标准**：用户能完成 Journey 1（日常开发者）和 Journey 2（谨慎开发者）的完整流程。

### Phase 4: 差异化打磨（Week 4）

**目标**：让用户觉得"这个工具很强"

**Must-Have：**
- Debug Panel（原始事件流、Token 用量、执行日志）
- 设置页面（API Key 管理、模型选择、权限模式配置）
- Dock Badge（未读会话数）
- 窗口状态记忆

**Nice-to-Have（本 Phase 或后续）：**
- Hook 事件可视化
- 多 Agent / 子任务可视化
- 会话搜索

**验证标准**：用户能完成 Journey 3（SDK 评估者）和 Journey 4（问题排查者）的完整流程。

### Risk Mitigation Strategy

**技术风险**：
- SDK API 不稳定或文档不足 → 预留 Phase 1 第一天通读 SDK 源码，提前识别坑点
- SwiftUI 性能瓶颈（大量事件渲染卡顿）→ Phase 2 必须做性能测试，必要时引入虚拟化滚动
- 内存泄漏（`AsyncStream` 未正确取消）→ 每个 Phase 结束做 Instruments 内存分析

**市场风险**：
- 用户不需要"可视化执行过程" → Phase 2 结束后找 2-3 个开发者试用，收集反馈
- 竞品（如 OpenWork）快速跟进原生方案 → 保持差异化聚焦在 Swift 生态深度整合

**资源风险**：
- 个人开发时间不足 → 严格守住 MVP 范围，Growth/Vision 功能绝不提前
- 遇到技术难题卡住 → 社区求助（Swift Forums、GitHub Issues）优先于自己死磕

## Functional Requirements

### 会话管理 (Session Management)

- FR1: 用户可以创建新的 Agent 会话
- FR2: 用户可以在会话列表中查看所有历史会话（按时间排序）
- FR3: 用户可以在会话之间切换，切换时保留每个会话的事件历史
- FR4: 用户可以删除会话及其所有关联数据
- FR5: 用户可以重命名会话以方便识别
- FR6: 系统可以在应用重启后恢复上次的会话状态和窗口位置

### 事件流可视化 (Event Visualization)

- FR7: 系统可以将 SDK 产生的所有事件类型实时渲染为对应的 UI 组件
- FR8: 用户可以看到 Agent 的流式文本输出（逐字显示）
- FR9: 用户可以看到 Agent 的思考状态指示（Thinking 动画）
- FR10: 用户可以看到会话的最终结果摘要（包含状态、耗时、Token 用量）
- FR11: 系统可以用视觉方式区分不同类型的事件（用户消息、工具调用、工具结果、系统事件等）
- FR12: 用户可以看到错误事件的突出显示（红色高亮、错误详情）
- FR13: 系统可以在事件流过大时保持流畅滚动（通过性能优化手段确保大量事件时不卡顿）

### 工具执行可视化 (Tool Execution Visualization)

- FR14: 用户可以看到每次工具调用的结构化卡片（工具名、输入参数、执行状态）
- FR15: 用户可以看到工具执行的实时进度（旋转指示器、已用时间）
- FR16: 用户可以展开/折叠工具调用卡片查看详细参数和完整结果
- FR17: 用户可以看到工具执行结果的摘要（成功/失败状态、截断的内容预览）
- FR18: 用户可以通过点击工具调用卡片在 Inspector Panel 中查看完整详情
- FR19: 系统可以对不同类型的工具（文件操作、Shell 命令、搜索等）展示差异化的卡片样式

### 权限与审批 (Permission & Approval)

- FR20: 用户可以在工具调用需要审批时收到原生弹窗通知
- FR21: 用户可以在权限弹窗中查看工具名称、操作描述和具体参数
- FR22: 用户可以选择"允许一次"（Allow Once）来授权当前操作
- FR23: 用户可以选择"始终允许"（Always Allow）来授权同类操作
- FR24: 用户可以拒绝（Deny）操作并附带原因
- FR25: 用户可以在设置中查看和修改已授权的权限规则列表
- FR26: 用户可以在设置中选择全局权限模式（自动批准、手动审批等）

### Agent 配置与交互 (Agent Configuration & Interaction)

- FR27: 用户可以输入和保存 LLM API Key
- FR28: 用户可以选择 Agent 使用的模型
- FR29: 用户可以在输入框中编写消息发送给 Agent
- FR30: 用户可以在 Agent 执行过程中发送追加消息
- FR31: 用户可以中断正在执行的 Agent 任务
- FR32: 用户可以在 InputBar 中使用 Shift+Enter 换行，Enter 发送

### 执行计划可视化 (Execution Plan)

- FR34: 用户可以看到 Agent 的任务拆解计划（Plan 步骤列表）
- FR35: 用户可以看到每个计划步骤的执行状态（待执行、执行中、已完成）
- FR36: 用户可以看到计划步骤之间的依赖关系

### 调试与检查 (Debug & Inspection)

- FR37: 用户可以通过右侧面板查看选中事件的完整详细信息（JSON 格式、耗时、Token 用量）
- FR38: 用户可以在 Debug Panel 中查看原始事件流（未经 UI 处理的 SDK 原始数据）
- FR39: 用户可以在 Debug Panel 中查看 Token 消耗的实时统计
- FR40: 用户可以在 Debug Panel 中查看工具执行的详细日志
- FR41: 用户可以展开/折叠 Inspector Panel

### 内容渲染 (Content Rendering)

- FR42: 系统可以正确渲染 Agent 输出中的 Markdown 内容（标题、列表、代码块、表格、粗体/斜体）
- FR43: 系统可以对代码块进行语法高亮
- FR44: 系统可以折叠/展开长文本内容

### 应用外壳 (Application Shell)

- FR45: 用户可以通过标准 macOS 菜单栏操作应用（File/Edit/View/Window/Help）
- FR46: 用户可以通过键盘快捷键执行常用操作（Cmd+N 新建会话、Cmd+W 关闭等）
- FR47: 系统可以在 Dock 栏显示未读会话数量 badge
- FR48: 用户可以在应用设置中管理 API Key、模型选择和权限配置
- FR49: 系统可以在首次启动时引导用户完成 API Key 配置

## Non-Functional Requirements

### Performance

- NFR1: 应用冷启动到可交互状态不超过 2 秒（在 Apple Silicon Mac 上）
- NFR2: SDK 事件从产出到 UI 渲染完成的端到端延迟不超过 100ms
- NFR3: 流式文本渲染的逐字输出间隔不超过 50ms，无可见卡顿
- NFR4: 100+ 轮会话的事件列表滚动帧率不低于 60fps（需虚拟化渲染）
- NFR5: 会话切换的加载时间不超过 500ms

### Security

- NFR6: LLM API Key 必须通过 macOS Keychain 存储，禁止明文持久化
- NFR7: 所有与 LLM API 的通信必须通过 HTTPS 加密
- NFR8: 本地会话数据存储必须使用 macOS 原生文件权限保护
- NFR9: Tool Result 中的敏感信息（API Key、密码）必须在 UI 中默认遮罩，用户可手动展开
- NFR10: 权限审批操作必须记录审计日志（工具名、操作内容、用户决策、时间戳）

### Reliability

- NFR11: 应用在 SDK 事件流异常断开时不得崩溃，必须显示友好的连接中断提示
- NFR12: 应用在长时间运行（8小时+）后无内存泄漏，内存占用增长不超过 20%
- NFR13: 单个会话包含 1000+ 事件时，应用仍可正常操作，无 UI 冻结
- NFR14: 应用异常退出后重启，可恢复至最近的会话状态

### Compatibility

- NFR15: 支持 macOS 14 (Sonoma) 及以上版本
- NFR16: Apple Silicon (ARM64) 原生运行，Intel Mac 通过 Rosetta 兼容
- NFR17: 完整支持 macOS 深色模式和浅色模式，跟随系统设置自动切换
- NFR18: 支持标准 macOS 窗口管理行为（全屏、分屏、Stage Manager）

### Data Persistence

- NFR19: 会话数据和事件历史通过本地持久化机制持久化，应用重启后可恢复
- NFR20: 用户配置（API Key、模型选择、权限规则）通过系统安全存储和配置管理机制持久化
- NFR21: 窗口位置和 Inspector 展开状态在应用重启后保持
