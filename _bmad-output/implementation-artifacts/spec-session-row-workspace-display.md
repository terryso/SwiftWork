---
title: '会话行工作目录显示'
type: 'feature'
created: '2026-05-09T10:53:00+08:00'
status: 'done'
route: 'one-shot'
context:
  - '{project-root}/_bmad-output/project-context.md'
---

## Intent

**Problem:** 会话已绑定工作目录，但侧边栏会话行中没有地方展示当前工作目录是什么，用户无法直观区分不同工作目录的会话。

**Approach:** 在 `SessionRowView` 的会话名字下方、时间戳上方，新增一行显示工作目录的文件夹名称（带 folder 图标），仅当 `workspacePath` 非空时显示。

## Suggested Review Order

1. `SwiftWork/Views/Sidebar/SessionRowView.swift` — 唯一变更文件：添加工作目录标签行、修复空字符串防御和无障碍标签
