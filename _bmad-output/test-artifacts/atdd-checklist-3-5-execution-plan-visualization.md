---
stepsCompleted: ['step-01-preflight-and-context', 'step-02-generation-mode', 'step-03-test-strategy', 'step-04-generate-tests', 'step-04c-aggregate', 'step-05-validate-and-complete']
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-05-03'
storyId: '3.5'
storyKey: '3-5-execution-plan-visualization'
storyFile: '_bmad-output/implementation-artifacts/3-5-execution-plan-visualization.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-3-5-execution-plan-visualization.md'
generatedTestFiles:
  - 'SwiftWorkTests/Models/UI/PlanStepModelTests.swift'
  - 'SwiftWorkTests/SDKIntegration/PlanEventMapperTests.swift'
  - 'SwiftWorkTests/Views/Timeline/PlanViewTests.swift'
inputDocuments:
  - '_bmad-output/implementation-artifacts/3-5-execution-plan-visualization.md'
  - '_bmad-output/project-context.md'
  - '_bmad/tea/config.yaml'
  - 'SwiftWork/Models/UI/AgentEventType.swift'
  - 'SwiftWork/SDKIntegration/EventMapper.swift'
  - 'SwiftWork/Models/UI/AgentEvent.swift'
  - 'SwiftWorkTests/Support/TestDataFactory.swift'
  - 'SwiftWorkTests/SDKIntegration/EventMapperTests.swift'
---

# ATDD Checklist: Story 3.5 — 执行计划可视化

**Story ID:** 3.5
**Story Key:** 3-5-execution-plan-visualization
**TDD Phase:** RED (test scaffolds, will fail until implementation)
**Stack:** Backend (Swift/macOS native, XCTest)
**Generation Mode:** AI Generation (sequential)

---

## Story Summary

As a 用户, I want 看到 Agent 的任务拆解计划和执行进度, so that 我可以理解 Agent 的工作方式和当前进展。

**覆盖的 FRs:** FR34 (步骤列表), FR35 (状态指示器), FR36 (依赖关系)
**覆盖的 ARCHs:** ARCH-8 (@Observable), ARCH-9 (ToolRenderable 协议), ARCH-12 (分层边界)

---

## Acceptance Criteria Breakdown

### AC#1 — PlanView 显示步骤列表 (FR34)

Given Agent 生成了任务执行计划, When 接收到 Plan 相关事件, Then PlanView 显示步骤列表，每个步骤显示序号和描述。

**测试覆盖:**

| Test | Level | Priority | File |
|------|-------|----------|------|
| PlanStep 初始化所有属性 | Unit (Model) | P0 | PlanStepModelTests.swift |
| PlanData 初始化含步骤列表 | Unit (Model) | P0 | PlanStepModelTests.swift |
| EnterPlanMode toolUse → .plan | Unit (SDKIntegration) | P0 | PlanEventMapperTests.swift |
| ExitPlanMode toolUse → .plan | Unit (SDKIntegration) | P0 | PlanEventMapperTests.swift |
| TodoWrite toolUse → .plan | Unit (SDKIntegration) | P0 | PlanEventMapperTests.swift |
| AgentEventType 含 .plan case | Unit (Model) | P0 | PlanEventMapperTests.swift |
| PlanView 实例化 | Unit (View) | P0 | PlanViewTests.swift |
| PlanView 解析编号列表步骤 | Unit (View) | P1 | PlanViewTests.swift |
| PlanView 解析 Markdown 列表 | Unit (View) | P1 | PlanViewTests.swift |

### AC#2 — 步骤状态指示器 (FR35)

Given Plan 步骤列表已渲染, When Agent 开始执行某个步骤, Then 该步骤状态变为"执行中"（旋转指示器），已完成步骤显示勾号。

**测试覆盖:**

| Test | Level | Priority | File |
|------|-------|----------|------|
| PlanStepStatus 含 4 个 case | Unit (Model) | P0 | PlanStepModelTests.swift |
| PlanStepStatus 遵循 Sendable | Unit (Model) | P0 | PlanStepModelTests.swift |
| PlanStepStatus 遵循 Equatable | Unit (Model) | P0 | PlanStepModelTests.swift |
| PlanStepStatus 原始值正确 | Unit (Model) | P0 | PlanStepModelTests.swift |
| PlanStep 状态生命周期转换 | Unit (Model) | P1 | PlanStepModelTests.swift |
| PlanStepRow pending 实例化 | Unit (View) | P0 | PlanViewTests.swift |
| PlanStepRow inProgress 实例化 | Unit (View) | P0 | PlanViewTests.swift |
| PlanStepRow completed 实例化 | Unit (View) | P0 | PlanViewTests.swift |
| PlanStepRow failed 实例化 | Unit (View) | P0 | PlanViewTests.swift |

