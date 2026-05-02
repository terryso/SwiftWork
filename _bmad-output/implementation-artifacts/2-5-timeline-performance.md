# Story 2.5: Timeline 性能优化

Status: done

## Story

As a 用户,
I want 在长时间会话中 Timeline 依然保持流畅滚动,
so that 我不会因为事件数量增多而体验到卡顿。

## Acceptance Criteria

1. **Given** 会话包含 500+ 个事件 **When** 用户滚动 Timeline **Then** 使用 LazyVStack 懒加载渲染，滚动帧率不低于 60fps（NFR4, FR13）**And** 空闲内存占用不超过 100MB，活跃内存不超过 300MB

2. **Given** 会话包含 1000+ 个事件 **When** 加载会话 **Then** 通过分页加载策略，UI 不冻结（NFR13）**And** 仅渲染可视区域及 buffer 范围内的事件

3. **Given** 长时间运行会话（8小时+） **When** 持续使用 **Then** 无内存泄漏，内存占用增长不超过 20%（NFR12）

**覆盖的 FRs:** FR13
**覆盖的 NFRs:** NFR4, NFR12, NFR13
**覆盖的 ARCHs:** ARCH-10

## Tasks / Subtasks

- [x] Task 1: 实现事件分页加载（AC: #2）
  - [x] 1.1 在 `SwiftDataEventStore` 中添加分页查询方法 `fetchEvents(for:offset:limit:) -> [AgentEvent]`
  - [x] 1.2 在 `EventStoring` 协议中添加分页方法签名
  - [x] 1.3 在 `AgentBridge` 中添加分页加载状态管理：`visibleRange: Range<Int>`、`pageSize: Int`（默认 50）
  - [x] 1.4 实现 `loadInitialPage(for:)` 方法：加载前 50 个事件，设置 `hasMoreEvents` 标志
  - [x] 1.5 实现 `loadMoreEvents()` 方法：追加加载下一页事件到 `events` 数组
  - [x] 1.6 修改 `loadEvents(for:)` 方法：对大会话（1000+ 事件）仅加载首页，而非全量加载

- [x] Task 2: 实现虚拟化窗口渲染（AC: #1, #2）
  - [x] 2.1 创建 `SwiftWork/Views/Workspace/Timeline/TimelineVirtualizationManager.swift`
  - [x] 2.2 定义 `VirtualizationState`：跟踪可视区域的第一个和最后一个可见事件索引
  - [x] 2.3 定义渲染窗口常量：`renderBuffer = 20`（可视区域前后各多渲染 20 个事件）
  - [x] 2.4 实现 `eventsToRender(from:allEvents:)` 方法：返回可视窗口内的事件子集
  - [x] 2.5 在 `TimelineView` 中集成虚拟化：用 `ScrollPosition`（macOS 14+ API）检测当前可见事件
  - [x] 2.6 使用 `scrollPosition(id:anchor:)` 绑定当前可见区域的首个事件 ID
  - [x] 2.7 替换当前全量 `ForEach(agentBridge.events)` 为虚拟化后的子集 `ForEach(virtualizedEvents)`
  - [x] 2.8 在虚拟化窗口边界渲染占位视图（固定高度的 Spacer），维持正确的总滚动高度

- [x] Task 3: 实现智能滚动行为（AC: #1）
  - [x] 3.1 创建 `SwiftWork/Views/Workspace/Timeline/ScrollModeManager.swift`
  - [x] 3.2 定义 `ScrollMode` 枚举：`.followLatest`（自动滚到底部）、`.manualBrowse`（用户手动浏览）
  - [x] 3.3 检测用户手动上滚行为：当用户向上滚动超过 16px 时从 `.followLatest` 切换到 `.manualBrowse`
  - [x] 3.4 在 `.followLatest` 模式下：新事件到达时自动滚动到底部（当前行为）
  - [x] 3.5 在 `.manualBrowse` 模式下：新事件到达时不自动滚动，显示"回到底部"悬浮按钮
  - [x] 3.6 实现"回到底部"按钮 UI：悬浮在 Timeline 右下角，点击后滚动到最新事件并切换回 `.followLatest`
  - [x] 3.7 当用户滚动到距离底部 96px 以内时，自动切换回 `.followLatest` 模式
  - [x] 3.8 参考 OpenWork `scroll-controller.ts` 的双模式行为（交互逻辑，非实现方式）

