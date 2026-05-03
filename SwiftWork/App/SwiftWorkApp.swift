import SwiftUI
import SwiftData

@main
struct SwiftWorkApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .defaultSize(width: 1200, height: 800)
        .modelContainer(for: [
            Session.self,
            Event.self,
            PermissionRule.self,
            AppConfiguration.self
        ])
        .commands {
            // File menu — replace default "New Window" with "新建会话"
            CommandGroup(replacing: .newItem) {
                Button("新建会话") {
                    appState.sessionViewModel.createSession()
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            // View menu — add Inspector and Debug Panel toggles
            CommandGroup(after: .toolbar) {
                Button("切换 Inspector") {
                    withAnimation {
                        appState.isInspectorVisible.toggle()
                    }
                }
                .keyboardShortcut("i", modifiers: .command)

                Button("切换 Debug Panel") {
                    withAnimation {
                        appState.isDebugPanelVisible.toggle()
                    }
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }

            // App menu — replace default "Settings..." with custom binding
            CommandGroup(replacing: .appSettings) {
                Button("设置...") {
                    appState.isSettingsPresented = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
