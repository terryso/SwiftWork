import XCTest
import OpenAgentSDK
@testable import SwiftWork

// Acceptance tests for Skill source grouping logic (AC#2).
// SkillSource is a pure-function enum that categorizes skills by baseDir.

@MainActor
final class SkillSourceGroupingTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeSkill(
        name: String = "test-skill",
        baseDir: String? = nil
    ) -> Skill {
        Skill(
            name: name,
            description: "Test skill",
            promptTemplate: "Do something",
            baseDir: baseDir
        )
    }

    /// Fixed workspace root so tests are hermetic and don't depend on
    /// FileManager.default.currentDirectoryPath (which varies by test runner).
    private var workspaceRoot: String {
        "/tmp/SkillSourceGroupingTests/workspace"
    }

    // MARK: - AC#2: Skill source grouping by baseDir

    // [P0] Built-in skill: baseDir == nil -> .builtIn
    func testSkillSourceBuiltInWhenBaseDirIsNil() {
        let skill = makeSkill(name: "commit", baseDir: nil)

        let source = SkillSource.from(skill, workspaceRoot: workspaceRoot)
        XCTAssertEqual(source, .builtIn,
            "Skill with nil baseDir should be classified as Built-in")
    }

    // [P0] Project skill: baseDir starts with CWD -> .project
    func testSkillSourceProjectWhenBaseDirUnderCWD() {
        let projectPath = workspaceRoot + "/.claude/skills/my-skill"
        let skill = makeSkill(name: "my-skill", baseDir: projectPath)

        let source = SkillSource.from(skill, workspaceRoot: workspaceRoot)
        XCTAssertEqual(source, .project,
            "Skill with baseDir under project CWD should be classified as Project")
    }

    // [P0] User skill: baseDir is non-nil but NOT under CWD -> .user
    func testSkillSourceUserWhenBaseDirOutsideCWD() {
        let userPath = "/Users/nick/.claude/skills/custom-skill"
        let skill = makeSkill(name: "custom-skill", baseDir: userPath)

        let source = SkillSource.from(skill, workspaceRoot: workspaceRoot)
        XCTAssertEqual(source, .user,
            "Skill with baseDir outside project CWD should be classified as User")
    }

    // [P1] User skill: baseDir is in home directory
    func testSkillSourceUserWhenBaseDirInHomeDirectory() {
        let homeSkillPath = NSHomeDirectory() + "/.claude/skills/global-skill"
        let skill = makeSkill(name: "global-skill", baseDir: homeSkillPath)

        let source = SkillSource.from(skill, workspaceRoot: workspaceRoot)
        XCTAssertEqual(source, .user,
            "Skill with baseDir in home directory should be classified as User")
    }

    // [P1] BuiltInSkills from SDK have nil baseDir -> all classified as .builtIn
    func testAllBuiltInSkillsClassifiedAsBuiltIn() {
        let builtInSkills = [
            BuiltInSkills.commit,
            BuiltInSkills.review,
            BuiltInSkills.simplify,
            BuiltInSkills.debug,
            BuiltInSkills.test,
        ]

        for skill in builtInSkills {
            let source = SkillSource.from(skill, workspaceRoot: workspaceRoot)
            XCTAssertEqual(source, .builtIn,
                "BuiltIn skill '\(skill.name)' should be classified as Built-in, got \(source)")
        }
    }

    // [P1] Grouping a mixed list of skills produces correct categories
    func testGroupingMixedSkills() {
        let skills: [Skill] = [
            makeSkill(name: "commit", baseDir: nil),
            makeSkill(name: "project-skill", baseDir: workspaceRoot + "/.claude/skills/ps"),
            makeSkill(name: "user-skill", baseDir: "/Users/nick/.claude/skills/us"),
            makeSkill(name: "review", baseDir: nil),
        ]

        let grouped = Dictionary(grouping: skills, by: { SkillSource.from($0, workspaceRoot: workspaceRoot) })

        XCTAssertEqual(grouped[.builtIn]?.count, 2,
            "Should have 2 Built-in skills")
        XCTAssertEqual(grouped[.project]?.count, 1,
            "Should have 1 Project skill")
        XCTAssertEqual(grouped[.user]?.count, 1,
            "Should have 1 User skill")
    }

    // [P2] Edge case: baseDir is exactly the CWD itself (not under it)
    func testSkillSourceWhenBaseDirEqualsCWD() {
        let skill = makeSkill(name: "edge-skill", baseDir: workspaceRoot)

        let source = SkillSource.from(skill, workspaceRoot: workspaceRoot)
        XCTAssertEqual(source, .project,
            "Skill with baseDir exactly equal to CWD should be classified as Project")
    }

    // [P2] Edge case: baseDir starts with same prefix but is different path
    func testSkillSourceWhenBaseDirHasSimilarPrefixButDifferentPath() {
        let fakePath = workspaceRoot + "-suffix/skills/skill"
        let skill = makeSkill(name: "tricky-skill", baseDir: fakePath)

        let source = SkillSource.from(skill, workspaceRoot: workspaceRoot)
        XCTAssertEqual(source, .user,
            "Skill with baseDir that merely shares a prefix with CWD should be User, not Project. " +
            "Implementation must ensure exact path prefix matching (add trailing '/' to CWD check).")
    }
}
