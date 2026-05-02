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

    // MARK: - Pagination State (Story 2-5)

    @ObservationIgnored
    private var pageSize: Int = 50

    @ObservationIgnored
    private var totalPersistedEvents: Int = 0

    @ObservationIgnored
    private var trimmedEventCount: Int = 0

    var hasMoreEvents: Bool {
        totalPersistedEvents > trimmedEventCount + events.count
    }

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
            let total = try eventStore.totalEventCount(for: session.id)
            totalPersistedEvents = total

            if total > 1000 {
                // Large session: load first page only
                let firstPage = try eventStore.fetchEvents(for: session.id, offset: 0, limit: pageSize)
                events = firstPage
                eventOrder = total
            } else {
                // Small session: load all events
                let persisted = try eventStore.fetchEvents(for: session.id)
                events = persisted
                eventOrder = persisted.count
            }
            rebuildToolContentMap()
        } catch {
            errorMessage = AppError(
                domain: .data,
                code: "LOAD_EVENTS_FAILED",
                message: error.localizedDescription,
                underlying: error
            ).message
        }
    }

    func loadInitialPage(for session: Session) {
        clearEvents()
        currentSession = session

        guard let eventStore else { return }

        do {
            totalPersistedEvents = try eventStore.totalEventCount(for: session.id)
            let limit = min(pageSize, totalPersistedEvents)
            let firstPage = try eventStore.fetchEvents(for: session.id, offset: 0, limit: limit)
            events = firstPage
            eventOrder = totalPersistedEvents
            rebuildToolContentMap()
        } catch {
            errorMessage = AppError(
                domain: .data,
                code: "LOAD_EVENTS_FAILED",
                message: error.localizedDescription,
                underlying: error
            ).message
        }
    }

    func loadMoreEvents() {
        guard let eventStore, let currentSession else { return }

        let offset = trimmedEventCount + events.count
        guard offset < totalPersistedEvents else { return }

        do {
            let remaining = totalPersistedEvents - offset
            let limit = min(pageSize, remaining)
            let nextPage = try eventStore.fetchEvents(
                for: currentSession.id,
                offset: offset,
                limit: limit
            )
            events.append(contentsOf: nextPage)
            rebuildToolContentMap()
        } catch {
            // Non-critical: pagination failure should not block the user
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
        totalPersistedEvents = 0
        trimmedEventCount = 0
    }

    private func appendAndPersist(_ event: AgentEvent) {
        events.append(event)
        processToolContentMap(for: event)

        guard event.type != .partialMessage,
              let eventStore, let currentSession else { return }

        totalPersistedEvents += 1

        do {
            try eventStore.persist(event, session: currentSession, order: eventOrder)
            eventOrder += 1
        } catch {
            // Non-critical: persistence failure should not block the user
        }

        trimOldEvents()
    }

    private let maxInMemory = 500

    func trimOldEvents() {
        guard events.count > maxInMemory else { return }
        let removeCount = events.count - maxInMemory
        let removed = Array(events.prefix(removeCount))
        events.removeFirst(removeCount)
        trimmedEventCount += removeCount

        // Clean up toolContentMap entries that belonged to removed events
        for event in removed {
            if event.type == .toolUse {
                let toolUseId = event.metadata["toolUseId"] as? String ?? ""
                toolContentMap.removeValue(forKey: toolUseId)
            }
        }
    }
}
