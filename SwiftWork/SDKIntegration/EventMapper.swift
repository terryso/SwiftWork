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
}
