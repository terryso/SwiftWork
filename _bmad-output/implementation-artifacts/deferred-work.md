# Deferred Work

## Deferred from: code review of 1-2-onboarding-agent-config (2026-05-01)

- KeychainManagerTests 直接操作真实 Keychain — 作为集成测试保留，后续可添加 mock 版本进行纯单元测试
- Keychain 未显式设置 kSecAttrAccessible — 默认值 kSecAttrAccessibleWhenUnlocked 已满足当前 macOS 应用需求，未来跨平台移植时需显式设置
- WelcomeView 缺少 accessibility 标识 — VoiceOver 支持属于后续 UX 打磨阶段，应在 Phase 4 统一处理
