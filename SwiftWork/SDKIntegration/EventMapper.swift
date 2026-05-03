import Foundation
import OpenAgentSDK

struct EventMapper {
    /// Maps an SDKMessage to an AgentEvent.
    /// Pure function with no side effects.
    static func map(_ message: SDKMessage) -> AgentEvent {
        switch message {
        case .partialMessage(let data):
            return AgentEvent(
                type: .partialMessage,
                content: data.text,
                timestamp: .now
            )

        case .assistant(let data):
            return AgentEvent(
                type: .assistant,
                content: data.text,
                metadata: [
                    "model": data.model,
                    "stopReason": data.stopReason
                ],
                timestamp: .now
            )

        case .toolUse(let data):
            // Plan-related tools: remap to .plan event type
            if data.toolName == "EnterPlanMode" || data.toolName == "ExitPlanMode" || data.toolName == "TodoWrite" {
                return mapPlanToolUse(data)
            }
            return AgentEvent(
                type: .toolUse,
                content: data.toolName,
                metadata: [
                    "toolName": data.toolName,
                    "toolUseId": data.toolUseId,
                    "input": data.input
                ],
                timestamp: .now
            )

        case .toolResult(let data):
            return AgentEvent(
                type: .toolResult,
                content: data.content,
                metadata: [
                    "toolUseId": data.toolUseId,
                    "isError": data.isError
                ],
                timestamp: .now
            )

        case .toolProgress(let data):
            return AgentEvent(
                type: .toolProgress,
                content: data.toolName,
                metadata: [
                    "toolUseId": data.toolUseId,
                    "toolName": data.toolName,
                    "elapsedTimeSeconds": data.elapsedTimeSeconds ?? 0
                ],
                timestamp: .now
            )

        case .result(let data):
            return AgentEvent(
                type: .result,
                content: data.text,
                metadata: [
                    "subtype": data.subtype.rawValue,
                    "numTurns": data.numTurns,
                    "durationMs": data.durationMs,
                    "totalCostUsd": data.totalCostUsd
                ],
                timestamp: .now
            )

        case .system(let data):
            return AgentEvent(
                type: .system,
                content: data.message,
                metadata: ["subtype": data.subtype.rawValue],
                timestamp: .now
            )

        case .userMessage(let data):
            return AgentEvent(
                type: .userMessage,
                content: data.message,
                timestamp: .now
            )

        case .hookStarted(let data):
            return AgentEvent(
                type: .system,
                content: "Hook 启动: \(data.hookName)",
                metadata: ["hookEvent": data.hookEvent],
                timestamp: .now
            )

        case .hookProgress(let data):
            return AgentEvent(
                type: .system,
                content: data.stdout ?? data.stderr ?? "Hook 进度: \(data.hookName)",
                metadata: ["hookName": data.hookName],
                timestamp: .now
            )

        case .hookResponse(let data):
            return AgentEvent(
                type: .system,
                content: data.output ?? "Hook 完成",
                metadata: [
                    "hookName": data.hookName,
                    "exitCode": data.exitCode ?? 0
                ],
                timestamp: .now
            )

        case .taskStarted(let data):
            return AgentEvent(
                type: .system,
                content: "子任务启动: \(data.description)",
                metadata: [
                    "taskId": data.taskId,
                    "taskType": data.taskType
                ],
                timestamp: .now
            )

        case .taskProgress(let data):
            return AgentEvent(
                type: .system,
                content: "子任务进度: \(data.taskId)",
                metadata: ["taskId": data.taskId],
                timestamp: .now
            )

        case .authStatus(let data):
            return AgentEvent(
                type: .system,
                content: data.message,
                metadata: ["authStatus": data.status],
                timestamp: .now
            )

        case .filesPersisted(let data):
            return AgentEvent(
                type: .system,
                content: "文件已保存: \(data.filePaths.joined(separator: ", "))",
                timestamp: .now
            )

        case .localCommandOutput(let data):
            return AgentEvent(
                type: .system,
                content: data.output,
                metadata: ["command": data.command],
                timestamp: .now
            )

        case .promptSuggestion(let data):
            return AgentEvent(
                type: .system,
                content: data.suggestions.joined(separator: "\n"),
                timestamp: .now
            )

        case .toolUseSummary(let data):
            return AgentEvent(
                type: .system,
                content: "工具使用汇总: \(data.toolUseCount) 次",
                metadata: ["tools": data.tools],
                timestamp: .now
            )
        }
    }

