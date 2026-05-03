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
    private var queuedMessages: [String] = []

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

    var hasEarlierEvents: Bool {
        trimmedEventCount > 0
    }

    @ObservationIgnored
    private var onResultCallbacks: [(String) -> Void] = []

    func addOnResultCallback(_ callback: @escaping (String) -> Void) {
        onResultCallbacks.append(callback)
    }

    func removeAllOnResultCallbacks() {
        onResultCallbacks.removeAll()
    }

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

            if total > pageSize {
                // Load the latest page, then backfill until the latest user prompt is included.
                var offset = max(0, total - pageSize)
                var latestWindow = try eventStore.fetchEvents(for: session.id, offset: offset, limit: pageSize)

                while offset > 0 && !latestWindow.contains(where: { $0.type == .userMessage }) {
                    let fetchLimit = min(pageSize, offset)
                    let nextOffset = offset - fetchLimit
                    let earlierPage = try eventStore.fetchEvents(
                        for: session.id,
                        offset: nextOffset,
                        limit: fetchLimit
                    )
                    latestWindow.insert(contentsOf: earlierPage, at: 0)
                    offset = nextOffset
                }

                events = latestWindow
                trimmedEventCount = offset
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

    func loadEarlierEvents() {
        guard let eventStore, let currentSession, trimmedEventCount > 0 else { return }

        let limit = min(pageSize, trimmedEventCount)
        let offset = trimmedEventCount - limit

        do {
            let earlierPage = try eventStore.fetchEvents(
                for: currentSession.id,
                offset: offset,
                limit: limit
            )
            trimmedEventCount = offset
            events.insert(contentsOf: earlierPage, at: 0)
            rebuildToolContentMap()
        } catch {
        }
    }

    // MARK: - Message Sending

    func sendMessage(_ text: String) {
        guard let agent, !text.isEmpty else { return }

        let userEvent = AgentEvent(
            type: .userMessage,
            content: text,
            timestamp: .now
        )
        appendAndPersist(userEvent)
        errorMessage = nil

        queuedMessages.append(text)

        guard !isRunning else { return }
        isRunning = true
        startNextQueuedMessage(using: agent)
    }

    private func startNextQueuedMessage(using agent: Agent) {
        guard !queuedMessages.isEmpty else {
            currentTask = nil
            isRunning = false
            return
        }

        let text = queuedMessages.removeFirst()
        currentTask = _Concurrency.Task { [weak self] in
            guard let self else { return }
            var receivedResult = false
            let sdkStream = agent.stream(text)
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
                    receivedResult = true
                    for callback in self.onResultCallbacks {
                        callback(event.content)
                    }
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
            self.currentTask = nil

            if self.queuedMessages.isEmpty {
                self.isRunning = false
            } else {
                self.startNextQueuedMessage(using: agent)
            }
        }
    }

    func cancelExecution() {
        queuedMessages.removeAll()
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
        queuedMessages = []
        currentTask?.cancel()
        currentTask = nil
        eventOrder = 0
        totalPersistedEvents = 0
        trimmedEventCount = 0
        onResultCallbacks.removeAll()
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
