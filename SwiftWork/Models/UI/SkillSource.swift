import Foundation
import OpenAgentSDK

struct SkillSourceDirectories: Equatable, Sendable {
    let sharedAgentsConfiguration: String
    let sharedAgents: String
    let claudeCode: String
    let codex: String
    let swiftWork: String

    static func userDefaults(fileManager: FileManager = .default) -> SkillSourceDirectories {
        let home = fileManager.homeDirectoryForCurrentUser
        let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? home.appendingPathComponent("Library/Application Support", isDirectory: true)

        return SkillSourceDirectories(
            sharedAgentsConfiguration: home.appendingPathComponent(".config/agents/skills", isDirectory: true).path,
            sharedAgents: home.appendingPathComponent(".agents/skills", isDirectory: true).path,
            claudeCode: home.appendingPathComponent(".claude/skills", isDirectory: true).path,
            codex: home.appendingPathComponent(".codex/skills", isDirectory: true).path,
            swiftWork: applicationSupport
                .appendingPathComponent("SwiftWork", isDirectory: true)
                .appendingPathComponent("skills", isDirectory: true)
                .path
        )
    }
}

enum SkillSource: String, CaseIterable, Equatable, Sendable {
    case builtIn
    case swiftWork
    case claudeCode
    case codex
    case sharedAgents

    static func from(
        _ skill: Skill,
        directories: SkillSourceDirectories = .userDefaults()
    ) -> SkillSource {
        guard let baseDir = skill.baseDir else { return .builtIn }

        if contains(baseDir, in: directories.swiftWork) {
            return .swiftWork
        }
        if contains(baseDir, in: directories.codex) {
            return .codex
        }
        if contains(baseDir, in: directories.claudeCode) {
            return .claudeCode
        }
        return .sharedAgents
    }

    var displayName: String {
        switch self {
        case .builtIn: "Built-in"
        case .swiftWork: "SwiftWork"
        case .claudeCode: "Claude Code"
        case .codex: "Codex"
        case .sharedAgents: "Shared Agents"
        }
    }

    private static func contains(_ baseDir: String, in rootDirectory: String) -> Bool {
        let root = (rootDirectory as NSString).standardizingPath
        let base = (baseDir as NSString).standardizingPath
        let prefix = root.hasSuffix("/") ? root : root + "/"
        return base == root || base.hasPrefix(prefix)
    }
}
