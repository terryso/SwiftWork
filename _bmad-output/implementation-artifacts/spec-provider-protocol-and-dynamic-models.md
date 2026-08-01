---
title: '支持 Provider 协议与动态模型发现'
type: 'bugfix'
created: '2026-08-01'
status: 'done'
baseline_commit: 'f9e292373ecb4e4d3411e9c9bc231dfa9404b4b9'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/project-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** 当前 Base URL 和 API Key 虽可配置，但 Agent 始终使用 SDK 默认的 Anthropic 协议，模型选择器也只显示三个硬编码 Claude 模型，导致 OpenAI-compatible 服务无法正确使用。

**Approach:** 将 SwiftWork 的 SDK 从 0.9.0 升级到最新发布版 0.12.0，增加 Anthropic 与 OpenAI-compatible 选择，用当前 Provider、Base URL 和 Key 获取模型，并把同一协议传给 Agent 与标题生成。

## Boundaries & Constraints

**Always:** Key 仅存 Keychain，不进入日志/错误；Provider/模型存 AppConfiguration；旧配置按 Anthropic 兼容；Anthropic 用 `GET /v1/models` 和 `x-api-key`，OpenAI-compatible 用 `GET /models` 和 Bearer；候选只来自当前 API；异步任务可取消，UI 只在 MainActor 更新。

**Ask First:** 增加第三种协议、保存多套 Provider/Profile 凭据、修改 `open-agent-sdk-swift` 源码、升级到 0.12.0 之后的版本、引入新的网络依赖。

**Never:** 静态模型候选；在 Keychain 外保存 Key；用推理请求发现模型；失败后换协议或沿用另一 Provider 模型。

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| 获取模型 | 任一 Provider + 有效地址/Key | 请求对应 models 端点，ID 去重排序 | 非 2xx、坏 JSON、空列表显示可重试错误 |
| 首次配置 | Provider/地址/Key 尚未保存 | 先获取模型，有选择后才可完成 | 失败保留输入 |
| 旧配置 | 有 Key/Claude 模型，无 Provider | 按 Anthropic 加载并刷新 | 失败保留最后已存选择 |
| 切换协议 | Anthropic → OpenAI-compatible | 清空旧候选，获取并保存新模型 | 新列表成功前旧模型不可发送 |
| 自定义地址 | 尾斜杠；OpenAI 地址含 `/v1` | 规范化后追加一次模型路径 | 非法 URL 请求前报错 |

</frozen-after-approval>

## Code Map

- `SwiftWork/Models/UI/AgentProvider.swift` -- App Provider、显示名、默认地址和持久化值。
- `SwiftWork/Services/ModelDiscoveryService.swift` -- models 请求、认证、解析与端点规范化。
- `SwiftWork/ViewModels/SettingsViewModel.swift` -- Provider 持久化、刷新状态和选择一致性。
- `SwiftWork/Views/{Onboarding,Settings}/` -- Provider/模型加载、错误和重试 UI。
- `SwiftWork/SDKIntegration/AgentBridge.swift`、`SwiftWork/Views/Workspace/WorkspaceView.swift` -- Provider 映射与传递。
- `SwiftWork/Services/TitleGenerator.swift` -- 两种协议的标题请求/解析。
- `SwiftWork/Utils/Constants.swift`、`SwiftWork.xcodeproj/project.pbxproj` -- 移除静态候选并登记新文件。
- `Package.swift`、两个 `Package.resolved` -- SDK 锁定从 0.9.0 升级为最新发布版 0.12.0。

## Tasks & Acceptance

**Execution:**
- [x] Package manifests/lockfiles -- 升级 OpenAgentSDK 0.12.0，并完成必要的编译兼容改动。
- [x] Provider model/constants -- 定义两种协议、兼容旧配置并删除静态候选。
- [x] Model discovery service/tests -- 覆盖 URL/Header、去重解析、HTTP/JSON/空响应和取消。
- [x] Settings view model/tests -- 持久化 Provider、动态刷新并隔离不同协议模型。
- [x] Onboarding/Settings views/tests -- 加入协议选择、加载/空态/错误/重试和完成门槛。
- [x] AgentBridge/Workspace/TitleGenerator/tests -- Agent 与标题生成均使用所选协议。
- [x] Xcode project -- 新文件加入正确 target。

