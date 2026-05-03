# Story 3-4 手工验收清单

_Story: Inspector Panel — 右侧面板查看选中事件的详细信息_

## AC#1: Inspector 显示选中事件详情

### 空状态

- [ ] 打开 App，展开 Inspector（toolbar 右上角 `sidebar.right` 图标）
- [ ] 未选中任何事件时，Inspector 显示空状态：放大镜图标 + "选择一个事件以查看详情"

### 事件选中联动

- [ ] 点击 Timeline 中的 userMessage 事件 → Inspector 显示该事件详情（类型标签、时间戳、内容）
- [ ] 点击 Timeline 中的 assistant 事件 → Inspector 切换到该事件
- [ ] 点击 Timeline 中的 system (.init) 事件 → Inspector 显示子类型和 Session ID
- [ ] 选中事件在 Timeline 上显示蓝色边框高亮
- [ ] 切换选中不同事件，Inspector 内容实时更新

### 工具事件详情

- [ ] 选中 toolUse 事件 → Inspector 显示：工具名、状态、耗时（如有）、参数 JSON（如有）、输出（如有）
- [ ] 工具运行中 → 状态显示 "running"，耗时实时更新
- [ ] 工具完成 → 状态显示 "completed"，输出文本可选中复制
- [ ] 工具失败 → 输出文本显示为红色
- [ ] toolUse 事件无配对 ToolContent → 回退显示 metadata 中的 toolName 和 input

### Result 事件详情

- [ ] 选中 result 事件 → Inspector 显示：耗时、费用、Turn 数
- [ ] 有 Token 用量数据时 → 显示 inputTokens 和 outputTokens
- [ ] 有费用明细时 → 显示 costBreakdown JSON

### JSON 原始数据

- [ ] "原始数据"行默认折叠，显示 `▶` 箭头
- [ ] 点击展开 → 显示格式化 JSON（id, type, content, metadata, timestamp），箭头变为 `▼`
- [ ] 点击 CopyButton → JSON 内容复制到剪贴板
- [ ] 切换选中事件 → JSON 区域自动折叠回初始状态

## AC#2 & AC#3: Inspector 展开/折叠

### 切换交互

- [ ] 点击 toolbar `sidebar.right` 图标 → Inspector 面板从右侧滑出（300pt 宽），图标变为 accent color 高亮
- [ ] 再次点击 → Inspector 面板滑出收起，图标恢复 secondary 色
- [ ] 展开/折叠有 0.25s easeInOut 动画，过渡流畅

### 状态持久化

- [ ] 展开 Inspector → 关闭 App → 重新打开 → Inspector 仍为展开状态
- [ ] 折叠 Inspector → 关闭 App → 重新打开 → Inspector 仍为折叠状态

## 跨场景边界

### 会话切换

- [ ] 在会话 A 中选中一个事件 → 切换到会话 B → Inspector 回到空状态（无残留选中）
- [ ] 切换会话后 Inspector 的展开/折叠状态不受影响

### 事件类型覆盖

- [ ] 选中 partialMessage / hookStarted / hookProgress 等 Growth 类型事件 → Inspector 显示通用 metadata，不崩溃
- [ ] 选中 unknown 类型事件 → Inspector 正常渲染，不崩溃

### 滚动交互

- [ ] Inspector 展开时，Timeline 正常滚动，无手势冲突
- [ ] 在事件密集区域（100+ 事件）点击选中，无明显卡顿

---

**验收人:** _________  **日期:** _________  **结果:** Pass / Fail
