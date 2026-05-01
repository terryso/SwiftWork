---
stepsCompleted: ['step-01-preflight-and-context', 'step-02-generation-mode', 'step-03-test-strategy', 'step-04-generate-tests', 'step-04c-aggregate', 'step-05-validate-and-complete']
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-05-01'
storyId: '2.2'
storyKey: '2-2-tool-card-experience'
storyFile: '_bmad-output/implementation-artifacts/2-2-tool-card-experience.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-2-2-tool-card-experience.md'
generatedTestFiles:
  - 'SwiftWorkTests/SDKIntegration/ToolContentPairingTests.swift'
  - 'SwiftWorkTests/Views/Timeline/ToolCardViewTests.swift'
  - 'SwiftWorkTests/Views/Timeline/ToolCardTimelineIntegrationTests.swift'
inputDocuments:
  - '_bmad-output/implementation-artifacts/2-2-tool-card-experience.md'
  - '_bmad-output/project-context.md'
  - 'SwiftWork/SDKIntegration/AgentBridge.swift'
  - 'SwiftWork/Models/UI/ToolContent.swift'
  - 'SwiftWork/Views/Workspace/Timeline/TimelineView.swift'
  - 'SwiftWork/SDKIntegration/ToolRendererRegistry.swift'
  - 'SwiftWork/SDKIntegration/ToolRenderable.swift'
  - 'SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/BashToolRenderer.swift'
  - 'SwiftWork/Views/Workspace/Timeline/EventViews/ToolRenderers/FileEditToolRenderer.swift'
  - 'SwiftWorkTests/Support/TestDataFactory.swift'
  - 'SwiftWorkTests/SDKIntegration/AgentBridgeTests.swift'
  - 'SwiftWorkTests/SDKIntegration/ToolRendererRegistryTests.swift'
  - 'SwiftWorkTests/Views/Timeline/TimelineEventViewsTests.swift'
---

# ATDD Checklist — Story 2.2: Tool Card 完整体验

## Story Summary

**Story ID:** 2.2
**Story Key:** 2-2-tool-card-experience
**Primary Test Level:** Unit (Swift/XCTest backend)
**Epic:** Epic 2 — Agent 执行可视化（Tool Card 体验）

**Description:** 将 `.toolUse`、`.toolResult`、`.toolProgress` 三个独立事件配对为统一的 ToolCardView，使工具调用从分散的三张卡片变为一张可展开的完整卡片。

**覆盖的 FRs:** FR14, FR15, FR16, FR17, FR18
**覆盖的 ARCHs:** ARCH-9

---

## Acceptance Criteria Breakdown

### AC#1: ToolCallView 卡片渲染 (FR14)
- `.toolUse` 事件渲染 ToolCardView 卡片
- 包含工具名、输入参数摘要、执行状态指示器
- 折叠状态显示标题行 + 副标题（通过 ToolRenderable 委托）
- 展开状态显示完整 input JSON + 工具特定 body

### AC#2: 进度指示器 (FR15)
- `.toolProgress` 更新 ToolCardView 状态为 running
- 显示旋转进度指示器和已用时间

### AC#3: 结果展示与折叠/展开 (FR16, FR17)
- `.toolResult` 合并到 ToolCardView（成功绿/失败红）
- 默认折叠显示摘要，点击展开显示完整参数和结果
- Diff 格式检测（+绿色、-红色、@@蓝色）
- Copy 按钮支持
- `.toolResult` 和 `.toolProgress` 不再渲染独立卡片

### AC#4: Inspector 联动 (FR18)
- 点击卡片设置 selectedEventId
- 选中态视觉反馈（蓝色边框/高亮背景）
- selectedEventId 通过 @Binding 传递给 WorkspaceView

---

## Test Strategy

### Stack Detection
- **Detected Stack:** `backend` (Swift/XCTest, macOS native app)
- **Test Framework:** XCTest
- **Test Runner:** `swift test`
- **Generation Mode:** AI Generation (backend stack, no browser recording)

### Test Levels
| Level | Usage | Count |
|-------|-------|-------|
| Unit | toolContentMap pairing, ToolCardView rendering, TimelineView dispatch | 39 |

### Priority Distribution
| Priority | Count | Description |
|----------|-------|-------------|
| P0 | 23 | Critical path — pairing, status, rendering, selection |
| P1 | 16 | Edge cases, fallbacks, ordering, new renderers |

