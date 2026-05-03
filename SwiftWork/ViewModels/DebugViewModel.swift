import Foundation

/// Token usage summary aggregated from all .result events.
struct TokenSummary: Equatable {
    let totalInputTokens: Int
    let totalOutputTokens: Int
    let totalTokens: Int
    let totalCostUsd: Double

    static let zero = TokenSummary(
        totalInputTokens: 0,
        totalOutputTokens: 0,
        totalTokens: 0,
        totalCostUsd: 0.0
    )
}

/// A single tool execution log entry derived from toolContentMap.
struct ToolLogEntry: Identifiable {
    let id: String
    let toolName: String
    let toolUseId: String
    let status: ToolExecutionStatus
    let elapsedTimeSeconds: Int?
    let summaryTitle: String
    let resultPreview: String
    let timestamp: Date
}

@MainActor
@Observable
final class DebugViewModel {
    let agentBridge: AgentBridge

    init(agentBridge: AgentBridge) {
        self.agentBridge = agentBridge
    }

    // MARK: - AC#1: Raw Event Stream (FR38)

    /// Filtered events excluding partialMessage (streaming intermediates).
    var filteredEvents: [AgentEvent] {
        agentBridge.events.filter { $0.type != .partialMessage }
    }

    /// JSON string representation for each filtered event.
    var rawEventJSONStrings: [String] {
        filteredEvents.map { rawJSONString(for: $0) }
    }

    // MARK: - AC#2: Token Statistics (FR39)

    /// Aggregated token summary from all .result events.
    var tokenSummary: TokenSummary {
        var totalInput = 0
        var totalOutput = 0
        var totalCost = 0.0

        for event in agentBridge.events where event.type == .result {
            if let usage = event.metadata["usage"] as? [String: Any] {
                totalInput += (usage["inputTokens"] as? Int) ?? 0
                totalOutput += (usage["outputTokens"] as? Int) ?? 0
            }
            totalCost += (event.metadata["totalCostUsd"] as? Double) ?? 0.0
        }

        return TokenSummary(
            totalInputTokens: totalInput,
            totalOutputTokens: totalOutput,
            totalTokens: totalInput + totalOutput,
            totalCostUsd: totalCost
        )
    }

    /// Per-call token breakdown from each .result event, in order.
    var perCallTokenBreakdown: [AgentEvent] {
        agentBridge.events.filter { $0.type == .result }
    }

    // MARK: - AC#3: Tool Execution Logs (FR40)

    /// Tool execution logs derived from toolContentMap, ordered by timestamp.
    var toolLogs: [ToolLogEntry] {
        // Build a lookup from toolUseId -> timestamp via events
        var timestampLookup: [String: Date] = [:]
        for event in agentBridge.events where event.type == .toolUse {
            if let toolUseId = event.metadata["toolUseId"] as? String {
                timestampLookup[toolUseId] = event.timestamp
            }
        }

        let logs = agentBridge.toolContentMap.values.map { content -> ToolLogEntry in
            let preview = truncatedPreview(content.output, maxLength: 200)
            return ToolLogEntry(
                id: content.toolUseId,
                toolName: content.toolName,
                toolUseId: content.toolUseId,
                status: content.status,
                elapsedTimeSeconds: content.elapsedTimeSeconds,
                summaryTitle: content.summaryTitle,
                resultPreview: preview,
                timestamp: timestampLookup[content.toolUseId] ?? Date.distantPast
            )
        }

        return logs.sorted { $0.timestamp < $1.timestamp }
    }

    // MARK: - JSON Serialization

    func rawJSONString(for event: AgentEvent) -> String {
        let payload: [String: Any] = [
            "id": event.id.uuidString,
            "type": event.type.rawValue,
            "content": event.content,
            "metadata": event.metadata,
            "timestamp": event.timestamp.ISO8601Format()
        ]
        guard let data = try? JSONSerialization.data(
            withJSONObject: payload,
            options: [.prettyPrinted, .sortedKeys]
        ) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    // MARK: - Private Helpers

    private func truncatedPreview(_ text: String?, maxLength: Int) -> String {
        guard let text, !text.isEmpty else { return "" }
        if text.count <= maxLength { return text }
        let ellipsis = "..."
        let trimLength = maxLength - ellipsis.count
        return String(text.prefix(trimLength)) + ellipsis
    }
}
