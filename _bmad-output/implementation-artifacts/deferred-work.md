# Deferred Work

## Deferred from: code review of 1-2-onboarding-agent-config (2026-05-01)

- KeychainManagerTests 直接操作真实 Keychain — 作为集成测试保留，后续可添加 mock 版本进行纯单元测试。**处置决策：接受。** 集成测试有价值，优先级低。
- Keychain 未显式设置 kSecAttrAccessible — 默认值 kSecAttrAccessibleWhenUnlocked 已满足当前 macOS 应用需求，未来跨平台移植时需显式设置。**处置决策：接受。** 仅跨平台时需要。
- WelcomeView 缺少 accessibility 标识 — VoiceOver 支持属于后续 UX 打磨阶段，应在 Phase 4 统一处理。**处置决策：接受。** UX 打磨阶段处理。

## Deferred from: fix-tool-card-spinner (2026-05-01)

- Orphan toolResult events (no prior toolUse entry in toolContentMap) are silently dropped — pre-existing behavior, not a regression. Legacy ToolResultView fallback renders acceptably. **处置决策：接受。** 极端边界情况，降级渲染可接受。
- ~~loadEvents(for:) does not rebuild toolContentMap from persisted events~~ — **已修复。** `loadEvents(for:)` 已在加载后调用 `rebuildToolContentMap()`，toolContentMap 从持久化事件正确重建。

## Deferred from: code review of 1-6-app-state-restore (2026-05-01)

- loadNSRect treats zero rect as nil — minimized window edge case where NSRectFromString returns zero. Extremely unlikely in practice; design choice rather than bug. **处置决策：接受。** 极端边界情况。

## Deferred from: fix-tool-card-spinner (2026-05-01)

- ~~loadEvents(for:) does not rebuild toolContentMap from persisted events~~ — **已修复。** `rebuildToolContentMap()` 在 loadEvents/loadInitialPage/loadMoreEvents/loadEarlierEvents 中均已调用。

## Deferred from: code review of 2-5-timeline-performance (2026-05-02)

- 缺少 600ms 手势窗口防误判 — Story spec 引用 OpenWork scroll-controller.ts 的 600ms 防抖窗口未实现，快速滚动时可能导致 follow/manual 模式闪烁 [ScrollModeManager.swift]。v1 可接受，后续 UX 打磨时添加。**处置决策：计划修复。** UX 打磨阶段添加防抖。
- ~~无向上滚动加载更多事件触发机制~~ — **已修复。** 添加了 `loadEarlierEvents()` 方法和 TimelineView topPlaceholder 的 onAppear 触发机制。

## Deferred from: checkpoint review of 4-1-debug-panel (2026-05-03)

- ~~`colorForEventType` 在 InspectorView 和 RawEventStreamView 中重复~~ — **已修复。** 提取为共享 `Color+EventType.swift` 扩展。
- DebugViewModel 计算属性（`toolLogs`、`tokenSummary`、`filteredEvents`）每次访问遍历全量 events — MVP 阶段会话事件数在可接受范围内。如后续出现性能问题，改为 `@ObservationIgnored` + 手动刷新按钮。**处置决策：接受。** MVP 阶段可接受，性能问题出现时再优化。
- `ForEach(Array(resultEvents.enumerated()), id: \.offset)` 在 TokenStatsView 中使用 index 作为 identity — append-only 事件模式下风险极低，理想做法应使用 event.id。**处置决策：接受。** 低风险，后续清理时修改。

## Deferred from: code review of 4-2-app-settings (2026-05-03)

- 缺少规格中的"高级"Tab — 规格 Tab 结构为三 Tab（通用/权限/高级），实际实现为两 Tab（通用/权限），Base URL 放入通用 Tab。**处置决策：接受。** 设计决策：Base URL 与 API Key 逻辑关联更紧密。

## Deferred from: code review of 4-4-dock-badge-window-management (2026-05-03)

- AppState notification observer never cleaned up (no deinit) — AppState lives for app lifetime so harmless. **处置决策：接受。** 生命周期同应用，无害。
- ~~markSessionAsUnread marks selectedSession, not the actual result session~~ — **部分修复。** 改为多回调模式（`addOnResultCallback`），WorkspaceView 和 ContentView 各自注册回调，不再互相覆盖。但仍然使用 selectedSession，因为当前单会话执行模型下是正确的。
- Sendable warnings in ContentView.swift:207 and ContentView.swift:215 — pre-existing from Story 4-3 (non-Sendable `saveWindowFrameThrottled` to `@Sendable` parameter). **处置决策：计划修复。** 后续清理时处理。

## Deferred from: code review of 3-2-permission-config-rules (2026-05-02)

- globalMode 持久化 `persistGlobalMode()` 写入失败时静默吞掉错误 — 默认值兜底，功能不受影响，但丢失了诊断信息。**处置决策：接受。** 影响极低，用户无感知。

## Deferred from: code review of 3-4-inspector-panel (2026-05-03)

- ~~CopyButton 定义在 ToolCardView.swift 中而非独立文件~~ — **已修复。** 提取为 `SwiftWork/Views/Common/CopyButton.swift`，4 个文件复用同一组件。

## Newly discovered during retrospective tech debt review (2026-05-03)

- WorkspaceView.setupTitleGeneration() overwrites agentBridge.onResult callback — **已修复。** 改为多回调模式 `addOnResultCallback`，支持多个回调共存。
- loadEvents(for:) for large sessions (>1000) loaded oldest events instead of newest — **已修复。** 改为加载最新 pageSize 条事件，并跟踪 trimmedEventCount 以支持向上分页加载。

## Deferred from: code review of 5-1-sdk-skill-pipeline (2026-05-05)

- hashInput not collision-resistant — doom loop detection "hash" uses `String(describing:)` which may produce nondeterministic output for nested types and can collide for different inputs. Pre-existing design choice, acceptable for heuristic detection, not a correctness bug. [AgentBridge.swift:590-597]
- nonisolated(unsafe) for input dict crossing actors — `setupPermissionCallback` uses `nonisolated(unsafe)` to pass the SDK's input dictionary across actor boundaries. SDK contract is that input dicts are immutable in practice, but the pattern suppresses concurrency safety checks. [AgentBridge.swift:473]
- Dead code: PendingPermissionRequest and PermissionDialogView — These files are no longer referenced after the inline permission card migration. `PermissionDialogView` is marked deprecated but still compiles. Cleanup task for a future story. [PendingPermissionRequest.swift, PermissionDialogView.swift]

## Deferred from: code review of 6-3-mcp-management-panel (2026-05-07)

- Management panel hardcodes `scope: .global` for add/edit sheets — cannot add or edit workspace-scoped MCP configs from the management panel. Acceptable for MVP, but should be extended when project-scoped MCP becomes a priority. [MCPManagementView.swift:37,48]
- No expandable "查看详情" section for error display — AC7 spec mentions a "查看详情" expandable area, but the current implementation shows error inline. Minor deviation, acceptable for MVP. [MCPServerDetailView.swift:100-114]

- source_spec: `_bmad-output/implementation-artifacts/spec-swiftwork-global-skill-discovery.md`
  summary: 为全局 Skill 的 supporting files 设计受限的 workspace 外读取与执行边界。
  evidence: 现有 workspace 系统提示禁止普通文件操作越界，而 SDK SkillTool 会返回全局 Skill 的 baseDir 与 supportingFiles；依赖 references 或 scripts 的既有全局 Skill 无法同时遵守两者。
