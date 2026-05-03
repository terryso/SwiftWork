# Story 4-3 手工测试验收清单

## 前置条件

- [ ] 应用正常启动，显示主界面（Sidebar + Workspace）
- [ ] 已完成 onboarding（API Key 已配置）
- [ ] 至少存在一个会话

---

## AC #1: 标准 macOS 菜单结构（FR45）

**目标：** 验证应用菜单栏包含 File/Edit/View/Window/Help 五个标准菜单

- [ ] **1.1 File 菜单**
  - 步骤：点击菜单栏 File
  - 预期：显示「新建会话」(Cmd+N) 和「关闭窗口」(Cmd+W)

- [ ] **1.2 Edit 菜单**
  - 步骤：点击菜单栏 Edit
  - 预期：显示标准项：复制(Cmd+C)、粘贴(Cmd+V)、剪切(Cmd+X)、全选(Cmd+A)、撤销(Cmd+Z)、重做(Cmd+Shift+Z)

- [ ] **1.3 View 菜单 — Inspector**
  - 步骤：点击菜单栏 View
  - 预期：显示「切换 Inspector」(Cmd+I)

- [ ] **1.4 View 菜单 — Debug Panel**
  - 步骤：点击菜单栏 View
  - 预期：显示「切换 Debug Panel」(Cmd+Shift+D)

- [ ] **1.5 应用菜单（设置）**
  - 步骤：点击第一个菜单（SwiftWork）
  - 预期：显示「设置...」(Cmd+,)

- [ ] **1.6 Window 菜单**
  - 步骤：点击菜单栏 Window
  - 预期：显示标准项：最小化(Cmd+M)、缩放、全部前置

- [ ] **1.7 Help 菜单**
  - 步骤：点击菜单栏 Help
  - 预期：显示搜索框（SwiftUI 默认提供）

---

## AC #2: Cmd+N 新建会话（FR46）

**目标：** 验证快捷键 Cmd+N 创建新会话并自动选中

- [ ] **2.1 Cmd+N 创建会话**
  - 步骤：按下 Cmd+N
  - 预期：Sidebar 新增一个会话，Workspace 切换到新会话

- [ ] **2.2 连续创建多个会话**
  - 步骤：连续按 Cmd+N 三次
  - 预期：Sidebar 显示 3 个新会话，每次自动选中最新创建的

- [ ] **2.3 菜单栏点击「新建会话」**
  - 步骤：File 菜单 → 点击「新建会话」
  - 预期：与 Cmd+N 效果相同，创建并选中新会话

- [ ] **2.4 不同界面下 Cmd+N 均可用**
  - 步骤：在 Inspector 打开、Debug Panel 打开、设置打开等不同状态下按 Cmd+N
  - 预期：均能正常创建新会话

---

## AC #3: Cmd+W 关闭窗口（FR46）

**目标：** 验证 Cmd+W 关闭当前窗口（SwiftUI WindowGroup 默认行为）

- [ ] **3.1 Cmd+W 关闭窗口**
  - 步骤：按下 Cmd+W
  - 预期：当前窗口关闭（macOS 标准行为）

---

## AC #4: Cmd+, 打开设置页面（FR46）

**目标：** 验证快捷键 Cmd+, 打开设置 Sheet

- [ ] **4.1 Cmd+, 打开设置**
  - 步骤：按下 Cmd+,
  - 预期：弹出设置 Sheet，显示通用和权限两个 Tab

- [ ] **4.2 关闭设置后再次打开**
  - 步骤：关闭设置 Sheet → 再次按 Cmd+,
  - 预期：设置 Sheet 再次正常弹出

- [ ] **4.3 菜单栏点击「设置...」**
  - 步骤：应用菜单 → 点击「设置...」
  - 预期：与 Cmd+, 效果相同

- [ ] **4.4 齿轮按钮仍可用**
  - 步骤：点击 Sidebar toolbar 的齿轮图标
  - 预期：仍能正常打开设置（回归验证）

---

## View 菜单快捷键

**目标：** 验证 Inspector 和 Debug Panel 的快捷键切换

- [ ] **5.1 Cmd+I 打开 Inspector**
  - 步骤：按下 Cmd+I
  - 预期：Inspector 面板打开（右侧滑入）

- [ ] **5.2 Cmd+I 关闭 Inspector**
  - 步骤：再次按下 Cmd+I
  - 预期：Inspector 面板关闭

- [ ] **5.3 Cmd+Shift+D 打开 Debug Panel**
  - 步骤：按下 Cmd+Shift+D
  - 预期：Debug Panel 打开（底部浮出）

- [ ] **5.4 Cmd+Shift+D 关闭 Debug Panel**
  - 步骤：再次按下 Cmd+Shift+D
  - 预期：Debug Panel 关闭

- [ ] **5.5 Inspector 持久化**
  - 步骤：Cmd+I 打开 Inspector → Cmd+Q 退出 → 重新启动应用
  - 预期：Inspector 仍为打开状态（通过 AppStateManager 恢复）

- [ ] **5.6 Debug Panel 持久化**
  - 步骤：Cmd+Shift+D 打开 Debug Panel → Cmd+Q 退出 → 重新启动应用
  - 预期：Debug Panel 仍为打开状态

---

## AppState 共享状态验证

**目标：** 验证菜单命令和 UI 操作共享同一状态实例

- [ ] **6.1 菜单命令 → UI 同步**
  - 步骤：Cmd+I 打开 Inspector → 观察 Workspace 中的 Inspector 状态
  - 预期：Workspace 中 Inspector 状态与菜单命令一致

- [ ] **6.2 UI 操作 → 菜单命令同步**
  - 步骤：通过 Workspace 内的按钮关闭 Inspector → 菜单栏 View 显示的状态一致
  - 预期：两种操作方式共享同一 AppState 实例

---

## 回归验证

- [ ] **7.1 首次引导流程**
  - 步骤：删除应用数据 → 重新启动 → 完成 onboarding
  - 预期：WelcomeView 正常显示，onboarding 完成后菜单栏功能正常

- [ ] **7.2 Sidebar 会话管理**
  - 步骤：通过 Sidebar 创建/选择/删除会话
  - 预期：功能与之前版本一致，无回归

- [ ] **7.3 Agent 执行**
  - 步骤：发送消息触发 Agent 执行
  - 预期：Timeline 正常显示事件流

- [ ] **7.4 设置页面功能**
  - 步骤：Cmd+, 打开设置 → 修改模型/API Key
  - 预期：设置页面功能正常，与 4-2 版本一致

---

## 自动化测试结果

| 指标 | 结果 |
|------|------|
| 总测试数 | 742 |
| 失败数 | 0 |
| 新增 Story 4-3 测试 | 18 (MenuBarCommands 12 + AppStateIntegration 6) |
| 新增 AppEntryTests | 1 |
| 覆盖率 | 100% |
| 质量门 | PASS |

---

## 验收决策

- [ ] 所有 AC 测试项通过 → **Approve**
- [ ] 存在阻塞性问题 → **Rework**（记录问题详情）
- [ ] 非阻塞性问题 → **Approve with notes**

验收人：__________  日期：__________  决策：__________
