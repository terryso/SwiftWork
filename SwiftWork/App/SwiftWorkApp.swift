import SwiftUI
import SwiftData

@main
struct SwiftWorkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Session.self,
            Event.self,
            PermissionRule.self,
            AppConfiguration.self
        ])
    }
}
