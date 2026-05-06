import Foundation
import OpenAgentSDK

/// Categorizes a ``Skill`` by its origin: built-in, project-local, or user-global.
///
/// Grouping rules:
/// - `baseDir == nil` → `.builtIn` (registered in code via `BuiltInSkills`)
/// - `baseDir` starts with the current working directory → `.project`
/// - Everything else → `.user`
enum SkillSource: String, CaseIterable, Equatable, Sendable {
    case builtIn
    case project
    case user

    /// Determine the source of a skill based on its `baseDir`.
    ///
    /// Uses `FileManager.default.currentDirectoryPath` as the project root.
    /// A trailing `/` is appended to the CWD to avoid false prefix matches
    /// (e.g. `/foo-bar` should not match `/foo` as a prefix).
    static func from(_ skill: Skill) -> SkillSource {
        guard let baseDir = skill.baseDir else { return .builtIn }
        let cwd = FileManager.default.currentDirectoryPath
        // Append "/" to avoid false prefix matches like /foo matching /foo-bar
        let cwdPrefix = cwd.hasSuffix("/") ? cwd : cwd + "/"
        return baseDir.hasPrefix(cwdPrefix) || baseDir == cwd ? .project : .user
    }
}