- [x] Task 4: 内存优化与泄漏防护（AC: #3）
  - [x] 4.1 在 `AgentBridge` 中实现 `trimOldEvents()` 方法：当 `events.count > maxInMemory` 时移除最早的事件（保留最新 500 个在内存中）
  - [x] 4.2 确保 `AgentEvent` 和 `ToolContent` 无循环引用——检查 `metadata: [String: any Sendable]` 不会持有闭包
  - [x] 4.3 确保 `AsyncStream` subscription 在 Task 取消时正确清理（当前实现已正确，需验证）
  - [x] 4.4 在 `MarkdownContentView` 中缓存 Markdown 解析结果（避免每次 body 求值重新解析）
  - [x] 4.5 验证 `StreamingTextView` 在流式文本结束后释放定时器资源
  - [x] 4.6 添加 `@ObservationIgnored` 标记不需要触发 UI 重渲染的内部缓存属性

- [x] Task 5: 性能测试与基准（AC: #1, #2, #3）
  - [x] 5.1 创建 `SwiftWorkTests/Views/Timeline/TimelinePerformanceTests.swift`
  - [x] 5.2 测试分页加载：加载 1000 个事件的首页（50 个），验证加载时间 < 100ms
  - [x] 5.3 测试虚拟化窗口：验证 `eventsToRender` 方法在 1000 个事件中仅返回窗口内的子集
  - [x] 5.4 测试滚动模式切换：验证向上滚动触发 `.manualBrowse`，滚到底部触发 `.followLatest`
  - [x] 5.5 测试内存修剪：验证 `trimOldEvents()` 在超过阈值时正确移除旧事件
  - [x] 5.6 测试 `SwiftDataEventStore` 分页查询：验证 offset/limit 参数正确工作
  - [x] 5.7 所有新测试通过 `swift test`

## Dev Notes

### 核心目标：让 Timeline 在大量事件下保持 60fps 流畅滚动

Story 2-1 到 2-4 建立了完整的事件可视化和渲染系统。本 story 的核心工作是**解决大规模事件场景下的性能问题**——通过分页加载、虚拟化窗口、智能滚动三大策略，确保 1000+ 事件时 UI 不冻结、8 小时运行无内存泄漏。

**当前性能瓶颈分析：**

1. **全量加载**：`AgentBridge.loadEvents(for:)` 一次性从 SwiftData 加载所有事件到 `events: [AgentEvent]` 数组。1000+ 事件时会导致会话切换延迟。
2. **全量渲染**：`TimelineView` 中 `ForEach(agentBridge.events)` 遍历所有事件。虽然 `LazyVStack` 只渲染可见区域，但 ForEach 仍会为每个事件创建视图描述（View identity），大量事件的 identity 计算开销不可忽略。
3. **无滚动状态管理**：当前 `scrollToLast` 在每次 `events.count` 变化时都自动滚动到底部。用户向上浏览历史时会被强制拉回底部。
4. **Markdown 解析无缓存**：`MarkdownContentView` 每次 body 求值可能重新解析 Markdown（取决于 SwiftUI 重渲染频率）。

### 前序 Story 关键上下文

**Story 2-4 已完成的内容（必须在此基础上扩展，不重新创建）：**

1. **`MarkdownRenderer.swift`**：已实现 `@MainActor static func render(_ markdown: String)` 方法，返回 `[AnyView]`。性能注意：Splash 高亮是 CPU 密集操作，长代码块可能超过 16ms。
2. **`MarkdownContentView.swift`**：已实现折叠/展开逻辑（1000 字符 / 20 行阈值）。当前没有缓存机制。
3. **`AssistantMessageView.swift`**：已集成 `MarkdownContentView`。每次 SwiftUI 重渲染时都会重新创建 `MarkdownContentView`。
4. **`StreamingTextView.swift`**：流式文本使用纯 `Text`，不涉及 Markdown 解析。性能已经 OK。

