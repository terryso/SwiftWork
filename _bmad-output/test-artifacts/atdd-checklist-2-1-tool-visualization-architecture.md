---
stepsCompleted: ['step-01-preflight-and-context', 'step-02-generation-mode', 'step-03-test-strategy', 'step-04-generate-tests', 'step-05-validate-and-complete']
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-05-01'
storyId: '2.1'
storyKey: '2-1-tool-visualization-architecture'
storyFile: '_bmad-output/implementation-artifacts/2-1-tool-visualization-architecture.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-2-1-tool-visualization-architecture.md'
generatedTestFiles:
  - 'SwiftWorkTests/SDKIntegration/ToolRendererRegistryTests.swift'
inputDocuments:
  - '_bmad-output/implementation-artifacts/2-1-tool-visualization-architecture.md'
  - '_bmad-output/planning-artifacts/epics.md'
  - '_bmad-output/project-context.md'
  - 'SwiftWork/Models/UI/ToolContent.swift'
  - 'SwiftWork/Models/UI/AgentEvent.swift'
  - 'SwiftWork/Models/UI/AgentEventType.swift'
  - 'SwiftWork/SDKIntegration/EventMapper.swift'
  - 'SwiftWork/Views/Workspace/Timeline/TimelineView.swift'
  - 'SwiftWork/Views/Workspace/Timeline/EventViews/ToolCallView.swift'
  - 'SwiftWorkTests/Support/TestDataFactory.swift'
  - 'SwiftWorkTests/SDKIntegration/EventMapperTests.swift'
  - 'SwiftWorkTests/Views/Timeline/TimelineEventViewsTests.swift'
  - 'SwiftWorkTests/Models/UI/ToolContentTests.swift'
---

# ATDD Checklist — Story 2.1: Tool 可视化基础架构

## Story Summary

**Story ID:** 2.1
**Story Key:** 2-1-tool-visualization-architecture
**Primary Test Level:** Unit (Swift/XCTest backend)
**Epic:** Epic 2 — Agent 执行可视化（Tool Card 体验）

**Description:** 建立可扩展的工具卡片渲染系统，使每种工具类型可以注册自己的 SwiftUI 渲染器，新增工具类型时无需修改核心 Timeline 逻辑。

**覆盖的 FRs:** FR14 (基础), FR19 (基础)
**覆盖的 ARCHs:** ARCH-9

---

## Acceptance Criteria Breakdown

### AC#1: ToolRenderable 协议定义
- 协议定义 `toolName`（静态属性）、`body(content:)` 方法返回 `some View`
- 协议提供默认扩展方法 `summaryTitle(content:)` 和 `subtitle(content:)`
- 协议遵循 `Sendable`

### AC#2: ToolRendererRegistry 注册和查找
- Registry 支持注册和查找 ToolRenderable 实现
- 查找未注册工具时返回 `nil`
- 支持同名覆盖

### AC#3: TimelineView 通过 Registry 查找渲染器
- 已注册的工具使用自定义渲染器
- 未注册的工具使用默认 `ToolCallView` 渲染
- 现有行为保持不变（零回归风险）

### AC#4: ToolUse/ToolResult 配对
- `ToolUse` 和 `ToolResult` 通过 `toolUseId` 关联
- 渲染系统能将 Tool 调用和其结果配对展示在同一卡片中

### AC#5: 测试覆盖
- 测试覆盖 Registry 的注册/查找/默认回退逻辑
- 测试 ToolContent 数据提取
- 所有测试通过 `swift test`

---

## Test Strategy

### Stack Detection
- **Detected Stack:** `backend` (Swift/XCTest, macOS native app)
- **Test Framework:** XCTest
- **Test Runner:** `swift test`

### Test Levels
| Level | Usage | Count |
|-------|-------|-------|
| Unit | Protocol contracts, Registry logic, ToolContent extraction | 26 |

### Priority Distribution
| Priority | Count | Description |
|----------|-------|-------------|
| P0 | 14 | Critical path — protocol, registry, extraction |
| P1 | 12 | Edge cases, defaults, fallbacks |

---

## Red-Phase Test Scaffolds

### Test File Created

| File | Tests | Priority | Status |
|------|-------|----------|--------|
| `SwiftWorkTests/SDKIntegration/ToolRendererRegistryTests.swift` | 26 | P0/P1 | RED (compilation fails) |

### Test Coverage by Acceptance Criterion

| AC | Tests | Priority |
|----|-------|----------|
| AC#1 (ToolRenderable protocol) | 5 | P0: 2, P1: 3 |
| AC#2 (Registry register/lookup) | 6 | P0: 3, P1: 3 |
| AC#3 (TimelineView integration) | 4 | P0: 2, P1: 2 |
| AC#4 (ToolContent status/extraction) | 9 | P0: 4, P1: 5 |
| AC#5 (summaryTitle from JSON) | 4 | P0: 1, P1: 3 |

### Red Phase Compilation Errors

Build fails with **36 compilation errors** referencing these missing types/members:

