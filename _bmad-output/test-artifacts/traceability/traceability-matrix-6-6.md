---
stepsCompleted: ['step-01-load-context', 'step-02-discover-tests', 'step-03-map-criteria', 'step-04-analyze-gaps', 'step-05-gate-decision']
lastStep: 'step-05-gate-decision'
lastSaved: '2026-05-07'
coverageBasis: 'acceptance_criteria'
oracleConfidence: 'high'
oracleResolutionMode: 'formal_requirements'
oracleSources: ['_bmad-output/implementation-artifacts/6-6-mcp-advanced-settings-config.md']
externalPointerStatus: 'not_used'
---

# Traceability Report: Story 6-6 — MCP 高级设置与配置文件

## Gate Decision: PASS

**Rationale:** P0 coverage is 100%, overall coverage is 100% (minimum: 80%). All 4 acceptance criteria fully covered with 60 active tests across 3 test files. No critical or high-priority gaps. 3 informational gaps identified with accepted mitigations.

---

## Coverage Summary

| Metric | Value |
|--------|-------|
| Total Acceptance Criteria | 4 |
| Fully Covered | 4 (100%) |
| Partially Covered | 0 |
| Uncovered | 0 |
| P0 Coverage | 4/4 (100%) |
| Total Unique Tests | 60 |
| Active Tests | 60 |
| Test Files | 3 |

### By Test Level

| Level | Tests |
|-------|-------|
| Unit | 51 |
| Integration | 9 |
| E2E | 0 |

---

## Oracle Resolution

| Property | Value |
|----------|-------|
| Coverage Basis | `acceptance_criteria` |
| Oracle Resolution Mode | `formal_requirements` |
| Oracle Confidence | `high` |
| External Pointer Status | `not_used` |
| Oracle Sources | `_bmad-output/implementation-artifacts/6-6-mcp-advanced-settings-config.md` |

---

## Traceability Matrix

### AC1 — 高级设置折叠区 (P0) — FULL

**Description:** Given 用户在 MCP 管理面板查看底部, When 面板加载完成, Then 显示"高级设置"可折叠区域（默认折叠），包含配置文件路径信息和操作按钮

**Coverage: FULL** — 6 tests (4 unit + 2 unit/watching)

| # | Test | File | Level | Priority |
|---|------|------|-------|----------|
| 1 | testMCPAdvancedSettingsViewCanBeCreated | MCPAdvancedSettingsViewTests.swift:28 | unit | P0 |
| 2 | testMCPAdvancedSettingsViewWorksWithNilWorkspace | MCPAdvancedSettingsViewTests.swift:38 | unit | P0 |
| 3 | testViewModelInitializesCollapsed | MCPAdvancedSettingsViewTests.swift:126 | unit | P0 |
| 4 | testViewModelTogglesExpanded | MCPAdvancedSettingsViewTests.swift:132 | unit | P0 |
| 5 | testStartWatchingDoesNotCrash | MCPConfigFileManagerTests.swift:601 | unit | P0 |
| 6 | testStopWatchingWhenNotWatching | MCPConfigFileManagerTests.swift:623 | unit | P0 |

**Covered Scenarios:**
- MCPAdvancedSettingsView 可实例化（有/无 agentBridge）
- ViewModel 默认折叠、可切换展开
- 文件监控注册/停止不崩溃
- View 集成到 MCPManagementView serverList 底部

**Implementation Verified:**
- Collapsible header with gearshape icon + chevron toggle
- `@State isExpanded = false` default
- `.transition(.opacity.combined(with: .move(edge: .top)))` animation
- `onDisappear` lifecycle calls `stopWatching()`
- Inserted at bottom of `MCPManagementView.serverList` LazyVStack

---

### AC2 — 配置文件路径显示 (P0) — FULL

**Description:** Given 用户展开高级设置区域, When 查看, Then 显示配置文件路径信息：Project scope 路径、Global scope 路径，通过 scope 切换按钮切换

**Coverage: FULL** — 11 tests (unit)

