import Foundation
import OpenAgentSDK
import Observation

@MainActor
@Observable
final class AgentBridge {
    var events: [AgentEvent] = []
    var isRunning = false
    var errorMessage: String?
    var streamingText: String = ""

    /// Tracks tool content by toolUseId, pairing toolUse/toolProgress/toolResult events.
    var toolContentMap: [String: ToolContent] = [:]

    @ObservationIgnored
    private var agent: Agent?

    @ObservationIgnored
    private var currentTask: _Concurrency.Task<Void, Never>?

    @ObservationIgnored
    private var activeTaskGeneration: UInt64 = 0

    @ObservationIgnored
    private var eventStore: (any EventStoring)?

    @ObservationIgnored
    private var currentSession: Session?

    @ObservationIgnored
    private var eventOrder: Int = 0

    var onResult: ((String) -> Void)?

    func configure(apiKey: String, baseURL: String?, model: String, workspacePath: String?) {
        let options = AgentOptions(
            apiKey: apiKey,
            model: model,
            baseURL: baseURL,
            maxTurns: 10,
            permissionMode: .default,
            cwd: workspacePath,
            tools: getAllBaseTools(tier: .core)
        )
        self.agent = createAgent(options: options)
    }

    func configureEvents(store: any EventStoring, session: Session) {
        self.eventStore = store
        self.currentSession = session
    }

    func loadEvents(for session: Session) {
        clearEvents()
        currentSession = session

        guard let eventStore else { return }

        do {
            let persisted = try eventStore.fetchEvents(for: session.id)
            events = persisted
            eventOrder = persisted.count
        } catch {
            errorMessage = AppError(
                domain: .data,
                code: "LOAD_EVENTS_FAILED",
                message: error.localizedDescription,
                underlying: error
            ).message
        }
    }

    func sendMessage(_ text: String) {
        guard let agent, !text.isEmpty else { return }

        if isRunning {
            cancelExecution()
        }

        let userEvent = AgentEvent(
            type: .userMessage,
            content: text,
            timestamp: .now
        )
        appendAndPersist(userEvent)

        errorMessage = nil
        isRunning = true

        activeTaskGeneration &+= 1
        let myGeneration = activeTaskGeneration

        currentTask = _Concurrency.Task { [weak self] in
            guard let self else { return }
            var receivedResult = false
            let stream = agent.stream(text)
            for await message in stream {
                guard !_Concurrency.Task.isCancelled else { break }

                if case .userMessage = message { continue }

                let event = EventMapper.map(message)

                if event.type == .partialMessage {
                    self.streamingText += event.content
                    continue
                }

                if event.type == .assistant {
                    self.streamingText = ""
                }

                if event.type == .result {
                    receivedResult = true
                    self.onResult?(event.content)
                }
                self.appendAndPersist(event)
            }
            if !_Concurrency.Task.isCancelled && !receivedResult {
                self.appendAndPersist(AgentEvent(
                    type: .system,
                    content: "Agent 流异常结束，未收到完整响应。",
                    metadata: ["isError": true],
                    timestamp: .now
                ))
            }
            self.finalizeToolContentMap()
            if self.activeTaskGeneration == myGeneration {
                self.currentTask = nil
            }
            self.isRunning = false
        }
    }

    func cancelExecution() {
        agent?.interrupt()
        currentTask?.cancel()
        isRunning = false
        streamingText = ""
        finalizeToolContentMap()

        appendAndPersist(AgentEvent(
            type: .system,
            content: "任务已取消",
            metadata: ["isCancellation": true],
            timestamp: .now
        ))
    }

    func clearEvents() {
        events = []
        streamingText = ""
        errorMessage = nil
        isRunning = false
        toolContentMap = [:]
        currentTask?.cancel()
        currentTask = nil
        eventOrder = 0
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
        case .toolUse:
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

    private func appendAndPersist(_ event: AgentEvent) {
        events.append(event)
        processToolContentMap(for: event)

        guard event.type != .partialMessage,
              let eventStore, let currentSession else { return }

        do {
            try eventStore.persist(event, session: currentSession, order: eventOrder)
            eventOrder += 1
        } catch {
            // Non-critical: persistence failure should not block the user
        }
    }
}
