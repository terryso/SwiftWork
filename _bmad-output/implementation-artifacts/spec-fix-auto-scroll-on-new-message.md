---
title: 'Fix: streaming auto-scroll broken by content-growth misdetection'
type: 'bugfix'
created: '2026-05-03'
status: 'done'
route: 'one-shot'
---

# Fix: streaming auto-scroll broken by content-growth misdetection

## Intent

**Problem:** Commit 7db1edc replaced `scrollPositionId`-based scroll detection with `BottomAnchorPreferenceKey` + cumulative delta. When streaming text grows, the bottom-anchor element moves down, producing `scrollDelta < 0`. This is misinterpreted as "user scrolling up," accumulating delta until mode switches to `manualBrowse`, which stops all auto-scrolling mid-stream. Additionally, sending a new message in an existing session never reset scroll mode to `followLatest`.

**Approach:** Dual detection strategy:
1. `onPreferenceChange(BottomAnchorPreferenceKey)` — ONLY for "near bottom" detection (distanceFromBottom <= 96 → `followLatest`). Never switches to `manualBrowse`.
2. `onChange(of: scrollPositionId)` — ONLY for "user scrolled to earlier event" detection (→ `manualBrowse`). Not affected by content growth.
3. `onChange(of: events.count)` — detect new `.userMessage` events and reset to `followLatest`.

## Suggested Review Order

1. [TimelineView.swift](../../SwiftWork/Views/Workspace/Timeline/TimelineView.swift) — scroll detection handlers at ~L78-100
2. [ScrollModeManager.swift](../../SwiftWork/Views/Workspace/Timeline/ScrollModeManager.swift) — `scrollMode` and `returnToBottom()` method
