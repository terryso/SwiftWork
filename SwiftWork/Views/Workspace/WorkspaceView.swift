import SwiftUI

struct WorkspaceView: View {
    let agentBridge: AgentBridge
    let eventStore: (any EventStoring)?
    let session: Session
    let settingsViewModel: SettingsViewModel
    let sessionViewModel: SessionViewModel

    var body: some View {
        @Bindable var bridge = agentBridge
        VStack(spacing: 0) {
            TimelineView(agentBridge: agentBridge)
                .frame(maxHeight: .infinity)

            Divider()

            InputBarView(agentBridge: agentBridge)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .sheet(item: $bridge.pendingPermissionRequest, onDismiss: {
            agentBridge.resolvePermission(.deny)
        }) { request in
            PermissionDialogView(request: request) { result in
                agentBridge.resolvePermission(result)
            }
        }
        .task {
            configureAgent()
            loadPersistedEvents()
            setupTitleGeneration()
        }
        .onChange(of: session.id) { _, _ in
            agentBridge.clearEvents()
            configureAgent()
            loadPersistedEvents()
            setupTitleGeneration()
        }
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
    }

    private func setupTitleGeneration() {
        let keychainManager = KeychainManager()
        let apiKey = (try? keychainManager.getAPIKey()) ?? ""
        let model = settingsViewModel.selectedModel
        let baseURL = settingsViewModel.baseURL.isEmpty ? nil : settingsViewModel.baseURL

        agentBridge.onResult = { [weak session] _ in
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
