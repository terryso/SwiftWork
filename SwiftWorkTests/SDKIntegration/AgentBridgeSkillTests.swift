import XCTest
import OpenAgentSDK
import Observation
@testable import SwiftWork

// ATDD Red Phase -- Story 5.1: SDK Skill Pipeline
// Acceptance tests for AgentBridge skill discovery, BuiltInSkills registration,
// SkillTool execution, and UI-layer skill list exposure.
// These tests assert EXPECTED behavior that does NOT exist yet.
// They WILL FAIL until AgentBridge.configure() is updated to enable skill discovery.

@MainActor
final class AgentBridgeSkillTests: XCTestCase {

    private final class AvailabilityBox: @unchecked Sendable {
        var isAvailable: Bool

        init(isAvailable: Bool) {
            self.isAvailable = isAvailable
        }
    }

    // MARK: - Test Helpers

    private func makeBridge() -> AgentBridge {
        AgentBridge()
    }

    private func makeBridge(sourceDirectories: SkillSourceDirectories) -> AgentBridge {
        AgentBridge(
            skillDirectoryService: SkillDirectoryService(
                sourceDirectories: sourceDirectories,
                skillHubExecutableCandidates: []
            )
        )
    }

    private func makeSourceDirectories(under root: URL) -> SkillSourceDirectories {
        SkillSourceDirectories(
            sharedAgentsConfiguration: root.appendingPathComponent("config-agents").path,
            sharedAgents: root.appendingPathComponent("agents").path,
            claudeCode: root.appendingPathComponent("claude").path,
            codex: root.appendingPathComponent("codex").path,
            swiftWork: root.appendingPathComponent("swiftwork").path
        )
    }

