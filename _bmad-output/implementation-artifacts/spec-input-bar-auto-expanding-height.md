---
title: 'Input Bar Auto-Expanding Height'
type: 'refactor'
created: '2026-05-04'
status: 'done'
route: 'one-shot'
---

## Intent

**Problem:** 输入框默认占据过多垂直空间（minHeight: 36pt + padding），不符合常见聊天应用的紧凑单行体验。超出最大高度后文本被裁剪而非滚动。

**Approach:** 将裸 NSTextView 包装在 NSScrollView 中，通过 AutoSizingScrollView 的 intrinsicContentSize 实现从单行（22pt）到最大高度（120pt）的自动扩展，超出后启用 overlay 滚动条。

## Boundaries & Constraints

**Always:** 保持 IME 安全输入（中文/日文组合不被打断）、Enter 发送 / Shift+Enter 换行行为不变。

**Never:** 不改变 InputBar 的整体布局结构（HStack + 发送/停止按钮）、不引入 SwiftUI 动画。

## Code Map

- `SwiftWork/Views/Workspace/InputBar/IMESafeTextView.swift` -- NSTextView + NSScrollView 包装，intrinsicContentSize 驱动高度
- `SwiftWork/Views/Workspace/InputBar/InputBarView.swift` -- 输入栏容器，移除固定 frame 约束

## Tasks & Acceptance

**Execution:**
- [x] `IMESafeTextView.swift` -- 引入 AutoSizingScrollView 替代裸 NSTextView，intrinsicContentSize 在 [22, 120] 范围内随内容增长
- [x] `IMESafeTextView.swift` -- layout() 中正确处理 textContainer 宽度（减去水平 inset）和 text view frame
- [x] `IMESafeTextView.swift` -- updateNSView 中添加 hasMarkedText() 保护 IME 组合
- [x] `InputBarView.swift` -- 移除 .frame(minHeight: 36, maxHeight: 120)，减少 padding

**Acceptance Criteria:**
- Given 空输入框, when 显示, then 高度约 30pt（单行紧凑外观）
- Given 输入多行文本, when 文本换行, then 输入框平滑增长至最大 120pt
- Given 内容超过 120pt, when 继续输入, then 出现 overlay 滚动条，文本不裁剪
- Given IME 组合中, when SwiftUI 重渲染, then 组合不被打断

## Verification

**Commands:**
- `swift build` -- expected: Build complete
- `swift test` -- expected: 779 tests passed, 0 failures

**Manual checks:**
- 在 Xcode 中运行 app，验证输入框初始为紧凑单行，输入多行文本后自动扩展
- 测试中文输入法，确认组合过程不被打断
- 粘贴长文本，确认滚动条出现
