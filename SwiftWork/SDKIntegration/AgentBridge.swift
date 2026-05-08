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

struct ExplicitSlashSkillInvocation: Equatable, Sendable {
    let canonicalName: String
    let invokedName: String
    let args: String?
}

enum MessageSendOutcome: Equatable, Sendable {
    case ignored
    case sentPlainText
    case sentSlashSkill(ExplicitSlashSkillInvocation)
    case rejectedUnavailableSkill(ExplicitSlashSkillInvocation)
    case requiresWorkspaceBinding(ExplicitSlashSkillInvocation)
}

private struct QueuedMessageRequest {
    let userFacingText: String
    let payload: Payload

    enum Payload {
        case plainText(String)
        case explicitSlashSkill(ExplicitSlashSkillInvocation)
    }
}

private enum PreparedMessageRequest {
    case plainText(QueuedMessageRequest)
    case explicitSlashSkill(QueuedMessageRequest, ExplicitSlashSkillInvocation)
    case unavailableSkill(ExplicitSlashSkillInvocation)
    case workspaceRequired(ExplicitSlashSkillInvocation)
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
    private var queuedMessages: [QueuedMessageRequest] = []

    @ObservationIgnored
    private var eventStore: (any EventStoring)?

    @ObservationIgnored
    private var currentSession: Session?

    @ObservationIgnored
    private let sdkSessionStore = SessionStore()

    @ObservationIgnored
    private var eventOrder: Int = 0

    @ObservationIgnored
    private var configuredWorkspacePath: String?
    @ObservationIgnored
    private var configuredWorkspaceState: SessionWorkspaceState = .unbound
    @ObservationIgnored
    private let workspaceService = SessionWorkspaceService()
    private static var builtInSkillCatalog: [Skill] {
        [
            BuiltInSkills.commit,
            BuiltInSkills.review,
            BuiltInSkills.simplify,
            BuiltInSkills.debug,
            BuiltInSkills.test,
        ]
    }

    @ObservationIgnored
    private var slashSkillCatalog: [Skill] = AgentBridge.builtInSkillCatalog

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

    var discoveredSkills: [Skill] = []
    var discoveredSkillsRevision: Int = 0

    /// All registered skills, including non-user-invocable ones.
    /// Used by the Settings Skills panel to display every registered skill.
    var allRegisteredSkills: [Skill] {
        slashSkillCatalog
    }

    // MARK: - MCP Config System (Story 6-1)

    @ObservationIgnored
    var mcpConfigStore: MCPServerConfigStore?

    var activeWorkspaceRoot: String? {
        if case .ready(let binding) = configuredWorkspaceState {
            return binding.path
        }
        return nil
    }

    // MARK: - MCP Management (Story 6-3)

    /// Get runtime MCP server statuses from the running Agent.
    func mcpServerStatus() async -> [String: McpServerStatus] {
        guard let agent else { return [:] }
        return await agent.mcpServerStatus()
    }

    /// Enable or disable a specific MCP Server at runtime.
    /// Also updates SwiftData config for persistence.
    func toggleMcpServer(name: String, enabled: Bool) async throws {
        // Update SwiftData config
        if let store = mcpConfigStore {
            let configs = try store.list()
            if let config = configs.first(where: { $0.name == name }) {
                _ = try store.update(config, enabled: enabled)
            }
        }
        // Update SDK runtime
        guard let agent else { return }
        try await agent.toggleMcpServer(name: name, enabled: enabled)
    }

    /// Reconnect a specific MCP Server.
    func reconnectMcpServer(name: String) async throws {
        guard let agent else { return }
        try await agent.reconnectMcpServer(name: name)
    }

    /// Hot-update MCP servers on the running Agent after an edit.
    /// Called by EditMCPServerSheet after saving config changes.
    func updateMCPServers() {
        guard isRunning else { return }
        let configs = (try? mcpConfigStore?.enabledConfigsForWorkspace(activeWorkspaceRoot)) ?? []
        let mcpServers = mcpConfigStore?.toSDKConfigs(configs) ?? [:]
        _Concurrency.Task { [weak self] in
            guard let self, let agent = self.agent else { return }
            do {
                let result = try await agent.setMcpServers(mcpServers)
                os_log("SwiftWork MCP: hot-update result — added: %{public}@, removed: %{public}@, errors: %{public}@",
                       log: .default, type: .info,
                       result.added.description, result.removed.description, result.errors.description)
            } catch {
                os_log("SwiftWork MCP: hot-update failed: %{public}s", log: .default, type: .error, error.localizedDescription)
            }
        }
    }