**Story 2-3 已完成的内容：**
- `Color+Theme.swift`：`Color.EventStyle` 和 `Color.EventIcon` 定义了事件类型颜色
- 所有事件视图已有视觉区分

**Story 2-2 已完成的内容：**
- `ToolCardView`：工具调用卡片，可展开/折叠
- `ToolContent` 和 `toolContentMap`：配对工具事件的数据结构

### 技术方案：三层性能优化

**第一层：分页加载（解决加载性能）**

```
SwiftDataEventStore
    |
    |  fetchEvents(for:offset:limit:)
    |  FetchDescriptor + .limit(limit) + .offset(offset)
    v
AgentBridge
    |
    |  loadInitialPage() -> 加载前 50 个事件
    |  loadMoreEvents()  -> 追加加载下一页
    |  events: [AgentEvent] -> 仅包含已加载的事件
    v
TimelineView
    |
    |  滚动到顶部时触发 loadMoreEvents()
    v
```

SwiftData `FetchDescriptor` 支持 `.limit()` 和 `.offset()` 方法，可以直接实现分页查询，无需自定义 SQL。

**第二层：虚拟化窗口（解决渲染性能）**

```swift
// macOS 14+ 原生 API
@State private var scrollPosition = ScrollPosition(idType: UUID.self)

ScrollView {
    // 顶部占位（已加载但不在窗口内的事件）
    topPlaceholder

    LazyVStack {
        ForEach(virtualizedEvents) { event in
            eventView(for: event)
                .id(event.id)
        }
    }

    // 底部占位
    bottomPlaceholder
}
.scrollPosition($scrollPosition)
.onChange(of: scrollPosition) { updateVisibleRange() }
```

关键实现细节：
- `ScrollPosition` 是 macOS 14+ 原生 API，不需要 UIKit/AppKit 桥接
- `scrollPosition(id:)` 可以绑定当前可见区域的第一个/最后一个元素 ID
- 当 `ScrollPosition` 变化时，更新 `visibleRange`，重新计算 `virtualizedEvents`
- 占位视图使用固定高度（估算每个事件平均高度），维持总滚动高度不变

**第三层：智能滚动（解决用户体验）**

```
ScrollModeManager
    |
    |  scrollMode: .followLatest / .manualBrowse
    |  检测用户滚动方向和位置
    |
    |  .followLatest:
    |    - 新事件到达时自动 scrollToLast
    |    - 保持当前行为
    |
    |  .manualBrowse:
    |    - 新事件到达时不自动滚动
    |    - 显示"回到底部"浮动按钮
    |    - 用户点击按钮或滚到底部时切换回 .followLatest
    v
```

### 关键性能指标（必须达标）

| 指标 | 目标 | 验证方式 |
|------|------|----------|
| 500 事件滚动帧率 | >= 60fps | Instruments Core Animation |
| 1000 事件加载时间 | < 500ms | 计时测试（分页加载首页） |
| 空闲内存 | < 100MB | Xcode Memory Graph |
| 活跃内存（1000 事件） | < 300MB | Xcode Memory Graph |
| 8 小时内存增长 | < 20% | 长时间运行 Instruments Leaks |

### 文件变更清单

**NEW（新建文件）：**
- `SwiftWork/Views/Workspace/Timeline/TimelineVirtualizationManager.swift` -- 虚拟化窗口计算逻辑
- `SwiftWork/Views/Workspace/Timeline/ScrollModeManager.swift` -- 智能滚动模式管理
- `SwiftWorkTests/Views/Timeline/TimelinePerformanceTests.swift` -- 性能相关测试

