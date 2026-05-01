import Foundation
import SwiftData

@MainActor
@Observable
final class SessionViewModel {
    var sessions: [Session] = []
    var selectedSession: Session?
    var errorMessage: String?

    private var modelContext: ModelContext?
    private(set) var appStateManager: AppStateManager?

    func setAppStateManager(_ manager: AppStateManager) {
        appStateManager = manager
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchSessions()
    }

    func fetchSessions() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<Session>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        do {
            sessions = try modelContext.fetch(descriptor)
            errorMessage = nil
        } catch {
            errorMessage = AppError(
                domain: .data,
                code: "FETCH_SESSIONS_FAILED",
                message: error.localizedDescription,
                underlying: error
            ).message
        }
    }

    func createSession() {
        guard let modelContext else { return }
        let session = Session()
        modelContext.insert(session)
        do {
            try modelContext.save()
            sessions.insert(session, at: 0)
            selectedSession = session
            appStateManager?.saveLastActiveSessionID(session.id)
            errorMessage = nil
        } catch {
            errorMessage = AppError(
                domain: .data,
                code: "CREATE_SESSION_FAILED",
                message: error.localizedDescription,
                underlying: error
            ).message
        }
    }

    func selectSession(_ session: Session) {
        selectedSession = session
        appStateManager?.saveLastActiveSessionID(session.id)
    }

    func deleteSession(_ session: Session) {
        guard let modelContext else { return }
        modelContext.delete(session)
        try? modelContext.save()
        sessions.removeAll { $0.id == session.id }
        if selectedSession?.id == session.id {
            selectedSession = sessions.first
        }
    }

    func updateSessionTitle(_ session: Session, title: String) {
        guard let modelContext else { return }
        session.title = title
        session.updatedAt = .now
        try? modelContext.save()
        sessions.sort { $0.updatedAt > $1.updatedAt }
    }
}
