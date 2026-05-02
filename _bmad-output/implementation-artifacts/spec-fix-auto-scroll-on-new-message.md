---
title: 'Fix: auto-scroll to bottom when user sends new message'
type: 'bugfix'
created: '2026-05-03'
status: 'done'
route: 'one-shot'
---

# Fix: auto-scroll to bottom when user sends new message

## Intent

**Problem:** When a user sends a new message in the same session while scroll mode is `manualBrowse` (from previously scrolling up), the AI response does not auto-scroll to the bottom. The `onChange(of: events.count)` handler only scrolls when `scrollMode == .followLatest`, but nothing resets the mode back to `followLatest` when the user sends a new message.

**Approach:** Detect new `.userMessage` events in the `onChange(of: agentBridge.events.count)` handler and call `scrollModeManager.returnToBottom()` to reset to `followLatest` mode before scrolling.

## Suggested Review Order

1. [TimelineView.swift](../../SwiftWork/Views/Workspace/Timeline/TimelineView.swift) — the onChange handler at ~L105 with the new userMessage detection logic
2. [ScrollModeManager.swift](../../SwiftWork/Views/Workspace/Timeline/ScrollModeManager.swift) — the `returnToBottom()` method being called
