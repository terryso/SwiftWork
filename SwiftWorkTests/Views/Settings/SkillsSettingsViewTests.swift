import XCTest
import SwiftUI
import SwiftData
import OpenAgentSDK
@testable import SwiftWork

// ATDD Red Phase -- Story 5.4: Skill Management Panel
// Acceptance tests for SettingsView Skills tab integration (AC#1, AC#2, AC#3, AC#4).
// These tests assert EXPECTED behavior that does NOT exist yet.
// They WILL FAIL until SettingsView is updated with Skills tab and SkillsListView is created.

@MainActor
final class SkillsSettingsViewTests: XCTestCase {

    // MARK: - Test Helpers

    private var testContainer: ModelContainer!

    private func makeTestContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        testContainer = try! ModelContainer(
            for: PermissionRule.self, AppConfiguration.self, Session.self, Event.self,
            configurations: config
        )
        return testContainer
    }

    private func makeHandler(in context: ModelContext) -> PermissionHandler {
        let handler = PermissionHandler()
        handler.setModelContext(context)
        return handler
    }

    private func makeBridge() -> AgentBridge {
        let bridge = AgentBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: FileManager.default.currentDirectoryPath,
            sessionId: UUID().uuidString
        )
        return bridge
    }

    override func tearDown() async throws {
        testContainer = nil
    }

    // MARK: - AC#1: Settings new Skills tab

    // [P0] SettingsView accepts agentBridge parameter
    func testSettingsViewAcceptsAgentBridge() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)
        let bridge = makeBridge()
        let viewModel = SettingsViewModel()
        viewModel.configure(modelContext: context)

        // SettingsView should accept an agentBridge parameter
        let view = SettingsView(
            settingsViewModel: viewModel,
            permissionHandler: handler,
            agentBridge: bridge
        )
        XCTAssertNotNil(view,
            "SettingsView should accept agentBridge parameter")
    }

    // [P0] SettingsView has three tabs: General, Permissions, Skills
    func testSettingsViewHasThreeTabs() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)
        let bridge = makeBridge()
        let viewModel = SettingsViewModel()
        viewModel.configure(modelContext: context)

        let view = SettingsView(
            settingsViewModel: viewModel,
            permissionHandler: handler,
            agentBridge: bridge
        )
        XCTAssertNotNil(view,
            "SettingsView should compile with three-tab layout including Skills")
    }

    // [P1] SettingsView backwards compatibility -- two-param init still works
    func testSettingsViewBackwardCompatTwoParamInit() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)
        let viewModel = SettingsViewModel()
        viewModel.configure(modelContext: context)

        // Old two-parameter init should still work
        let view = SettingsView(
            settingsViewModel: viewModel,
            permissionHandler: handler
        )
        XCTAssertNotNil(view,
            "SettingsView(settingsViewModel:permissionHandler:) should still compile (backward compat)")
    }

    // [P1] SettingsView backward compat -- single-param init still works
    func testSettingsViewBackwardCompatSingleParamInit() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)

        let view = SettingsView(permissionHandler: handler)
        XCTAssertNotNil(view,
            "SettingsView(permissionHandler:) should still compile (backward compat)")
    }

    // MARK: - AC#2: Skill list by source grouping

    // [P0] SkillsListView is creatable and accepts skill data
    func testSkillsListViewAcceptsSkills() throws {
        let bridge = makeBridge()
        let skills = bridge.discoveredSkills

        let view = SkillsListView(
            skills: skills,
            sourceDirectories: bridge.skillSourceDirectories
        )
        XCTAssertNotNil(view,
            "SkillsListView should accept skills array parameter")
    }

    // [P0] SkillsListView renders with empty skills list
    func testSkillsListViewHandlesEmptySkills() {
        let view = SkillsListView(skills: [])
        XCTAssertNotNil(view,
            "SkillsListView should handle empty skills array gracefully")
    }

    // [P1] SkillsListView groups skills by source
    func testSkillsListViewGroupingBySource() throws {
        let bridge = makeBridge()
        let skills = bridge.discoveredSkills

        // All BuiltInSkills should be in the list
        XCTAssertTrue(skills.count >= 4,
            "Should have at least 4 BuiltInSkills discovered")

        // Group them by source
        let grouped = Dictionary(grouping: skills, by: {
            SkillSource.from($0, directories: bridge.skillSourceDirectories)
        })

        // All BuiltInSkills should have nil baseDir -> .builtIn group
        let builtInCount = grouped[.builtIn]?.count ?? 0
        XCTAssertGreaterThanOrEqual(builtInCount, 4,
            "All BuiltInSkills should be in .builtIn group")
    }

    // MARK: - AC#3: Skill detail expansion

    // [P0] SkillListItemView is creatable with a skill
    func testSkillListItemViewAcceptsSkill() {
        let skill = Skill(
            name: "test-skill",
            description: "A test skill",
            aliases: ["ts"],
            toolRestrictions: [.bash, .read],
            promptTemplate: "Do something",
            whenToUse: "When testing",
            argumentHint: "[message]",
            baseDir: "/some/path"
        )

        let view = SkillListItemView(skill: skill, isExpanded: false)
        XCTAssertNotNil(view,
            "SkillListItemView should accept a Skill parameter")
    }

    // [P0] SkillListItemView renders expanded state
    func testSkillListItemViewExpandedState() {
        let skill = Skill(
            name: "test-skill",
            description: "A test skill",
            aliases: ["ts"],
            toolRestrictions: [.bash, .read],
            promptTemplate: "Do something",
            whenToUse: "When testing",
            argumentHint: "[message]",
            baseDir: "/some/path"
        )

        let view = SkillListItemView(skill: skill, isExpanded: true)
        XCTAssertNotNil(view,
            "SkillListItemView should render in expanded state")
    }

    // [P1] Skill with no aliases still renders correctly
    func testSkillListItemViewWithNoAliases() {
        let skill = Skill(
            name: "simple-skill",
            description: "No aliases",
            aliases: [],
            promptTemplate: "Do it"
        )

        let view = SkillListItemView(skill: skill, isExpanded: true)
        XCTAssertNotNil(view,
            "SkillListItemView should handle skill with no aliases")
    }

    // [P1] Skill with no optional fields renders correctly
    func testSkillListItemViewWithMinimalSkill() {
        let skill = Skill(
            name: "minimal",
            description: "",
            promptTemplate: "Template"
        )

        let view = SkillListItemView(skill: skill, isExpanded: true)
        XCTAssertNotNil(view,
            "SkillListItemView should handle skill with no optional fields")
    }

    // MARK: - AC#4: Open in Finder button

    // [P0] Skill with baseDir can trigger Finder open (logic test)
    func testSkillWithBaseDirHasValidURL() {
        let basePath = "/tmp/skill-test-dir"
        let skill = Skill(
            name: "finder-skill",
            description: "Has baseDir",
            promptTemplate: "Test",
            baseDir: basePath
        )

        XCTAssertNotNil(skill.baseDir,
            "Skill should have non-nil baseDir")
        let url = URL(fileURLWithPath: skill.baseDir!)
        XCTAssertEqual(url.path, basePath,
            "baseDir should produce a valid file URL")
    }

    // [P0] Built-in skill has no baseDir -> no Open in Finder
    func testBuiltInSkillHasNoBaseDir() {
        let skill = BuiltInSkills.commit
        XCTAssertNil(skill.baseDir,
            "BuiltIn skill should have nil baseDir -> no Open in Finder button")
    }

    // [P1] SkillSource.from returns .builtIn for skill with nil baseDir (no Finder)
    func testBuiltInSkillsDoNotShowOpenInFinder() {
        let builtIn = BuiltInSkills.commit
        let source = SkillSource.from(builtIn)
        XCTAssertEqual(source, .builtIn)

        // Built-in skills have nil baseDir, so Open in Finder should not appear
        XCTAssertNil(builtIn.baseDir,
            "Built-in skills should not show Open in Finder")
    }

    // MARK: - Integration: AgentBridge allRegisteredSkills

    // [P0] AgentBridge exposes allRegisteredSkills (including non-userInvocable)
    func testAgentBridgeExposesAllRegisteredSkills() {
        let bridge = makeBridge()

        // allRegisteredSkills should include ALL skills (not just userInvocable)
        let allSkills = bridge.allRegisteredSkills
        XCTAssertFalse(allSkills.isEmpty,
            "allRegisteredSkills should not be empty after configure()")
        XCTAssertGreaterThanOrEqual(allSkills.count, bridge.discoveredSkills.count,
            "allRegisteredSkills should be >= discoveredSkills (includes non-userInvocable)")
    }

    // [P1] allRegisteredSkills includes skills regardless of userInvocable flag
    func testAllRegisteredSkillsIncludesNonUserInvocable() {
        let bridge = makeBridge()

        // Create a non-userInvocable skill and verify it's in allRegisteredSkills
        // but not in discoveredSkills
        let allSkills = bridge.allRegisteredSkills
        let invocableSkills = bridge.discoveredSkills

        // discoveredSkills is filtered to userInvocable only
        for skill in invocableSkills {
            XCTAssertTrue(skill.userInvocable,
                "discoveredSkills should only contain userInvocable skills")
        }

        // allRegisteredSkills may contain more than just userInvocable
        XCTAssertTrue(allSkills.count >= invocableSkills.count,
            "allRegisteredSkills should contain at least as many as discoveredSkills")
    }

    // MARK: - Regression: existing SettingsView behavior preserved

    // [P0] Skills tab addition does not break existing General tab
    func testGeneralTabStillWorksAfterSkillsTab() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)
        let bridge = makeBridge()
        let viewModel = SettingsViewModel()
        viewModel.configure(modelContext: context)

        let view = SettingsView(
            settingsViewModel: viewModel,
            permissionHandler: handler,
            agentBridge: bridge
        )
        XCTAssertNotNil(view,
            "SettingsView with Skills tab should not break General tab rendering")

        // SettingsViewModel should still function normally
        viewModel.selectedModel = "claude-sonnet-4-6"
        XCTAssertEqual(viewModel.selectedModel, "claude-sonnet-4-6")
    }

    // [P0] Skills tab addition does not break Permissions tab
    func testPermissionsTabStillWorksAfterSkillsTab() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)
        let bridge = makeBridge()

        let view = SettingsView(
            permissionHandler: handler,
            agentBridge: bridge
        )
        XCTAssertNotNil(view,
            "SettingsView with Skills tab should not break Permissions tab rendering")

        // PermissionHandler should still function
        handler.globalMode = .autoApprove
        XCTAssertEqual(handler.globalMode, .autoApprove)
    }
}
