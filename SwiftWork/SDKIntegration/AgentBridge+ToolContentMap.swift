import Foundation

extension AgentBridge {

    /// Rebuilds toolContentMap from persisted events, then finalizes
    /// any tools still in pending/running state (historical sessions
    /// have no active stream, so all tools should show completed).
    func rebuildToolContentMap() {
        for event in events {
            processToolContentMap(for: event)
        }
        finalizeToolContentMap()
    }

    /// Finalizes all pending/running tools to completed state.
    /// Called when the stream ends to ensure no spinners remain forever.
    func finalizeToolContentMap() {
        for (toolUseId, content) in toolContentMap {
            if content.status == .pending || content.status == .running {
                var copy = content
                copy.status = .completed
                toolContentMap[toolUseId] = copy
            }
        }
    }

    /// Processes an event and updates toolContentMap for tool events.
    /// Call this for each event to maintain the tool content pairing.
    func processToolContentMap(for event: AgentEvent) {
        switch event.type {
        case .toolUse, .plan:
            let content = ToolContent.fromToolUseEvent(event)
            toolContentMap[content.toolUseId] = content
        case .toolProgress:
            let toolUseId = event.metadata["toolUseId"] as? String ?? ""
            if let existing = toolContentMap[toolUseId] {
                toolContentMap[toolUseId] = existing.applyingProgress(event)
            }
        case .toolResult:
            let resultContent = ToolContent.fromToolResultEvent(event)
            let toolUseId = resultContent.toolUseId
            if let existing = toolContentMap[toolUseId] {
                toolContentMap[toolUseId] = ToolContent(
                    toolName: existing.toolName,
                    toolUseId: existing.toolUseId,
                    input: existing.input,
                    output: resultContent.output,
                    isError: resultContent.isError,
                    status: resultContent.status,
                    elapsedTimeSeconds: existing.elapsedTimeSeconds
                )
            }
        default:
            break
        }
    }
}
