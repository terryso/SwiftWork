# Deferred Work

## Deferred from: code review of 1-2-onboarding-agent-config (2026-05-01)

- KeychainManagerTests 直接操作真实 Keychain — 作为集成测试保留，后续可添加 mock 版本进行纯单元测试
- Keychain 未显式设置 kSecAttrAccessible — 默认值 kSecAttrAccessibleWhenUnlocked 已满足当前 macOS 应用需求，未来跨平台移植时需显式设置
- WelcomeView 缺少 accessibility 标识 — VoiceOver 支持属于后续 UX 打磨阶段，应在 Phase 4 统一处理

## Deferred from: code review of 1-6-app-state-restore (2026-05-01)

- loadNSRect treats zero rect as nil — minimized window edge case where NSRectFromString returns zero. Extremely unlikely in practice; design choice rather than bug.

## Deferred from: fix-tool-card-spinner (2026-05-01)

- Orphan toolResult events (no prior toolUse entry in toolContentMap) are silently dropped — pre-existing behavior, not a regression. Legacy ToolResultView fallback renders acceptably.
- loadEvents(for:) does not rebuild toolContentMap from persisted events — after app restart or session switch, all historical tools degrade to legacy ToolCallView rendering. Should be addressed when implementing session restore for tool cards.

## Deferred from: code review of 2-5-timeline-performance (2026-05-02)

- 缺少 600ms 手势窗口防误判 — Story spec 引用 OpenWork scroll-controller.ts 的 600ms 防抖窗口未实现，快速滚动时可能导致 follow/manual 模式闪烁 [ScrollModeManager.swift]。v1 可接受，后续 UX 打磨时添加。
- 无向上滚动加载更多事件触发机制 — 用户向上滚动到已加载事件顶部时没有触发 loadMoreEvents() 的机制，当前仅支持初始分页加载 [TimelineView.swift]。后续 story 可通过 topPlaceholder.onAppear 触发。

## Deferred from: checkpoint review of 4-1-debug-panel (2026-05-03)

- `colorForEventType` 在 InspectorView 和 RawEventStreamView 中重复 — 提取为共享 `Color+EventType.swift` 扩展可消除重复，但当前刻意保持独立以避免不必要的大范围重构。建议在 Epic 4 收尾或 Phase 4 UX 打磨阶段统一处理。
- DebugViewModel 计算属性（`toolLogs`、`tokenSummary`、`filteredEvents`）每次访问遍历全量 events — MVP 阶段会话事件数在可接受范围内。如后续出现性能问题，改为 `@ObservationIgnored` + 手动刷新按钮。
- `ForEach(Array(resultEvents.enumerated()), id: \.offset)` 在 TokenStatsView 中使用 index 作为 identity — append-only 事件模式下风险极低，理想做法应使用 event.id。

## Deferred from: code review of 4-2-app-settings (2026-05-03)

- 缺少规格中的"高级"Tab — 规格 Tab 结构为三 Tab（通用/权限/高级），实际实现为两 Tab（通用/权限），Base URL 放入通用 Tab。设计决策：Base URL 与 API Key 逻辑关联更紧密，高级 Tab 标注为"可选"。
