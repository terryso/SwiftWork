---
title: 'fix: tool card spinner never stops for WebSearch and other tools'
type: 'bugfix'
created: '2026-05-01'
status: 'done'
route: 'one-shot'
---

# fix: tool card spinner never stops for WebSearch and other tools

## Intent

**Problem:** ToolCardView 的 `ProgressView()` spinner 在工具状态为 `.running` 时显示，但当 stream 结束时若 `toolResult` 未正确配对，status 永远停留在 `.running`，导致 spinner 无限旋转。WebSearch 等未注册 renderer 的工具尤为明显。

**Approach:** 在 `AgentBridge` 中添加 `finalizeToolContentMap()` 方法，在 stream 结束和取消执行时将所有 `.pending`/`.running` 工具状态转为 `.completed`。同时在 `clearEvents()` 中清理 `toolContentMap`。

## Suggested Review Order

- [SwiftWork/SDKIntegration/AgentBridge.swift](SwiftWork/SDKIntegration/AgentBridge.swift) — 核心 fix：添加 `finalizeToolContentMap()` 并在 stream 结束/cancel/clear 时调用
- [SwiftWork/Views/Workspace/Timeline/EventViews/ToolCardView.swift](SwiftWork/Views/Workspace/Timeline/EventViews/ToolCardView.swift) — 消费端：`ProgressView()` 在 `.running` 时显示，fix 确保 status 不再卡住
- [_bmad-output/implementation-artifacts/deferred-work.md](_bmad-output/implementation-artifacts/deferred-work.md) — 2 项 deferred findings（orphan toolResult、loadEvents 不重建 map）
