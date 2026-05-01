import SwiftUI
import SwiftData

@main
struct SwiftWorkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 1200, height: 800)
        .modelContainer(for: [
            Session.self,
            Event.self,
            PermissionRule.self,
            AppConfiguration.self
        ])
    }
}
