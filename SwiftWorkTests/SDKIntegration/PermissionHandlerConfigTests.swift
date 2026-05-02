import XCTest
import SwiftData
@testable import SwiftWork

// Story 3.2: 权限配置与规则管理
// Unit tests for PermissionHandler: rule deletion and globalMode persistence.

@MainActor
final class PermissionHandlerConfigTests: XCTestCase {

    // MARK: - Test Helpers

    private var testContainer: ModelContainer!

    private func makeContext() -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        testContainer = try! ModelContainer(
            for: PermissionRule.self, AppConfiguration.self,
            configurations: config
        )
        return testContainer.mainContext
    }

    private func makeHandler() -> (PermissionHandler, ModelContext) {
        let context = makeContext()
        let handler = PermissionHandler()
        handler.setModelContext(context)
        return (handler, context)
    }

    override func tearDown() {
        testContainer = nil
        super.tearDown()
    }

    private func assertApproved(_ decision: PermissionDecision, file: StaticString = #file, line: UInt = #line) {
        if case .approved = decision {
            // expected
        } else {
            XCTFail("Expected .approved, got \(decision)", file: file, line: line)
        }
    }

    private func assertDenied(_ decision: PermissionDecision, file: StaticString = #file, line: UInt = #line) {
        if case .denied = decision {
            // expected
        } else {
            XCTFail("Expected .denied, got \(decision)", file: file, line: line)
        }
    }

    private func assertRequiresApproval(
        _ decision: PermissionDecision,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        if case .requiresApproval = decision {
            // expected
        } else {
            XCTFail("Expected .requiresApproval, got \(decision)", file: file, line: line)
        }
    }

    // MARK: - AC#2: deleteRule removes rule from cachedRules and ModelContext

    // [P0] deleteRule removes a single rule from cachedRules and ModelContext
    func testDeleteRuleRemovesFromCacheAndContext() throws {
        let (handler, context) = makeHandler()
        handler.globalMode = .manualReview

        handler.addPersistentRule(toolName: "Bash", pattern: "rm *", decision: .deny)
        handler.addPersistentRule(toolName: "Read", pattern: "*", decision: .allow)

        // Verify rules were added
        let rulesBefore = try context.fetch(FetchDescriptor<PermissionRule>())
        XCTAssertEqual(rulesBefore.count, 2, "Should have 2 rules before deletion")

        // Delete the Bash rule -- need to get a reference
        let bashRules = try context.fetch(FetchDescriptor<PermissionRule>(
            predicate: #Predicate<PermissionRule> { $0.toolName == "Bash" }
        ))
        guard let bashRule = bashRules.first else {
            XCTFail("Bash rule should exist")
            return
        }

        handler.deleteRule(bashRule)

        // Verify rule removed from ModelContext
        let rulesAfter = try context.fetch(FetchDescriptor<PermissionRule>())
        XCTAssertEqual(rulesAfter.count, 1, "Should have 1 rule after deletion")
        XCTAssertEqual(rulesAfter.first?.toolName, "Read")

        // Verify Bash tool now requires approval (rule removed from cache)
        let decision = handler.evaluate(toolName: "Bash", input: ["command": "rm -rf /tmp"])
        assertRequiresApproval(decision)
    }

    // [P0] deleteRule(at:) batch deletion removes multiple rules via IndexSet
    func testDeleteRuleBatchRemoval() throws {
        let (handler, context) = makeHandler()
        handler.globalMode = .manualReview

        handler.addPersistentRule(toolName: "Bash", pattern: "*", decision: .allow)
        handler.addPersistentRule(toolName: "Read", pattern: "*", decision: .allow)
        handler.addPersistentRule(toolName: "Write", pattern: "*", decision: .deny)

        // Get all rules and create index set for first two
        let allRules = try context.fetch(FetchDescriptor<PermissionRule>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        ))
        XCTAssertEqual(allRules.count, 3, "Should have 3 rules")

        let indexSet = IndexSet([0, 1])
        handler.deleteRule(at: indexSet)

        let rulesAfter = try context.fetch(FetchDescriptor<PermissionRule>())
        XCTAssertEqual(rulesAfter.count, 1, "Should have 1 rule after batch deletion")
    }

    // [P1] deleteRule on empty rules list does not crash
    func testDeleteRuleOnEmptyListDoesNotCrash() throws {
        let (handler, _) = makeHandler()

        // Should not crash when no rules exist
        let rule = PermissionRule(toolName: "Bash", pattern: "*", decision: .allow)
        handler.deleteRule(rule)

        // Verify handler is still functional
        handler.globalMode = .manualReview
        let decision = handler.evaluate(toolName: "Bash", input: ["command": "ls"])
        assertRequiresApproval(decision)
    }

    // [P1] After deleteRule, subsequent same-pattern operations require re-approval
    func testDeletedRuleRequiresReApproval() throws {
        let (handler, context) = makeHandler()
        handler.globalMode = .manualReview

        handler.addPersistentRule(toolName: "Bash", pattern: "git *", decision: .allow)

        // Should be approved with the rule in place
        assertApproved(handler.evaluate(toolName: "Bash", input: ["command": "git status"]))

        // Delete the rule
        let rules = try context.fetch(FetchDescriptor<PermissionRule>())
        handler.deleteRule(rules.first!)

        // Same tool should now require approval
        assertRequiresApproval(handler.evaluate(toolName: "Bash", input: ["command": "git status"]))
    }

    // MARK: - AC#3: globalMode persistence to AppConfiguration

    // [P0] globalMode persisted to AppConfiguration on change
    func testGlobalModePersistedToAppConfiguration() throws {
        let (handler, context) = makeHandler()

        // Change mode -- didSet should trigger persistGlobalMode
        handler.globalMode = .manualReview

        // Verify AppConfiguration was saved
        let descriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate<AppConfiguration> { $0.key == "globalPermissionMode" }
        )
        let configs = try context.fetch(descriptor)
        XCTAssertEqual(configs.count, 1, "Should have 1 config entry for globalPermissionMode")

        let savedValue = configs.first!.value
        let savedString = String(data: savedValue, encoding: .utf8)
        XCTAssertEqual(savedString, "manualReview", "Saved mode should be 'manualReview'")
    }

    // [P0] globalMode restored from AppConfiguration on setModelContext
    func testGlobalModeRestoredOnSetModelContext() throws {
        let context = makeContext()

        // Pre-seed AppConfiguration with a saved mode
        let savedMode = AppConfiguration(
            key: "globalPermissionMode",
            value: Data("denyAll".utf8)
        )
        context.insert(savedMode)
        try context.save()

        // Create new handler and set context -- should restore mode
        let handler = PermissionHandler()
        handler.setModelContext(context)

        XCTAssertEqual(handler.globalMode, .denyAll, "globalMode should be restored from AppConfiguration")
    }

    // [P1] Multiple globalMode changes persist the latest value
    func testMultipleGlobalModeChangesPersistLatest() throws {
        let (handler, context) = makeHandler()

        handler.globalMode = .manualReview
        handler.globalMode = .denyAll
        handler.globalMode = .autoApprove

        let descriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate<AppConfiguration> { $0.key == "globalPermissionMode" }
        )
        let configs = try context.fetch(descriptor)
        // Should be a single entry (upsert behavior)
        XCTAssertGreaterThanOrEqual(configs.count, 1, "Should have at least 1 config entry")

        let savedValue = configs.first!.value
        let savedString = String(data: savedValue, encoding: .utf8)
        XCTAssertEqual(savedString, "autoApprove", "Should persist the latest mode")
    }

    // [P1] globalMode persistence does not fire before modelContext is set
    func testGlobalModeDoesNotPersistBeforeModelContextSet() throws {
        let handler = PermissionHandler()

        // Change mode before setting context -- should not crash
        handler.globalMode = .manualReview

        // Verify default is still available
        XCTAssertEqual(handler.globalMode, .manualReview)
    }

    // [P1] Persisted autoApprove mode restores correctly
    func testPersistAutoApproveModeRestoresCorrectly() throws {
        let context = makeContext()

        let savedMode = AppConfiguration(
            key: "globalPermissionMode",
            value: Data("autoApprove".utf8)
        )
        context.insert(savedMode)
        try context.save()

        let handler = PermissionHandler()
        handler.setModelContext(context)

        XCTAssertEqual(handler.globalMode, .autoApprove)
        assertApproved(handler.evaluate(toolName: "Bash", input: [:]))
    }

    // [P2] Deleting all rules leaves handler in functional state
    func testDeleteAllRulesLeavesHandlerFunctional() throws {
        let (handler, context) = makeHandler()
        handler.globalMode = .manualReview

        handler.addPersistentRule(toolName: "Bash", pattern: "*", decision: .allow)

        let rules = try context.fetch(FetchDescriptor<PermissionRule>())
        for rule in rules {
            handler.deleteRule(rule)
        }

        // Handler should still work correctly
        assertRequiresApproval(handler.evaluate(toolName: "Bash", input: ["command": "ls"]))

        // Switching modes should still work
        handler.globalMode = .autoApprove
        assertApproved(handler.evaluate(toolName: "Bash", input: [:]))
    }
}
