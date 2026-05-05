# Manual Acceptance Checklist — Story 5.3: Skill 调用 Timeline 卡片渲染

**Date:** 2026-05-05
**Reviewer:** Nick
**Status:** ⬜ Pending

## 前置条件

- [ ] App 已构建并启动
- [ ] API Key 已配置，Agent 可正常连接
- [ ] 至少有一个可用 skill（如 `/review` 或 `/simplify`）

## AC#1 — Skill toolUse 卡片识别与渲染

- [ ] 触发一次 Skill 调用（如输入 `/review check auth code`），Timeline 中出现 Skill 专用卡片
- [ ] 卡片显示 skill 名称，格式为 `/review`（斜杠前缀）
- [ ] 卡片显示参数 "check auth code" 作为副标题
- [ ] 卡片左边条为紫色（与其他工具的绿色/橙色区分）
- [ ] 卡片图标为 sparkles（不是 terminal 或 wrench）

## AC#2 — Skill toolResult 完成状态

- [ ] Skill 执行完成后，卡片更新为 completed 状态标签（绿色）
- [ ] 展开卡片，显示执行结果摘要（成功/失败状态图标）
- [ ] 成功时显示绿色 checkmark 图标 + commandName
- [ ] 失败时显示红色 xmark 图标 + 错误信息

## AC#3 — 展开详情

- [ ] 点击卡片可展开/折叠
- [ ] 展开后显示 skill 的 prompt 摘要（前 ~200 字符）
- [ ] 展开后显示 INPUT 区域，包含完整 input JSON
- [ ] 展开后显示 OUTPUT 区域（toolResult 内容）

## AC#4 — 多个 Skill 调用视觉区分

- [ ] 连续触发多个不同 Skill 调用，每个独立渲染为卡片
- [ ] 每张卡片根据各自 input JSON 显示正确的 skill 名称和参数
- [ ] Skill 卡片与普通工具卡片（Bash、Edit 等）视觉明显不同（紫色 + sparkles）

## 边界情况

- [ ] Skill 调用长时间运行时，卡片显示 pending/running 状态 + ProgressView
- [ ] Skill 调用失败时，卡片显示红色错误状态

## 视觉检查

- [ ] Skill 卡片与 Bash 卡片（绿色 + terminal）颜色不同
- [ ] Skill 卡片与 Edit 卡片（橙色 + doc.text）颜色不同
- [ ] 折叠态信息层次清晰：图标 → `/skillName` → args 参数 → 状态标签
- [ ] 展开态布局合理，无文字溢出或截断异常

## 回归检查

- [ ] 普通工具调用（Bash、Read、Edit）仍正常渲染
- [ ] Timeline 滚动流畅，Skill 卡片不影响整体性能
- [ ] 其他 Timeline 事件（assistant message、system 提示等）不受影响

## Sign-off

- [ ] 全部通过 → 标记 Story 5-3 为 done
- [ ] 有失败项 → 记录问题，退回修复
