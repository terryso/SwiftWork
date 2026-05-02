import Foundation

enum PermissionDialogResult: Sendable, Equatable {
    case allowOnce
    case alwaysAllow
    case deny
}

@MainActor
final class PendingPermissionRequest: Identifiable {
    let id = UUID()
    let toolName: String
    let description: String
    let parameters: [String: any Sendable]
    let input: [String: Any]
    let toolTypeTag: String

    private var continuation: CheckedContinuation<PermissionDialogResult, Never>?
    private var resolved = false

    init(
        toolName: String,
        description: String,
        parameters: [String: any Sendable],
        input: [String: Any]
    ) {
        self.toolName = toolName
        self.description = description
        self.parameters = parameters
        self.input = input
        self.toolTypeTag = Self.computeToolTypeLabel(toolName)
    }

    func setContinuation(_ continuation: CheckedContinuation<PermissionDialogResult, Never>) {
        self.continuation = continuation
    }

    func resolve(_ result: PermissionDialogResult) {
        guard !resolved else { return }
        resolved = true
        continuation?.resume(returning: result)
        continuation = nil
    }

    func waitForResult() async -> PermissionDialogResult {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    private static func computeToolTypeLabel(_ toolName: String) -> String {
        switch toolName {
        case "Bash": return "终端命令"
        case "Edit", "Write": return "文件编辑"
        case "Read": return "文件读取"
        case "Grep", "Glob": return "文件搜索"
        default: return toolName
        }
    }
}
