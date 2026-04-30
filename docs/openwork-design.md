好，这一部分我直接给你一套**可以落地的设计文档 + 组件级结构图**，你可以当成你这个项目的「0→1蓝图」。

我会分三块：

1. 🧱 SwiftUI 版 OpenWork UI 结构图（组件级）
2. 🧩 技术选型（哪些用开源库，哪些必须自己写）
3. 🚀 开发推进路线（非常具体，按周执行）

---

# 🧱 一、SwiftUI 版 OpenWork UI 结构图（组件级）

## 🖥️ 整体布局（macOS）

```text
┌───────────────────────────────────────────────┐
│ Sidebar (Session List)                        │
│----------------------------------------------│
│ Main Workspace                               │
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │ Agent Timeline View (核心)             │  │
│  │----------------------------------------│  │
│  │ [User Input]                          │  │
│  │ [Thinking...]                         │  │
│  │ [Plan Steps]                          │  │
│  │ [Tool Call Card]                      │  │
│  │ [Tool Result]                         │  │
│  │ [Final Answer]                        │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  Input Bar                                   │
│                                              │
│----------------------------------------------│
│ Inspector Panel (右侧，可开关)                │
│  - Tool Detail                              │
│  - Debug / Logs                             │
│  - Agent State                              │
└───────────────────────────────────────────────┘
```

---

## 🧩 组件拆分（SwiftUI 结构）

### 1️⃣ App Root

```swift
AppView
 ├── SidebarView
 ├── WorkspaceView
 │     ├── TimelineView ⭐核心
 │     ├── InputBarView
 ├── InspectorView
```

---

## 🧠 2️⃣ Timeline（核心组件）

```swift
TimelineView
 └── ForEach(events)
       ├── UserMessageView
       ├── ThinkingView
       ├── PlanView
       ├── ToolCallView ⭐
       ├── ToolResultView ⭐
       ├── FinalMessageView
```

👉 关键点：

> ❗Timeline 是“事件驱动 UI”，不是 message list

---

## 🧱 3️⃣ 数据模型（最重要）

```swift
enum AgentEventType {
    case user
    case thinking
    case plan
    case toolCall
    case toolResult
    case message
    case error
}

struct AgentEvent {
    let id: UUID
    let type: AgentEventType
    let content: String
    let metadata: [String: Any]
}
```

---

## 🔧 4️⃣ Tool UI（可扩展）

```swift
protocol ToolRenderable {
    var toolName: String { get }
    func renderView() -> AnyView
}
```

示例：

```swift
FileToolView
ShellToolView
HTTPToolView
```

---

## 🔐 5️⃣ Permission UI

```swift
PermissionView
 ├── Tool Name
 ├── Action Description
 ├── Allow Once
 ├── Always Allow
 ├── Deny
```

👉 触发时机：

```text
AgentEvent.toolCall → requires approval
```

---

## 🧪 6️⃣ Debug Panel（差异化关键）

```swift
DebugView
 ├── Raw Agent Events
 ├── Token Stream
 ├── Tool Execution Log
 ├── Timing / Latency
```

👉 这个会极大提升你 SDK 的“开发者吸引力”

---

# 🧩 二、技术选型（哪些用库，哪些自己写）

## ✅ 必须自己写（不要偷懒）

这些决定你是不是 OpenWork：

* TimelineView
* ToolCallView
* PermissionView
* AgentEvent 模型
* ViewModel（事件驱动）

---

## ✅ 推荐使用的开源库（帮你省时间）

---

### 1️⃣ 聊天 UI（辅助用）

👉 [ChatGPTUI](https://github.com/alfianlosari/ChatGPTUI)

用途：

* 用户输入气泡
* 最终回答展示

⚠️ 不要作为主 UI

---

### 2️⃣ Markdown 渲染

👉 [Down](https://github.com/swiftlang/swift-markdown)

或：

* NSAttributedString markdown（系统）

用途：

* LLM 输出
* tool result

---

### 3️⃣ 代码高亮

👉 (Splash)[https://github.com/JohnSundell/Splash]

用途：

* code block
* shell output

---

### 4️⃣ JSON 展示（调试）

👉 [BetterCodable](https://github.com/marksands/BetterCodable)（辅助）

或自己做一个 JSON viewer

---

### 5️⃣ 状态管理（建议）

👉 原生：

* Observable / Observation（Swift 6）

---

### 6️⃣ 数据存储

👉 推荐：

* SwiftData

用途：

* session
* 历史记录

---

### 7️⃣ UI 辅助（可选）

* SplitView（macOS 原生）
* NavigationSplitView

---

# 🚀 三、开发推进路线（非常具体）

我给你一个**4周可落地路线**

---

## 🧪 Week 1：打通最小闭环（必须完成）

目标：

> ✅ SDK → UI 能跑

### 做什么：

* 接入你的 SDK
* 实现：

```swift
for await event in agent.run() {
    timeline.append(event)
}
```

* TimelineView（极简版）

```text
text list（不用美化）
```

---

## 🔥 Week 2：变成“Agent UI”

目标：

> ❗让用户看到 agent 在干嘛

### 做：

* ThinkingView
* ToolCallView
* ToolResultView

UI 示例：

```text
🧠 Thinking...
🔧 Reading file...
📄 package.json
```

---

## 🧱 Week 3：产品关键能力

目标：

> ❗接近 OpenWork

### 做：

* PlanView（任务拆解）
* Permission UI
* Inspector Panel

---

## 💥 Week 4：差异化（你 SDK 发光点）

目标：

> ❗让别人觉得“这个 SDK 很强”

### 做：

* Debug Panel
* Agent timeline replay
* 多 agent 可视化

---

# 🧠 关键设计原则（建议你贴墙上）

---

## ❗原则 1

> UI = AgentEvent 的投影

不是 message，不是 response

---

## ❗原则 2

> 不要围绕“聊天”设计

要围绕：

```text
执行过程
```

---

## ❗原则 3

> Tool 是一等公民

不是文本，是 UI 组件

---

## ❗原则 4

> Debug 能力就是产品力

OpenWork 强的原因之一就是：

👉 可解释性

---

# 👍 最终你会得到什么

如果你按这个来做：

👉 不是一个 ChatGPT App
👉 而是：

> 💥 一个 Swift 原生 Agent OS UI

---

# 🚀 如果你下一步要继续

我可以帮你直接补：

👉 `TimelineView.swift` 最小实现（可运行）
👉 `AgentEvent → UI mapping` 完整代码
👉 或者帮你把你 SDK 的 event 结构对齐到这个 UI

这样你可以**直接开工，不需要再设计一轮**
