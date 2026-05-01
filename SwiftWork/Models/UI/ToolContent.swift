import Foundation

/// 工具执行状态枚举
enum ToolExecutionStatus: String, Sendable, Equatable {
    case pending    // 仅 toolUse，尚无 toolResult
    case running    // 收到 toolProgress
    case completed  // toolResult isError=false
    case failed     // toolResult isError=true
}

struct ToolContent: Sendable {
    let toolName: String
    let toolUseId: String
    let input: String
    let output: String?
    let isError: Bool
    // status 是唯一可变字段——通过 applyingProgress() 和 toolResult 更新状态，
    // 其他字段保持 let 确保不可变。struct 的值语义保证每次更新创建新副本。
    var status: ToolExecutionStatus
    let elapsedTimeSeconds: Int?

    init(
        toolName: String,
        toolUseId: String,
        input: String,
        output: String?,
        isError: Bool,
        status: ToolExecutionStatus = .pending,
        elapsedTimeSeconds: Int? = nil
    ) {
        self.toolName = toolName
        self.toolUseId = toolUseId
        self.input = input
        self.output = output
        self.isError = isError
        self.status = status
        self.elapsedTimeSeconds = elapsedTimeSeconds
    }

    /// 从 toolUse AgentEvent 提取 ToolContent
    static func fromToolUseEvent(_ event: AgentEvent) -> ToolContent {
        let toolName = event.metadata["toolName"] as? String ?? event.content
        let toolUseId = event.metadata["toolUseId"] as? String ?? ""
        let input = event.metadata["input"] as? String ?? ""

        return ToolContent(
            toolName: toolName,
            toolUseId: toolUseId,
            input: input,
            output: nil,
            isError: false,
            status: .pending
        )
    }

    /// 从 toolResult AgentEvent 提取 ToolContent。
    /// 注意：返回的 ToolContent 的 toolName 和 input 为空（toolResult 事件不含这些字段）。
    /// 需要通过 toolUseId 与原始 toolUse 事件配对合并使用（Story 2-2 实现）。
    static func fromToolResultEvent(_ event: AgentEvent) -> ToolContent {
        let toolUseId = event.metadata["toolUseId"] as? String ?? ""
        let isError = event.metadata["isError"] as? Bool ?? false

        return ToolContent(
            toolName: "",
            toolUseId: toolUseId,
            input: "",
            output: event.content,
            isError: isError,
            status: isError ? .failed : .completed
        )
    }

    /// 应用 progress 事件更新 elapsed time 和 status
    func applyingProgress(_ event: AgentEvent) -> ToolContent {
        let elapsed = event.metadata["elapsedTimeSeconds"] as? Int
        return ToolContent(
            toolName: toolName,
            toolUseId: toolUseId,
            input: input,
            output: output,
            isError: isError,
            status: .running,
            elapsedTimeSeconds: elapsed
        )
    }

    /// 从 input JSON 提取摘要标题
    var summaryTitle: String {
        guard !input.isEmpty,
              let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return toolName
        }

        // Bash: 提取 command
        if let command = json["command"] as? String, !command.isEmpty {
            return command
        }

        // Read/Write/Edit: 提取 file_path
        if let filePath = json["file_path"] as? String, !filePath.isEmpty {
            return filePath
        }

        // Grep/Glob: 提取 pattern
        if let pattern = json["pattern"] as? String, !pattern.isEmpty {
            return pattern
        }

        return toolName
    }
}
