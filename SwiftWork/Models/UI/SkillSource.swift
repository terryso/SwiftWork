import Foundation
import OpenAgentSDK

/// Categorizes a ``Skill`` by its origin: built-in, project-local, or user-global.
///
/// Grouping rules:
/// - `baseDir == nil` → `.builtIn` (registered in code via `BuiltInSkills`)
/// - `baseDir` starts with the active session workspace root → `.project`
/// - Everything else → `.user`
enum SkillSource: String, CaseIterable, Equatable, Sendable {
    case builtIn
    case project
    case user

    static func from(_ skill: Skill, workspaceRoot: String? = nil) -> SkillSource {
        guard let baseDir = skill.baseDir else { return .builtIn }
        guard let workspaceRoot, !workspaceRoot.isEmpty else { return .user }
        let root = (workspaceRoot as NSString).standardizingPath
        let base = (baseDir as NSString).standardizingPath
        let rootPrefix = root.hasSuffix("/") ? root : root + "/"
        return base.hasPrefix(rootPrefix) || base == root ? .project : .user
    }
}