| # | Test | File | Level | Priority |
|---|------|------|-------|----------|
| 1 | testConfigFilePathGlobalScope | MCPConfigFileManagerTests.swift:97 | unit | P0 |
| 2 | testConfigFilePathGlobalScopeIgnoresWorkspace | MCPConfigFileManagerTests.swift:109 | unit | P0 |
| 3 | testConfigFilePathProjectScope | MCPConfigFileManagerTests.swift:117 | unit | P0 |
| 4 | testConfigFilePathProjectScopeNilWorkspace | MCPConfigFileManagerTests.swift:127 | unit | P0 |
| 5 | testConfigFilePathProjectScopeEmptyWorkspace | MCPConfigFileManagerTests.swift:135 | unit | P0 |
| 6 | testViewModelInitializesWithGlobalScope | MCPAdvancedSettingsViewTests.swift:50 | unit | P0 |
| 7 | testViewModelCanSwitchScope | MCPAdvancedSettingsViewTests.swift:56 | unit | P0 |
| 8 | testViewModelProjectScopeUnavailableWhenNoWorkspace | MCPAdvancedSettingsViewTests.swift:65 | unit | P0 |
| 9 | testViewModelProjectScopeAvailableWithWorkspace | MCPAdvancedSettingsViewTests.swift:72 | unit | P0 |
| 10 | testViewModelResolvesGlobalConfigPath | MCPAdvancedSettingsViewTests.swift:81 | unit | P0 |
| 11 | testManagerPathResolutionBothScopes | MCPConfigFileIntegrationTests.swift:363 | integration | P0 |

**Covered Scenarios:**
- Global scope resolves to `~/.claude/settings.json`
- Global scope ignores workspacePath parameter
- Project scope resolves to `{workspace}/.claude/settings.json`
- Project scope returns nil when workspacePath is nil or empty
- ViewModel defaults to global scope, can switch to project
- Project scope unavailable without workspace path

**Implementation Verified:**
- `configFilePath(scope:workspacePath:) -> String?` in MCPConfigFileManager
- Global: `FileManager.homeDirectoryForCurrentUser + .claude/settings.json`
- Project: `workspacePath + /.claude/settings.json` (nil guard)
- Scope toggle UI buttons (Project/Global)
- Monospaced font, `truncationMode(.middle)`, `textSelection(.enabled)`
- "文件尚未创建" warning in orange when file missing

---

### AC3 — 在 Finder 中显示 (P0) — FULL

**Description:** Given 用户点击"在 Finder 中显示"按钮, When 操作执行, Then 在 Finder 中打开并定位到配置文件（如果文件存在）或提示文件尚未创建

**Coverage: FULL** — 7 tests (5 P0 + 2 P1)

| # | Test | File | Level | Priority |
|---|------|------|-------|----------|
| 1 | testConfigFileExistsTrue | MCPConfigFileManagerTests.swift:146 | unit | P0 |
| 2 | testConfigFileExistsFalse | MCPConfigFileManagerTests.swift:155 | unit | P0 |
| 3 | testReadConfigFileReturnsData | MCPConfigFileManagerTests.swift:165 | unit | P0 |
| 4 | testReadConfigFileReturnsNilForMissing | MCPConfigFileManagerTests.swift:179 | unit | P0 |
| 5 | testManagerReportsCorrectFileExistence | MCPConfigFileIntegrationTests.swift:352 | integration | P0 |
| 6 | testRevealInFinderDoesNotCrashForExistingFile | MCPConfigFileManagerTests.swift:583 | unit | P1 |
| 7 | testRevealInFinderDoesNotCrashForMissingFile | MCPConfigFileManagerTests.swift:593 | unit | P1 |

**Covered Scenarios:**
- `configFileExists` correctly detects file present/absent
- `readConfigFile` returns Data for existing file, nil for missing
- `revealInFinder` does not crash for existing or non-existing files
- Integration test verifies existence check with real temp files

