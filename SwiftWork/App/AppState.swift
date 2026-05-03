import SwiftUI

@MainActor
@Observable
final class AppState {
    let sessionViewModel = SessionViewModel()
    let settingsViewModel = SettingsViewModel()
    var isSettingsPresented = false
    var isInspectorVisible = false
    var isDebugPanelVisible = false
}
