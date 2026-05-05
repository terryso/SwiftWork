# Manual Acceptance Checklist — Story 5.2: 输入框斜杠命令自动补全

**Date:** 2026-05-05
**Reviewer:** Nick
**Status:** ⬜ Pending

## 前置条件

- [ ] App 已构建并启动
- [ ] API Key 已配置，Agent 可正常连接
- [ ] `discoveredSkills` 非空（AgentBridge 已发现 skills）

## AC#1 — 斜杠触发自动补全

- [ ] 输入框为空时输入 `/`，光标下方弹出浮动菜单
- [ ] 菜单显示所有 userInvocable skill，每项包含 name + description
- [ ] 默认选中第一项（高亮背景）

## AC#2 — 模糊过滤

- [ ] 输入 `/co`，菜单过滤为匹配 "co" 的 skill（如 commit）
- [ ] 输入 `/ci`，通过别名匹配显示 commit
- [ ] 前缀匹配项排在包含匹配项之前
- [ ] 输入 `/COM`（大写）仍然匹配 commit（大小写不敏感）

## AC#3 — 键盘选择与确认

- [ ] 菜单弹出后按 Down 箭头，选中项下移一行
- [ ] 按 Up 箭头，选中项上移一行
- [ ] 在第一项按 Up，循环跳到最后一项
- [ ] 在最后一项按 Down，循环跳到第一项
- [ ] 按 Enter 确认选择，输入框替换为 `/skillName `（末尾带空格）
- [ ] 确认后菜单关闭

## AC#4 — Escape/点击外部关闭

- [ ] 菜单弹出后按 Escape，菜单关闭
- [ ] Escape 后输入框保留当前文本（如 `/co`），不被清空
- [ ] 点击菜单外区域，菜单关闭（待验证——取决于 SwiftUI onTapGesture 外部点击行为）

## AC#5 — 不匹配时作为普通文本发送

- [ ] 输入 `/hello`（不匹配任何 skill），菜单不弹出
- [ ] 按 Enter 发送，`/hello` 作为普通文本发送给 Agent

## AC#6 — 仅在行首触发

- [ ] 输入 `hello /`，不触发自动补全
- [ ] 输入 `hello/world`，不触发自动补全
- [ ] 输入 `  /`（前导空白 + 斜杠），触发自动补全

## 鼠标交互

- [ ] 鼠标点击菜单中某一项，输入框替换为 `/skillName `
- [ ] 点击后菜单关闭

## 视觉检查

- [ ] 菜单出现在输入框正上方
- [ ] 菜单宽度与输入框一致
- [ ] 菜单最大高度约 200pt，超出时可滚动
- [ ] 每行显示：skill 名称（粗体）+ argumentHint（如有）+ aliases（如有）+ 描述（截断 1 行）
- [ ] 选中项有淡蓝色高亮背景
- [ ] 菜单有圆角、边框、阴影

## 回归检查

- [ ] 不含 `/` 的普通消息仍可正常发送
- [ ] Agent 运行中发送消息仍正常工作
- [ ] Shift+Enter 换行仍正常工作
- [ ] 多行文本发送仍正常工作

## Sign-off

- [ ] 全部通过 → 标记 Story 5-2 为 done
- [ ] 有失败项 → 记录问题，退回修复