---

## Red-Phase Test Scaffolds

### Test Files Created

| File | Tests | Priority | Status |
|------|-------|----------|--------|
| `SwiftWorkTests/SDKIntegration/ToolContentPairingTests.swift` | 15 | P0: 9, P1: 6 | RED (compilation fails) |
| `SwiftWorkTests/Views/Timeline/ToolCardViewTests.swift` | 16 | P0: 10, P1: 6 | RED (compilation fails) |
| `SwiftWorkTests/Views/Timeline/ToolCardTimelineIntegrationTests.swift` | 12 | P0: 5, P1: 7 | RED (compilation fails) |

### Test Coverage by Acceptance Criterion

| AC | Tests | Priority | Files |
|----|-------|----------|-------|
| AC#1 (ToolCardView rendering) | 14 | P0: 8, P1: 6 | ToolCardViewTests, ToolCardTimelineIntegrationTests |
| AC#2 (Progress indicator) | 4 | P0: 4 | ToolContentPairingTests, ToolCardViewTests |
| AC#3 (Result display & pairing) | 12 | P0: 7, P1: 5 | ToolContentPairingTests, ToolCardViewTests, ToolCardTimelineIntegrationTests |
| AC#4 (Inspector selection) | 3 | P0: 3 | ToolCardViewTests, ToolCardTimelineIntegrationTests |
| Full lifecycle | 6 | P0: 3, P1: 3 | All files |

### Red Phase Compilation Errors

Build fails with **176 compilation errors** referencing these missing types/members:

| Missing Type/Member | Error Count | Maps To |
|---------------------|-------------|---------|
| `AgentBridge.processToolContentMap(for:)` | 80 | Task 1 — New method |
| `AgentBridge.toolContentMap` | 64 | Task 1 — New property |
| `ToolCardView` (struct init) | 20 | Task 2 — New View |
| `ToolResultContentView` (struct init) | 12 | Task 5 — New View |

---

## Implementation Checklist

### Task 1: Implement toolContentMap in AgentBridge (AC: #1, #2, #3)
- [ ] Add `var toolContentMap: [String: ToolContent] = [:]` to AgentBridge
- [ ] Add `func processToolContentMap(for event: AgentEvent)` method
- [ ] Handle `.toolUse` → create ToolContent entry
- [ ] Handle `.toolProgress` → update existing entry (status=running, elapsedTime)
- [ ] Handle `.toolResult` → merge output (status=completed/failed)
- [ ] Ignore non-tool events
- [ ] Update `clearEvents()` to clear toolContentMap

### Task 2: Create ToolCardView (AC: #1, #2, #3)
- [ ] Create `SwiftWork/Views/Workspace/Timeline/EventViews/ToolCardView.swift`
- [ ] Accept `content: ToolContent`, `registry: ToolRendererRegistry`, `isSelected: Bool`, `onSelect: () -> Void`
- [ ] Header row: icon + summaryTitle + status badge
- [ ] Status badge colors: pending=gray, running=blue+ProgressView, completed=green, failed=red
- [ ] Collapsed state (default): header + subtitle only
- [ ] Expanded state: tool-specific body + input JSON + output + Copy buttons

### Task 3: Integrate ToolRenderable renderers into ToolCardView (AC: #1, #3)
- [ ] Header summaryTitle/subtitle delegate to renderer
- [ ] Expanded body delegates to `ToolRenderable.body(content:)`
- [ ] Unregistered tools use generic renderer (toolName + raw input/output)

### Task 4: Update TimelineView dispatch (AC: #1, #2, #3)
- [ ] `.toolUse` branch: look up toolContentMap, render ToolCardView
- [ ] `.toolResult` branch: return EmptyView() (paired into ToolCardView)
- [ ] `.toolProgress` branch: return EmptyView() (paired into ToolCardView)
- [ ] Add `selectedEventId` state
- [ ] Pass selectedEventId to WorkspaceView via @Binding

### Task 5: Create ToolResultContentView (AC: #3)
- [ ] Create `SwiftWork/Views/Workspace/Timeline/EventViews/ToolResultContentView.swift`
- [ ] Success: green icon + truncated preview (200 chars or 5 lines)
- [ ] Error: red icon + full error message + red background
- [ ] Diff detection: +green, -red, @@blue line backgrounds
- [ ] Copy buttons for input and output

