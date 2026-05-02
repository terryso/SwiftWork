# SwiftWork

English | **[中文](./README_CN.md)**

[![Swift](https://img.shields.io/badge/Swift-6.1-orange)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)](https://developer.apple.com/macos/)
[![CI](https://github.com/terryso/SwiftWork/actions/workflows/ci.yml/badge.svg)](https://github.com/terryso/SwiftWork/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/terryso/6bc0b5140838d40c8e71ae39ce64f25f/raw/coverage.json)](https://github.com/terryso/SwiftWork/actions)
[![BMAD](https://bmad-badge.vercel.app/terryso/SwiftWork.svg)](https://github.com/bmad-code-org/BMAD-METHOD)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](./LICENSE)

macOS-native AI workspace for visualizing and interacting with AI agents. SwiftWork provides real-time observability into agent execution — see what the agent is doing, why it's doing it, and the results of each step.

Built with [Open Agent SDK (Swift)](https://github.com/terryso/open-agent-sdk-swift).

## Features

### Session Management
- Create, rename, and delete chat sessions
- Chronological session list in sidebar
- Last active session is preserved across restarts

### Agent Conversation
- Message input with Enter to send, Shift+Enter for newline
- Real-time streaming of agent responses
- Task interruption support

### Event Timeline
- Real-time rendering of 18+ SDK event types
- Streaming text with partial message updates
- Thinking state animation
- Visual differentiation between user, tool, and system events

### Tool Card Visualization
- Structured tool call cards showing name, parameters, and execution status
- Real-time progress indicators with expand/collapse for detailed results
- Extensible `ToolRenderable` protocol for adding new tool types

### Inspector Panel
- Three-panel layout (Sidebar + Workspace + Inspector)
- Detailed event inspection panel
- Panel state persistence across sessions

### Onboarding & Configuration
- First-launch setup wizard
- API key management via macOS Keychain
- Model selection interface

## Tech Stack

| Component | Technology |
|---|---|
| Language | Swift 6.1+ with strict concurrency |
| Platform | macOS 14+ (Sonoma), Apple Silicon native |
| UI Framework | SwiftUI with `@Observable` |
| Persistence | SwiftData |
| Agent SDK | [Open Agent SDK (Swift)](https://github.com/terryso/open-agent-sdk-swift) |
| Markdown | [swift-markdown](https://github.com/apple/swift-markdown) (Apple) |
| Syntax Highlighting | [Splash](https://github.com/JohnSundell/Splash) |
| Auto-Update | [Sparkle](https://github.com/sparkle-project/Sparkle) 2.x |

## Project Structure

```
SwiftWork/
├── App/
│   ├── SwiftWorkApp.swift            # App entry point
│   └── ContentView.swift             # Root view with NavigationSplitView
├── Models/
│   ├── UI/                           # UI-facing models (AgentEvent, ToolContent)
│   └── SwiftData/                    # Persistent models (Session, Event)
├── ViewModels/
│   ├── SessionViewModel.swift        # Session management
│   └── SettingsViewModel.swift       # Settings management
├── Views/
│   ├── Sidebar/                      # Session list
│   ├── Workspace/
│   │   ├── Timeline/EventViews/      # Per-event-type views
│   │   ├── Inspector/                # Event detail panel
│   │   └── InputBar/                 # Message input
│   └── Settings/                     # Settings interface
├── SDKIntegration/
│   ├── AgentBridge.swift             # SDK ↔ ViewModel bridge
│   ├── EventMapper.swift             # SDKMessage → AgentEvent
│   ├── ToolRenderable.swift          # Tool rendering protocol
│   └── ToolRendererRegistry.swift    # Extensible tool registry
└── Utils/
    └── Extensions/                   # Color, Date formatting helpers
```

## Architecture

SwiftWork follows an event-driven architecture:

```
AsyncStream<SDKMessage> → AgentBridge → EventMapper → ViewModel → SwiftUI
```

Key principles:
- **Strict concurrency** — all UI code is `@MainActor` isolated
- **Separation of concerns** — views consume UI models, never raw SDK types
- **Extensibility** — new tool types are registered via `ToolRendererRegistry` without modifying the timeline

## Getting Started

### Prerequisites
- macOS 14.0+ (Sonoma)
- Xcode 16.0+
- Swift 6.1+

### Build & Run

```bash
git clone https://github.com/terryso/SwiftWork.git
cd SwiftWork
open Package.swift
# Press Cmd+R in Xcode to build and run
```

Or via command line:

```bash
swift build
swift run SwiftWork
```

## Installation

Download the latest `SwiftWork-*.dmg` from [Releases](https://github.com/terryso/SwiftWork/releases), then:

1. Open the DMG and drag **SwiftWork.app** to **Applications**
2. Run the following command to remove macOS quarantine:

```bash
xattr -cr /Applications/SwiftWork.app
```

3. Launch SwiftWork from Applications or Spotlight

## Development Status

| Epic | Description | Status |
|---|---|---|
| Epic 1 | First launch & basic interaction (SDK→UI loop) | Done |
| Epic 2 | Agent execution visualization (Tool Cards) | In Progress |
| Epic 3 | Permission control & session management | Backlog |
| Epic 4 | Debug panel & app shell | Backlog |

**Epic 1** (done): Project init, onboarding, session management, message input, event timeline, state restore.

**Epic 2** (in progress): Tool visualization architecture, tool card experience, event visual system, markdown/code highlighting, timeline performance.

## Roadmap

### In Progress — Epic 2: Agent Execution Visualization
- [ ] Event visual system — color/icon differentiation by event type, error highlighting
- [ ] Markdown rendering — headings, lists, bold/italic, inline code, tables
- [ ] Code syntax highlighting — Swift, Python, JavaScript, Bash via Splash
- [ ] Long text collapse/expand
- [ ] Timeline performance — lazy loading, virtualization for 1000+ events

### Planned — Epic 3: Permission Control & Session Management
- [ ] Permission system — native macOS dialogs for tool call approval (Allow Once / Always Allow / Deny)
- [ ] Permission rules management — view, edit, delete rules in settings
- [ ] Global permission modes — auto-approve, manual review, deny all
- [ ] Session management — delete sessions with cascade, inline rename
- [ ] Follow-up messages during agent execution
- [ ] Inspector Panel — full event details (JSON, timing, token usage)
- [ ] Execution plan visualization — step list with status and dependencies

### Planned — Epic 4: Debug Panel & App Shell
- [ ] Debug Panel — raw SDK event stream, token consumption stats, tool execution logs
- [ ] App settings — API Key management, model selection, permission configuration
- [ ] macOS menu bar — File / Edit / View / Window / Help menus
- [ ] Keyboard shortcuts — Cmd+N, Cmd+W, Cmd+,
- [ ] Dock badge — unread session count
- [ ] Standard macOS window management — fullscreen, split view, Stage Manager

## License

[MIT](./LICENSE)
