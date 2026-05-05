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

    var body: some View {
        HStack(spacing: 0) {
            // Main content area
            VStack(spacing: 0) {
                TimelineView(
                    agentBridge: agentBridge,
                    reloadToken: timelineReloadToken,
                    selectedEventId: $selectedEventId
                )
                .frame(maxHeight: .infinity)

                Divider()

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
            configureAgent()
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
        .onChange(of: session.id) { _, _ in
            agentBridge.clearEvents()
            selectedEventId = nil
            eventLookup.removeAll()
            configureAgent()
            loadPersistedEvents()
            setupTitleGeneration()
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
            .background(Color.orange.opacity(0.08))
        }
        .buttonStyle(.plain)
    }

    private var selectedEvent: AgentEvent? {
        guard let id = selectedEventId else { return nil }
        return eventLookup[id]
    }

    private func configureAgent() {
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
            sessionId: session.id.uuidString
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
}