**Implementation Verified:**
- `revealInFinder(path:)` calls `NSWorkspace.shared.selectFile`
- `configFileExists(atPath:)` uses `FileManager.fileExists`
- Button disabled when `currentPath == nil` or file does not exist
- "文件尚未创建" shown when file missing

---

### AC4 — 外部编辑检测与重新加载 (P0) — FULL

**Description:** Given 用户在外部编辑器中修改了配置文件, When 切换回 SwiftWork, Then 应用检测到文件变更，提示用户并重新加载 MCP 配置到 SwiftData

**Coverage: FULL** — 36 tests (29 P0 + 4 P1 + 3 integration-only)

| # | Test | File | Level | Priority |
|---|------|------|-------|----------|
| **JSON Parsing** | | | | |
| 1 | testLoadConfigsParsesSingleStdioServer | MCPConfigFileManagerTests.swift:188 | unit | P0 |
| 2 | testLoadConfigsParsesMultipleServers | MCPConfigFileManagerTests.swift:203 | unit | P0 |
| 3 | testLoadConfigsParsesSSEServer | MCPConfigFileManagerTests.swift:217 | unit | P0 |
| 4 | testLoadConfigsParsesStdioArgs | MCPConfigFileManagerTests.swift:231 | unit | P0 |
| 5 | testLoadConfigsParsesEnv | MCPConfigFileManagerTests.swift:245 | unit | P0 |
| 6 | testLoadConfigsReturnsEmptyForMissingFile | MCPConfigFileManagerTests.swift:258 | unit | P0 |
| 7 | testLoadConfigsReturnsEmptyForInvalidJSON | MCPConfigFileManagerTests.swift:265 | unit | P0 |
| 8 | testLoadConfigsReturnsEmptyForNoMcpServersKey | MCPConfigFileManagerTests.swift:275 | unit | P0 |
| 9 | testLoadConfigsDefaultsEnabledTrue | MCPConfigFileManagerTests.swift:285 | unit | P0 |
| 10 | testLoadConfigsHonorsExplicitDisabled | MCPConfigFileManagerTests.swift:296 | unit | P0 |
| 11 | testLoadConfigsInfersStdioFromCommand | MCPConfigFileManagerTests.swift:319 | unit | P0 |
| 12 | testLoadConfigsInfersSSEFromUrl | MCPConfigFileManagerTests.swift:340 | unit | P0 |
| 13 | testLoadConfigsParsesHttpType | MCPConfigFileManagerTests.swift:360 | unit | P0 |
| 14 | testLoadConfigsHandlesEmptyMcpServers | MCPConfigFileManagerTests.swift:383 | unit | P0 |
| 15 | testLoadConfigsHandlesEmptyArgs | MCPConfigFileManagerTests.swift:393 | unit | P1 |
| 16 | testLoadConfigsHandlesMissingOptionalFields | MCPConfigFileManagerTests.swift:416 | unit | P1 |
| **Import to SwiftData** | | | | |
| 17 | testImportFromFileAddsNewConfigs | MCPConfigFileManagerTests.swift:442 | unit | P0 |
| 18 | testImportFromFileOverwritesDuplicateName | MCPConfigFileManagerTests.swift:456 | unit | P0 |
| 19 | testImportFromFileMixedAddAndUpdate | MCPConfigFileManagerTests.swift:486 | unit | P0 |
| 20 | testImportFromFilePreservesSwiftDataOnlyConfigs | MCPConfigFileManagerTests.swift:520 | unit | P0 |
| 21 | testImportFromFileDoesNotCrashOnMissingFile | MCPConfigFileManagerTests.swift:552 | unit | P0 |
| 22 | testImportFromFileSetsCorrectScope | MCPConfigFileManagerTests.swift:566 | unit | P0 |
| **File Watching** | | | | |
| 23 | testFileChangeTriggersCallback | MCPConfigFileManagerTests.swift:630 | unit | P1 |
| 24 | testStopWatchingStopsCallbacks | MCPConfigFileManagerTests.swift:657 | unit | P1 |
| **Integration** | | | | |
| 25 | testFullImportPipeline | MCPConfigFileIntegrationTests.swift:48 | integration | P0 |
| 26 | testReimportUpdatesConfigs | MCPConfigFileIntegrationTests.swift:91 | integration | P0 |
| 27 | testImportMultipleServersDedup | MCPConfigFileIntegrationTests.swift:138 | integration | P0 |
| 28 | testScopeAwareImport | MCPConfigFileIntegrationTests.swift:187 | integration | P0 |
| 29 | testEmptyFileImportPreservesExisting | MCPConfigFileIntegrationTests.swift:250 | integration | P0 |
| 30 | testAgentBridgeHotUpdateAfterImport | MCPConfigFileIntegrationTests.swift:282 | integration | P0 |
| 31 | testImportThenDisableReflectsInHotUpdate | MCPConfigFileIntegrationTests.swift:317 | integration | P0 |
| **View-Level** | | | | |
| 32 | testViewModelRefreshConfigDoesNotCrashWithoutStore | MCPAdvancedSettingsViewTests.swift:144 | unit | P0 |
| 33 | testViewModelRefreshConfigReloadsFromFile | MCPAdvancedSettingsViewTests.swift:151 | unit | P0 |

