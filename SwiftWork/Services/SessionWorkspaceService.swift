import Foundation

struct SessionWorkspaceBinding: Equatable, Sendable {
    let path: String
    let bookmarkData: Data?
}

enum SessionWorkspaceState: Equatable, Sendable {
    case ready(SessionWorkspaceBinding)
    case unbound
    case needsRepair(lastKnownPath: String)

    var workspacePath: String? {
        switch self {
        case .ready(let binding):
            binding.path
        case .unbound:
            nil
        case .needsRepair(let path):
            path
        }
    }

    var requiresBinding: Bool {
        switch self {
        case .ready:
            false
        case .unbound, .needsRepair:
            true
        }
    }
}

enum SessionWorkspaceError: LocalizedError {
    case inaccessible(String)

    var errorDescription: String? {
        switch self {
        case .inaccessible(let path):
            "无法访问工作目录：\(path)"
        }
    }
}

@MainActor
final class SessionWorkspaceService {
    private var activeSecurityScopedURL: URL?
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func resolveState(for session: Session) -> SessionWorkspaceState {
        resolveState(workspacePath: session.workspacePath, bookmarkData: session.workspaceBookmark)
    }

    func resolveState(workspacePath: String?, bookmarkData: Data?) -> SessionWorkspaceState {
        guard let workspacePath,
              !workspacePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .unbound
        }

        let normalizedPath = normalize(path: workspacePath)
        if let restoredPath = restoredPath(from: bookmarkData),
           validate(path: restoredPath) {
            return .ready(SessionWorkspaceBinding(path: restoredPath, bookmarkData: bookmarkData))
        }

        let binding = SessionWorkspaceBinding(path: normalizedPath, bookmarkData: bookmarkData)
        return validate(path: normalizedPath) ? .ready(binding) : .needsRepair(lastKnownPath: normalizedPath)
    }

    func mostRecentValidWorkspace(
        in sessions: [Session],
        excluding excludedSessionID: UUID? = nil
    ) -> SessionWorkspaceBinding? {
        for session in sessions where session.id != excludedSessionID {
            if case .ready(let binding) = resolveState(for: session) {
                return binding
            }
        }
        return nil
    }

    func bindWorkspace(_ session: Session, to url: URL) throws {
        let binding = try makeBinding(for: url)
        apply(binding, to: session)
    }

    func apply(_ binding: SessionWorkspaceBinding, to session: Session) {
        session.workspacePath = binding.path
        session.workspaceBookmark = binding.bookmarkData
    }

    @discardableResult
    func activateWorkspace(for session: Session) -> SessionWorkspaceState {
        releaseActiveWorkspaceAccess()

        let state = resolveState(for: session)
        guard case .ready(let binding) = state else {
            return state
        }

        if binding.bookmarkData != nil {
            guard let url = resolveBookmarkURL(from: binding.bookmarkData),
                  url.startAccessingSecurityScopedResource() else {
                return .needsRepair(lastKnownPath: binding.path)
            }
            activeSecurityScopedURL = url
        }

        return state
    }

    func releaseActiveWorkspaceAccess() {
        activeSecurityScopedURL?.stopAccessingSecurityScopedResource()
        activeSecurityScopedURL = nil
    }

    func agentWorkingDirectory(for state: SessionWorkspaceState) -> String {
        switch state {
        case .ready(let binding):
            return binding.path
        case .unbound:
            return safeFallbackWorkingDirectory()
        case .needsRepair(let path):
            let _ = path
            return safeFallbackWorkingDirectory()
        }
    }

    func normalize(path: String) -> String {
        (path as NSString).standardizingPath
    }

    private var unboundAgentWorkingDirectory: String {
        let home = fileManager.homeDirectoryForCurrentUser.path
        return (home as NSString).appendingPathComponent(".swiftwork-unbound-workspace")
    }

    private func safeFallbackWorkingDirectory() -> String {
        let path = unboundAgentWorkingDirectory
        if !fileManager.fileExists(atPath: path) {
            try? fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
        }
        return path
    }

    private func makeBinding(for url: URL) throws -> SessionWorkspaceBinding {
        let normalizedPath = normalize(path: url.path)
        guard validate(path: normalizedPath) else {
            throw SessionWorkspaceError.inaccessible(normalizedPath)
        }

        let bookmarkData = try? url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        return SessionWorkspaceBinding(path: normalizedPath, bookmarkData: bookmarkData)
    }

    private func validate(path: String) -> Bool {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory),
              isDirectory.boolValue,
              fileManager.isReadableFile(atPath: path) else {
            return false
        }

        return true
    }

    private func resolveBookmarkURL(from data: Data?) -> URL? {
        guard let data else { return nil }
        var isStale = false
        return try? URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope, .withoutUI],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
    }

    private func restoredPath(from bookmarkData: Data?) -> String? {
        guard let url = resolveBookmarkURL(from: bookmarkData) else { return nil }
        return normalize(path: url.path)
    }
}
