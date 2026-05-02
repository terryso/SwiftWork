# Story 3-1 手工验收清单

**Story:** 权限系统实现
**日期:** 2026-05-02
**测试结果:** 533 tests passed, 0 failures

---

## 前置条件

- [ ] App 可正常启动，无 crash
- [ ] 已有功能（会话、Timeline、消息输入）正常工作（回归验证）

## AC#1: 权限评估 & Sheet 弹窗

**Given** manualReview 模式启用，Agent 要执行一个需要审批的工具调用
**When** PermissionHandler 评估结果为 `.requiresApproval`
**Then** 弹出原生 macOS Sheet 对话框

- [ ] Sheet 正确弹出（非 alert / popover）
- [ ] 显示 shield 图标（`shield.checkered`）
- [ ] 显示工具类型标签（Bash→"终端命令"、Edit/Write→"文件编辑"、Read→"文件读取"）
- [ ] 显示操作描述文本
- [ ] 显示参数键值对（command/filepath/cwd 等，中文标签）
- [ ] 底部三个按钮：拒绝（红色）、始终允许（轮廓）、允许一次（主按钮）
- [ ] "显示详细信息" 可展开完整 JSON
- [ ] Sheet 宽度约 480pt

## AC#2: Allow Once（允许一次）

**Given** 权限弹窗已弹出
**When** 用户点击"允许一次"
**Then** 当前工具调用被授权，下次同类操作仍需审批

- [ ] 点击"允许一次"后工具正常执行
- [ ] 同一会话中再次调用同类工具**不弹窗**（sessionOverride 生效）
- [ ] 新建会话后同类工具**再次弹窗**（sessionOverride 仅会话级）

## AC#3: Always Allow（始终允许）

**Given** 权限弹窗已弹出
**When** 用户点击"始终允许"
**Then** 当前调用被授权，该工具+模式持久化为 PermissionRule

- [ ] 点击"始终允许"后工具正常执行
- [ ] 同一会话中再次调用同类工具不弹窗
- [ ] **重启 app** 后同类工具仍然不弹窗（PermissionRule 已持久化到 SwiftData）
- [ ] PermissionRule 记录包含正确的 toolName、pattern("*")、decision(.allow)

## AC#4: Deny（拒绝）

**Given** 权限弹窗已弹出
**When** 用户点击"拒绝"
**Then** 工具调用被拒绝，Agent 收到拒绝反馈

- [ ] 点击"拒绝"后工具不执行
- [ ] Agent 收到拒绝原因（"用户拒绝"）
- [ ] Agent 可继续执行其他任务（不卡死）
- [ ] 按 Escape 键关闭 Sheet 等同于拒绝

## AC#5: 审计日志

**Given** 任何权限决策发生
**When** 用户做出选择
**Then** 审计日志记录工具名、操作内容、用户决策、时间戳

- [ ] 每次弹窗操作后 auditLog 正确追加一条记录
- [ ] autoApprove 模式下的调用也记录审计日志
- [ ] 审计条目包含：toolName、input 描述、simplified decision、timestamp、sessionOverride flag

## 向后兼容性（默认 autoApprove）

**Given** 使用默认配置（autoApprove 模式）
**When** 正常使用 app，Agent 调用各种工具
**Then** 无权限弹窗，行为与 Story 1-1~2-5 完全一致

- [ ] Bash 工具自动通过
- [ ] Read/Edit/Write 工具自动通过
- [ ] 无任何弹窗或阻断
- [ ] 审计日志仍正确记录所有决策

## 边界情况

- [ ] 无网络时权限系统不影响 app 已有功能
- [ ] 快速连续触发多个工具调用时，Sheet 不会叠加（一次只弹一个）
- [ ] Sheet 弹出时主窗口内容仍可滚动查看（Sheet 不阻塞主线程）

---

## 验收结果

- [ ] **通过** — 所有 AC 检查项通过
- [ ] **有条件通过** — 存在非阻塞性问题，附说明
- [ ] **不通过** — 存在阻塞性问题，需返工

**验收人:** ________  **日期:** ________  **备注:** ________
