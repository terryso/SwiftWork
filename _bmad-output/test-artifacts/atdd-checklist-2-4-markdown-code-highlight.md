---
stepsCompleted:
  - step-01-preflight-and-context
  - step-02-generation-mode
  - step-03-test-strategy
  - step-04c-aggregate
  - step-05-validate-and-complete
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-05-02'
storyId: '2.4'
storyKey: '2-4-markdown-code-highlight'
storyFile: '_bmad-output/implementation-artifacts/2-4-markdown-code-highlight.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-2-4-markdown-code-highlight.md'
generatedTestFiles:
  - SwiftWorkTests/Services/MarkdownRendererTests.swift
  - SwiftWorkTests/Services/CodeHighlighterTests.swift
  - SwiftWorkTests/Views/Timeline/MarkdownContentViewTests.swift
  - SwiftWorkTests/Views/Timeline/MarkdownRenderingIntegrationTests.swift
---

# ATDD Checklist: Story 2.4 — Markdown 渲染与代码高亮

## TDD Red Phase (Current)

**Status:** RED PHASE — All test scaffolds generated and guarded with `#if false` compilation blocks.

| Test Level | File | Test Count | P0 | P1 | P2 |
|------------|------|-----------|----|----|-----|
| Unit (Service) | `SwiftWorkTests/Services/MarkdownRendererTests.swift` | 13 | 5 | 5 | 3 |
| Unit (Service) | `SwiftWorkTests/Services/CodeHighlighterTests.swift` | 9 | 3 | 4 | 2 |
| Unit (View) | `SwiftWorkTests/Views/Timeline/MarkdownContentViewTests.swift` | 8 | 3 | 3 | 2 |
| Integration | `SwiftWorkTests/Views/Timeline/MarkdownRenderingIntegrationTests.swift` | 9 | 2 | 4 | 3 |
| **Total** | **4 files** | **39** | **13** | **16** | **10** |

## Acceptance Criteria Coverage

### AC#1: Markdown 元素渲染 (FR42)

**Given** Agent 输出包含 Markdown 内容 **When** Timeline 渲染文本事件 **Then** MarkdownRenderer 正确渲染标题（H1-H3）、列表（有序/无序）、粗体/斜体、行内代码（`code`）、链接、表格