| Missing Type/Member | Error Count | Maps To |
|---------------------|-------------|---------|
| `ToolRendererRegistry` | 9 | AC#2 — New class |
| `ToolRenderable` (protocol) | 2 | AC#1 — New protocol |
| `ToolExecutionStatus` (enum) | 6 | AC#4 — New enum |
| `ToolContent.status` | 2 | AC#4 — New field |
| `ToolContent.summaryTitle` | 4 | AC#5 — New computed property |
| `ToolContent.elapsedTimeSeconds` | 2 | AC#4 — New field |
| `ToolContent.fromToolUseEvent()` | 1 | AC#4 — New static method |
| `ToolContent.fromToolResultEvent()` | 2 | AC#4 — New static method |
| `ToolContent.applyingProgress()` | 1 | AC#4 — New instance method |
| `TimelineView` extra arg `toolRendererRegistry` | 2 | AC#3 — API change |
| `MockToolRenderer.summaryTitle` | 1 | Protocol method |
| `MockToolRenderer.subtitle` | 1 | Protocol method |

---

## Implementation Checklist

### Task 1: Define ToolRenderable Protocol (AC#1)
- [ ] Create `SwiftWork/SDKIntegration/ToolRenderable.swift`
- [ ] Define `static var toolName: String { get }`
- [ ] Define `@MainActor func body(content: ToolContent) -> any View`
- [ ] Provide default extension: `summaryTitle(content:)` returns `content.toolName`
- [ ] Provide default extension: `subtitle(content:)` returns `nil`
- [ ] Protocol conforms to `Sendable`

### Task 2: Extend ToolContent Model (AC#4, #5)
- [ ] Add `ToolExecutionStatus` enum: `.pending`, `.running`, `.completed`, `.failed`
- [ ] Add `status: ToolExecutionStatus` field to `ToolContent`
- [ ] Add `elapsedTimeSeconds: Int?` field to `ToolContent`
- [ ] Add `summaryTitle: String` computed property (parse input JSON)
- [ ] Add `static func fromToolUseEvent(_:) -> ToolContent`
- [ ] Add `static func fromToolResultEvent(_:) -> ToolContent`
- [ ] Add `func applyingProgress(_:) -> ToolContent`
- [ ] Ensure `Sendable` conformance maintained

### Task 3: Implement ToolRendererRegistry (AC#2, #5)
- [ ] Create `SwiftWork/SDKIntegration/ToolRendererRegistry.swift`
- [ ] `@MainActor @Observable final class`
- [ ] `private var renderers: [String: any ToolRenderable]`
- [ ] `func register(_ renderer: any ToolRenderable)`
- [ ] `func renderer(for toolName: String) -> (any ToolRenderable)?`
- [ ] Pre-register skeleton renderers in `init()`

### Task 4: Refactor TimelineView (AC#3)
- [ ] Add `var toolRendererRegistry: ToolRendererRegistry` parameter with default value
- [ ] Modify `.toolUse` branch: query Registry, fall back to `ToolCallView`

### Task 5: Create Skeleton Renderers (AC#1, #3)
- [ ] `BashToolRenderer.swift` — terminal icon + command summary
- [ ] `FileEditToolRenderer.swift` — file icon + path summary
- [ ] `SearchToolRenderer.swift` — search icon + query summary

### Task 6: Run Tests
- [ ] `swift test` — all 26 tests should pass

---

## Red-Green-Refactor Workflow

### RED Phase (Current — TEA Complete)
- [x] Test file created: `SwiftWorkTests/SDKIntegration/ToolRendererRegistryTests.swift`
- [x] 26 test methods defined covering all 5 acceptance criteria
- [x] Build fails with compilation errors (expected)
- [x] All missing types/members documented above

### GREEN Phase (DEV Team)
- [ ] Implement Task 1-5 above
- [ ] Activate tests by removing compilation barriers (types will exist)
- [ ] Run `swift test` — all 26 tests should pass
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

# Run specific test file
swift test --filter ToolRendererRegistryTests

# Run specific test
swift test --filter ToolRendererRegistryTests/testRegisterAndLookupRenderer
```

---

## Key Risks and Assumptions

1. **Assumption:** `ToolRenderable` protocol will use `@MainActor` for `body(content:)` since it returns SwiftUI Views
2. **Assumption:** `ToolContent` struct will be extended in-place (not replaced) to maintain backward compatibility
3. **Risk:** Mock renderer uses static mutable state — production code should not; this is test-only
4. **Risk:** SDK tool names ("Bash", "Read", "Edit", etc.) must be verified against actual SDK source
5. **Assumption:** `TimelineView` will accept registry via parameter with default value (backward compatible)

---

## Next Steps for DEV Team

1. Implement Story 2.1 tasks in order (Task 1 -> Task 6)
2. Start with `ToolRenderable` protocol and `ToolExecutionStatus` enum (unblocks most compilation errors)
3. Run `swift build --build-tests` after each task to verify progress
4. All 26 tests should pass when implementation is complete
5. After GREEN phase, proceed to Story 2.2 (Tool Card Complete Experience)

**Recommended next workflow:** `bmad-dev-story` for Story 2.1 implementation
