import SwiftUI

@MainActor
@Observable
final class AppState {
    let sessionViewModel = SessionViewModel()
    let settingsViewModel = SettingsViewModel()
    var isSettingsPresented = false
    var isInspectorVisible = false
    var isDebugPanelVisible = false
    var unreadSessionCount: Int = 0 {
        didSet {
            updateDockBadge()
        }
    }

    @ObservationIgnored
    private var notificationObservers: [NSObjectProtocol] = []

    init() {
        listenForAppActivation()
    }

    // MARK: - Dock Badge

    func updateDockBadge() {
        if unreadSessionCount > 0 {
            NSApplication.shared.dockTile.badgeLabel = "\(unreadSessionCount)"
        } else {
            NSApplication.shared.dockTile.badgeLabel = nil
        }
    }

    // MARK: - Unread Session Management

    func markSessionAsUnread(_ session: Session) {
        guard !session.hasUnreadResult else { return }
        session.hasUnreadResult = true
        unreadSessionCount += 1
    }

    func clearUnreadForSession(_ session: Session) {
        guard session.hasUnreadResult else { return }
        session.hasUnreadResult = false
        unreadSessionCount = max(0, unreadSessionCount - 1)
    }

    func clearAllUnread() {
        for session in sessionViewModel.sessions where session.hasUnreadResult {
            session.hasUnreadResult = false
        }
        unreadSessionCount = 0
    }

    // MARK: - App Activation

    private func listenForAppActivation() {
        let observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.clearAllUnread()
            }
        }
        notificationObservers.append(observer)
    }
}