    private func createFilesystemSkill(
        name: String,
        description: String,
        under root: String,
        allowedTools: String? = nil
    ) throws {
        let skillDirectory = URL(fileURLWithPath: root, isDirectory: true)
            .appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: skillDirectory, withIntermediateDirectories: true)
        let manifest = """
        ---
        name: \(name)
        description: \(description)
        \(allowedTools.map { "allowed-tools: \($0)" } ?? "")
        ---
        Execute \(name).
        """
        try Data(manifest.utf8).write(to: skillDirectory.appendingPathComponent("SKILL.md"))
    }

    private var workspacePath: String {
        FileManager.default.currentDirectoryPath
    }

    private func withCurrentDirectory<T>(
        _ path: String,
        perform: () throws -> T
    ) throws -> T {
        let previous = FileManager.default.currentDirectoryPath
        XCTAssertTrue(FileManager.default.changeCurrentDirectoryPath(path))
        defer {
            XCTAssertTrue(FileManager.default.changeCurrentDirectoryPath(previous))
        }
        return try perform()
    }

    private func makeSkill(
        name: String,
        aliases: [String] = [],
        userInvocable: Bool = true,
        toolRestrictions: [ToolRestriction]? = nil,
        available: @escaping @Sendable () -> Bool = { true }
    ) -> Skill {
        Skill(
            name: name,
            description: "Test skill \(name)",
            aliases: aliases,
            userInvocable: userInvocable,
            toolRestrictions: toolRestrictions,
            isAvailable: available,
            promptTemplate: "Template for \(name)"
        )
    }

    private func completedStream() -> AsyncStream<SDKMessage> {
        AsyncStream { continuation in
            continuation.yield(.result(SDKMessage.ResultData(
                subtype: .success,
                text: "done",
                usage: nil,
                numTurns: 0,
                durationMs: 0
            )))
            continuation.finish()
        }
    }

    private func failedStream() -> AsyncStream<SDKMessage> {
        AsyncStream { continuation in
            continuation.yield(.result(SDKMessage.ResultData(
                subtype: .errorDuringExecution,
                text: "",
                usage: nil,
                numTurns: 0,
                durationMs: 0,
                errors: ["Expected test failure"]
            )))
            continuation.finish()
        }
    }

    private func waitForExecutionToFinish(
        _ bridge: AgentBridge,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = ContinuousClock.now.advanced(by: .seconds(1))
        while bridge.isRunning && ContinuousClock.now < deadline {
            try? await _Concurrency.Task.sleep(for: .milliseconds(10))
        }
        XCTAssertFalse(bridge.isRunning, "Execution should finish within the timeout", file: file, line: line)
    }

    // MARK: - AC#1: AgentOptions enables Skill discovery

    // [P0] configure() creates a SkillRegistry and assigns it to AgentOptions
    func testConfigureCreatesSkillRegistry() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: workspacePath,
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
        XCTAssertNil(bridge.activeWorkspaceRoot)
        XCTAssertFalse(
            bridge.discoveredSkills.contains(where: { $0.name == "commit" }),
            "Unbound sessions should not expose workspace-dependent built-in skills"
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
            workspacePath: workspacePath,
            sessionId: UUID().uuidString
        )

        // At minimum, BuiltInSkills should be present even without filesystem skills.
        // The key assertion: the skill discovery pipeline is wired up.
        let skills = bridge.discoveredSkills
        XCTAssertGreaterThanOrEqual(skills.count, 4,
            "Should have built-in workspace skills when a workspace is bound")
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
            workspacePath: workspacePath,
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
            workspacePath: workspacePath,
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
            workspacePath: workspacePath,
            sessionId: UUID().uuidString
        )

        // discoveredSkills should be a [Skill] array
        let skills: [Skill] = bridge.discoveredSkills
        XCTAssertFalse(skills.isEmpty,
            "discoveredSkills should not be empty after configure()")
    }

    // [P0] allRegisteredSkills exposes built-in skills even before configure()
    func testAllRegisteredSkillsExposeBuiltInsBeforeConfigure() {
        let bridge = makeBridge()

        let skillNames = Set(bridge.allRegisteredSkills.map(\.name))

        XCTAssertTrue(skillNames.contains("commit"))
        XCTAssertTrue(skillNames.contains("review"))
        XCTAssertTrue(skillNames.contains("simplify"))
        XCTAssertTrue(skillNames.contains("debug"))
        XCTAssertTrue(skillNames.contains("test"))
    }

    // [P0] allRegisteredSkills keeps workspace-dependent built-ins visible when unbound
    func testAllRegisteredSkillsIncludeWorkspaceBuiltInsWhenWorkspaceUnbound() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: nil,
            sessionId: UUID().uuidString
        )

        let allSkillNames = Set(bridge.allRegisteredSkills.map(\.name))
        let discoveredSkillNames = Set(bridge.discoveredSkills.map(\.name))

        XCTAssertTrue(allSkillNames.contains("commit"),
            "Settings-visible catalog should still include /commit when workspace is unbound")
        XCTAssertTrue(allSkillNames.contains("review"),
            "Settings-visible catalog should still include /review when workspace is unbound")
        XCTAssertFalse(discoveredSkillNames.contains("commit"),
            "Slash autocomplete/runtime registry should still hide workspace-dependent skills when unbound")
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
            workspacePath: workspacePath,
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
            workspacePath: workspacePath,
            sessionId: UUID().uuidString
        )

        // All discovered skills should be user-invocable
        for skill in bridge.discoveredSkills {
            XCTAssertTrue(skill.userInvocable,
                "discoveredSkills should only contain user-invocable skills, found non-invocable: \(skill.name)")
        }
    }

    func testTestSkillAvailabilityUsesWorkspaceRootInsteadOfProcessCWD() throws {
        let fileManager = FileManager.default
        let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let workspaceURL = tempRoot.appendingPathComponent("workspace")
        let sandboxCWDURL = tempRoot.appendingPathComponent("sandbox-cwd")

        try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: sandboxCWDURL, withIntermediateDirectories: true)
        fileManager.createFile(
            atPath: workspaceURL.appendingPathComponent("Package.swift").path,
            contents: Data("".utf8)
        )
        defer { try? fileManager.removeItem(at: tempRoot) }

        try withCurrentDirectory(sandboxCWDURL.path) {
            let bridge = makeBridge()
            bridge.configure(
                apiKey: "test-key",
                baseURL: nil,
                model: "test-model",
                workspacePath: workspaceURL.path,
                sessionId: UUID().uuidString
            )

            XCTAssertTrue(bridge.discoveredSkills.contains(where: { $0.name == "test" }),
                "Test skill should be available when the bound workspace contains Package.swift")
            XCTAssertNotNil(bridge.resolveExplicitSlashSkillInvocation(in: "/test"),
                "Explicit /test should resolve against the bound workspace, not the app process cwd")
            guard case .sentSlashSkill(let invocation) = bridge.sendMessage("/test") else {
                return XCTFail("Expected /test to send successfully when workspace contains Package.swift")
            }
            XCTAssertEqual(invocation.canonicalName, "test")
        }
    }

    func testTestSkillAvailabilityDoesNotLeakFromProcessCWDIntoWorkspace() throws {
        let fileManager = FileManager.default
        let workspaceURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: workspaceURL) }

        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: workspaceURL.path,
            sessionId: UUID().uuidString
        )

        XCTAssertFalse(bridge.discoveredSkills.contains(where: { $0.name == "test" }),
            "Test skill should stay hidden when the bound workspace has no test framework indicators")
        XCTAssertNil(bridge.resolveExplicitSlashSkillInvocation(in: "/test"),
            "Explicit /test should not resolve when the workspace itself has no test framework indicators")
    }

    // MARK: - Regression: existing AgentBridge behavior preserved

    // [P0] configure() with skill discovery does not break existing event handling
    func testConfigureWithSkillsDoesNotBreakEventHandling() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: workspacePath,
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
            workspacePath: workspacePath,
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
            workspacePath: workspacePath,
            sessionId: UUID().uuidString
        )
        let firstCount = bridge.discoveredSkills.count

        bridge.configure(
            apiKey: "key2",
            baseURL: nil,
            model: "model2",
            workspacePath: workspacePath,
            sessionId: UUID().uuidString
        )
        let secondCount = bridge.discoveredSkills.count

        XCTAssertEqual(firstCount, secondCount,
            "Re-configure should produce same BuiltInSkills count")
    }

    func testResolveExplicitSlashSkillInvocationByCanonicalName() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: workspacePath,
            sessionId: UUID().uuidString
        )
        bridge.registerSkill(makeSkill(name: "polyv-live-cli", aliases: ["polyv"]))

        let invocation = bridge.resolveExplicitSlashSkillInvocation(in: "/polyv-live-cli 获取最新5个频道")

        XCTAssertEqual(invocation?.canonicalName, "polyv-live-cli")
        XCTAssertEqual(invocation?.invokedName, "polyv-live-cli")
        XCTAssertEqual(invocation?.args, "获取最新5个频道")
    }

    func testResolveExplicitSlashSkillInvocationByAlias() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: workspacePath,
            sessionId: UUID().uuidString
        )
        bridge.registerSkill(makeSkill(name: "polyv-live-cli", aliases: ["polyv"]))

        let invocation = bridge.resolveExplicitSlashSkillInvocation(in: "/polyv 获取最新5个频道")

        XCTAssertEqual(invocation?.canonicalName, "polyv-live-cli")
        XCTAssertEqual(invocation?.invokedName, "polyv")
        XCTAssertEqual(invocation?.args, "获取最新5个频道")
    }

    func testUnboundSessionRejectsWorkspaceDependentSlashSkill() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: nil,
            sessionId: UUID().uuidString
        )

        let outcome = bridge.sendMessage("/commit")

        guard case .requiresWorkspaceBinding(let invocation) = outcome else {
            return XCTFail("Expected unbound workspace-dependent slash skill to be rejected")
        }
        XCTAssertEqual(invocation.canonicalName, "commit")
        XCTAssertEqual(bridge.errorMessage, "Skill /commit 需要先绑定工作目录。")
    }

    func testExplicitBashOnlySlashSkillUsesDirectStreamWithCanonicalNameAndExactArgs() async {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: workspacePath,
            sessionId: UUID().uuidString
        )
        bridge.registerSkill(makeSkill(
            name: "analytics",
            toolRestrictions: [.bash]
        ))
        let directStreamCalled = expectation(description: "Direct skill stream called")
        var directSkillCalls: [(String, String?)] = []
        bridge.executeSkillStreamHandler = { name, args in
            directSkillCalls.append((name, args))
            directStreamCalled.fulfill()
            return self.completedStream()
        }

        let outcome = bridge.sendMessage("/analytics recent")

        guard case .sentSlashSkill(let invocation) = outcome else {
            return XCTFail("Expected explicit slash invocation to route through slash skill handling")
        }
        XCTAssertEqual(invocation.canonicalName, "analytics")
        XCTAssertEqual(invocation.args, "recent")

        await fulfillment(of: [directStreamCalled], timeout: 1)
        await waitForExecutionToFinish(bridge)

        XCTAssertEqual(directSkillCalls.map(\.0), ["analytics"])
        XCTAssertEqual(directSkillCalls.first?.1, "recent")

        let toolUseEvent = bridge.events.first(where: {
            $0.type == .toolUse && ($0.metadata["toolName"] as? String) == "Skill"
        })
        XCTAssertNotNil(toolUseEvent, "Explicit slash send should emit a Skill toolUse event")

        let toolResultEvent = bridge.events.first(where: { $0.type == .toolResult })
        XCTAssertNotNil(toolResultEvent, "Explicit slash send should emit a Skill toolResult event")
        XCTAssertTrue(toolResultEvent?.content.contains("\"commandName\":\"analytics\"") == true)
    }

    func testExplicitBashOnlySkillAliasUsesDirectStreamWithCanonicalNameAndExactArgs() async {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: workspacePath,
            sessionId: UUID().uuidString
        )
        bridge.registerSkill(makeSkill(
            name: "analytics",
            aliases: ["sls"],
            toolRestrictions: [.bash]
        ))
        let directStreamCalled = expectation(description: "Direct skill stream called through alias")
        var directSkillCalls: [(String, String?)] = []
        bridge.executeSkillStreamHandler = { name, args in
            directSkillCalls.append((name, args))
            directStreamCalled.fulfill()
            return self.completedStream()
        }

        let outcome = bridge.sendMessage("/sls recent 7d")

        guard case .sentSlashSkill(let invocation) = outcome else {
            return XCTFail("Expected alias invocation to route through slash skill handling")
        }
        XCTAssertEqual(invocation.canonicalName, "analytics")
        XCTAssertEqual(invocation.invokedName, "sls")
        XCTAssertEqual(invocation.args, "recent 7d")

        await fulfillment(of: [directStreamCalled], timeout: 1)
        await waitForExecutionToFinish(bridge)

        XCTAssertEqual(directSkillCalls.map(\.0), ["analytics"])
        XCTAssertEqual(directSkillCalls.first?.1, "recent 7d")
    }

    func testExplicitFilesystemBashDeclarationUsesIsolatedLocalToolPool() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgentBridgeRestrictedSkill-\(UUID().uuidString)", isDirectory: true)
        let workspace = root.appendingPathComponent("workspace", isDirectory: true)
        let directories = makeSourceDirectories(under: root.appendingPathComponent("global"))
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        try createFilesystemSkill(
            name: "analytics",
            description: "Analytics",
            under: directories.codex,
            allowedTools: "Bash(uv:*)"
        )
        defer { try? FileManager.default.removeItem(at: root) }

        let bridge = makeBridge(sourceDirectories: directories)
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: workspace.path,
            sessionId: UUID().uuidString
        )
        let isolatedStreamCalled = expectation(description: "Isolated local skill stream called")
        var capturedCall: (name: String, args: String?, tools: [String])?
        bridge.restrictedSkillStreamHandler = { name, args, tools in
            capturedCall = (name, args, tools)
            isolatedStreamCalled.fulfill()
            return self.completedStream()
        }

        let outcome = bridge.sendMessage("/analytics recent 7d")

        guard case .sentSlashSkill = outcome else {
            return XCTFail("Expected explicit filesystem Skill to start")
        }
        await fulfillment(of: [isolatedStreamCalled], timeout: 1)
        await waitForExecutionToFinish(bridge)

        XCTAssertEqual(capturedCall?.name, "analytics")
        XCTAssertEqual(capturedCall?.args, "recent 7d")
        XCTAssertEqual(capturedCall?.tools, ["Bash"],
                       "A Bash-only Skill must not expose ToolSearch or MCP tools")
    }

    func testUnboundFilesystemBashDeclarationRequiresWorkspaceBinding() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgentBridgeUnboundRestrictedSkill-\(UUID().uuidString)", isDirectory: true)
        let directories = makeSourceDirectories(under: root)
        try createFilesystemSkill(
            name: "analytics",
            description: "Analytics",
            under: directories.codex,
            allowedTools: "Bash(uv:*)"
        )
        defer { try? FileManager.default.removeItem(at: root) }

        let bridge = makeBridge(sourceDirectories: directories)
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: nil,
            sessionId: UUID().uuidString
        )

        let outcome = bridge.sendMessage("/analytics")

        guard case .requiresWorkspaceBinding(let invocation) = outcome else {
            return XCTFail("A Bash-only filesystem Skill must not run from an unbound workspace")
        }
        XCTAssertEqual(invocation.canonicalName, "analytics")
        XCTAssertEqual(bridge.errorMessage, "Skill /analytics 需要先绑定工作目录。")
    }

    func testExplicitSkillErrorStreamReleasesQueue() async {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: workspacePath,
            sessionId: UUID().uuidString
        )
        bridge.registerSkill(makeSkill(name: "analytics", toolRestrictions: [.bash]))
        let directStreamCalled = expectation(description: "Direct error skill stream called")
        bridge.executeSkillStreamHandler = { _, _ in
            directStreamCalled.fulfill()
            return self.failedStream()
        }

        _ = bridge.sendMessage("/analytics")

        await fulfillment(of: [directStreamCalled], timeout: 1)
        await waitForExecutionToFinish(bridge)
        XCTAssertTrue(bridge.events.contains(where: { $0.type == .result }),
                      "The direct error result should remain visible in the timeline")
    }

    func testUnknownSlashFallsBackToPlainTextSend() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: workspacePath,
            sessionId: UUID().uuidString
        )

        let outcome = bridge.sendMessage("/unknown do something")

        XCTAssertEqual(outcome, .sentPlainText)
        XCTAssertEqual(bridge.events.first?.type, .userMessage)
        XCTAssertEqual(bridge.events.first?.content, "/unknown do something")
    }

    func testUnavailableSlashSkillIsRejectedBeforeSending() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: workspacePath,
            sessionId: UUID().uuidString
        )
        bridge.registerSkill(makeSkill(name: "polyv-live-cli", aliases: ["polyv"], available: { false }))

        let outcome = bridge.sendMessage("/polyv 获取最新5个频道")

        guard case .rejectedUnavailableSkill(let invocation) = outcome else {
            return XCTFail("Expected unavailable slash skill to be rejected")
        }
        XCTAssertEqual(invocation.canonicalName, "polyv-live-cli")
        XCTAssertTrue(bridge.events.isEmpty, "Rejected slash invocation should not append a user event")
        XCTAssertEqual(bridge.errorMessage, "Skill /polyv-live-cli 当前不可用，未发送消息。")
    }

    func testSlashResolutionIsCaseInsensitive() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: workspacePath,
            sessionId: UUID().uuidString
        )
        bridge.registerSkill(makeSkill(name: "polyv-live-cli", aliases: ["polyv"]))

        let invocation = bridge.resolveExplicitSlashSkillInvocation(in: "/POLYV 获取最新5个频道")

        XCTAssertEqual(invocation?.canonicalName, "polyv-live-cli")
        XCTAssertEqual(invocation?.invokedName, "POLYV")
    }

    func testHiddenSlashSkillFallsBackToPlainText() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: workspacePath,
            sessionId: UUID().uuidString
        )
        bridge.registerSkill(makeSkill(name: "internal-polyv", userInvocable: false))

        let outcome = bridge.sendMessage("/internal-polyv do something")

        XCTAssertEqual(outcome, .sentPlainText)
        XCTAssertEqual(bridge.events.first?.content, "/internal-polyv do something")
    }

    func testRefreshingDiscoveredSkillsReflectsAvailabilityChanges() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: workspacePath,
            sessionId: UUID().uuidString
        )

        let availability = AvailabilityBox(isAvailable: false)
        bridge.registerSkill(makeSkill(name: "polyv-live-cli", available: { availability.isAvailable }))
        XCTAssertFalse(bridge.discoveredSkills.contains(where: { $0.name == "polyv-live-cli" }))

        availability.isAvailable = true
        bridge.refreshDiscoveredSkillsSnapshot()

        XCTAssertTrue(bridge.discoveredSkills.contains(where: { $0.name == "polyv-live-cli" }))
    }

    func testNonSlashTextDoesNotResolveAsSkillInvocation() {
        let bridge = makeBridge()
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: workspacePath,
            sessionId: UUID().uuidString
        )
        bridge.registerSkill(makeSkill(name: "polyv-live-cli", aliases: ["polyv"]))

        XCTAssertNil(bridge.resolveExplicitSlashSkillInvocation(in: "please run /polyv"))
    }

    // MARK: - Global Skill discovery

    func testGlobalCatalogDoesNotChangeAcrossWorkspaceStates() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgentBridgeGlobalStates-\(UUID().uuidString)", isDirectory: true)
        let workspace = root.appendingPathComponent("workspace", isDirectory: true)
        let directories = makeSourceDirectories(under: root)
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        try createFilesystemSkill(name: "global-only", description: "Global", under: directories.codex)
        defer { try? FileManager.default.removeItem(at: root) }

        let states: [SessionWorkspaceState] = [
            .ready(SessionWorkspaceBinding(path: workspace.path, bookmarkData: nil)),
            .unbound,
            .needsRepair(lastKnownPath: root.appendingPathComponent("missing").path),
        ]
        var catalogs: [Set<String>] = []

        for state in states {
            let bridge = makeBridge(sourceDirectories: directories)
            bridge.configure(
                apiKey: "test-key",
                baseURL: nil,
                model: "test-model",
                workspacePath: state.workspacePath,
                sessionId: UUID().uuidString,
                workspaceState: state
            )
            catalogs.append(Set(bridge.allRegisteredSkills.map(\.name)))
        }

        XCTAssertEqual(catalogs[0], catalogs[1])
        XCTAssertEqual(catalogs[1], catalogs[2])
        XCTAssertTrue(catalogs[0].contains("global-only"))
    }

    func testReadyWorkspaceSkillDirectoriesAreNotScanned() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgentBridgeNoWorkspaceScan-\(UUID().uuidString)", isDirectory: true)
        let workspace = root.appendingPathComponent("workspace", isDirectory: true)
        let directories = makeSourceDirectories(under: root.appendingPathComponent("global"))
        try createFilesystemSkill(
            name: "workspace-only",
            description: "Workspace",
            under: workspace.appendingPathComponent(".agents/skills").path
        )
        defer { try? FileManager.default.removeItem(at: root) }

        let bridge = makeBridge(sourceDirectories: directories)
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: workspace.path,
            sessionId: UUID().uuidString
        )

        XCTAssertFalse(bridge.allRegisteredSkills.contains(where: { $0.name == "workspace-only" }))
    }

    func testPublisherSkillIsAvailableToSettingsAndSlashResolution() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgentBridgePublisher-\(UUID().uuidString)", isDirectory: true)
        let directories = makeSourceDirectories(under: root)
        try createFilesystemSkill(
            name: "published",
            description: "Published",
            under: directories.swiftWork + "/@publisher"
        )
        defer { try? FileManager.default.removeItem(at: root) }

        let bridge = makeBridge(sourceDirectories: directories)
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: nil,
            sessionId: UUID().uuidString
        )

        XCTAssertTrue(bridge.allRegisteredSkills.contains(where: { $0.name == "published" }))
        XCTAssertTrue(bridge.discoveredSkills.contains(where: { $0.name == "published" }))
        XCTAssertEqual(
            bridge.resolveExplicitSlashSkillInvocation(in: "/published")?.canonicalName,
            "published"
        )
    }

    func testRefreshReusesRegistryAndRemovesStaleSkills() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgentBridgeRefresh-\(UUID().uuidString)", isDirectory: true)
        let directories = makeSourceDirectories(under: root)
        try createFilesystemSkill(name: "old-skill", description: "Old", under: directories.swiftWork)
        defer { try? FileManager.default.removeItem(at: root) }

        let bridge = makeBridge(sourceDirectories: directories)
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: nil,
            sessionId: UUID().uuidString
        )
        let registryIdentity = bridge.skillRegistryIdentity

        try FileManager.default.removeItem(
            at: URL(fileURLWithPath: directories.swiftWork).appendingPathComponent("old-skill")
        )
        try createFilesystemSkill(name: "new-skill", description: "New", under: directories.swiftWork)
        bridge.refreshDiscoveredSkillsSnapshot()

        XCTAssertEqual(bridge.skillRegistryIdentity, registryIdentity)
        XCTAssertFalse(bridge.allRegisteredSkills.contains(where: { $0.name == "old-skill" }))
        XCTAssertTrue(bridge.allRegisteredSkills.contains(where: { $0.name == "new-skill" }))
        XCTAssertNil(bridge.resolveExplicitSlashSkillInvocation(in: "/old-skill"))
        XCTAssertEqual(
            bridge.resolveExplicitSlashSkillInvocation(in: "/new-skill")?.canonicalName,
            "new-skill"
        )
    }

    func testSkillToolDescriptionRefreshesAfterFilesystemChanges() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgentBridgeLiveSkillTool-\(UUID().uuidString)", isDirectory: true)
        let directories = makeSourceDirectories(under: root)
        try createFilesystemSkill(name: "old-skill", description: "Old", under: directories.swiftWork)
        defer { try? FileManager.default.removeItem(at: root) }

        let bridge = makeBridge(sourceDirectories: directories)
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: workspacePath,
            sessionId: UUID().uuidString
        )
        XCTAssertTrue(bridge.currentSkillToolDescription?.contains("old-skill") == true)

        try FileManager.default.removeItem(
            at: URL(fileURLWithPath: directories.swiftWork).appendingPathComponent("old-skill")
        )
        try createFilesystemSkill(name: "new-skill", description: "New", under: directories.swiftWork)
        bridge.refreshDiscoveredSkillsSnapshot()

        XCTAssertFalse(bridge.currentSkillToolDescription?.contains("old-skill") == true)
        XCTAssertTrue(bridge.currentSkillToolDescription?.contains("new-skill") == true)
    }

    func testSkillToolDescriptionOmitsUnavailableWorkspaceSkills() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgentBridgeAvailableSkillTool-\(UUID().uuidString)", isDirectory: true)
        let directories = makeSourceDirectories(under: root)
        defer { try? FileManager.default.removeItem(at: root) }

        let bridge = makeBridge(sourceDirectories: directories)
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: nil,
            sessionId: UUID().uuidString
        )
        bridge.registerSkill(makeSkill(
            name: "workspace-only",
            toolRestrictions: [.bash]
        ))

        XCTAssertTrue(bridge.allRegisteredSkills.contains(where: { $0.name == "workspace-only" }))
        XCTAssertFalse(bridge.currentSkillToolDescription?.contains("workspace-only") == true)
    }

    func testRegisterBeforeConfigurePreservesBuiltInCatalog() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgentBridgePreconfigureRegistration-\(UUID().uuidString)", isDirectory: true)
        let directories = makeSourceDirectories(under: root)
        defer { try? FileManager.default.removeItem(at: root) }

        let bridge = makeBridge(sourceDirectories: directories)
        bridge.registerSkill(makeSkill(name: "programmatic"))

        let names = Set(bridge.allRegisteredSkills.map(\.name))
        XCTAssertTrue(names.contains("programmatic"))
        XCTAssertTrue(names.contains("commit"))
        XCTAssertTrue(names.contains("review"))
        XCTAssertTrue(names.contains("simplify"))
        XCTAssertTrue(names.contains("debug"))
        XCTAssertTrue(names.contains("test"))
    }

    func testRefreshNotifiesSettingsCatalogObservers() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgentBridgeSettingsObservation-\(UUID().uuidString)", isDirectory: true)
        let directories = makeSourceDirectories(under: root)
        defer { try? FileManager.default.removeItem(at: root) }

        let bridge = makeBridge(sourceDirectories: directories)
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: nil,
            sessionId: UUID().uuidString
        )
        let catalogChanged = expectation(description: "Settings catalog observation fires")
        withObservationTracking {
            _ = bridge.allRegisteredSkills
        } onChange: {
            catalogChanged.fulfill()
        }

        try createFilesystemSkill(name: "new-skill", description: "New", under: directories.swiftWork)
        bridge.refreshDiscoveredSkillsSnapshot()

        wait(for: [catalogChanged], timeout: 1)
        XCTAssertTrue(bridge.allRegisteredSkills.contains(where: { $0.name == "new-skill" }))
    }

    func testResultEventTriggersFilesystemRescan() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgentBridgeTurnRefresh-\(UUID().uuidString)", isDirectory: true)
        let directories = makeSourceDirectories(under: root)
        defer { try? FileManager.default.removeItem(at: root) }

        let bridge = makeBridge(sourceDirectories: directories)
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: nil,
            sessionId: UUID().uuidString
        )
        try createFilesystemSkill(name: "after-turn", description: "After", under: directories.swiftWork)

        _ = bridge.handleStreamMessage(.result(SDKMessage.ResultData(
            subtype: .success,
            text: "done",
            usage: nil,
            numTurns: 1,
            durationMs: 1
        )))

        XCTAssertTrue(bridge.allRegisteredSkills.contains(where: { $0.name == "after-turn" }))
    }

    func testSystemPromptUsesExplicitSwiftWorkInstallDirectory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgentBridgeInstallPrompt-\(UUID().uuidString)", isDirectory: true)
        let directories = makeSourceDirectories(under: root)
        defer { try? FileManager.default.removeItem(at: root) }

        let bridge = makeBridge(sourceDirectories: directories)
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: nil,
            sessionId: UUID().uuidString
        )

        let prompt = bridge.lastConfiguredSystemPrompt ?? ""
        XCTAssertTrue(prompt.contains("skillhub install ... --dir \"\(directories.swiftWork)\""))
        XCTAssertTrue(prompt.contains("Never install to `./skills`"))
    }
}
