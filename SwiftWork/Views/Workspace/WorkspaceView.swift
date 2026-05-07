import AppKit
import SwiftUI

struct WorkspaceView: View {
    let agentBridge: AgentBridge
    let eventStore: (any EventStoring)?
    let session: Session
    let settingsViewModel: SettingsViewModel
    let sessionViewModel: SessionViewModel
    @Binding var isInspectorVisible: Bool
    @Binding var isDebugPanelVisible: Bool

    var onOpenSettings: (() -> Void)?

    @State private var selectedEventId: UUID?
    @State private var eventLookup: [UUID: AgentEvent] = [:]
    @State private var debugViewModel: DebugViewModel?
    @State private var timelineReloadToken = UUID()
    @State private var workspaceState: SessionWorkspaceState = .unbound
    @State private var mcpStatusViewModel: MCPStatusViewModel?

    var body: some View {
        HStack(spacing: 0) {
            // Main content area
            VStack(spacing: 0) {
                workspaceStatusBanner
                TimelineView(
                    agentBridge: agentBridge,
                    reloadToken: timelineReloadToken,
                    selectedEventId: $selectedEventId
                )
                .frame(maxHeight: .infinity)

                Divider()

                if let mcpStatusViewModel {
                    WorkspaceStatusBar(viewModel: mcpStatusViewModel)
                    Divider()
                }

                InputBarView(agentBridge: agentBridge)

                if agentBridge.permissionHandler.globalMode == .autoApprove {
                    autoApproveWarningBar
                }
            }
            .background(Color(nsColor: .textBackgroundColor))

            // Inspector panel
            if isInspectorVisible {
                HStack(spacing: 0) {
                    Divider()
                    InspectorView(
                        selectedEvent: selectedEvent,
                        toolContentMap: agentBridge.toolContentMap
                    )
                    .frame(width: 300)
                    .background(Color(nsColor: .controlBackgroundColor))
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            // Debug panel
            if isDebugPanelVisible {
                if let debugViewModel {
                    HStack(spacing: 0) {
                        Divider()
                        DebugView(debugViewModel: debugViewModel)
                            .frame(width: 320)
                            .background(Color(nsColor: .controlBackgroundColor))
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isInspectorVisible.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.right")
                        .foregroundStyle(isInspectorVisible ? Color.accentColor : .secondary)
                }
                .help(isInspectorVisible ? "隐藏 Inspector" : "显示 Inspector")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isDebugPanelVisible.toggle()
                    }
                } label: {
                    Image(systemName: "ladybug")
                        .foregroundStyle(isDebugPanelVisible ? Color.accentColor : .secondary)
                }
                .help(isDebugPanelVisible ? "隐藏 Debug Panel" : "显示 Debug Panel")
            }
        }
        .task {
            debugViewModel = DebugViewModel(agentBridge: agentBridge)
            setupMCPStatusViewModel()
            refreshWorkspaceContext()
            loadPersistedEvents()
            setupTitleGeneration()
        }
        .onChange(of: agentBridge.events.count) { oldCount, newCount in
            if newCount == 0 {
                eventLookup.removeAll()
            } else if newCount > oldCount {
                for i in oldCount..<newCount {
                    let event = agentBridge.events[i]
                    eventLookup[event.id] = event
                }
            } else {
                eventLookup = Dictionary(uniqueKeysWithValues: agentBridge.events.map { ($0.id, $0) })
            }
        }
        .onChange(of: agentBridge.isRunning) { _, isRunning in
            Task {
                await mcpStatusViewModel?.onAgentRunningChanged(isRunning: isRunning)
            }
        }
        .onChange(of: session.id) { _, _ in
            sessionViewModel.deactivateActiveWorkspace()
            agentBridge.clearEvents()
            selectedEventId = nil
            eventLookup.removeAll()
            refreshWorkspaceContext()
            loadPersistedEvents()
            setupTitleGeneration()
            setupMCPStatusViewModel()
        }
        .onChange(of: session.workspacePath) { _, _ in
            refreshWorkspaceContext()
        }
        .onChange(of: session.workspaceBookmark) { _, _ in
            refreshWorkspaceContext()
        }
        .onDisappear {
            mcpStatusViewModel?.stopPeriodicRefresh()
            sessionViewModel.deactivateActiveWorkspace()
        }
    }

    @ViewBuilder
    private var workspaceStatusBanner: some View {
        switch workspaceState {
        case .ready:
            EmptyView()
        case .unbound:
            workspaceBanner(
                icon: "folder.badge.questionmark",
                title: "此会话尚未绑定工作目录",
                detail: "你仍可继续普通对话；文件、终端和项目级 Skill 需要先绑定目录。"
            )
        case .needsRepair(let path):
            workspaceBanner(
                icon: "exclamationmark.triangle.fill",
                title: "工作目录不可用",
                detail: "无法访问 \(path)。请重新选择目录后再使用文件、终端和项目级 Skill。"
            )
        }
    }

    private var autoApproveWarningBar: some View {
        Button {
            onOpenSettings?()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                Text("自动批准已开启 — 所有工具调用无需确认")
                    .font(.system(size: 11))
            }
            .foregroundStyle(.orange)
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private var selectedEvent: AgentEvent? {
        guard let id = selectedEventId else { return nil }
        return eventLookup[id]
    }

    private func refreshWorkspaceContext() {
        workspaceState = sessionViewModel.activateWorkspace(for: session)
        configureAgent(for: workspaceState)
    }

    private func configureAgent(for state: SessionWorkspaceState) {
        let keychainManager = KeychainManager()
        let apiKey: String
        do {
            apiKey = try keychainManager.getAPIKey() ?? ""
        } catch {
            apiKey = ""
        }

        let model = settingsViewModel.selectedModel
        let baseURL = settingsViewModel.baseURL.isEmpty ? nil : settingsViewModel.baseURL

        agentBridge.configure(
            apiKey: apiKey,
            baseURL: baseURL,
            model: model,
            workspacePath: session.workspacePath,
            sessionId: session.id.uuidString,
            workspaceState: state
        )
    }

    private func loadPersistedEvents() {
        guard let eventStore else { return }
        agentBridge.configureEvents(store: eventStore, session: session)
        agentBridge.loadEvents(for: session)
        timelineReloadToken = UUID()
    }

    private func setupTitleGeneration() {
        let keychainManager = KeychainManager()
        let apiKey = (try? keychainManager.getAPIKey()) ?? ""
        let model = settingsViewModel.selectedModel
        let baseURL = settingsViewModel.baseURL.isEmpty ? nil : settingsViewModel.baseURL

        agentBridge.addOnResultCallback { [weak session] _ in
            guard let session, session.title == "新会话" else { return }
            let events = agentBridge.events
            Task {
                if let title = await TitleGenerator.generate(
                    events: events,
                    apiKey: apiKey,
                    baseURL: baseURL,
                    model: model
                ) {
                    sessionViewModel.updateSessionTitle(session, title: title)
                }
            }
        }
    }

    private func workspaceBanner(icon: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                if sessionViewModel.mostRecentWorkspaceBinding(excluding: session) != nil {
                    Button("使用最近目录") {
                        if sessionViewModel.useMostRecentWorkspace(for: session) {
                            refreshWorkspaceContext()
                        }
                    }
                }

                Button("选择文件夹") {
                    chooseWorkspace()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func chooseWorkspace() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "绑定"
        panel.message = "选择此会话的工作目录"

        if panel.runModal() == .OK, let url = panel.url,
           sessionViewModel.updateWorkspace(session, to: url) {
            refreshWorkspaceContext()
        }
    }

    private func setupMCPStatusViewModel() {
        mcpStatusViewModel?.stopPeriodicRefresh()
        guard let store = agentBridge.mcpConfigStore else { return }
        let vm = MCPStatusViewModel(store: store, agentBridge: agentBridge)
        mcpStatusViewModel = vm
        Task {
            await vm.loadConfiguredServers()
            await vm.refreshStatus()
        }
        vm.startPeriodicRefresh()
    }
}
