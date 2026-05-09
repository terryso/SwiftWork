# SwiftWork - macOS AI 智能体工作台

![SwiftWork Banner](https://i.v2ex.co/2yumzVnq.png)

**[English](./README.md)** | 中文

[![Swift](https://img.shields.io/badge/Swift-6.1-orange)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)](https://developer.apple.com/macos/)
[![Download macOS](https://img.shields.io/badge/Download-macOS-000000?logo=apple&logoColor=white)](https://github.com/terryso/SwiftWork/releases/latest)
[![CI](https://github.com/terryso/SwiftWork/actions/workflows/ci.yml/badge.svg)](https://github.com/terryso/SwiftWork/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/terryso/6bc0b5140838d40c8e71ae39ce64f25f/raw/coverage.json)](https://github.com/terryso/SwiftWork/actions)
[![BMAD](https://bmad-badge.vercel.app/terryso/SwiftWork.svg)](https://github.com/bmad-code-org/BMAD-METHOD)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](./LICENSE)

macOS 原生 AI 工作台，用于可视化和交互 AI Agent。SwiftWork 提供 Agent 执行的实时可观测性——让你看到 Agent 正在做什么、为什么做以及每一步的执行结果。

基于 [Open Agent SDK (Swift)](https://github.com/terryso/open-agent-sdk-swift) 构建。

https://github.com/user-attachments/assets/f1151485-0bb7-4f0e-b0db-a5fe15ce73bb

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

### 权限控制
- 时间线内联审批卡片——在上下文中批准、会话允许或拒绝工具调用
- 模板驱动的规则创建与内联编辑
- 自动批准模式，附带视觉警告指示器
- 权限规则管理——查看、编辑、删除规则

### Skill 技能系统
- 输入框斜杠命令自动补全——输入 `/` 即可发现可用技能
- Skill 时间线卡片——技能执行事件的专属渲染
- 设置中的技能管理面板——按来源分组浏览（Built-in / Project / User）

### Inspector 面板
- 三栏布局（侧边栏 + 工作区 + 检查面板）
- 详细事件检查面板
- 面板状态跨会话持久化

### 引导与配置
- 首次启动引导向导
- 通过应用沙盒存储管理 API Key
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
│   │   │   └── ToolRenderers/        # Skill、Bash 等工具卡片
│   │   ├── Inspector/                # 事件详情面板
│   │   └── InputBar/                 # 消息输入 + Skill 自动补全
│   ├── Permission/                   # 内联审批卡片
│   └── Settings/                     # 设置 + 技能管理
├── SDKIntegration/
│   ├── AgentBridge.swift             # SDK ↔ ViewModel 桥接 + Skill 管道
│   ├── EventMapper.swift             # SDKMessage → AgentEvent 映射
│   ├── PermissionHandler.swift       # 工具调用审批逻辑
│   ├── ToolRenderable.swift          # 工具渲染协议
│   └── ToolRendererRegistry.swift    # 可扩展工具注册表
├── Services/
│   └── KeychainManager.swift         # 安全凭证存储
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
| Epic 2 | Agent 执行可视化（Tool Card 体验） | 已完成 |
| Epic 3 | 权限控制与会话管理（用户掌控力） | 已完成 |
| Epic 4 | 调试面板与应用外壳（开发者工具体验） | 已完成 |
| Epic 5 | 技能系统（斜杠命令、卡片渲染、管理面板） | 已完成 |

**Epic 1**（已完成）：项目初始化、引导配置、会话管理、消息输入、事件时间线、状态恢复。

**Epic 2**（已完成）：工具可视化架构、工具卡片体验、事件视觉系统、Markdown/代码高亮、时间线性能优化。

**Epic 3**（已完成）：内联权限审批卡片、权限规则增删改查、自动批准模式、会话管理、Inspector 面板、执行计划可视化。

**Epic 4**（已完成）：调试面板、多标签设置、macOS 菜单栏、Dock Badge。

**Epic 5**（已完成）：SDK Skill 管道、斜杠命令自动补全、Skill 时间线卡片渲染、技能管理面板。

## 路线图

### 计划中 — 下一步
- [ ] 死循环检测——识别并警告 Agent 陷入重复循环
- [ ] 多 Agent 支持——在不同 Agent 配置之间切换
- [ ] 插件系统——第三方工具渲染器和技能扩展
- [ ] 会话导出——将对话记录保存为 Markdown 或 JSON

## 许可证

[MIT](./LICENSE)