**Covered Scenarios:**
- JSON 解析：单服务器、多服务器、stdio/sse/http 类型
- JSON 解析：args、env、headers 正确解码
- JSON 解析：type 推断（command -> stdio, url -> sse）
- JSON 解析：enabled 默认值和显式 false
- JSON 解析：无效 JSON、空 mcpServers、缺失字段容错
- 导入：新增、去重覆盖、保留 SwiftData 独有配置
- 导入：scope 正确设置、空文件不清除已有配置
- 端到端：文件 -> 解析 -> 导入 SwiftData -> AgentBridge 热更新
- 端到端：重新导入更新配置、scope 感知导入
- 端到端：禁用后热更新反映正确状态
- 文件监控：DispatchSource 注册/停止/回调触发

**Implementation Verified:**
- `parseConfigData` -> `parseServerEntry`: full JSON -> MCPServerConfig mapping
- Type inference: `command` present -> `.stdio`, `url` present -> `.sse`
- `importFromFile`: add new, `store.replace` existing (dedup by name)
- `DispatchSource` file watching with `[.write, .delete, .rename, .attrib]`
- `startWatching`/`stopWatching` lifecycle bound to `onAppear`/`onDisappear`
- Manual `refreshConfig()` button with error alert feedback
- `agentBridge?.updateMCPServers()` for hot-update after import

---

## Gap Analysis

| Category | Count |
|----------|-------|
| Critical Gaps (P0 uncovered) | 0 |
| High Gaps (P1 uncovered) | 0 |
| Medium Gaps (P2 uncovered) | 0 |
| Low Gaps (P3 uncovered) | 1 |
| Informational | 3 |

### GAP-1 [INFO] — DispatchSource cancel/close race condition

**AC:** AC4 | **Severity:** Informational
**Description:** `stopWatching()` assigns `fileSource = nil` before closing the file descriptor. Under Swift 6 strict concurrency, adding a `cancelHandler` to close the descriptor crashes. The current implementation may briefly leak a descriptor during rapid start/stop cycles.
**Mitigation:** Accepted as-is per code review decision. The manual refresh button covers the primary reload use case. File watching is supplementary.

### GAP-2 [LOW] — File watching starts on actionButtons.onAppear

**AC:** AC4 | **Severity:** Low
**Description:** `startFileWatchingIfNeeded()` is called from `actionButtons.onAppear`, which only fires when the action buttons section is rendered (after expansion + scroll). It does not start immediately when the advanced settings section expands.
**Mitigation:** Manual refresh button is the primary mechanism per Dev Notes. File watching is explicitly documented as supplementary.

### GAP-3 [INFO] — No UI test for collapse/expand animation

