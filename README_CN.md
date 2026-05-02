# SwiftWork

**[English](./README.md)** | 中文

[![Swift](https://img.shields.io/badge/Swift-6.1-orange)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)](https://developer.apple.com/macos/)
[![CI](https://github.com/terryso/SwiftWork/actions/workflows/ci.yml/badge.svg)](https://github.com/terryso/SwiftWork/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/terryso/6bc0b5140838d40c8e71ae39ce64f25f/raw/coverage.json)](https://github.com/terryso/SwiftWork/actions)
[![BMAD](https://bmad-badge.vercel.app/terryso/SwiftWork.svg)](https://github.com/bmad-code-org/BMAD-METHOD)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](./LICENSE)

macOS 原生 AI 工作台，用于可视化和交互 AI Agent。SwiftWork 提供 Agent 执行的实时可观测性——让你看到 Agent 正在做什么、为什么做以及每一步的执行结果。

基于 [Open Agent SDK (Swift)](https://github.com/terryso/open-agent-sdk-swift) 构建。

## 功能特性

### 会话管理
- 创建、重命名和删除对话会话
- 按时间排序的侧边栏会话列表
- 重启后保留上次活跃会话

### Agent 对话
- Enter 发送消息，Shift+Enter 换行
- Agent 响应实时流式输出
- 支持中断任务执行

### 事件时间线
- 实时渲染 18+ 种 SDK 事件类型
- 流式文本局部更新
- 思考状态动画
- 用户、工具、系统事件的视觉区分

### Tool Card 可视化
- 结构化工具调用卡片，展示名称、参数和执行状态
- 实时进度指示器，支持展开/折叠查看详细结果
- 可扩展的 `ToolRenderable` 协议，便于添加新工具类型

### Inspector 面板
- 三栏布局（侧边栏 + 工作区 + 检查面板）
- 详细事件检查面板
- 面板状态跨会话持久化

### 引导与配置
- 首次启动引导向导
- 通过 macOS Keychain 管理 API Key
- 模型选择界面

## 技术栈

| 组件 | 技术 |
|---|---|
| 语言 | Swift 6.1+，严格并发模式 |
| 平台 | macOS 14+ (Sonoma)，Apple Silicon 原生支持 |
| UI 框架 | SwiftUI，使用 `@Observable` |
| 持久化 | SwiftData |
| Agent SDK | [Open Agent SDK (Swift)](https://github.com/terryso/open-agent-sdk-swift) |
| Markdown 渲染 | [swift-markdown](https://github.com/apple/swift-markdown) (Apple) |
| 语法高亮 | [Splash](https://github.com/JohnSundell/Splash) |
| 自动更新 | [Sparkle](https://github.com/sparkle-project/Sparkle) 2.x |

## 项目结构

```
SwiftWork/
├── App/
│   ├── SwiftWorkApp.swift            # 应用入口
│   └── ContentView.swift             # NavigationSplitView 根视图
├── Models/
│   ├── UI/                           # UI 模型（AgentEvent、ToolContent）
│   └── SwiftData/                    # 持久化模型（Session、Event）
├── ViewModels/
│   ├── SessionViewModel.swift        # 会话管理
│   └── SettingsViewModel.swift       # 设置管理
├── Views/
│   ├── Sidebar/                      # 会话列表
│   ├── Workspace/
│   │   ├── Timeline/EventViews/      # 各事件类型视图
│   │   ├── Inspector/                # 事件详情面板
│   │   └── InputBar/                 # 消息输入框
│   └── Settings/                     # 设置界面
├── SDKIntegration/
│   ├── AgentBridge.swift             # SDK ↔ ViewModel 桥接
│   ├── EventMapper.swift             # SDKMessage → AgentEvent 映射
│   ├── ToolRenderable.swift          # 工具渲染协议
│   └── ToolRendererRegistry.swift    # 可扩展工具注册表
└── Utils/
    └── Extensions/                   # 颜色、日期格式化等工具
```

## 架构设计

SwiftWork 采用事件驱动架构：

```
AsyncStream<SDKMessage> → AgentBridge → EventMapper → ViewModel → SwiftUI
```

核心原则：
- **严格并发** — 所有 UI 代码使用 `@MainActor` 隔离
- **关注点分离** — 视图只消费 UI 模型，不直接接触 SDK 类型
- **可扩展性** — 通过 `ToolRendererRegistry` 注册新工具类型，无需修改时间线逻辑

## 快速开始

### 环境要求
- macOS 14.0+ (Sonoma)
- Xcode 16.0+
- Swift 6.1+

### 构建与运行

```bash
git clone https://github.com/terryso/SwiftWork.git
cd SwiftWork
open Package.swift
# 在 Xcode 中按 Cmd+R 构建并运行
```

或通过命令行：

```bash
swift build
swift run SwiftWork
```

## 安装

从 [Releases](https://github.com/terryso/SwiftWork/releases) 下载最新的 `SwiftWork-*.dmg`，然后：

1. 打开 DMG，将 **SwiftWork.app** 拖到 **应用程序** 文件夹
2. 执行以下命令移除 macOS 隔离标记：

```bash
xattr -cr /Applications/SwiftWork.app
```

3. 从启动台或 Spotlight 启动 SwiftWork

## 开发进度

| Epic | 描述 | 状态 |
|---|---|---|
| Epic 1 | 首次启动与基础交互（SDK→UI 闭环） | 已完成 |
| Epic 2 | Agent 执行可视化（Tool Card 体验） | 进行中 |
| Epic 3 | 权限控制与会话管理（用户掌控力） | 待开发 |
| Epic 4 | 调试面板与应用外壳（开发者工具体验） | 待开发 |

**Epic 1**（已完成）：项目初始化、引导配置、会话管理、消息输入、事件时间线、状态恢复。

**Epic 2**（进行中）：工具可视化架构、工具卡片体验、事件视觉系统、Markdown/代码高亮、时间线性能优化。

## 路线图

### 进行中 — Epic 2：Agent 执行可视化
- [ ] 事件视觉系统 — 颜色/图标区分事件类型，错误高亮
- [ ] Markdown 渲染 — 标题、列表、粗体/斜体、行内代码、表格
- [ ] 代码语法高亮 — Swift、Python、JavaScript、Bash（基于 Splash）
- [ ] 长文本折叠/展开
- [ ] Timeline 性能优化 — 懒加载、虚拟化，支持 1000+ 事件

### 计划中 — Epic 3：权限控制与会话管理
- [ ] 权限系统 — 原生 macOS 弹窗审批工具调用（允许一次 / 始终允许 / 拒绝）
- [ ] 权限规则管理 — 在设置中查看、编辑、删除规则
- [ ] 全局权限模式 — 自动批准、手动审批、全部拒绝
- [ ] 会话管理 — 级联删除会话、内联重命名
- [ ] Agent 执行中追加消息
- [ ] Inspector Panel — 完整事件详情（JSON、耗时、Token 用量）
- [ ] 执行计划可视化 — 步骤列表、状态与依赖关系

### 计划中 — Epic 4：调试面板与应用外壳
- [ ] 调试面板 — 原始 SDK 事件流、Token 消耗统计、工具执行日志
- [ ] 应用设置 — API Key 管理、模型选择、权限配置
- [ ] macOS 菜单栏 — File / Edit / View / Window / Help 菜单
- [ ] 键盘快捷键 — Cmd+N、Cmd+W、Cmd+,
- [ ] Dock Badge — 未读会话数
- [ ] macOS 标准窗口管理 — 全屏、分屏、Stage Manager

## 许可证

[MIT](./LICENSE)
