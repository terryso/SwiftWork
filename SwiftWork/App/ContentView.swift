import SwiftUI
import SwiftData
import AppKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var agentBridge = AgentBridge()
    @State private var eventStore: (any EventStoring)?
    @State private var hasCompletedOnboarding: Bool? = nil
    @State private var appStateManager = AppStateManager()
    @State private var mainWindow: NSWindow?
    @State private var notificationObservers: [NSObjectProtocol] = []

    var body: some View {
        Group {
            if let completed = hasCompletedOnboarding {
                if completed {
                    NavigationSplitView {
                        SidebarView(sessionViewModel: appState.sessionViewModel)
                            .toolbar {
                                ToolbarItem(placement: .automatic) {
                                    Button {
                                        appState.isSettingsPresented = true
                                    } label: {
                                        Image(systemName: "gearshape")
                                    }
                                    .help("设置")
                                }
                            }
                    } detail: {
                        if let session = appState.sessionViewModel.selectedSession {
                            WorkspaceView(
                                agentBridge: agentBridge,
                                eventStore: eventStore,
                                session: session,
                                settingsViewModel: appState.settingsViewModel,
                                sessionViewModel: appState.sessionViewModel,
                                isInspectorVisible: Binding(
                                    get: { appState.isInspectorVisible },
                                    set: { appState.isInspectorVisible = $0 }
                                ),
                                isDebugPanelVisible: Binding(
                                    get: { appState.isDebugPanelVisible },
                                    set: { appState.isDebugPanelVisible = $0 }
                                )
                            )
                        } else {
                            Text("选择或创建一个会话")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    WelcomeView(viewModel: appState.settingsViewModel) {
                        withAnimation {
                            hasCompletedOnboarding = true
                        }
                    }
                }
            }
        }
        .background(
            WindowAccessor { window in
                mainWindow = window
            }
        )
        .sheet(isPresented: Binding(
            get: { appState.isSettingsPresented },
            set: { appState.isSettingsPresented = $0 }
        )) {
            SettingsView(settingsViewModel: appState.settingsViewModel, permissionHandler: agentBridge.permissionHandler)
                .frame(minWidth: 520, minHeight: 450)
        }
        .task {
            appState.settingsViewModel.configure(modelContext: modelContext)
            hasCompletedOnboarding = appState.settingsViewModel.isAPIKeyConfigured
                && !appState.settingsViewModel.isFirstLaunch

            if hasCompletedOnboarding == true {
                configureAndRestoreState()
            }

            // Listen for app termination to save final state snapshot
            listenForAppLifecycle()
        }
        .onChange(of: hasCompletedOnboarding) { _, newValue in
            if newValue == true {
                configureAndRestoreState()
            }
        }
        .onChange(of: mainWindow) { _, newWindow in
            // Window reference arrives asynchronously; restore frame once available
            if let newWindow {
                restoreWindowFrame(in: newWindow)
            }
        }
        .onChange(of: appState.isInspectorVisible) { _, newValue in
            appStateManager.saveInspectorVisibility(newValue)
        }
        .onChange(of: appState.isDebugPanelVisible) { _, newValue in
            appStateManager.saveDebugPanelVisibility(newValue)
        }
        .onDisappear {
            for observer in notificationObservers {
                NotificationCenter.default.removeObserver(observer)
            }
            notificationObservers.removeAll()
        }
    }

    // MARK: - State Restore Helpers

    private func configureAndRestoreState() {
        appStateManager.configure(modelContext: modelContext)
        appStateManager.loadAppState()

        appState.sessionViewModel.setAppStateManager(appStateManager)
        appState.sessionViewModel.configure(modelContext: modelContext)
        eventStore = SwiftDataEventStore(modelContext: modelContext)

        agentBridge.permissionHandler.setModelContext(modelContext)

        // Restore selected session
        restoreSelectedSession()

        // Restore Inspector visibility
        appState.isInspectorVisible = appStateManager.isInspectorVisible

        // Restore Debug Panel visibility
        appState.isDebugPanelVisible = appStateManager.isDebugPanelVisible

        // Restore window frame if window reference is already available
        if let window = mainWindow {
            restoreWindowFrame(in: window)
        }
    }

    private func restoreSelectedSession() {
        if let restoredID = appStateManager.lastActiveSessionID {
            let matching = appState.sessionViewModel.sessions.first { $0.id == restoredID }
            if let match = matching {
                appState.sessionViewModel.selectSession(match)
            } else {
                // Fallback: select first (most recent) session
                if let first = appState.sessionViewModel.sessions.first {
                    appState.sessionViewModel.selectSession(first)
                }
            }
        }
    }

    private func restoreWindowFrame(in window: NSWindow) {
        guard let frame = appStateManager.windowFrame else { return }
        window.setFrame(frame, display: true)
    }

    private func listenForAppLifecycle() {
        // Save state on app termination
        let terminateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                if let window = mainWindow {
                    appStateManager.saveWindowFrame(window.frame)
                }
            }
        }
        notificationObservers.append(terminateObserver)

        // Throttled window state saving on move/resize
        var saveTask: Task<Void, Never>?
        let saveWindowFrameThrottled: (Notification) -> Void = { _ in
            saveTask?.cancel()
            saveTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                if let window = mainWindow {
                    appStateManager.saveWindowFrame(window.frame)
                }
            }
        }

        let moveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: nil,
            queue: .main,
            using: saveWindowFrameThrottled
        )
        notificationObservers.append(moveObserver)

        let resizeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: nil,
            queue: .main,
            using: saveWindowFrameThrottled
        )
        notificationObservers.append(resizeObserver)
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .modelContainer(for: AppConfiguration.self, inMemory: true)
}
