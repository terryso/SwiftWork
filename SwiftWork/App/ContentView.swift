import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var settingsViewModel = SettingsViewModel()
    @State private var hasCompletedOnboarding: Bool? = nil

    var body: some View {
        Group {
            if let completed = hasCompletedOnboarding {
                if completed {
                    NavigationSplitView {
                        Text("Sidebar")
                            .navigationTitle("SwiftWork")
                    } detail: {
                        Text("Workspace")
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
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: AppConfiguration.self, inMemory: true)
}
