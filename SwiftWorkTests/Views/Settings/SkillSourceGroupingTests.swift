import XCTest
import OpenAgentSDK
@testable import SwiftWork

@MainActor
final class SkillSourceGroupingTests: XCTestCase {
    private let directories = SkillSourceDirectories(
        sharedAgentsConfiguration: "/test-home/.config/agents/skills",
        sharedAgents: "/test-home/.agents/skills",
        claudeCode: "/test-home/.claude/skills",
        codex: "/test-home/.codex/skills",
        swiftWork: "/test-home/Library/Application Support/SwiftWork/skills"
    )

    private func makeSkill(name: String, baseDir: String?) -> Skill {
        Skill(
            name: name,
            description: "Test skill",
            promptTemplate: "Do something",
            baseDir: baseDir
        )
    }

    func testBuiltInSkillHasBuiltInSource() {
        let skill = makeSkill(name: "commit", baseDir: nil)

        XCTAssertEqual(SkillSource.from(skill, directories: directories), .builtIn)
    }

    func testSwiftWorkSkillHasSwiftWorkSource() {
        let skill = makeSkill(
            name: "swiftwork-skill",
            baseDir: directories.swiftWork + "/@publisher/swiftwork-skill"
        )

        XCTAssertEqual(SkillSource.from(skill, directories: directories), .swiftWork)
    }

    func testClaudeSkillHasClaudeCodeSource() {
        let skill = makeSkill(name: "claude-skill", baseDir: directories.claudeCode + "/claude-skill")

        XCTAssertEqual(SkillSource.from(skill, directories: directories), .claudeCode)
    }

    func testCodexSkillHasCodexSource() {
        let skill = makeSkill(name: "codex-skill", baseDir: directories.codex + "/codex-skill")

        XCTAssertEqual(SkillSource.from(skill, directories: directories), .codex)
    }

    func testBothAgentsRootsHaveSharedAgentsSource() {
        let configSkill = makeSkill(
            name: "config-skill",
            baseDir: directories.sharedAgentsConfiguration + "/config-skill"
        )
        let agentsSkill = makeSkill(
            name: "agents-skill",
            baseDir: directories.sharedAgents + "/agents-skill"
        )

        XCTAssertEqual(SkillSource.from(configSkill, directories: directories), .sharedAgents)
        XCTAssertEqual(SkillSource.from(agentsSkill, directories: directories), .sharedAgents)
    }

    func testUnknownFilesystemSkillFallsBackToSharedAgents() {
        let skill = makeSkill(name: "unknown", baseDir: "/other/global/skills/unknown")

        XCTAssertEqual(SkillSource.from(skill, directories: directories), .sharedAgents)
    }

    func testSimilarPathPrefixDoesNotMatchCodexRoot() {
        let skill = makeSkill(name: "tricky", baseDir: directories.codex + "-other/tricky")

        XCTAssertEqual(SkillSource.from(skill, directories: directories), .sharedAgents)
    }

    func testAllSourceDisplayNamesMatchSettingsContract() {
        XCTAssertEqual(
            SkillSource.allCases.map(\.displayName),
            ["Built-in", "SwiftWork", "Claude Code", "Codex", "Shared Agents"]
        )
    }
}
