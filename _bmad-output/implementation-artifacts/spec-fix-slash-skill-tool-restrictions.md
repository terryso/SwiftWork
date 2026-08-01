---
title: 'Fix Slash Skill Tool Restrictions'
type: 'bugfix'
created: '2026-08-01'
status: 'done'
baseline_commit: 'f680fde4c71fdac4c03b6d98d11f4cb70bcb316c'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/spec-fix-slash-skill-discovery-and-execution.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `/skill args` is expanded into text and sent to ordinary `Agent.stream(...)`, bypassing SDK enforcement of `allowed-tools`; a Bash-only skill can then see MCP.

**Approach:** Keep current slash parsing and Skill Timeline events, but run the work with `Agent.executeSkillStream(name, args:)`, the SDK entrypoint that filters the runtime tool pool.

## Boundaries & Constraints

**Always:** Enforce explicit-skill `allowed-tools`; preserve canonical/alias resolution, exact arguments, queue/cancellation, and ordinary or unknown slash input.

**Ask First:** Stop for SDK dependency, global MCP/permission, or unavailable-skill UX changes.

**Never:** Do not hard-code a skill/provider/MCP, route local files to WebReader, or change Settings, Timeline, or global MCP availability.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected behavior |
|---|---|---|
| Bash-only skill | `/analytics recent`; MCP enabled | Direct stream receives canonical name and exact args; SDK excludes MCP |
| Alias/ordinary | `/sls recent` or text/unknown slash | Alias is restricted; non-skills retain ordinary stream |

</frozen-after-approval>

## Code Map

- `SwiftWork/SDKIntegration/AgentBridge.swift` -- slash dispatch.
- `SwiftWorkTests/SDKIntegration/AgentBridgeSkillTests.swift` -- route regressions.

## Tasks & Acceptance

**Execution:**
- [x] `SwiftWork/SDKIntegration/AgentBridge.swift` -- use `executeSkillStream` after recording the existing Skill event pair; remove prompt re-entry.
- [x] `SwiftWork/SDKIntegration/AgentBridge.swift` + `SwiftWorkTests/SDKIntegration/AgentBridgeSkillTests.swift` -- add a no-network direct-stream seam and Bash-only canonical/alias tests.

**Acceptance Criteria:**
- Given Bash-only skill + MCP, when submitted, then SwiftWork calls the direct stream with canonical name and exact args, never prompt-rewrites into ordinary `stream`.
- Given alias, ordinary text, or unknown slash, when submitted, then alias stays restricted and non-skills retain their existing route; a direct-stream result releases the queue.

## Spec Change Log

## Design Notes

The SDK applies and restores declarations only in `executeSkillStream`; prompt metadata is advisory. The seam proves SwiftWork selects that API.

## Verification

**Commands:**
- `swift test --filter AgentBridgeSkillTests` -- expected: focused tests pass without provider access.
- `swift build` and `swift test` -- expected: build and full suite pass.
- `git diff --check` -- expected: no whitespace errors.

## Suggested Review Order

**Restricted execution boundary**

- Explicit slash requests retain ordinary text behavior but use the SDK's restricted stream.
  [`AgentBridge.swift:603`](../../SwiftWork/SDKIntegration/AgentBridge.swift#L603)

- Preserve the existing Skill event pair before direct execution starts.
  [`AgentBridge.swift:741`](../../SwiftWork/SDKIntegration/AgentBridge.swift#L741)

**Regression evidence**

- A no-network seam asserts canonical dispatch and exact user arguments.
  [`AgentBridge.swift:104`](../../SwiftWork/SDKIntegration/AgentBridge.swift#L104)

- Canonical and alias paths retain Skill cards while selecting direct streams.
  [`AgentBridgeSkillTests.swift:662`](../../SwiftWorkTests/SDKIntegration/AgentBridgeSkillTests.swift#L662)

- Direct-stream errors still end the request and leave their result visible.
  [`AgentBridgeSkillTests.swift:745`](../../SwiftWorkTests/SDKIntegration/AgentBridgeSkillTests.swift#L745)
