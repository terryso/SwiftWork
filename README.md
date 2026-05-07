# SwiftWork - AI AGENT WORKBENCH FOR MACOS

![SwiftWork Banner](https://i.v2ex.co/2yumzVnq.png)

English | **[中文](./README_CN.md)**

[![Swift](https://img.shields.io/badge/Swift-6.1-orange)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)](https://developer.apple.com/macos/)
[![Download macOS](https://img.shields.io/badge/Download-macOS-000000?logo=apple&logoColor=white)](https://github.com/terryso/SwiftWork/releases/latest)
[![CI](https://github.com/terryso/SwiftWork/actions/workflows/ci.yml/badge.svg)](https://github.com/terryso/SwiftWork/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/terryso/6bc0b5140838d40c8e71ae39ce64f25f/raw/coverage.json)](https://github.com/terryso/SwiftWork/actions)
[![BMAD](https://bmad-badge.vercel.app/terryso/SwiftWork.svg)](https://github.com/bmad-code-org/BMAD-METHOD)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/terryso/SwiftWork)
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

### Permission Control
- Inline approval cards in the timeline — approve, allow for session, or deny tool calls in context
- Template-driven rule creation with inline editing in Settings
- Auto-approve mode with visual warning indicator
- Permission rule management — view, edit, delete rules

### Skill System
- Slash command autocomplete in input bar — type `/` to discover available skills
- Skill timeline cards — dedicated rendering for skill execution events
- Skill management panel in Settings — browse skills grouped by source (Built-in / Project / User)

### Inspector Panel
- Three-panel layout (Sidebar + Workspace + Inspector)
- Detailed event inspection panel
- Panel state persistence across sessions

### Onboarding & Configuration
- First-launch setup wizard
- API key management via app sandbox storage
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
│   │   │   └── ToolRenderers/        # Skill, Bash, etc. tool cards
│   │   ├── Inspector/                # Event detail panel
│   │   └── InputBar/                 # Message input + skill autocomplete
│   ├── Permission/                   # Inline approval cards
│   └── Settings/                     # Settings + skill management
├── SDKIntegration/
│   ├── AgentBridge.swift             # SDK ↔ ViewModel bridge + skill pipeline
│   ├── EventMapper.swift             # SDKMessage → AgentEvent
│   ├── PermissionHandler.swift       # Tool call approval logic
│   ├── ToolRenderable.swift          # Tool rendering protocol
│   └── ToolRendererRegistry.swift    # Extensible tool registry
├── Services/
│   └── KeychainManager.swift         # Secure credential storage
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
| Epic 2 | Agent execution visualization (Tool Cards) | Done |
| Epic 3 | Permission control & session management | Done |
| Epic 4 | Debug panel & app shell | Done |
| Epic 5 | Skill system (slash commands, cards, management) | Done |

**Epic 1** (done): Project init, onboarding, session management, message input, event timeline, state restore.

**Epic 2** (done): Tool visualization architecture, tool card experience, event visual system, markdown/code highlighting, timeline performance.

**Epic 3** (done): Inline permission approval cards, permission rules CRUD, auto-approve mode, session management, inspector panel, execution plan visualization.

**Epic 4** (done): Debug panel, multi-tab settings, macOS menu bar, dock badge.

**Epic 5** (done): SDK skill pipeline, slash command autocomplete, skill timeline card rendering, skill management panel.

## Roadmap

### Planned — Next
- [ ] Doom loop detection — identify and warn when agent is stuck in repetitive cycles
- [ ] Multi-agent support — switch between different agent configurations
- [ ] Plugin system — third-party tool renderers and skill extensions
- [ ] Export sessions — save conversation transcripts as Markdown or JSON

## License

[MIT](./LICENSE)