    // MARK: - Plan Tool Mapping

    /// Maps plan-related toolUse events (EnterPlanMode, ExitPlanMode, TodoWrite) to .plan type.
    private static func mapPlanToolUse(_ data: SDKMessage.ToolUseData) -> AgentEvent {
        var metadata: [String: any Sendable] = [
            "toolUseId": data.toolUseId,
            "input": data.input
        ]

        let content: String

        switch data.toolName {
        case "EnterPlanMode":
            metadata["planAction"] = "enter"
            content = "进入计划模式"

        case "ExitPlanMode":
            metadata["planAction"] = "exit"
            let (planText, approved) = parseExitPlanInput(data.input)
            metadata["approved"] = approved
            if !planText.isEmpty {
                content = planText
                let steps = PlanStep.parseList(from: planText)
                if !steps.isEmpty {
                    metadata["steps"] = steps.map { step -> [String: any Sendable] in
                        [
                            "id": step.id,
                            "description": step.description,
                            "status": step.status.rawValue,
                            "dependencies": step.dependencies
                        ] as [String: any Sendable]
                    }
                }
            } else {
                // JSON parse failed — try extracting plan from raw input
                let rawContent = extractPlanFromRawInput(data.input)
                content = rawContent.isEmpty ? "退出计划模式" : rawContent
            }

        case "TodoWrite":
            metadata["planAction"] = "todoUpdate"
            let todoSteps = parseTodoInput(data.input)
            if !todoSteps.isEmpty {
                metadata["steps"] = todoSteps.map { step -> [String: any Sendable] in
                    [
                        "id": step.id,
                        "description": step.description,
                        "status": step.status.rawValue,
                        "dependencies": step.dependencies
                    ] as [String: any Sendable]
                }
            }
            content = "更新任务清单"

        default:
            content = data.toolName
        }

        return AgentEvent(
            type: .plan,
            content: content,
            metadata: metadata,
            timestamp: .now
        )
    }

    /// Parses ExitPlanMode input JSON to extract plan text and approval status.
    private static func parseExitPlanInput(_ input: String) -> (plan: String, approved: Bool) {
        guard !input.isEmpty,
              let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return ("", false) }

        let plan = json["plan"] as? String ?? ""
        let approved = json["approved"] as? Bool ?? false
        return (plan, approved)
    }

    /// Extracts plan text from raw input when the primary JSON parse fails.
    /// Returns empty string on failure so PlanView falls back to default text.
    private static func extractPlanFromRawInput(_ input: String) -> String {
        guard let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let plan = json["plan"] as? String,
              !plan.isEmpty
        else { return "" }
        return plan
    }

    /// Parses TodoWrite input JSON to extract todo items as plan steps.
    private static func parseTodoInput(_ input: String) -> [PlanStep] {
        guard !input.isEmpty,
              let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [] }

        // Single todo operation
        if let text = json["text"] as? String, !text.isEmpty {
            let id = json["id"] as? String ?? UUID().uuidString
            let action = json["action"] as? String ?? "add"
            let status: PlanStepStatus = action == "toggle" ? .completed : .pending
            return [PlanStep(id: id, description: text, status: status, dependencies: [])]
        }

        // Batch todos (if input has array)
        if let todos = json["todos"] as? [[String: Any]] {
            return todos.enumerated().map { (index, todo) in
                let text = todo["text"] as? String ?? ""
                let id = todo["id"] as? String ?? "todo-\(index)"
                return PlanStep(id: id, description: text, status: .pending, dependencies: [])
            }
        }

        return []
    }
}