    init(permissionHandler: PermissionHandler = PermissionHandler()) {
        self.permissionHandler = permissionHandler
    }

    func configure(
        apiKey: String,
        baseURL: String?,
        model: String,
        workspacePath: String?,
        sessionId: String,
        workspaceState: SessionWorkspaceState? = nil
    ) {
        let resolvedWorkspaceState = workspaceState ?? inferredWorkspaceState(from: workspacePath)
        configuredWorkspaceState = resolvedWorkspaceState
        configuredWorkspacePath = resolvedWorkspaceState.workspacePath

        let fullRegistry = SkillRegistry()
        runtimeAwareBuiltInSkills(for: activeWorkspaceRoot).forEach(fullRegistry.register)

        let skillDirectories = workspaceService.skillSearchDirectories(for: resolvedWorkspaceState)
        let discoveredCount = fullRegistry.registerDiscoveredSkills(from: skillDirectories)
        slashSkillCatalog = fullRegistry.allSkills

        let registry = SkillRegistry()
        for skill in slashSkillCatalog where skillAvailableInCurrentWorkspace(skill) {
            registry.register(skill)
        }

        self.skillRegistry = registry
        refreshDiscoveredSkills()

        var tools = configuredTools(for: resolvedWorkspaceState)
        if !registry.allSkills.isEmpty {
            tools.append(createSkillTool(registry: registry))
        }

        // MCP config (Story 6-1)
        let mcpConfigs = (try? mcpConfigStore?.enabledConfigsForWorkspace(activeWorkspaceRoot)) ?? []
        let mcpServers = mcpConfigStore?.toSDKConfigs(mcpConfigs)

        let options = AgentOptions(
            apiKey: apiKey,
            model: model,
            baseURL: baseURL,
            systemPrompt: workspaceSystemPrompt(for: resolvedWorkspaceState),
            maxTurns: 10,
            permissionMode: .default,
            cwd: workspaceService.agentWorkingDirectory(for: resolvedWorkspaceState),
            tools: tools,
            mcpServers: (mcpServers?.isEmpty ?? true) ? nil : mcpServers,
            sessionStore: sdkSessionStore,
            sessionId: sessionId,
            skillRegistry: registry,
            skillDirectories: skillDirectories,
            projectRoot: activeWorkspaceRoot,
            persistSession: true
        )

        let skillCount = registry.allSkills.count
        os_log("SwiftWork SkillRegistry: %d skills registered (%d discovered from filesystem)", log: .default, type: .info, skillCount, discoveredCount)
        os_log("SwiftWork MCP: %d configs loaded", log: .default, type: .info, mcpConfigs.count)

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

    @discardableResult
    func sendMessage(_ text: String) -> MessageSendOutcome {
        guard let agent, !text.isEmpty else { return .ignored }

        switch prepareMessageRequest(for: text) {
        case .workspaceRequired(let invocation):
            errorMessage = "Skill /\(invocation.canonicalName) 需要先绑定工作目录。"
            return .requiresWorkspaceBinding(invocation)
        case .unavailableSkill(let invocation):
            errorMessage = "Skill /\(invocation.canonicalName) 当前不可用，未发送消息。"
            return .rejectedUnavailableSkill(invocation)
        case .plainText(let request):
            enqueue(request, using: agent)
            return .sentPlainText
        case .explicitSlashSkill(let request, let invocation):
            enqueue(request, using: agent)
            return .sentSlashSkill(invocation)
        }
    }

    func resolveExplicitSlashSkillInvocation(in text: String) -> ExplicitSlashSkillInvocation? {
        if case .explicitSlashSkill(_, let invocation) = prepareMessageRequest(for: text) {
            return invocation
        }
        return nil
    }

    func registerSkill(_ skill: Skill) {
        if skillRegistry == nil {
            skillRegistry = SkillRegistry()
        }
        slashSkillCatalog.append(skill)
        if skillAvailableInCurrentWorkspace(skill) {
            skillRegistry?.register(skill)
        }
        refreshDiscoveredSkills()
    }

    func refreshDiscoveredSkillsSnapshot() {
        refreshDiscoveredSkills()
    }

    private func enqueue(_ request: QueuedMessageRequest, using agent: Agent) {
        let userEvent = AgentEvent(
            type: .userMessage,
            content: request.userFacingText,
            timestamp: .now
        )
        appendAndPersist(userEvent)
        errorMessage = nil

        queuedMessages.append(request)

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

        let request = queuedMessages.removeFirst()
        currentTask = _Concurrency.Task { [weak self] in
            guard let self else { return }
            var receivedResult = false
            let outboundText: String
            switch request.payload {
            case .plainText(let text):
                outboundText = text
            case .explicitSlashSkill(let invocation):
                guard let resolved = await self.resolveExplicitSlashSkillRequest(invocation) else {
                    self.currentTask = nil
                    if self.queuedMessages.isEmpty {
                        self.isRunning = false
                    } else {
                        self.startNextQueuedMessage(using: agent)
                    }
                    return
                }
                outboundText = resolved
            }
            let sdkStream = agent.stream(outboundText)
            for await message in sdkStream {
                guard !_Concurrency.Task.isCancelled else { break }
                receivedResult = self.handleStreamMessage(message) || receivedResult
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

    private func prepareMessageRequest(for text: String) -> PreparedMessageRequest {
        if let resolution = resolveSlashSkillRequest(in: text) {
            switch resolution {
            case .available(let invocation):
                return .explicitSlashSkill(
                    QueuedMessageRequest(
                        userFacingText: text,
                        payload: .explicitSlashSkill(invocation)
                    ),
                    invocation
                )
            case .unavailable(let invocation):
                return .unavailableSkill(invocation)
            case .workspaceRequired(let invocation):
                return .workspaceRequired(invocation)
            }
        }

        return .plainText(
            QueuedMessageRequest(userFacingText: text, payload: .plainText(text))
        )
    }

    private enum SlashSkillResolution {
        case available(ExplicitSlashSkillInvocation)
        case unavailable(ExplicitSlashSkillInvocation)
        case workspaceRequired(ExplicitSlashSkillInvocation)
    }

    private func resolveSlashSkillRequest(in text: String) -> SlashSkillResolution? {
        refreshDiscoveredSkills()

        guard let parsedInvocation = parseSlashCommand(in: text),
              let skill = resolveCatalogSkill(named: parsedInvocation.invokedName) else {
            return nil
        }

        let invocation = ExplicitSlashSkillInvocation(
            canonicalName: skill.name,
            invokedName: parsedInvocation.invokedName,
            args: parsedInvocation.args
        )

        guard skillAvailableInCurrentWorkspace(skill) else {
            return .workspaceRequired(invocation)
        }

        guard isSkillAvailableInCurrentWorkspace(skill) else {
            return .unavailable(invocation)
        }
        return .available(invocation)
    }

    private func parseSlashCommand(in text: String) -> (invokedName: String, args: String?)? {
        let trimmedLeading = String(text.drop(while: { $0.isWhitespace }))
        guard trimmedLeading.hasPrefix("/") else { return nil }

        let commandLine = String(trimmedLeading.dropFirst())
        guard !commandLine.isEmpty else { return nil }

        if let whitespaceIndex = commandLine.firstIndex(where: { $0.isWhitespace }) {
            let invokedName = String(commandLine[..<whitespaceIndex])
            guard !invokedName.isEmpty else { return nil }
            let remaining = String(commandLine[whitespaceIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
            return (invokedName, remaining.isEmpty ? nil : remaining)
        }

        return (commandLine, nil)
    }

    private func resolveUserInvocableSkill(named invokedName: String) -> Skill? {
        resolveSkill(named: invokedName, in: skillRegistry?.allSkills ?? [])
    }

    private func resolveCatalogSkill(named invokedName: String) -> Skill? {
        resolveSkill(named: invokedName, in: slashSkillCatalog)
    }

    private func resolveSkill(named invokedName: String, in skills: [Skill]) -> Skill? {
        let normalized = invokedName.lowercased()
        return skills.first(where: { skill in
            guard skill.userInvocable else { return false }
            if skill.name.lowercased() == normalized {
                return true
            }
            return skill.aliases.contains(where: { $0.lowercased() == normalized })
        })
    }

    private func resolveExplicitSlashSkillRequest(_ invocation: ExplicitSlashSkillInvocation) async -> String? {
        guard let registry = skillRegistry else { return nil }

        let inputPayload: [String: String] = [
            "skill": invocation.canonicalName,
            "args": invocation.args ?? ""
        ]
        let inputText = serializeJSON(inputPayload)
        let toolUseId = UUID().uuidString

        appendAndPersist(AgentEvent(
            type: .toolUse,
            content: "Skill",
            metadata: [
                "toolName": "Skill",
                "toolUseId": toolUseId,
                "input": inputText
            ],
            timestamp: .now
        ))

        let tool = createSkillTool(registry: registry)
        let context = ToolContext(
            cwd: workspaceService.agentWorkingDirectory(for: configuredWorkspaceState),
            toolUseId: toolUseId,
            skillRegistry: registry,
            restrictionStack: ToolRestrictionStack()
        )
        let result = await tool.call(input: inputPayload, context: context)

        appendAndPersist(AgentEvent(
            type: .toolResult,
            content: result.content,
            metadata: [
                "toolUseId": toolUseId,
                "isError": result.isError
            ],
            timestamp: .now
        ))

        guard !result.isError,
              let resolved = parseResolvedSkillResult(result.content, invocation: invocation) else {
            errorMessage = "Skill /\(invocation.canonicalName) 执行准备失败，未发送消息。"
            return nil
        }

        errorMessage = nil
        return resolved
    }

    private func parseResolvedSkillResult(
        _ content: String,
        invocation: ExplicitSlashSkillInvocation
    ) -> String? {
        guard let data = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let prompt = json["prompt"] as? String else {
            return nil
        }

        let metadata: [String: Any] = [
            "canonicalName": invocation.canonicalName,
            "invokedName": invocation.invokedName,
            "args": invocation.args ?? "",
            "allowedTools": json["allowedTools"] as? [String] ?? [],
            "model": json["model"] as? String ?? "",
            "baseDir": json["baseDir"] as? String ?? "",
            "supportingFiles": json["supportingFiles"] as? [String] ?? []
        ]
        let payload: [String: Any] = [
            "slashSkill": metadata,
            "skillPrompt": prompt
        ]

        return """
        The user explicitly selected a slash skill. The skill resolution step has already completed, so do not decide whether to use a skill for this request.

        Resolved slash skill payload:
        ```json
        \(serializeJSON(payload))
        ```

        Follow the `skillPrompt` field as the authoritative instructions for this turn, using the resolved `slashSkill.args` exactly as provided.
        """
    }

    private func serializeJSON(_ object: Any) -> String {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }

    private func refreshDiscoveredSkills() {
        let refreshed = (skillRegistry?.allSkills ?? []).filter { skill in
            skill.userInvocable && isSkillAvailableInCurrentWorkspace(skill)
        }
        let currentNames = discoveredSkills.map(\.name)
        let refreshedNames = refreshed.map(\.name)
        discoveredSkills = refreshed
        if currentNames != refreshedNames {
            discoveredSkillsRevision += 1
        }
    }

    private func inferredWorkspaceState(from workspacePath: String?) -> SessionWorkspaceState {
        workspaceService.resolveState(workspacePath: workspacePath, bookmarkData: nil)
    }

    private func configuredTools(for state: SessionWorkspaceState) -> [ToolProtocol] {
        let baseTools = getAllBaseTools(tier: .core)
        guard state.requiresBinding else { return baseTools }

        let allowedNames: Set<String> = ["AskUser", "ToolSearch", "WebFetch", "WebSearch"]
        return baseTools.filter { allowedNames.contains($0.name) }
    }

    private func skillAvailableInCurrentWorkspace(_ skill: Skill) -> Bool {
        switch configuredWorkspaceState {
        case .ready:
            true
        case .unbound, .needsRepair:
            !skillRequiresWorkspace(skill)
        }
    }

    private func isSkillAvailableInCurrentWorkspace(_ skill: Skill) -> Bool {
        return skill.isAvailable()
    }

    private func runtimeAwareBuiltInSkills(for workspaceRoot: String?) -> [Skill] {
        Self.builtInSkillCatalog.map { skill in
            guard skill.name == "test" else { return skill }

            // When a workspace root is explicitly bound, use it as the sole authority
            // for test-skill availability — do not fall back to the process CWD.
            // The CWD-based fallback is reserved for unbound sessions where the
            // xcodebuild test runner sets CWD to "/" and discovery relies on
            // DerivedData heuristics instead.
            let hasExplicitWorkspace = (workspaceRoot != nil && !workspaceRoot!.isEmpty)
            let originalCheck = skill.isAvailable
            return Skill(
                name: skill.name,
                description: skill.description,
                aliases: skill.aliases,
                userInvocable: skill.userInvocable,
                toolRestrictions: skill.toolRestrictions,
                modelOverride: skill.modelOverride,
                isAvailable: {
                    if hasExplicitWorkspace {
                        AgentBridge.workspaceHasTestFrameworkIndicators(in: workspaceRoot)
                    } else {
                        originalCheck()
                    }
                },
                promptTemplate: skill.promptTemplate,
                whenToUse: skill.whenToUse,
                argumentHint: skill.argumentHint,
                baseDir: skill.baseDir,
                supportingFiles: skill.supportingFiles
            )
        }
    }

    private func workspaceHasTestFrameworkIndicators() -> Bool {
        Self.workspaceHasTestFrameworkIndicators(in: activeWorkspaceRoot)
    }

    nonisolated private static func workspaceHasTestFrameworkIndicators(in workspaceRoot: String?) -> Bool {
        let fileManager = FileManager.default
        let testIndicators = [
            "Package.swift",     // Swift PM
            "pytest.ini",        // Python pytest
            "jest.config",       // JavaScript Jest
            "vitest.config",     // JavaScript Vitest
            "Cargo.toml",        // Rust cargo test
            "go.mod",            // Go test
        ]

        // Check the workspace root first
        if let workspaceRoot, !workspaceRoot.isEmpty {
            for indicator in testIndicators {
                if fileManager.fileExists(atPath: workspaceRoot + "/" + indicator) {
                    return true
                }
            }
        }

        // Fallback: when the workspace root is "/" (the xcodebuild test runner default),
        // the workspace itself has no project context. In this case, attempt to discover
        // the project directory via DerivedData info.plist or other heuristics.
        // Only apply this fallback when the workspace root is the filesystem root,
        // so that intentionally-empty temp workspaces still correctly report no indicators.
        if workspaceRoot == "/" || (workspaceRoot == nil && fileManager.currentDirectoryPath == "/") {
            // Try DerivedData info.plist first
            if let derivedProjectDir = Self.findProjectDirFromDerivedData() {
                for indicator in testIndicators {
                    if fileManager.fileExists(atPath: derivedProjectDir + "/" + indicator) {
                        return true
                    }
                }
            }
        }

        return false
    }

    /// Attempts to find the source project directory by walking up from the main bundle
    /// and looking for a DerivedData info.plist that contains the WorkspacePath.
    nonisolated private static func findProjectDirFromDerivedData() -> String? {
        let fileManager = FileManager.default
        var path = Bundle.main.bundleURL.deletingLastPathComponent().path

        for _ in 0..<10 {
            let infoPlistPath = path + "/info.plist"
            if fileManager.fileExists(atPath: infoPlistPath),
               let data = try? Data(contentsOf: URL(fileURLWithPath: infoPlistPath)),
               let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
               let workspacePath = plist["WorkspacePath"] as? String {
                // WorkspacePath is like /path/to/Project.xcodeproj
                let projectDir = (workspacePath as NSString).deletingLastPathComponent
                if fileManager.fileExists(atPath: projectDir) {
                    return projectDir
                }
            }
            let parent = (path as NSString).deletingLastPathComponent
            if parent == path { break }
            path = parent
        }
        return nil
    }

    private func skillRequiresWorkspace(_ skill: Skill) -> Bool {
        let workspaceToolNames: Set<String> = ["bash", "read", "write", "edit", "glob", "grep"]
        if let restrictions = skill.toolRestrictions, !restrictions.isEmpty {
            let names = Set(restrictions.map { $0.rawValue.lowercased() })
            return !names.isDisjoint(with: workspaceToolNames)
        }

        return SkillSource.from(skill, workspaceRoot: activeWorkspaceRoot) == .project
    }

    private func workspaceSystemPrompt(for state: SessionWorkspaceState) -> String? {
        switch state {
        case .ready(let binding):
            "Session workspace root: \(binding.path). All filesystem and project operations must stay within this directory."
        case .unbound:
            "This session has no bound workspace. Do not attempt filesystem, terminal, or project-scope skill work until the user binds a workspace."
        case .needsRepair(let path):
            "The previous workspace at \(path) is unavailable. Do not attempt filesystem, terminal, or project-scope skill work until the user repairs the workspace binding."
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

    @discardableResult
    func handleStreamMessage(_ message: SDKMessage) -> Bool {
        if case .userMessage = message {
            return false
        }

        let event = EventMapper.map(message)

        if event.type == .partialMessage {
            streamingText += event.content
            return false
        }

        if event.type == .assistant {
            streamingText = ""
        }

        if event.type == .result {
            for callback in onResultCallbacks {
                callback(event.content)
            }
        }

        appendAndPersist(event)
        return event.type == .result
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