### AC#3 — 依赖关系可视化 (FR36)

Given 计划包含有依赖关系的步骤, When 渲染 PlanView, Then 通过缩进或连线方式显示步骤之间的依赖关系。

**测试覆盖:**

| Test | Level | Priority | File |
|------|-------|----------|------|
| PlanStep 含依赖 ID 列表 | Unit (Model) | P1 | PlanStepModelTests.swift |
| PlanData 步骤形成依赖链 | Unit (Model) | P1 | PlanStepModelTests.swift |
| PlanData 并行独立步骤 | Unit (Model) | P1 | PlanStepModelTests.swift |
| PlanStepRow 含依赖指示器 | Unit (View) | P1 | PlanViewTests.swift |
| PlanStepRow 多重依赖 | Unit (View) | P1 | PlanViewTests.swift |

### 回归测试

| Test | Level | Priority | File |
|------|-------|----------|------|
| 非 Plan toolUse 仍映射为 .toolUse | Unit (SDKIntegration) | P0 | PlanEventMapperTests.swift |
| FileRead toolUse 不受影响 | Unit (SDKIntegration) | P0 | PlanEventMapperTests.swift |
| plan toolResult 仍映射为 .toolResult | Unit (SDKIntegration) | P0 | PlanEventMapperTests.swift |
| AgentEventType.plan 在 CaseIterable 中 | Unit (Model) | P0 | PlanEventMapperTests.swift |
| Inspector 处理 .plan 事件 | Unit (View) | P0 | PlanViewTests.swift |

---

## Red-Phase Test Scaffolds Created

### Test File: `SwiftWorkTests/Models/UI/PlanStepModelTests.swift`
- **Test Count:** 14
- **TDD Phase:** RED (all tests will fail — PlanStep, PlanStepStatus, PlanData not yet defined)
- **Coverage:** AC#1 (model structure), AC#2 (status enum), AC#3 (dependencies)
- **Key Tests:**
  - PlanStepStatus enum with 4 cases + Sendable + Equatable + raw values
  - PlanStep init with id, description, status, dependencies
  - PlanData init with planId, content, approved, steps
  - Dependency chain and parallel step scenarios

### Test File: `SwiftWorkTests/SDKIntegration/PlanEventMapperTests.swift`
- **Test Count:** 15
- **TDD Phase:** RED (all tests will fail — EventMapper does not yet handle plan tools)
- **Coverage:** AC#1 (event mapping)
- **Key Tests:**
  - EnterPlanMode → .plan with planAction="enter"
  - ExitPlanMode → .plan with planAction="exit" + plan content + approved
  - TodoWrite → .plan with planAction="todoUpdate"
  - Regression: non-plan tools still map to .toolUse
  - AgentEventType.plan in CaseIterable

### Test File: `SwiftWorkTests/Views/Timeline/PlanViewTests.swift`
- **Test Count:** 15
- **TDD Phase:** RED (all tests will fail — PlanView, PlanStepRow not yet implemented)
- **Coverage:** AC#1 (view instantiation), AC#2 (step rows), AC#3 (dependency display)
- **Key Tests:**
  - PlanView with enter/exit/todo plan events
  - PlanStepRow for all 4 status values
  - Plan text parsing (numbered list, markdown list)
  - Inspector plan section handling

---

## Test Strategy Summary

| Metric | Value |
|--------|-------|
| Total Tests | 44 |
| P0 (Critical) | 28 |
| P1 (Important) | 16 |
| Unit (Model) | 14 |
| Unit (SDKIntegration) | 15 |
| Unit (View) | 15 |
| Primary Test Level | Unit |

---

## Implementation Checklist (GREEN Phase Tasks)

### Task 1: Data Models — PlanStep, PlanStepStatus, PlanData
- [ ] Create `SwiftWork/Models/UI/PlanStep.swift`
- [ ] Define `PlanStepStatus` enum (pending, inProgress, completed, failed) — String, Sendable, Equatable
- [ ] Define `PlanStep` struct (id: String, description: String, status: PlanStepStatus, dependencies: [String]) — Identifiable, Sendable
- [ ] Define `PlanData` struct (planId: String, content: String?, approved: Bool, steps: [PlanStep]) — Sendable
- [ ] **Activate:** Remove skip from PlanStepModelTests, verify RED, implement, verify GREEN