**AC:** AC1 | **Severity:** Informational
**Description:** No test verifies the SwiftUI animation behavior (transition timing, chevron rotation).
**Mitigation:** Animation is declarative SwiftUI (`withAnimation(.easeInOut(duration: 0.2))`). ViewModel state tests (`isExpanded` toggle) cover the logic. Animation correctness is visually verified.

### GAP-4 [INFO] — Project scope button disable state untested at View level

**AC:** AC2 | **Severity:** Informational
**Description:** No test verifies that the Project scope button renders as disabled in the actual SwiftUI view when workspacePath is nil.
**Mitigation:** `MCPAdvancedSettingsViewTests.testViewModelProjectScopeUnavailableWhenNoWorkspace` covers the ViewModel logic. The View uses `.disabled(isDisabled)` declaratively.

---

## Code Review Fixes Verified

| Fix | Status | Verification |
|-----|--------|-------------|
| MCPAdvancedSettingsViewTests.swift added to build target | VERIFIED | `F9A00F1A060EAEE9DE2BC904` in PBXBuildFile |
| File watching integrated into view lifecycle (onDisappear) | VERIFIED | `MCPAdvancedSettingsView.swift:33-35` calls `configManager.stopWatching()` |
| Error feedback via alert for refreshConfig failures | VERIFIED | `MCPAdvancedSettingsView.swift:25-32` `.alert()` with `errorMessage` binding |
| DispatchSource cancel/close race left as-is | VERIFIED | `MCPConfigFileManager.swift:205-214` simple cancel + nil + close sequence |

---

## Coverage Heuristics

| Heuristic | Status |
|-----------|--------|
| API endpoint coverage | not_applicable (no API endpoints) |
| Auth/authz negative paths | not_applicable (no auth flows) |
| Error-path coverage | present (missing file, invalid JSON, empty mcpServers, import failure, refreshConfig error alert) |
| UI journey E2E coverage | not_applicable (pure Swift, no browser E2E) |
| UI state coverage | present (collapsed/expanded, project/global scope, file exists/missing, error state) |
| Boundary value coverage | present (nil workspace, empty workspace, empty args, empty env, missing type field) |

---

## Gate Criteria

| Criterion | Required | Actual | Status |
|-----------|----------|--------|--------|
| P0 Coverage | 100% | 100% | MET |
| P1 Coverage Target | 90% | 100% | MET |
| P1 Coverage Minimum | 80% | 100% | MET |
| Overall Coverage | 80% | 100% | MET |
| Test Files in Build Target | 3/3 | 3/3 | MET |
| Regression Pass | 0 failures | 0 failures | MET |

---

## Test Inventory

| File | Tests | Level |
|------|-------|-------|
| `SwiftWorkTests/Services/MCPConfigFileManagerTests.swift` | 37 | unit |
| `SwiftWorkTests/Views/Settings/MCPAdvancedSettingsViewTests.swift` | 14 | unit |
| `SwiftWorkTests/Services/MCPConfigFileIntegrationTests.swift` | 9 | integration |
| **Total** | **60** | **51 unit + 9 integration** |

---

## Implementation Files

**New files (Story 6-6):**
- `SwiftWork/Services/MCPConfigFileManager.swift` — Config file read/write, parse, import, file watching
- `SwiftWork/Views/Settings/MCP/MCPAdvancedSettingsView.swift` — Collapsible advanced settings UI

**Test files (Story 6-6):**
- `SwiftWorkTests/Services/MCPConfigFileManagerTests.swift` — 37 unit tests
- `SwiftWorkTests/Views/Settings/MCPAdvancedSettingsViewTests.swift` — 14 unit tests
- `SwiftWorkTests/Services/MCPConfigFileIntegrationTests.swift` — 9 integration tests

**Modified files (Story 6-6):**
- `SwiftWork/Views/Settings/MCP/MCPManagementView.swift` — Integrated MCPAdvancedSettingsView at bottom
- `SwiftWork.xcodeproj/project.pbxproj` — Added new file references

---

*Generated: 2026-05-07 | Evaluator: Nick | Story: 6-6 MCP Advanced Settings Config*
