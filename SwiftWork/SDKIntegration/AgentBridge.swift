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
    private var inputContinuation: AsyncStream<String>.Continuation?

    @ObservationIgnored
    private var pendingTurnCount: Int = 0

    @ObservationIgnored
    private var eventStore: (any EventStoring)?

    @ObservationIgnored
    private var currentSession: Session?

    @ObservationIgnored
    private let sdkSessionStore = SessionStore()

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

    // MARK: - Permission System (Story 3-1)

    var pendingPermissionRequest: PendingPermissionRequest?

    @ObservationIgnored
    var permissionHandler: PermissionHandler

    init(permissionHandler: PermissionHandler = PermissionHandler()) {
        self.permissionHandler = permissionHandler
    }

    func configure(apiKey: String, baseURL: String?, model: String, workspacePath: String?, sessionId: String) {
        let options = AgentOptions(
            apiKey: apiKey,
            model: model,
            baseURL: baseURL,
            maxTurns: 10,
            permissionMode: .default,
            cwd: workspacePath,
            tools: getAllBaseTools(tier: .core),
            sessionStore: sdkSessionStore,
            sessionId: sessionId,
            persistSession: true
        )
        self.agent = createAgent(options: options)
        setupPermissionCallback()
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
                let firstPage = try eventStore.fetchEvents(for: session.id, offset: 0, limit: pageSize)
                events = firstPage
                eventOrder = total
            } else {
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
        }
    }

    // MARK: - Message Sending (streamInput multi-turn queue)

    func sendMessage(_ text: String) {
        guard let agent, !text.isEmpty else { return }

        let userEvent = AgentEvent(
            type: .userMessage,
            content: text,
            timestamp: .now
        )
        appendAndPersist(userEvent)
        errorMessage = nil

        if !isRunning {
            isRunning = true
            startInputStream(agent)
        }

        pendingTurnCount += 1
        inputContinuation?.yield(text)
    }

    private func startInputStream(_ agent: Agent) {
        let (inputStream, continuation) = AsyncStream<String>.makeStream()
        self.inputContinuation = continuation

        currentTask = _Concurrency.Task { [weak self] in
            guard let self else { return }
            let sdkStream = agent.streamInput(inputStream)
            for await message in sdkStream {
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
                    self.onResult?(event.content)
                    self.pendingTurnCount -= 1
                    if self.pendingTurnCount <= 0 {
                        self.inputContinuation?.finish()
                    }
                }
                self.appendAndPersist(event)
            }
            self.finalizeToolContentMap()
            self.currentTask = nil
            self.isRunning = false
            self.pendingTurnCount = 0
            self.inputContinuation = nil
        }
    }

    func cancelExecution() {
        inputContinuation?.finish()
        agent?.interrupt()
        currentTask?.cancel()
        isRunning = false
        streamingText = ""
        pendingTurnCount = 0
        inputContinuation = nil
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
        pendingTurnCount = 0
        inputContinuation?.finish()
        inputContinuation = nil
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

        for event in removed {
            if event.type == .toolUse {
                let toolUseId = event.metadata["toolUseId"] as? String ?? ""
                toolContentMap.removeValue(forKey: toolUseId)
            }
        }
    }

    // MARK: - Permission Callback (Story 3-1)

    private func setupPermissionCallback() {
        agent?.setCanUseTool { [weak self] tool, input, _ in
            guard let self else { return .allow() }
            let toolName = tool.name
            let inputDict = (input as? [String: Any]) ?? [:]
            nonisolated(unsafe) let unsafeInput = inputDict
            return await self.handlePermissionOnMainActor(toolName: toolName, input: unsafeInput)
        }
    }

    @MainActor
    private func handlePermissionOnMainActor(
        toolName: String,
        input: [String: Any]
    ) async -> CanUseToolResult {
        let decision = permissionHandler.evaluate(toolName: toolName, input: input)

        switch decision {
        case .approved:
            return .allow()
        case .denied(let reason):
            return .deny(reason)
        case .requiresApproval(let toolName, let description, let parameters):
            return await presentPermissionDialog(
                toolName: toolName,
                description: description,
                parameters: parameters,
                input: input
            )
        }
    }

    @MainActor
    private func presentPermissionDialog(
        toolName: String,
        description: String,
        parameters: [String: any Sendable],
        input: [String: Any]
    ) async -> CanUseToolResult {
        let request = PendingPermissionRequest(
            toolName: toolName,
            description: description,
            parameters: parameters,
            input: input
        )

        self.pendingPermissionRequest = request

        let dialogResult = await request.waitForResult()

        self.pendingPermissionRequest = nil

        switch dialogResult {
        case .allowOnce:
            permissionHandler.addSessionOverride(
                toolName: toolName,
                decision: .approved
            )
            return .allow()
        case .alwaysAllow:
            _ = permissionHandler.addPersistentRule(
                toolName: toolName,
                pattern: "*",
                decision: .allow
            )
            return .allow()
        case .deny:
            return .deny("用户拒绝")
        }
    }

    func resolvePermission(_ result: PermissionDialogResult) {
        pendingPermissionRequest?.resolve(result)
    }
}
