---
title: 'Expand Long AI Responses by Default'
type: 'bugfix'
created: '2026-05-07T11:10:36.071+08:00'
status: 'done'
route: 'one-shot'
---

# Expand Long AI Responses by Default

## Intent

**Problem:** Assistant responses rendered through `MarkdownContentView` were auto-collapsing when they crossed the long-content threshold, which hid the rest of the answer unless the user manually expanded it.

**Approach:** Initialize long markdown content in the expanded state and keep the existing manual fold/unfold controls, with targeted regression checks around the default expansion rule.

## Suggested Review Order

**Default expansion behavior**

- Start at the state initialization that flips long markdown to expanded by default.
  [`MarkdownContentView.swift:15`](../../SwiftWork/Views/Workspace/Timeline/EventViews/MarkdownContentView.swift#L15)

- Check the threshold helpers that now define when default expansion should apply.
  [`MarkdownContentView.swift:62`](../../SwiftWork/Views/Workspace/Timeline/EventViews/MarkdownContentView.swift#L62)

- Confirm manual expand/collapse controls still work after the default-state change.
  [`MarkdownContentView.swift:83`](../../SwiftWork/Views/Workspace/Timeline/EventViews/MarkdownContentView.swift#L83)

**Regression coverage**

- Review the updated tests that lock long responses to expanded-by-default behavior.
  [`MarkdownContentViewTests.swift:51`](../../SwiftWorkTests/Views/Timeline/MarkdownContentViewTests.swift#L51)

- End with the short-content assertion to ensure the new default stays scoped.
  [`MarkdownContentViewTests.swift:85`](../../SwiftWorkTests/Views/Timeline/MarkdownContentViewTests.swift#L85)