**Acceptance Criteria:**
- Given SwiftWork 解析依赖，when 构建或测试，then 使用 OpenAgentSDK 0.12.0 且无旧 API 编译错误。
- Given 有效 Provider/地址/Key，when 获取模型，then 只显示 API 返回的唯一非空模型 ID。
- Given 保存 OpenAI-compatible 模型，when 配置新会话，then SDK provider 为 `.openai` 且地址/模型一致。
- Given 旧配置无 Provider，when 升级加载，then 继续按 Anthropic 工作且无需重输 Key。
- Given 请求失败、空响应或取消，when UI 恢复，then 可重试、不崩溃、不泄漏 Key、不伪造静态成功列表。

## Spec Change Log

## Design Notes

本地 SDK 仓库 `main` 已与 `origin/main` 同步，最新发布 tag 为 0.12.0；SwiftWork 仍锁定 0.9.0。SDK 的 `supportedModels()` 仅读本地价格表，因此动态发现仍放在 Service 层；App Provider 只在 AgentBridge 映射成 SDK 类型。

## Verification

**Commands:**
- `git diff --check f9e292373ecb4e4d3411e9c9bc231dfa9404b4b9` -- 通过。
- `swift package resolve` -- OpenAgentSDK 解析到 0.12.0。
- 相关定向测试 -- 104 个测试通过，0 失败。
- `swift test` -- 1273 个测试通过，0 失败。
- `swift build` -- 通过；仅有既存的 `ContentView` Sendable 警告。
- `xcodebuild -project SwiftWork.xcodeproj -scheme SwiftWork -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build` -- `BUILD SUCCEEDED`。

**Manual checks (if no CLI):**
- 未执行手工 UI 操作；首次引导、设置页状态和协议传递由单元测试及 macOS 构建覆盖。

## Suggested Review Order

### 动态发现与状态一致性

Provider、地址、Key、取消与竞态统一在刷新流程收口。

- [刷新编排与持久化](../../SwiftWork/ViewModels/SettingsViewModel.swift#L220)
- [模型端点、认证与传输限制](../../SwiftWork/Services/ModelDiscoveryService.swift#L19)
- [旧配置与未知 Provider 兼容](../../SwiftWork/ViewModels/SettingsViewModel.swift#L46)

### Agent 与标题协议传播

配置变化会重建空闲 Agent，运行中任务保持一致快照。

- [工作区配置变更与会话快照](../../SwiftWork/Views/Workspace/WorkspaceView.swift#L128)
- [SDK Provider 映射与失败关闭](../../SwiftWork/SDKIntegration/AgentBridge.swift#L327)
- [双协议标题请求](../../SwiftWork/Services/TitleGenerator.swift#L3)

### UI、依赖与回归覆盖

模型候选只来自 API，并要求用户明确选择。

- [首次引导配置流程](../../SwiftWork/Views/Onboarding/WelcomeView.swift#L40)
- [设置页保存并获取模型](../../SwiftWork/Views/Settings/APIKeySettingsView.swift#L103)
- [动态模型选择器](../../SwiftWork/Views/Settings/ModelPickerView.swift#L35)
- [SDK 0.12.0 依赖](../../Package.swift#L18)
- [发现服务边界测试](../../SwiftWorkTests/Services/ModelDiscoveryServiceTests.swift#L46)
- [配置状态与竞态测试](../../SwiftWorkTests/ViewModels/SettingsViewModelTests.swift#L309)
- [SDK Provider 映射测试](../../SwiftWorkTests/SDKIntegration/AgentBridgeTests.swift#L609)
