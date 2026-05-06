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
    @ObservationIgnored private let workspaceService: SessionWorkspaceService

    init(workspaceService: SessionWorkspaceService = SessionWorkspaceService()) {
        self.workspaceService = workspaceService
    }

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
        let inheritedWorkspace = workspaceService.mostRecentValidWorkspace(in: sessions)
        let session = Session(
            workspacePath: inheritedWorkspace?.path,
            workspaceBookmark: inheritedWorkspace?.bookmarkData
        )
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
        onSessionSelected?(session)
    }

    var onSessionSelected: ((Session) -> Void)?

    /// Called when a session is deleted and its unread state needs cleanup.
    var onSessionCleared: ((Session) -> Void)?

    func deleteSession(_ session: Session) {
        guard let modelContext else { return }
        if session.hasUnreadResult {
            onSessionCleared?(session)
        }
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

    func workspaceState(for session: Session) -> SessionWorkspaceState {
        workspaceService.resolveState(for: session)
    }

    func mostRecentWorkspaceBinding(excluding session: Session? = nil) -> SessionWorkspaceBinding? {
        workspaceService.mostRecentValidWorkspace(in: sessions, excluding: session?.id)
    }

    @discardableResult
    func activateWorkspace(for session: Session) -> SessionWorkspaceState {
        workspaceService.activateWorkspace(for: session)
    }

    func deactivateActiveWorkspace() {
        workspaceService.releaseActiveWorkspaceAccess()
    }

    @discardableResult
    func updateWorkspace(_ session: Session, to url: URL) -> Bool {
        guard let modelContext else { return false }
        let oldPath = session.workspacePath
        let oldBookmark = session.workspaceBookmark
        let oldUpdatedAt = session.updatedAt
        do {
            try workspaceService.bindWorkspace(session, to: url)
            session.updatedAt = .now
            try modelContext.save()
            sessions.sort { $0.updatedAt > $1.updatedAt }
            errorMessage = nil
            return true
        } catch {
            session.workspacePath = oldPath
            session.workspaceBookmark = oldBookmark
            session.updatedAt = oldUpdatedAt
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    @discardableResult
    func useMostRecentWorkspace(for session: Session) -> Bool {
        guard let modelContext else { return false }
        guard let binding = mostRecentWorkspaceBinding(excluding: session) else {
            errorMessage = "没有可继承的最近工作目录。"
            return false
        }

        let oldPath = session.workspacePath
        let oldBookmark = session.workspaceBookmark
        let oldUpdatedAt = session.updatedAt
        workspaceService.apply(binding, to: session)
        session.updatedAt = .now
        do {
            try modelContext.save()
            sessions.sort { $0.updatedAt > $1.updatedAt }
            errorMessage = nil
            return true
        } catch {
            session.workspacePath = oldPath
            session.workspaceBookmark = oldBookmark
            session.updatedAt = oldUpdatedAt
            errorMessage = AppError(
                domain: .data,
                code: "UPDATE_WORKSPACE_FAILED",
                message: error.localizedDescription,
                underlying: error
            ).message
            return false
        }
    }
}
