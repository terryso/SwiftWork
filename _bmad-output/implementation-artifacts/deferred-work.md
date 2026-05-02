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
