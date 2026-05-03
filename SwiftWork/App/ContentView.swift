import SwiftUI
import SwiftData
import AppKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var settingsViewModel = SettingsViewModel()
    @State private var sessionViewModel = SessionViewModel()
    @State private var agentBridge = AgentBridge()
    @State private var eventStore: (any EventStoring)?
    @State private var hasCompletedOnboarding: Bool? = nil
    @State private var appStateManager = AppStateManager()
    @State private var isInspectorVisible: Bool = false
    @State private var isSettingsPresented: Bool = false
    @State private var mainWindow: NSWindow?
    @State private var notificationObservers: [NSObjectProtocol] = []

    var body: some View {
        Group {
            if let completed = hasCompletedOnboarding {
                if completed {
                    NavigationSplitView {
                        SidebarView(sessionViewModel: sessionViewModel)
                            .toolbar {
                                ToolbarItem(placement: .automatic) {
                                    Button {
                                        isSettingsPresented = true
                                    } label: {
                                        Image(systemName: "gearshape")
                                    }
                                    .help("设置")
                                }
                            }
                    } detail: {
                        if let session = sessionViewModel.selectedSession {
                            WorkspaceView(
                                agentBridge: agentBridge,
                                eventStore: eventStore,
                                session: session,
                                settingsViewModel: settingsViewModel,
                                sessionViewModel: sessionViewModel,
                                isInspectorVisible: $isInspectorVisible
                            )
                        } else {
                            Text("选择或创建一个会话")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    WelcomeView(viewModel: settingsViewModel) {
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
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(permissionHandler: agentBridge.permissionHandler)
                .frame(minWidth: 520, minHeight: 450)
        }
        .task {
            settingsViewModel.configure(modelContext: modelContext)
            hasCompletedOnboarding = settingsViewModel.isAPIKeyConfigured
                && !settingsViewModel.isFirstLaunch

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
        .onChange(of: isInspectorVisible) { _, newValue in
            appStateManager.saveInspectorVisibility(newValue)
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

        sessionViewModel.setAppStateManager(appStateManager)
        sessionViewModel.configure(modelContext: modelContext)
        eventStore = SwiftDataEventStore(modelContext: modelContext)

        agentBridge.permissionHandler.setModelContext(modelContext)

        // Restore selected session
        restoreSelectedSession()

        // Restore Inspector visibility
        isInspectorVisible = appStateManager.isInspectorVisible

        // Restore window frame if window reference is already available
        if let window = mainWindow {
            restoreWindowFrame(in: window)
        }
    }

    private func restoreSelectedSession() {
        if let restoredID = appStateManager.lastActiveSessionID {
            let matching = sessionViewModel.sessions.first { $0.id == restoredID }
            if let match = matching {
                sessionViewModel.selectSession(match)
            } else {
                // Fallback: select first (most recent) session
                if let first = sessionViewModel.sessions.first {
                    sessionViewModel.selectSession(first)
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
        .modelContainer(for: AppConfiguration.self, inMemory: true)
}
