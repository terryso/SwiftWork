# Story 6-6 手工验收清单

## AC1 — 高级设置折叠区

- [ ] 打开 Settings → MCP Servers，滚动到服务器列表底部，可见"高级设置"区域
- [ ] "高级设置"区域默认折叠，仅显示标题行（齿轮图标 + "高级设置" + "管理配置文件" + 向下箭头）
- [ ] 点击标题行，区域展开，显示 scope 切换、配置文件路径、操作按钮
- [ ] 再次点击标题行，区域折叠，有平滑动画

## AC2 — 配置文件路径显示

- [ ] 展开后默认选中 Global scope
- [ ] Global scope 显示路径 `~/.claude/settings.json`（monospaced 字体）
- [ ] 点击 Project 按钮切换到 Project scope（需有已绑定的 workspace）
- [ ] Project scope 显示路径 `{workspace}/.claude/settings.json`
- [ ] 无 workspace 绑定时，Project 按钮显示为禁用状态（灰色）
- [ ] 配置文件不存在时，路径下方显示橙色"文件尚未创建"提示

## AC3 — 在 Finder 中显示

- [ ] 配置文件存在时，点击"在 Finder 中显示"按钮，Finder 打开并定位到该文件
- [ ] 配置文件不存在时，"在 Finder 中显示"按钮显示为禁用状态

## AC4 — 外部编辑检测与重新加载

### 手动刷新

- [ ] 在外部编辑器中修改 `~/.claude/settings.json`，添加或修改一个 MCP server
- [ ] 回到 SwiftWork，点击"刷新配置"按钮
- [ ] 新增的 server 出现在 MCP 管理面板列表中
- [ ] 修改的 server 信息已更新（如 command、url 等）
- [ ] SwiftData 中独有的 server（文件中没有的）保持不变

### 文件监控（自动刷新）

- [ ] 展开高级设置后，配置文件存在时文件监控自动启动
- [ ] 在外部编辑器中修改配置文件并保存
- [ ] 切换回 SwiftWork，变更自动同步到 MCP 管理面板（无需手动点击刷新）
- [ ] 监控回调出错时弹出 alert 提示（而非静默失败）

### Scope 切换后监控更新

- [ ] 在 Global scope 下展开高级设置（监控 Global 配置文件）
- [ ] 切换到 Project scope
- [ ] 修改 Project scope 对应的配置文件
- [ ] 变更能被正确检测并同步（监控路径已随 scope 切换更新）

## 边界场景

- [ ] `~/.claude/settings.json` 文件不存在时，界面不崩溃，显示"文件尚未创建"
- [ ] 配置文件内容为空 JSON `{}` 时，刷新不崩溃，不影响已有配置
- [ ] 配置文件 JSON 格式错误时，刷新不崩溃
- [ ] 未绑定 workspace 时 Project scope 路径显示提示信息
- [ ] 高级设置区域折叠后，文件监控停止
