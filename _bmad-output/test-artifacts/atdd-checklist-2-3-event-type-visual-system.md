---
stepsCompleted: ['step-01-preflight-and-context', 'step-02-generation-mode', 'step-03-test-strategy', 'step-04-generate-tests', 'step-04c-aggregate', 'step-05-validate-and-complete']
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-05-02'
storyId: '2.3'
storyKey: '2-3-event-type-visual-system'
storyFile: '_bmad-output/planning-artifacts/epics.md#story-2.3'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-2-3-event-type-visual-system.md'
generatedTestFiles:
  - 'SwiftWorkTests/Views/Timeline/EventTypeVisualStyleTests.swift'
  - 'SwiftWorkTests/Views/Timeline/EventThemeIntegrationTests.swift'
inputDocuments:
  - '_bmad-output/planning-artifacts/epics.md'
  - '_bmad-output/project-context.md'
  - 'SwiftWork/Utils/Extensions/Color+Theme.swift'
  - 'SwiftWork/Models/UI/AgentEventType.swift'
  - 'SwiftWork/Models/UI/AgentEvent.swift'
  - 'SwiftWork/Models/UI/ToolContent.swift'
  - 'SwiftWork/Views/Workspace/Timeline/TimelineView.swift'
  - 'SwiftWork/Views/Workspace/Timeline/EventViews/UserMessageView.swift'
  - 'SwiftWork/Views/Workspace/Timeline/EventViews/ToolCardView.swift'
  - 'SwiftWork/Views/Workspace/Timeline/EventViews/ToolCallView.swift'
  - 'SwiftWork/Views/Workspace/Timeline/EventViews/ToolResultView.swift'
  - 'SwiftWork/Views/Workspace/Timeline/EventViews/ToolResultContentView.swift'
  - 'SwiftWork/Views/Workspace/Timeline/EventViews/SystemEventView.swift'
  - 'SwiftWork/Views/Workspace/Timeline/EventViews/ResultView.swift'
  - 'SwiftWork/Views/Workspace/Timeline/EventViews/UnknownEventView.swift'
  - 'SwiftWork/Views/Workspace/Timeline/EventViews/AssistantMessageView.swift'
  - 'SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/BashToolRenderer.swift'
  - 'SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/FileEditToolRenderer.swift'
  - 'SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/ReadToolRenderer.swift'
  - 'SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/SearchToolRenderer.swift'
  - 'SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/WriteToolRenderer.swift'
  - 'SwiftWork/SDKIntegration/ToolRenderable.swift'
  - 'SwiftWork/SDKIntegration/ToolRendererRegistry.swift'
  - 'SwiftWorkTests/Support/TestDataFactory.swift'
  - 'SwiftWorkTests/Views/Timeline/TimelineEventViewsTests.swift'
  - 'SwiftWorkTests/Views/Timeline/ToolCardViewTests.swift'
---

# ATDD Checklist — Story 2.3: 事件类型视觉系统

## Story Summary

**Story ID:** 2.3
**Story Key:** 2-3-event-type-visual-system
**Primary Test Level:** Unit (Swift/XCTest backend)
**Epic:** Epic 2 — Agent 执行可视化（Tool Card 体验）

**Description:** 通过颜色和图标直观区分不同类型的事件和工具，使用户可以快速扫描 Timeline 理解 Agent 的执行状态。

**覆盖的 FRs:** FR11, FR12, FR19
**覆盖的 ARCHs:** Color+Theme.swift

---

## Acceptance Criteria Breakdown

### AC#1: 事件类型差异化视觉样式 (FR11, FR12)

| 事件类型 | 视觉样式 | 优先级 |
|---------|---------|--------|
| 用户消息 (.userMessage) | 蓝色左侧气泡 | P0 |
| 工具调用 (.toolUse) | 灰色卡片 | P0 |
| 工具结果成功 (.toolResult, isError=false) | 绿色卡片 | P0 |
| 工具结果失败 (.toolResult, isError=true) | 红色卡片 | P0 |
| 系统事件 (.system) | 浅灰色次要文字 | P0 |
| 系统错误事件 | 红色高亮 | P0 |
| 助手回复 (.assistant) | 左对齐主色文字 | P0 |
| 结果 (.result, success) | 绿色状态图标 | P0 |
| 结果 (.result, error) | 红色状态图标 | P0 |
| 结果 (.result, cancelled) | 橙色状态图标 | P0 |

### AC#2: 工具类型差异化卡片样式 (FR19)

| 工具类型 | SF Symbol 图标 | 特征 |
|---------|---------------|------|
| Bash | terminal | 终端图标 |
| Edit (FileEdit) | pencil.line | 文件编辑图标 |
| Grep (Search) | text.magnifyingglass | 搜索图标 |
| Read | doc.text | 文档图标 |
| Write | pencil.and.outline | 写入图标 |
| 未知工具 | wrench.and.screwdriver | 通用工具图标 |

### AC#3: 错误事件突出显示 (FR12)

- 错误卡片使用红色边框和背景高亮
- 显示错误详情（错误图标 + 错误文本）
- 适用于 ToolResultView、SystemEventView、ToolCardView

---

## Test Strategy

### Test Levels (Backend: Swift/XCTest)

| 测试类型 | 目的 | 数量 |
|---------|------|------|
| Unit Tests | 验证各 View 组件实例化、渲染器注册、视觉样式属性 | 42 |
| Integration Tests | 验证 Timeline 视觉系统整体一致性、Registry 完整性 | 14 |

### Priority Distribution