| Test | Priority | Status |
|------|----------|--------|
| `testRenderPlainTextReturnsNonEmptyResult` | P0 | RED (#if false) |
| `testRenderHeadingsH1ThroughH3` | P0 | RED (#if false) |
| `testRenderBoldAndItalic` | P0 | RED (#if false) |
| `testRenderInlineCode` | P0 | RED (#if false) |
| `testRenderLinks` | P0 | RED (#if false) |
| `testRenderUnorderedList` | P1 | RED (#if false) |
| `testRenderOrderedList` | P1 | RED (#if false) |
| `testRenderTable` | P1 | RED (#if false) |
| `testRenderBlockQuote` | P1 | RED (#if false) |
| `testRenderThematicBreak` | P2 | RED (#if false) |
| `testMarkdownContentViewRendersInlineFormatting` | P1 | RED (#if false) |
| `testAssistantMessageViewRendersMarkdown` | P0 | RED (#if false) |
| `testAssistantMessageViewHandlesPlainTextContent` | P1 | RED (#if false) |
| `testResultViewRendersMarkdownContent` | P2 | RED (#if false) |

### AC#2: 代码块语法高亮 (FR43)

**Given** Agent 输出包含代码块（fenced code block） **When** 渲染代码块 **Then** CodeHighlighter 使用 Splash 对 Swift 代码进行语法高亮；非 Swift 代码块以等宽字体纯文本显示

| Test | Priority | Status |
|------|----------|--------|
| `testHighlightSwiftCodeReturnsNonNilAttributedOutput` | P0 | RED (#if false) |
| `testHighlightSwiftCodeAppliesColorAttributes` | P0 | RED (#if false) |
| `testHighlightEmptySwiftCode` | P1 | RED (#if false) |
| `testHighlightPythonCodeReturnsPlainText` | P0 | RED (#if false) |
| `testHighlightJavaScriptCodeReturnsPlainText` | P1 | RED (#if false) |
| `testHighlightBashCodeReturnsPlainText` | P1 | RED (#if false) |
| `testHighlightCodeWithNilLanguageReturnsPlainText` | P1 | RED (#if false) |
| `testSwiftCodeBlockHighlightedInMarkdownContext` | P1 | RED (#if false) |
| `testNonSwiftCodeBlockRenderedAsPlainText` | P1 | RED (#if false) |

### AC#3: 长文本折叠/展开 (FR44)

**Given** 事件内容超过一定长度 **When** 渲染长文本 **Then** 默认折叠显示前 N 行，点击"展开"显示完整内容

| Test | Priority | Status |
|------|----------|--------|
| `testMarkdownContentViewCollapsesLongText` | P0 | RED (#if false) |
| `testMarkdownContentViewDoesNotCollapseShortText` | P0 | RED (#if false) |
| `testMarkdownContentViewCollapsesManyLines` | P1 | RED (#if false) |

## Test Strategy

**Detected Stack:** Backend (Swift/macOS native app)

**Test Levels:**
- **Unit Tests** (Services): `MarkdownRenderer`, `CodeHighlighter` — pure logic testing
- **Unit Tests** (Views): `MarkdownContentView` — SwiftUI view instantiation and state
- **Integration Tests**: `AssistantMessageView` + `MarkdownContentView`, `ResultView` + `MarkdownContentView` — verify wiring

**No E2E/browser tests** — this is a native macOS app using XCTest, not a web frontend.

## Red-Phase Skip Convention

This project uses **XCTest** (not Playwright/Jest). The red-phase convention is:

- **Skip mechanism:** `#if false` / `#endif` compilation guard wrapping the test body
- **Why `#if false` instead of `XCTSkip()`:** Swift compiles all code paths including after `XCTSkip()`. Since `MarkdownRenderer`, `CodeHighlighter`, and `MarkdownContentView` types don't exist yet, code referencing them would cause compilation errors. `#if false` removes the code at compile time.
- **Activation:** Remove `#if false` / `#endif` wrapper to activate the test for the current task
- **Expected behavior:** Activated tests will FAIL (compilation error — types do not exist yet) until implementation is complete

## Implementation Tasks to Test Mapping

| Task | Tests to Activate | Implementation Files |
|------|-------------------|---------------------|
| Task 1: MarkdownRenderer | `MarkdownRendererTests` — remove `#if false`/`#endif` in all tests | `SwiftWork/Services/MarkdownRenderer.swift` |
| Task 2: CodeHighlighter | `CodeHighlighterTests` — remove `#if false`/`#endif` in all tests | `SwiftWork/Services/CodeHighlighter.swift` |
| Task 3: MarkdownContentView | `MarkdownContentViewTests` — remove `#if false`/`#endif` in all tests | `SwiftWork/Views/Workspace/Timeline/EventViews/MarkdownContentView.swift` |
| Task 4: Integration into existing views | `MarkdownRenderingIntegrationTests` — remove `#if false`/`#endif` in relevant tests | Update `AssistantMessageView.swift`, `ResultView.swift` |
| Task 5: Collapse/expand | `MarkdownContentViewTests` (AC#3 tests) — remove `#if false`/`#endif` | Update `MarkdownContentView.swift` |
| Task 6: Verify all tests pass | All tests — remove all remaining `#if false`/`#endif` guards | N/A |

## Next Steps (Red-Green-Refactor)

### RED Phase (Complete)
- [x] Test scaffolds generated with `#if false` compilation guards
- [x] All acceptance criteria have test coverage
- [x] Priority levels assigned (P0-P2)

### GREEN Phase (Task-by-Task Activation)
For each implementation task:

1. Open the corresponding test file(s)
2. Remove `#if false` / `#endif` wrappers from tests for the current task
3. Run `swift test` — verify tests fail (compilation error = expected)
4. Implement the feature code
5. Run `swift test` — verify tests pass
6. Commit passing tests and implementation together

### REFACTOR Phase
- After all tests pass, refactor for code quality
- Ensure no test regressions after refactoring
- Verify file length constraints (300 lines max per View file)

## Key Risks and Assumptions

1. **Splash only supports Swift syntax** — All other languages (Python, JS, Bash, JSON) fall back to plain monospace text. This is the expected MVP behavior.
2. **SwiftUI View testing limitation** — XCTest cannot inspect SwiftUI view internals. Tests verify instantiation and non-crash behavior, not visual rendering. Visual correctness requires manual review or Xcode Previews.
3. **`MarkupVisitor` Result type** — Using `AnyView` for visitor results is acceptable for MVP. Performance optimization (Story 2-5) may revisit this.
4. **StreamingTextView unchanged** — Per story requirements, streaming text remains plain `Text`. Only final `.assistant` events use Markdown rendering.
5. **Performance in LazyVStack** — Markdown parsing should be cached to avoid re-parsing on every SwiftUI body evaluation. This is a dev note, not a test requirement.

## Execution Commands

```bash
# Run all tests
swift test

# Run specific test file
swift test --filter MarkdownRendererTests
swift test --filter CodeHighlighterTests
swift test --filter MarkdownContentViewTests
swift test --filter MarkdownRenderingIntegrationTests

# Run specific test by name
swift test --filter "testRenderHeadingsH1ThroughH3"
```

## Generated Files

| File | Purpose | Lines |
|------|---------|-------|
| `SwiftWorkTests/Services/MarkdownRendererTests.swift` | MarkdownRenderer unit tests (AC#1) | ~120 |
| `SwiftWorkTests/Services/CodeHighlighterTests.swift` | CodeHighlighter unit tests (AC#2) | ~100 |
| `SwiftWorkTests/Views/Timeline/MarkdownContentViewTests.swift` | MarkdownContentView + collapse tests (AC#1, AC#3) | ~95 |
| `SwiftWorkTests/Views/Timeline/MarkdownRenderingIntegrationTests.swift` | Integration with existing views (AC#1, AC#2) | ~130 |

## Input Documents

- `_bmad-output/implementation-artifacts/2-4-markdown-code-highlight.md` — Story file
- `_bmad-output/project-context.md` — Project context (technology stack, testing rules, architecture)
- `_bmad/tea/config.yaml` — TEA configuration