### Task 2: EventMapper Plan Tool Mapping
- [ ] Add `plan` case to `AgentEventType.swift` (CaseIterable)
- [ ] Update `EventMapper.swift` `.toolUse` case: branch on toolName for EnterPlanMode/ExitPlanMode/TodoWrite
- [ ] Map EnterPlanMode → AgentEvent(type: .plan, metadata: ["planAction": "enter"])
- [ ] Map ExitPlanMode → AgentEvent(type: .plan, metadata: ["planAction": "exit", ...])
- [ ] Map TodoWrite → AgentEvent(type: .plan, metadata: ["planAction": "todoUpdate", ...])
- [ ] Update `AgentBridge+ToolContentMap.swift` to handle `.plan` events if needed
- [ ] **Activate:** Remove skip from PlanEventMapperTests, verify RED, implement, verify GREEN

### Task 3: PlanView SwiftUI View
- [ ] Create `SwiftWork/Views/Workspace/Timeline/EventViews/PlanView.swift`
- [ ] Implement step list rendering with status indicators
- [ ] Implement dependency visualization (indentation)
- [ ] Create `PlanStepRow` (sub-view or same file if < 300 lines)
- [ ] **Activate:** Remove skip from PlanViewTests, verify RED, implement, verify GREEN

### Task 4: TimelineView + Inspector Integration
- [ ] Add `.plan` case to `TimelineView.eventView(for:)` switch → PlanView(event:)
- [ ] Add `.plan` case to `InspectorView` event detail switch → planEventSection(event:)
- [ ] Add `.plan` case to `colorForEventType(_:)` → return distinct color
- [ ] Add `planEventSection(event:)` to `EventDetailSections.swift`
- [ ] **Verify:** All exhaustive switches compile (compiler-enforced)

### Task 5: Full Test Run
- [ ] Run `swift test` — all new tests pass, existing tests no regression
- [ ] Verify PlanView renders correctly in Timeline
- [ ] Verify Inspector shows plan details

---

## Red-Green-Refactor Workflow

### RED (Complete)
All 44 test scaffolds generated. Tests will fail because:
- `PlanStep`, `PlanStepStatus`, `PlanData` types do not exist yet
- `PlanView`, `PlanStepRow` views do not exist yet
- `EventMapper` does not handle plan tool names yet
- `AgentEventType` does not have `.plan` case yet

### GREEN (Next)
1. Implement Task 1 (data models) → activate PlanStepModelTests → verify pass
2. Implement Task 2 (EventMapper) → activate PlanEventMapperTests → verify pass
3. Implement Task 3 (PlanView) → activate PlanViewTests → verify pass
4. Implement Task 4 (integration) → verify all tests pass

### REFACTOR
- Extract PlanStepRowView if PlanView exceeds 300 lines
- Ensure naming consistency with existing patterns
- Verify no force unwraps in new code

---

## Execution Commands

```bash
# Run all tests
swift test

# Run specific test file
swift test --filter PlanStepModelTests
swift test --filter PlanEventMapperTests
swift test --filter PlanViewTests

# Run all Story 3-5 tests
swift test --filter "PlanStepModelTests|PlanEventMapperTests|PlanViewTests"
```

---

## Key Risks & Assumptions

1. **SDK 不发送独立 plan 事件** — Plan 功能通过 EnterPlanMode/ExitPlanMode/TodoWrite 工具实现，EventMapper 需要通过 toolName 分支映射。如果 SDK 工具名称变更，测试需同步更新
2. **PlanData 存储在 metadata 字典中** — AgentEvent.metadata 是 `[String: any Sendable]`，足够存储 PlanData 的序列化数据，但类型安全需要开发者注意
3. **PlanStepStatus 使用 struct（不可变）** — 因为 @Observable ViewModel 会持有步骤列表，状态变化通过替换整个步骤或使用可变集合实现
4. **Plan 文本解析是 best-effort** — 编号列表和 Markdown 列表有明确解析规则，自由文本降级为 Markdown 渲染
5. **EventMapper 是纯函数** — toolResult 事件不会重新映射为 .plan（只有 toolUse 才会），PlanView 需要从 toolContentMap 获取配对数据

---

## Next Steps for DEV Team

1. Read the story file: `_bmad-output/implementation-artifacts/3-5-execution-plan-visualization.md`
2. Start with Task 1 (data models) — activate PlanStepModelTests
3. Follow RED-GREEN-REFACTOR for each task
4. Run `swift test` frequently to catch regressions early
5. Story 3-5 completion unblocks Phase 4 stories

**Recommended workflow:** `bmad-dev-story` with this checklist as input