**UPDATE（更新文件）：**
- `SwiftWork/Views/Workspace/Timeline/TimelineView.swift` -- 集成虚拟化窗口和智能滚动
- `SwiftWork/SDKIntegration/AgentBridge.swift` -- 添加分页加载和内存修剪
- `SwiftWork/Services/EventStore.swift` -- 添加分页查询方法
- `SwiftWork/Views/Workspace/Timeline/EventViews/MarkdownContentView.swift` -- 添加解析缓存

**UNCHANGED（不修改——零回归风险）：**
- `SwiftWork/SDKIntegration/EventMapper.swift` -- 事件映射逻辑不变
- `SwiftWork/SDKIntegration/EventSerializer.swift` -- 序列化逻辑不变
- `SwiftWork/Models/UI/AgentEvent.swift` -- 事件模型不变
- `SwiftWork/Models/UI/ToolContent.swift` -- 工具内容模型不变
- `SwiftWork/Views/Workspace/Timeline/EventViews/StreamingTextView.swift` -- 流式文本不变
- `SwiftWork/Views/Workspace/Timeline/EventViews/ToolCardView.swift` -- 工具卡片不变
- 所有 EventView 子视图（UserMessageView、AssistantMessageView 等）不变

### 性能优化注意事项

1. **SwiftData 分页查询**：使用 `FetchDescriptor` 的 `.limit()` 和 `.offset()` 实现。不要使用 `.fetch()` 全量加载后再截取。
2. **`ScrollPosition` API**：macOS 14+ 原生支持，不需要 NSScrollView 桥接。使用 `scrollPosition(id:anchor:)` 绑定可见事件 ID。
3. **LazyVStack 与 ForEach 的配合**：LazyVStack 只实例化可见视图，但 ForEach 仍会为每个元素创建 identity。虚拟化窗口通过减少 ForEach 中的元素数量来减少 identity 计算开销。
4. **Markdown 解析缓存**：`MarkdownContentView` 应使用 `@State` 缓存 `MarkdownRenderer.render()` 的结果，避免每次 SwiftUI 重渲染时重新解析。缓存的 key 可以是 markdown 字符串的 hash。
5. **事件高度估算**：占位视图需要合理估算事件高度。可以使用固定平均值（如 80pt）或按事件类型分类估算（文本事件 120pt、工具卡片 60pt、结果卡片 80pt）。
6. **`@ObservationIgnored`**：在 `AgentBridge` 中，分页状态（`hasMoreEvents`、`currentPage`）和虚拟化相关属性不需要触发 UI 重渲染，应标记为 `@ObservationIgnored`。
7. **`trimOldEvents()` 调用时机**：在 `appendAndPersist()` 中检查 `events.count > maxInMemory` 时调用。修剪后的旧事件仍可通过分页从 SwiftData 重新加载。

### 与后续 Story 的关系

- **Story 3-4（Inspector Panel）**：Inspector 需要展示选中事件的完整详情。虚拟化窗口中不在内存的事件需要从 SwiftData 重新加载。`AgentBridge` 应提供 `loadEvent(id:)` 方法供 Inspector 使用。
- **Story 4-1（Debug Panel）**：Debug Panel 展示原始事件流，需要访问全量事件。Debug Panel 可以绕过虚拟化，直接从 `SwiftDataEventStore` 加载。

### OpenWork 滚动行为参考

参考 `domains/session/surface/scroll-controller.ts` 的交互逻辑（不参考 React 实现）：

- **两种模式**：`follow-latest`（自动滚到底部）和 `manual-browse`（用户手动浏览）
- **底部判定**：距离底部 96px 以内视为"在底部"
- **模式切换**：向上滚动 > 16px 退出 follow 模式
- **手势窗口**：600ms 防误判窗口
- **SwiftUI 实现方式**：使用 `scrollPosition` + `onChange` 检测滚动位置变化，而非 React 的 scroll event listener

### Project Structure Notes

