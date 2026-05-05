import Foundation
import OpenAgentSDK
import Observation
import os

struct TimelinePaginationState: Equatable, Sendable {
    var sessionID: UUID?
    var pageSize: Int
    var totalPersistedEvents: Int
    var leadingTrimmedCount: Int
    var loadedEventCount: Int
    var isLoadingEarlierEvents: Bool
    var reloadID: UUID
    var prependRevision: Int

    var hasEarlierEvents: Bool {
        leadingTrimmedCount > 0
    }
}

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

    var timelinePaginationState = TimelinePaginationState(
        sessionID: nil,
        pageSize: 50,
        totalPersistedEvents: 0,
        leadingTrimmedCount: 0,
        loadedEventCount: 0,
        isLoadingEarlierEvents: false,
        reloadID: UUID(),
        prependRevision: 0
    )

    var hasMoreEvents: Bool {
        totalPersistedEvents > trimmedEventCount + events.count
    }

    var hasEarlierEvents: Bool {
        trimmedEventCount > 0
    }

    var isLoadingEarlierEvents: Bool {
        timelinePaginationState.isLoadingEarlierEvents
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

    @ObservationIgnored
    var permissionHandler: PermissionHandler

    @ObservationIgnored
    private var recentToolCalls: [(toolName: String, inputHash: String)] = []

    @ObservationIgnored
    private let maxRecentToolCalls = 20

    @ObservationIgnored
    private let doomLoopThreshold = 3

    @ObservationIgnored
    private var permissionContinuations: [UUID: CheckedContinuation<PermissionDialogResult, Never>] = [:]

    @ObservationIgnored
    private var doomLoopContinuations: [UUID: CheckedContinuation<DoomLoopAction, Never>] = [:]

    // MARK: - Skill System (Story 5-1)

    @ObservationIgnored
    private var skillRegistry: SkillRegistry?

    var discoveredSkills: [Skill] {
        skillRegistry?.allSkills.filter { $0.userInvocable } ?? []
    }

    init(permissionHandler: PermissionHandler = PermissionHandler()) {
        self.permissionHandler = permissionHandler
    }

    func configure(apiKey: String, baseURL: String?, model: String, workspacePath: String?, sessionId: String) {
        let registry = SkillRegistry()
        registry.register(BuiltInSkills.commit)
        registry.register(BuiltInSkills.review)
        registry.register(BuiltInSkills.simplify)
        registry.register(BuiltInSkills.debug)
        registry.register(BuiltInSkills.test)

        let discoveredCount = registry.registerDiscoveredSkills()
        self.skillRegistry = registry

        var tools = getAllBaseTools(tier: .core)
        if !registry.allSkills.isEmpty {
            tools.append(createSkillTool(registry: registry))
        }

        let options = AgentOptions(
            apiKey: apiKey,
            model: model,
            baseURL: baseURL,
            maxTurns: 10,
            permissionMode: .default,
            cwd: workspacePath,
            tools: tools,
            sessionStore: sdkSessionStore,
            sessionId: sessionId,
            skillRegistry: registry,
            skillDirectories: [],
            persistSession: true
        )

        let skillCount = registry.allSkills.count
        os_log("SwiftWork SkillRegistry: %d skills registered (%d discovered from filesystem)", log: .default, type: .info, skillCount, discoveredCount)

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
        updatePaginationState(sessionID: session.id, reloaded: true)

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
            markStalePermissionEvents()
            updatePaginationState()
        } catch {
            errorMessage = AppError(
                domain: .data,
                code: "LOAD_EVENTS_FAILED",
                message: error.localizedDescription,
                underlying: error
            ).message
            updatePaginationState()
        }
    }

    func loadInitialPage(for session: Session) {
        clearEvents()
        currentSession = session
        updatePaginationState(sessionID: session.id, reloaded: true)

        guard let eventStore else { return }

        do {
            totalPersistedEvents = try eventStore.totalEventCount(for: session.id)
            let limit = min(pageSize, totalPersistedEvents)
            let firstPage = try eventStore.fetchEvents(for: session.id, offset: 0, limit: limit)
            events = firstPage
            eventOrder = totalPersistedEvents
            rebuildToolContentMap()
            markStalePermissionEvents()
            updatePaginationState()
        } catch {
            errorMessage = AppError(
                domain: .data,
                code: "LOAD_EVENTS_FAILED",
                message: error.localizedDescription,
                underlying: error
            ).message
            updatePaginationState()
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
            updatePaginationState()
        } catch {
        }
    }

    func loadEarlierEvents() {
        guard let eventStore,
              let currentSession,
              trimmedEventCount > 0,
              !timelinePaginationState.isLoadingEarlierEvents
        else { return }

        let limit = min(pageSize, trimmedEventCount)
        let offset = trimmedEventCount - limit
        timelinePaginationState.isLoadingEarlierEvents = true
        updatePaginationState()

        do {
            let earlierPage = try eventStore.fetchEvents(
                for: currentSession.id,
                offset: offset,
                limit: limit
            )
            trimmedEventCount = offset
            events.insert(contentsOf: earlierPage, at: 0)
            rebuildToolContentMap()
            timelinePaginationState.isLoadingEarlierEvents = false
            timelinePaginationState.prependRevision += 1
            updatePaginationState()
        } catch {
            timelinePaginationState.isLoadingEarlierEvents = false
            errorMessage = AppError(
                domain: .data,
                code: "LOAD_EARLIER_EVENTS_FAILED",
                message: error.localizedDescription,
                underlying: error
            ).message
            updatePaginationState()
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
        permissionHandler.clearSessionOverrides()
        recentToolCalls.removeAll()
        timelinePaginationState = TimelinePaginationState(
            sessionID: currentSession?.id,
            pageSize: pageSize,
            totalPersistedEvents: 0,
            leadingTrimmedCount: 0,
            loadedEventCount: 0,
            isLoadingEarlierEvents: false,
            reloadID: UUID(),
            prependRevision: 0
        )
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
        updatePaginationState()
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

        updatePaginationState()
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
        let inputHash = Self.hashInput(input: input)
        trackToolCall(toolName: toolName, inputHash: inputHash)

        if checkDoomLoop(toolName: toolName, inputHash: inputHash) {
            let doomLoopResult = await presentDoomLoopWarning(
                toolName: toolName,
                callCount: countRecentCalls(toolName: toolName, inputHash: inputHash)
            )
            if doomLoopResult == .stop {
                return .deny("用户停止死循环")
            }
        }

        let dialogResult: PermissionDialogResult = await withCheckedContinuation { cont in
            let metadata: [String: any Sendable] = [
                "toolName": toolName as any Sendable,
                "parameters": parameters as any Sendable
            ]

            let permissionEvent = AgentEvent(
                type: .permissionRequest,
                content: description,
                metadata: metadata,
                timestamp: .now
            )
            permissionContinuations[permissionEvent.id] = cont
            appendAndPersist(permissionEvent)
        }

        switch dialogResult {
        case .allowOnce:
            permissionHandler.addSessionOverride(
                toolName: toolName,
                decision: .approved
            )
            return .allow()
        case .alwaysAllow:
            permissionHandler.addSessionOverride(
                toolName: toolName,
                decision: .approved
            )
            return .allow()
        case .deny:
            permissionHandler.addSessionOverride(
                toolName: toolName,
                decision: .denied(reason: "用户拒绝")
            )
            return .deny("用户拒绝")
        }
    }

    func resolvePermission(eventId: UUID, result: PermissionDialogResult) {
        guard let cont = permissionContinuations.removeValue(forKey: eventId) else { return }
        cont.resume(returning: result)
    }

    func resolveDoomLoop(eventId: UUID, action: DoomLoopAction) {
        guard let cont = doomLoopContinuations.removeValue(forKey: eventId) else { return }
        cont.resume(returning: action)
    }

    // MARK: - Stale Event Cleanup

    private func markStalePermissionEvents() {
        for index in events.indices {
            let event = events[index]
            guard event.type == .permissionRequest || event.type == .doomLoopWarning else { continue }
            guard event.metadata["resolved"] == nil else { continue }

            var staleMetadata = event.metadata
            staleMetadata["resolved"] = "expired"
            events[index] = AgentEvent(
                id: event.id,
                type: event.type,
                content: event.content,
                metadata: staleMetadata,
                timestamp: event.timestamp
            )
        }
    }

    // MARK: - Doom Loop Detection

    private static func hashInput(input: [String: Any]) -> String {
        let sortedKeys = input.keys.sorted()
        var parts: [String] = []
        for key in sortedKeys {
            parts.append("\(key)=\(String(describing: input[key]))")
        }
        return parts.joined(separator: "&")
    }

    private func trackToolCall(toolName: String, inputHash: String) {
        recentToolCalls.append((toolName: toolName, inputHash: inputHash))
        if recentToolCalls.count > maxRecentToolCalls {
            recentToolCalls.removeFirst(recentToolCalls.count - maxRecentToolCalls)
        }
    }

    private func checkDoomLoop(toolName: String, inputHash: String) -> Bool {
        countRecentCalls(toolName: toolName, inputHash: inputHash) >= doomLoopThreshold
    }

    private func countRecentCalls(toolName: String, inputHash: String) -> Int {
        recentToolCalls.filter { $0.toolName == toolName && $0.inputHash == inputHash }.count
    }

    @MainActor
    private func presentDoomLoopWarning(toolName: String, callCount: Int) async -> DoomLoopAction {
        await withCheckedContinuation { cont in
            let metadata: [String: any Sendable] = [
                "toolName": toolName as any Sendable,
                "callCount": callCount as any Sendable
            ]

            let doomEvent = AgentEvent(
                type: .doomLoopWarning,
                content: "Agent 使用相同输入重复调用 \(toolName) 已达 \(callCount) 次",
                metadata: metadata,
                timestamp: .now
            )
            doomLoopContinuations[doomEvent.id] = cont
            appendAndPersist(doomEvent)
        }
    }

    private func updatePaginationState(sessionID: UUID? = nil, reloaded: Bool = false) {
        timelinePaginationState.sessionID = sessionID ?? currentSession?.id
        timelinePaginationState.pageSize = pageSize
        timelinePaginationState.totalPersistedEvents = totalPersistedEvents
        timelinePaginationState.leadingTrimmedCount = trimmedEventCount
        timelinePaginationState.loadedEventCount = events.count
        if reloaded {
            timelinePaginationState.reloadID = UUID()
            timelinePaginationState.prependRevision = 0
        }
    }
}
