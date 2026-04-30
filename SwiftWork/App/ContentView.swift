import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var settingsViewModel = SettingsViewModel()
    @State private var sessionViewModel = SessionViewModel()
    @State private var hasCompletedOnboarding: Bool? = nil

    var body: some View {
        Group {
            if let completed = hasCompletedOnboarding {
                if completed {
                    NavigationSplitView {
                        SidebarView(sessionViewModel: sessionViewModel)
                    } detail: {
                        if let session = sessionViewModel.selectedSession {
                            Text("Workspace: \(session.title)")
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
        .task {
            settingsViewModel.configure(modelContext: modelContext)
            hasCompletedOnboarding = settingsViewModel.isAPIKeyConfigured
                && !settingsViewModel.isFirstLaunch

            if hasCompletedOnboarding == true {
                sessionViewModel.configure(modelContext: modelContext)
            }
        }
        .onChange(of: hasCompletedOnboarding) { _, newValue in
            if newValue == true {
                sessionViewModel.configure(modelContext: modelContext)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: AppConfiguration.self, inMemory: true)
}