| 优先级 | 数量 | 说明 |
|--------|------|------|
| P0 | 32 | 核心 FR11/FR12/FR19 验收标准 |
| P1 | 24 | 扩展场景（subtitle、fallback、edge cases） |

---

## Red-Phase Test Scaffolds Created

### Test Files

| 文件路径 | 测试数 | 描述 |
|---------|--------|------|
| `SwiftWorkTests/Views/Timeline/EventTypeVisualStyleTests.swift` | 42 | AC#1/AC#2/AC#3 单元测试 |
| `SwiftWorkTests/Views/Timeline/EventThemeIntegrationTests.swift` | 14 | 视觉系统集成测试 |

**Total Tests:** 56 (all are red-phase acceptance tests)

---

## Acceptance Criteria Coverage

| AC | FR | Tests | Status |
|----|-----|-------|--------|
| AC#1: 事件类型差异化视觉样式 | FR11 | 10+ tests for distinct styles per event type | RED |
| AC#1: 错误事件突出显示 | FR12 | 6+ tests for red error styling | RED |
| AC#2: 工具类型差异化卡片 | FR19 | 16+ tests for tool-specific icons/renderers | RED |
| AC#3: 错误卡片红色高亮 | FR12 | 4+ tests for error card highlighting | RED |

---

## Implementation Checklist

### AC#1 Implementation Tasks

- [ ] Verify UserMessageView uses `.blue.opacity(0.15)` background (already implemented)
- [ ] Verify ToolCardView uses `.gray.opacity(0.1)` background for non-error (already implemented)
- [ ] Verify ToolResultView uses green/red background based on `isError` (already implemented)
- [ ] Verify SystemEventView uses `.secondary` foreground (already implemented)
- [ ] Verify ResultView uses green/orange/red status color based on `subtype` (already implemented)
- [ ] Verify AssistantMessageView uses `.primary` foreground (already implemented)

### AC#2 Implementation Tasks

- [ ] Verify BashToolRenderer uses `terminal` SF Symbol (already implemented)
- [ ] Verify FileEditToolRenderer uses `pencil.line` SF Symbol (already implemented)
- [ ] Verify SearchToolRenderer uses `text.magnifyingglass` SF Symbol (already implemented)
- [ ] Verify ReadToolRenderer uses `doc.text` SF Symbol (already implemented)
- [ ] Verify WriteToolRenderer uses `pencil.and.outline` SF Symbol (already implemented)
- [ ] Verify ToolCardView fallback uses `wrench.and.screwdriver` for unknown tools (already implemented)

### AC#3 Implementation Tasks

- [ ] Verify ToolCardView error card uses `.red.opacity(0.05)` background (already implemented)
- [ ] Verify ToolResultContentView error uses red styling (already implemented)
- [ ] Verify SystemEventView with `isError=true` uses red styling (already implemented)

### Color Theme Tasks

- [ ] Extend `Color+Theme.swift` with semantic event colors if needed for consistency
- [ ] Consider extracting status colors to `Color+Theme.swift` for reuse

---

## Red-Green-Refactor Workflow

### RED Phase (Current)
- All 56 tests generated as acceptance test scaffolds
- Tests verify EXPECTED behavior of the visual system
- Tests will PASS if visual system is correctly implemented

### GREEN Phase
1. Review existing implementation against acceptance criteria
2. Run tests: `swift test --filter EventTypeVisualStyleTests`
3. Run tests: `swift test --filter EventThemeIntegrationTests`
4. Fix any failing tests by updating implementation
5. Commit passing tests

### REFACTOR Phase
- Extract repeated color values to `Color+Theme.swift`
- Ensure consistent use of semantic colors across all event views
- Verify no visual regressions

---

## Execution Commands

```bash
# Run all Story 2-3 tests
swift test --filter EventTypeVisualStyleTests
swift test --filter EventThemeIntegrationTests

# Run specific test
swift test --filter EventTypeVisualStyleTests/testBashToolRendererUsesTerminalIcon

# Run all Timeline view tests
swift test --filter Timeline
```

---

## Key Observations

### Pre-existing Implementation

Story 2-3 的核心视觉系统实际上已经在 Story 2-1 和 2-2 的实现中部分完成：

1. **Event View 差异化样式已存在**: UserMessageView (蓝色气泡), ToolResultView (绿色/红色), SystemEventView (灰色/红色), ResultView (绿色/橙色/红色), AssistantMessageView (主色文字)
2. **Tool Renderers 已注册 5 种工具类型**: Bash, Edit, Grep, Read, Write — 各自使用不同的 SF Symbol 图标
3. **ToolCardView 已有 status 颜色系统**: pending=gray, running=blue, completed=green, failed=red
4. **Error 样式已实现**: ToolResultContentView 红色背景, SystemEventView 红色高亮, ToolCardView error 背景

### Potential Gaps

1. `Color+Theme.swift` 目前只有 `themeAccent`，可能需要扩展：
   - `themeUserMessage` (blue)
   - `themeToolCard` (gray)
   - `themeSuccess` (green)
   - `themeError` (red)
   - `themeSystem` (secondary)
2. 没有集中的 `EventTheme` 配置——颜色分散在各 View 文件中

---

## Next Steps for DEV Team

1. Run `swift test --filter EventTypeVisualStyleTests` and `swift test --filter EventThemeIntegrationTests`
2. Most tests should PASS immediately (visual system is largely implemented)
3. Address any failing tests by completing missing visual differentiations
4. Consider extracting semantic colors to `Color+Theme.swift` for long-term maintainability
5. Proceed to Story 2.4 (Markdown 渲染与代码高亮)
