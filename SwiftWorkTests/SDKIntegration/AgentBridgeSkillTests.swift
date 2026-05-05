import XCTest
import OpenAgentSDK
@testable import SwiftWork

// ATDD Red Phase -- Story 5.1: SDK Skill Pipeline
// Acceptance tests for AgentBridge skill discovery, BuiltInSkills registration,
// SkillTool execution, and UI-layer skill list exposure.
// These tests assert EXPECTED behavior that does NOT exist yet.
// They WILL FAIL until AgentBridge.configure() is updated to enable skill discovery.

@MainActor
final class AgentBridgeSkillTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeBridge() -> AgentBridge {
        AgentBridge()
    }

    // MARK: - AC#1: AgentOptions enables Skill discovery

    // [P0] configure() creates a SkillRegistry and assigns it to AgentOptions
    func testConfigureCreatesSkillRegistry() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: "/tmp/test-workspace",
            sessionId: UUID().uuidString
        )

        // After configure, the bridge should expose a non-nil skillRegistry
        // via the discoveredSkills computed property or internal access.
        // The SkillRegistry must be created and assigned before Agent init.
        XCTAssertFalse(
            bridge.discoveredSkills.isEmpty,
            "configure() should register BuiltInSkills, making discoveredSkills non-empty"
        )
    }

    // [P0] configure() sets skillDirectories to a non-nil value to trigger autoDiscoverSkills
    // This is verified indirectly: if skillDirectories is nil, autoDiscoverSkills() does nothing.
    // The presence of filesystem skills + BuiltInSkills confirms the trigger works.
    func testConfigureTriggersSkillDirectorySetup() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: nil,
            sessionId: UUID().uuidString
        )

        // If skillDirectories was nil, autoDiscoverSkills would be a no-op.
        // BuiltInSkills are registered directly, so they should always be present.
        let skills = bridge.discoveredSkills
        XCTAssertTrue(
            skills.contains(where: { $0.name == "commit" }),
            "BuiltInSkills.commit should be registered after configure()"
        )
    }

    // MARK: - AC#2: Filesystem Skill discovery

    // [P1] configure() discovers skills from .claude/skills/*/SKILL.md
    // Note: This test verifies the wiring. Actual filesystem discovery depends on
    // having skills in the default directories. With no filesystem skills present,
    // only BuiltInSkills will appear. The test verifies the mechanism is wired.
    func testConfigureDiscoversFilesystemSkills() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: nil,
            sessionId: UUID().uuidString
        )

        // At minimum, BuiltInSkills should be present even without filesystem skills.
        // The key assertion: the skill discovery pipeline is wired up.
        let skills = bridge.discoveredSkills
        XCTAssertGreaterThanOrEqual(skills.count, 5,
            "Should have at least 5 BuiltInSkills (commit, review, simplify, debug, test)")
    }

    // MARK: - AC#3: Skill list injected into system prompt

    // [P1] SkillRegistry has user-invocable skills available for prompt formatting
    func testSkillRegistryFormatsSkillsForPrompt() {
        let registry = SkillRegistry()
        registry.register(BuiltInSkills.commit)
        registry.register(BuiltInSkills.review)

        let prompt = registry.formatSkillsForPrompt()
        XCTAssertFalse(prompt.isEmpty,
            "formatSkillsForPrompt() should return non-empty string when skills are registered")
        XCTAssertTrue(prompt.contains("commit"),
            "Formatted prompt should mention the 'commit' skill")
        XCTAssertTrue(prompt.contains("review"),
            "Formatted prompt should mention the 'review' skill")
    }

    // [P1] formatSkillsForPrompt returns empty when no skills registered
    func testFormatSkillsForPromptEmptyWhenNoSkills() {
        let registry = SkillRegistry()
        let prompt = registry.formatSkillsForPrompt()
        XCTAssertTrue(prompt.isEmpty,
            "formatSkillsForPrompt() should return empty string when no skills registered")
    }

    // MARK: - AC#4: SkillTool execution success path

    // [P0] SkillRegistry.find() returns a registered skill by name
    func testSkillRegistryFindsRegisteredSkill() {
        let registry = SkillRegistry()
        registry.register(BuiltInSkills.commit)

        let skill = registry.find("commit")
        XCTAssertNotNil(skill, "Should find 'commit' skill by name")
        XCTAssertEqual(skill?.name, "commit")
        XCTAssertEqual(skill?.promptTemplate.isEmpty, false,
            "commit skill should have a non-empty promptTemplate")
    }

    // [P0] SkillRegistry.find() resolves skills by alias
    func testSkillRegistryFindsSkillByAlias() {
        let registry = SkillRegistry()
        registry.register(BuiltInSkills.commit)

        let skill = registry.find("ci")
        XCTAssertNotNil(skill, "Should find 'commit' skill by alias 'ci'")
        XCTAssertEqual(skill?.name, "commit")
    }

    // [P0] Registered skill has correct tool restrictions
    func testRegisteredSkillHasToolRestrictions() {
        let registry = SkillRegistry()
        registry.register(BuiltInSkills.commit)

        let skill = registry.find("commit")
        XCTAssertNotNil(skill?.toolRestrictions,
            "commit skill should have tool restrictions")
        let restrictionNames = skill?.toolRestrictions?.map(\.rawValue) ?? []
        XCTAssertTrue(restrictionNames.contains("bash"),
            "commit skill should allow 'bash' tool")
        XCTAssertTrue(restrictionNames.contains("read"),
            "commit skill should allow 'read' tool")
    }

    // MARK: - AC#5: SkillTool execution failure path

    // [P0] SkillRegistry.find() returns nil for non-existent skill
    func testSkillRegistryReturnsNilForNonExistentSkill() {
        let registry = SkillRegistry()
        registry.register(BuiltInSkills.commit)

        let skill = registry.find("nonexistent")
        XCTAssertNil(skill, "Should return nil for unregistered skill name")
    }

    // [P0] SkillRegistry.has() returns false for non-existent skill
    func testSkillRegistryHasReturnsFalseForMissingSkill() {
        let registry = SkillRegistry()
        XCTAssertFalse(registry.has("nonexistent"),
            "has() should return false for unregistered skill")
    }

    // [P1] SkillRegistry handles empty registry lookups gracefully
    func testSkillRegistryHandlesEmptyRegistry() {
        let registry = SkillRegistry()

        XCTAssertNil(registry.find("commit"),
            "Empty registry should return nil for any lookup")
        XCTAssertTrue(registry.allSkills.isEmpty,
            "Empty registry should have empty allSkills")
        XCTAssertTrue(registry.userInvocableSkills.isEmpty,
            "Empty registry should have empty userInvocableSkills")
    }

    // MARK: - AC#6: BuiltInSkills coexistence

    // [P0] All five BuiltInSkills are registered after configure()
    func testAllBuiltInSkillsRegistered() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: nil,
            sessionId: UUID().uuidString
        )

        let skills = bridge.discoveredSkills
        let skillNames = Set(skills.map { $0.name })

        XCTAssertTrue(skillNames.contains("commit"),
            "BuiltInSkills.commit should be registered")
        XCTAssertTrue(skillNames.contains("review"),
            "BuiltInSkills.review should be registered")
        XCTAssertTrue(skillNames.contains("simplify"),
            "BuiltInSkills.simplify should be registered")
        XCTAssertTrue(skillNames.contains("debug"),
            "BuiltInSkills.debug should be registered")
        XCTAssertTrue(skillNames.contains("test"),
            "BuiltInSkills.test should be registered")
    }

    // [P0] BuiltInSkills have correct userInvocable flag
    func testBuiltInSkillsAreUserInvocable() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: nil,
            sessionId: UUID().uuidString
        )

        for skill in bridge.discoveredSkills {
            XCTAssertTrue(skill.userInvocable,
                "BuiltIn skill '\(skill.name)' should be userInvocable")
        }
    }

    // [P1] BuiltInSkills are all user-invocable (direct registry test)
    // Note: BuiltInSkills.test has conditional isAvailable() that checks for test framework
    // indicators in CWD. In the xcodebuild test runner environment, CWD may not contain
    // these indicators, so userInvocableSkills may exclude it. We verify via allSkills instead.
    func testBuiltInSkillsDirectUserInvocable() {
        let registry = SkillRegistry()
        registry.register(BuiltInSkills.commit)
        registry.register(BuiltInSkills.review)
        registry.register(BuiltInSkills.simplify)
        registry.register(BuiltInSkills.debug)
        registry.register(BuiltInSkills.test)

        let allRegistered = registry.allSkills
        XCTAssertEqual(allRegistered.count, 5,
            "All 5 BuiltInSkills should be registered")

        let invocable = registry.userInvocableSkills
        XCTAssertGreaterThanOrEqual(invocable.count, 4,
            "At least 4 BuiltInSkills should be user-invocable (test may be conditionally available)")
        for skill in invocable {
            XCTAssertTrue(skill.userInvocable,
                "Each returned skill should be user-invocable: \(skill.name)")
        }
    }

    // [P1] Custom skill coexists with BuiltInSkills in registry
    func testCustomSkillCoexistsWithBuiltInSkills() {
        let registry = SkillRegistry()
        registry.register(BuiltInSkills.commit)
        registry.register(BuiltInSkills.review)

        let customSkill = Skill(
            name: "my-custom-skill",
            description: "A custom skill",
            promptTemplate: "Do something custom"
        )
        registry.register(customSkill)

        XCTAssertEqual(registry.allSkills.count, 3,
            "Registry should contain 2 BuiltInSkills + 1 custom skill")
        XCTAssertNotNil(registry.find("my-custom-skill"),
            "Custom skill should be findable alongside BuiltInSkills")
        XCTAssertNotNil(registry.find("commit"),
            "BuiltInSkills should still be findable after custom skill registration")
    }

    // MARK: - AC#7: UI-layer skill list exposure

    // [P0] AgentBridge exposes discoveredSkills computed property
    func testAgentBridgeExposesDiscoveredSkills() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: nil,
            sessionId: UUID().uuidString
        )

        // discoveredSkills should be a [Skill] array
        let skills: [Skill] = bridge.discoveredSkills
        XCTAssertFalse(skills.isEmpty,
            "discoveredSkills should not be empty after configure()")
    }

    // [P0] discoveredSkills reflects current registry state (not stale)
    func testDiscoveredSkillsReflectsCurrentState() {
        let bridge = makeBridge()
        // Before configure, discoveredSkills should be empty
        XCTAssertTrue(bridge.discoveredSkills.isEmpty,
            "discoveredSkills should be empty before configure()")

        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: nil,
            sessionId: UUID().uuidString
        )

        XCTAssertFalse(bridge.discoveredSkills.isEmpty,
            "discoveredSkills should be populated after configure()")
    }

    // [P1] discoveredSkills only returns user-invocable, available skills
    func testDiscoveredSkillsFiltersToUserInvocable() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: nil,
            sessionId: UUID().uuidString
        )

        // All discovered skills should be user-invocable
        for skill in bridge.discoveredSkills {
            XCTAssertTrue(skill.userInvocable,
                "discoveredSkills should only contain user-invocable skills, found non-invocable: \(skill.name)")
        }
    }

    // MARK: - Regression: existing AgentBridge behavior preserved

    // [P0] configure() with skill discovery does not break existing event handling
    func testConfigureWithSkillsDoesNotBreakEventHandling() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: nil,
            sessionId: UUID().uuidString
        )

        // Existing properties should still work
        XCTAssertTrue(bridge.events.isEmpty,
            "events should start empty after configure()")
        XCTAssertFalse(bridge.isRunning,
            "isRunning should be false after configure()")
        XCTAssertNil(bridge.errorMessage,
            "errorMessage should be nil after configure()")
    }

    // [P0] clearEvents does not remove skill registry
    func testClearEventsDoesNotRemoveSkillRegistry() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: nil,
            sessionId: UUID().uuidString
        )
        let initialSkillCount = bridge.discoveredSkills.count
        XCTAssertGreaterThan(initialSkillCount, 0)

        bridge.cancelExecution() // adds an event
        bridge.clearEvents()

        XCTAssertTrue(bridge.events.isEmpty,
            "Events should be cleared")
        XCTAssertEqual(bridge.discoveredSkills.count, initialSkillCount,
            "Skill registry should survive clearEvents()")
    }

    // [P1] Re-configuring replaces skill registry
    func testReconfigureRefreshesSkillRegistry() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "key1",
            baseURL: nil,
            model: "model1",
            workspacePath: nil,
            sessionId: UUID().uuidString
        )
        let firstCount = bridge.discoveredSkills.count

        bridge.configure(
            apiKey: "key2",
            baseURL: nil,
            model: "model2",
            workspacePath: nil,
            sessionId: UUID().uuidString
        )
        let secondCount = bridge.discoveredSkills.count

        XCTAssertEqual(firstCount, secondCount,
            "Re-configure should produce same BuiltInSkills count")
    }
}