- `TimelineVirtualizationManager.swift` 放在 `SwiftWork/Views/Workspace/Timeline/` -- 与 `TimelineView.swift` 同目录，因为它管理 Timeline 的虚拟化状态
- `ScrollModeManager.swift` 放在 `SwiftWork/Views/Workspace/Timeline/` -- 与 `TimelineView.swift` 同目录
- 遵循单文件不超过 300 行规则。如果 `TimelineView.swift` 因集成虚拟化而超过 300 行，将辅助方法提取到 `TimelineVirtualizationManager` 和 `ScrollModeManager` 中
- `TimelinePerformanceTests.swift` 放在 `SwiftWorkTests/Views/Timeline/` -- 与其他 Timeline 测试同目录

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.5: Timeline 性能优化]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 10: Timeline 渲染策略]
- [Source: _bmad-output/planning-artifacts/architecture.md#Decision 3: 事件存储策略]
- [Source: _bmad-output/project-context.md#Timeline 渲染策略]
- [Source: _bmad-output/project-context.md#OpenWork 滚动行为参考]
- [Source: _bmad-output/project-context.md#SwiftData 模型规则]
- [Source: _bmad-output/implementation-artifacts/2-4-markdown-code-highlight.md -- 前序 Story 上下文和 Markdown 渲染]
- [Source: SwiftWork/Views/Workspace/Timeline/TimelineView.swift -- 当前 Timeline 实现]
- [Source: SwiftWork/SDKIntegration/AgentBridge.swift -- 当前事件管理和加载逻辑]
- [Source: SwiftWork/Services/EventStore.swift -- 当前事件持久化和查询]
- [Source: SwiftWork/Views/Workspace/Timeline/EventViews/MarkdownContentView.swift -- 需要添加解析缓存]
- [Source: Apple Documentation - ScrollPosition (macOS 14+)]
- [Source: fatbobman.com/en/posts/the-evolution-of-swiftui-scroll-control-apis/ -- SwiftUI 滚动控制 API 演进]

### ATDD Artifacts

- Checklist: `_bmad-output/test-artifacts/atdd-checklist-2-5-timeline-performance.md`
- Unit + Integration tests: `SwiftWorkTests/Views/Timeline/TimelinePerformanceTests.swift`
- Test stubs: `SwiftWorkTests/Support/PerformanceTestStubs.swift`

## Dev Agent Record

### Agent Model Used

GLM-5.1

### Debug Log References

- Fixed macOS 14 compatibility: `ScrollPosition(idType:)` is macOS 15+ only. Replaced with `ScrollViewReader` + bottom anchor `onAppear`/`onDisappear` pattern for scroll position detection.
- Fixed `Group` return type inference errors in placeholder computed properties.
- Fixed existing `MockEventStore` in `AgentBridgeTests.swift` to conform to updated `EventStoring` protocol (added `fetchEvents(for:offset:limit:)` and `totalEventCount(for:)`).
- Fixed ATDD stub test assertion: `testVirtualizationManagerReturnsVisibleSubset` expected 70 but correct count is 90 (range 200..<250 + 20 buffer each side = 180..<270 = 90 elements).

### Completion Notes List

- Implemented paginated event loading via SwiftData `FetchDescriptor.fetchOffset`/`fetchLimit` in `SwiftDataEventStore`. Added `fetchEvents(for:offset:limit:)` and `totalEventCount(for:)` to `EventStoring` protocol.
- `AgentBridge.loadEvents(for:)` now loads only first 50 events for sessions with 1000+ events. Added `loadInitialPage(for:)`, `loadMoreEvents()`, `hasMoreEvents` property.
- Created `TimelineVirtualizationManager` with `eventsToRender(visibleRange:allEvents:)` that computes visible event subset with 20-item buffer on each side.
- Created `ScrollModeManager` with dual scroll mode (`.followLatest` / `.manualBrowse`). Scrolling up >16px switches to manual, scrolling within 96px of bottom switches back to follow.
- `TimelineView` integrated with virtualization (placeholder spacers for non-visible events) and smart scrolling (return-to-bottom button in manual mode).
- `MarkdownContentView` now caches rendered views using hash-based cache (`cachedMarkdownHash`), avoiding re-parsing on SwiftUI re-renders.
- `AgentBridge.trimOldEvents()` removes oldest events when exceeding 500 in memory, called automatically from `appendAndPersist()`.
- Pagination state (`pageSize`, `totalPersistedEvents`) marked `@ObservationIgnored` to avoid unnecessary UI re-renders.
- All 503 tests pass (0 failures) including 26 new TimelinePerformanceTests covering pagination, virtualization, scroll mode, memory trimming, and SwiftData pagination.

### File List

**NEW:**
- SwiftWork/Views/Workspace/Timeline/TimelineVirtualizationManager.swift
- SwiftWork/Views/Workspace/Timeline/ScrollModeManager.swift

**UPDATED:**
- SwiftWork/Services/EventStore.swift
- SwiftWork/SDKIntegration/AgentBridge.swift
- SwiftWork/Views/Workspace/Timeline/TimelineView.swift
- SwiftWork/Views/Workspace/Timeline/EventViews/MarkdownContentView.swift
- SwiftWorkTests/Views/Timeline/TimelinePerformanceTests.swift
- SwiftWorkTests/Support/PerformanceTestStubs.swift
- SwiftWorkTests/SDKIntegration/AgentBridgeTests.swift

## Review Findings

- [x] [Review][Patch] totalPersistedEvents 过度计数 partialMessage 事件 -- totalPersistedEvents 在 appendAndPersist 中对 partialMessage 事件也递增，但这些事件不会持久化到 SwiftData，导致 totalPersistedEvents 与实际持久化数量不一致，影响 hasMoreEvents 和 loadMoreEvents offset 计算 [AgentBridge.swift:286] -- **已修复**
- [x] [Review][Patch] trimOldEvents() 与分页 offset 不一致 -- 裁剪后的事件无法通过当前分页 API 重新加载；同时 toolContentMap 未清理裁剪事件对应的条目，造成内存泄漏 [AgentBridge.swift:305] -- **已修复**
- [x] [Review][Patch] clearEvents() 不重置 totalPersistedEvents -- 切换会话后 totalPersistedEvents 保留旧值，导致 hasMoreEvents 误判 [AgentBridge.swift:219] -- **已修复**
- [x] [Review][Patch] AgentBridge.swift 超过 300 行限制 -- 提取 toolContentMap 方法到 AgentBridge+ToolContentMap.swift 扩展文件 -- **已修复**
- [x] [Review][Patch] returnToBottomButton transition 动画不生效 -- Group 容器不支持 transition，替换为 ZStack + animation modifier [TimelineView.swift:160] -- **已修复**
- [x] [Review][Patch] VirtualizationState 未使用的死代码 -- 移除 TimelineVirtualizationManager.swift 中的 VirtualizationState 结构体及对应测试 -- **已修复**
- [x] [Review][Patch] PerformanceTestStubs.swift 纯死代码文件 -- 已删除 -- **已修复**
- [x] [Review][Defer] 缺少 600ms 手势窗口防误判 -- Story spec 引用 OpenWork scroll-controller.ts 的 600ms 防抖窗口未实现，当前可能导致快速滚动时模式闪烁 [ScrollModeManager.swift] -- deferred, v1 可接受
- [x] [Review][Defer] 无向上滚动加载更多事件触发机制 -- 用户向上滚动到已加载事件顶部时，没有触发 loadMoreEvents() 的机制；当前仅支持初始加载 [TimelineView.swift] -- deferred, 后续 story 可增强

## Change Log

- 2026-05-02: Story 2-5 implementation complete. Three-layer performance optimization: paginated loading, virtualized rendering window, smart scroll behavior. All 503 tests pass.
- 2026-05-02: Code review complete. 7 patches applied (fixed overcount, trim cleanup, reset state, file split, animation, dead code). 2 deferred (gesture debounce, upward load). 502 tests pass.