### Task 6: Selection & Inspector linkage (AC: #4)
- [ ] ToolCardView accepts `isSelected: Bool` and `onSelect: () -> Void`
- [ ] Selected state visual: blue border or highlight
- [ ] TimelineView manages `selectedEventId: UUID?`
- [ ] Pass selectedEventId @Binding to WorkspaceView

### Task 7: Expand skeleton renderers body (AC: #1)
- [ ] BashToolRenderer expanded: command + output terminal style
- [ ] FileEditToolRenderer expanded: file_path + Diff preview
- [ ] SearchToolRenderer expanded: pattern + results preview

### Task 8: Register new renderers (AC: #1)
- [ ] Create `ReadToolRenderer.swift` (toolName="Read", icon="doc.text")
- [ ] Create `WriteToolRenderer.swift` (toolName="Write", icon="pencil.and.outline")
- [ ] Register in `ToolRendererRegistry.init()`

### Task 9: Run Tests
- [ ] `swift test` — all 39 tests should pass

---

## Red-Green-Refactor Workflow

### RED Phase (Current — TEA Complete)
- [x] Test files created:
  - `SwiftWorkTests/SDKIntegration/ToolContentPairingTests.swift` (15 tests)
  - `SwiftWorkTests/Views/Timeline/ToolCardViewTests.swift` (16 tests)
  - `SwiftWorkTests/Views/Timeline/ToolCardTimelineIntegrationTests.swift` (12 tests)
- [x] 39 test methods defined covering all 4 acceptance criteria
- [x] Build fails with compilation errors (expected)
- [x] All missing types/members documented above

### GREEN Phase (DEV Team)
- [ ] Implement Task 1-8 above
- [ ] Activate tests by removing compilation barriers (types will exist)
- [ ] Run `swift test` — all 39 tests should pass
- [ ] Do NOT modify test expectations — fix implementation to match

### REFACTOR Phase
- [ ] Review for code quality and consistency
- [ ] Ensure no test breakage during refactor
- [ ] Verify `swift test` still passes

---

## Execution Commands

```bash
# Build tests (check compilation)
swift build --build-tests

# Run all tests
swift test

# Run specific test files
swift test --filter ToolContentPairingTests
swift test --filter ToolCardViewTests
swift test --filter ToolCardTimelineIntegrationTests

# Run specific test
swift test --filter ToolContentPairingTests/testFullPairingSequenceProducesCompleteToolContent
```

---

## Key Risks and Assumptions

1. **Assumption:** `toolContentMap` will be a `[String: ToolContent]` dictionary on `AgentBridge`, keyed by `toolUseId`
2. **Assumption:** `processToolContentMap(for:)` is a public method to allow testing — alternatively, pairing happens inside `appendAndPersist` and the method wraps that logic
3. **Assumption:** `ToolCardView` is a SwiftUI View struct accepting `content`, `registry`, `isSelected`, `onSelect` parameters
4. **Assumption:** `ToolResultContentView` is a standalone SwiftUI View struct accepting `output` and `isError`
5. **Risk:** TimelineView rendering of EmptyView for `.toolResult`/`.toolProgress` may require ForEach index tracking to avoid SwiftUI identity issues
6. **Risk:** `ToolCardView` with `@State isExpanded` may interfere with SwiftUI's identity when content updates — consider using `id(toolUseId)` on ToolCardView
7. **Assumption:** ReadToolRenderer and WriteToolRenderer will follow same pattern as existing renderers

---

## Next Steps for DEV Team

1. Implement Story 2.2 tasks in order (Task 1 -> Task 9)
2. Start with `AgentBridge.toolContentMap` and `processToolContentMap` (unblocks most ToolContentPairingTests)
3. Then create `ToolCardView` and `ToolResultContentView` (unblocks ToolCardViewTests)
4. Then update `TimelineView` dispatch (unblocks ToolCardTimelineIntegrationTests)
5. Run `swift build --build-tests` after each task to verify progress
6. All 39 tests should pass when implementation is complete
7. After GREEN phase, proceed to Story 2.3 (事件类型视觉系统)

**Recommended next workflow:** `bmad-dev-story` for Story 2.2 implementation
