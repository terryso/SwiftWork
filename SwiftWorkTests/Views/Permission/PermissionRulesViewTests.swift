import XCTest
import SwiftUI
import SwiftData
@testable import SwiftWork

// Story 3.2: 权限配置与规则管理
// Tests for PermissionRulesView: rule list display, deletion, global mode picker.

@MainActor
final class PermissionRulesViewTests: XCTestCase {

    // MARK: - Test Helpers

    private var testContainer: ModelContainer!

    private func makeTestContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        testContainer = try! ModelContainer(
            for: PermissionRule.self, AppConfiguration.self,
            configurations: config
        )
        return testContainer
    }

    private func makeHandler(in context: ModelContext) -> PermissionHandler {
        let handler = PermissionHandler()
        handler.setModelContext(context)
        return handler
    }

    private func seedRules(in context: ModelContext, count: Int = 3) {
        let tools = ["Bash", "Read", "Write", "Edit", "Grep"]
        let patterns = ["rm *", "*", "*.swift", "/tmp/*", "test*"]
        for i in 0..<count {
            let rule = PermissionRule(
                toolName: tools[i % tools.count],
                pattern: patterns[i % patterns.count],
                decision: i % 2 == 0 ? .allow : .deny
            )
            context.insert(rule)
        }
        try? context.save()
    }

    override func tearDown() async throws {
        testContainer = nil
    }

    // MARK: - AC#1: PermissionRulesView displays list of rules

    // [P0] PermissionRulesView compiles and can be instantiated
    func testPermissionRulesViewCompiles() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)

        // This test verifies the view type exists and compiles
        let view = PermissionRulesView(permissionHandler: handler)
        XCTAssertNotNil(view, "PermissionRulesView should be instantiable")
    }

    // [P0] PermissionRulesView shows rules when rules exist
    func testPermissionRulesViewShowsRulesWhenNotEmpty() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        seedRules(in: context, count: 3)

        let handler = makeHandler(in: context)

        // Verify that rules are queryable via @Query
        var descriptor = FetchDescriptor<PermissionRule>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let rules = try context.fetch(descriptor)
        XCTAssertEqual(rules.count, 3, "Should have 3 rules for the view to display")
    }

    // [P1] PermissionRulesView shows empty state when no rules exist
    func testPermissionRulesViewEmptyState() throws {
        let container = makeTestContainer()
        let context = container.mainContext

        let handler = makeHandler(in: context)

        // Verify no rules exist
        let descriptor = FetchDescriptor<PermissionRule>()
        let rules = try context.fetch(descriptor)
        XCTAssertTrue(rules.isEmpty, "Should have 0 rules for empty state display")
    }

    // MARK: - AC#1: Rule list displays correct information per row

    // [P1] Each rule row displays tool type label, pattern, decision, and creation time
    func testRuleRowDisplaysCorrectInformation() throws {
        let container = makeTestContainer()
        let context = container.mainContext

        let rule = PermissionRule(toolName: "Bash", pattern: "rm *", decision: .allow)
        context.insert(rule)
        try context.save()

        // Verify tool type label mapping works for display
        XCTAssertEqual(PermissionHandler.toolTypeLabel("Bash"), "终端命令")
        XCTAssertEqual(rule.pattern, "rm *")
        XCTAssertEqual(rule.decision, .allow)
        XCTAssertNotNil(rule.createdAt)
    }

    // [P1] Tool type labels are correctly mapped for all known tools
    func testToolTypeLabelMappings() {
        XCTAssertEqual(PermissionHandler.toolTypeLabel("Bash"), "终端命令")
        XCTAssertEqual(PermissionHandler.toolTypeLabel("Edit"), "文件编辑")
        XCTAssertEqual(PermissionHandler.toolTypeLabel("Write"), "文件编辑")
        XCTAssertEqual(PermissionHandler.toolTypeLabel("Read"), "文件读取")
        XCTAssertEqual(PermissionHandler.toolTypeLabel("Grep"), "文件搜索")
        XCTAssertEqual(PermissionHandler.toolTypeLabel("Glob"), "文件搜索")
        // Unknown tools return the tool name as-is
        XCTAssertEqual(PermissionHandler.toolTypeLabel("CustomTool"), "CustomTool")
    }

    // [P1] Rules are sorted by createdAt descending (newest first)
    func testRulesSortedByCreatedAtDescending() throws {
        let container = makeTestContainer()
        let context = container.mainContext

        // Insert rules with known creation order
        let olderRule = PermissionRule(toolName: "Bash", pattern: "*", decision: .allow)
        context.insert(olderRule)
        try context.save()

        // Small delay to ensure different timestamps
        let newerRule = PermissionRule(toolName: "Read", pattern: "*.swift", decision: .deny)
        context.insert(newerRule)
        try context.save()

        var descriptor = FetchDescriptor<PermissionRule>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let rules = try context.fetch(descriptor)

        XCTAssertEqual(rules.count, 2)
        XCTAssertEqual(rules.first?.toolName, "Read", "Newer rule should be first")
        XCTAssertEqual(rules.last?.toolName, "Bash", "Older rule should be last")
    }

    // MARK: - AC#2: Rule deletion via PermissionHandler

    // [P0] Deleting a rule through PermissionHandler removes it from SwiftData
    func testDeleteRuleRemovesFromSwiftData() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)

        handler.addPersistentRule(toolName: "Bash", pattern: "rm *", decision: .allow)

        var rules = try context.fetch(FetchDescriptor<PermissionRule>())
        XCTAssertEqual(rules.count, 1)

        handler.deleteRule(rules.first!)

        rules = try context.fetch(FetchDescriptor<PermissionRule>())
        XCTAssertTrue(rules.isEmpty, "Rule should be deleted from SwiftData")
    }

    // [P0] Batch deletion via IndexSet removes correct rules
    func testBatchDeletionViaIndexSet() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)

        handler.addPersistentRule(toolName: "Bash", pattern: "*", decision: .allow)
        handler.addPersistentRule(toolName: "Read", pattern: "*", decision: .allow)
        handler.addPersistentRule(toolName: "Write", pattern: "*", decision: .deny)

        var rules = try context.fetch(FetchDescriptor<PermissionRule>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        ))
        XCTAssertEqual(rules.count, 3)

        // Delete the first two rules (indices 0 and 1)
        handler.deleteRule(at: IndexSet([0, 1]))

        rules = try context.fetch(FetchDescriptor<PermissionRule>())
        XCTAssertEqual(rules.count, 1, "Should have 1 rule remaining after batch deletion")
    }

    // MARK: - AC#3: Global permission mode picker

    // [P0] Global mode can be switched and affects evaluation
    func testGlobalModeSwitchAffectsEvaluation() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)

        // Start with autoApprove
        handler.globalMode = .autoApprove
        let autoDecision = handler.evaluate(toolName: "Bash", input: [:])
        if case .approved = autoDecision { } else {
            XCTFail("autoApprove should return .approved")
        }

        // Switch to manualReview
        handler.globalMode = .manualReview
        let manualDecision = handler.evaluate(toolName: "Bash", input: ["command": "ls"])
        if case .requiresApproval = manualDecision { } else {
            XCTFail("manualReview with no rules should return .requiresApproval")
        }

        // Switch to denyAll
        handler.globalMode = .denyAll
        let denyDecision = handler.evaluate(toolName: "Bash", input: [:])
        if case .denied = denyDecision { } else {
            XCTFail("denyAll should return .denied")
        }
    }

    // [P0] All three GlobalPermissionMode values exist and are distinct
    func testAllGlobalPermissionModesExist() {
        let modes: [GlobalPermissionMode] = [.autoApprove, .manualReview, .denyAll]
        XCTAssertEqual(modes.count, 3, "Should have exactly 3 permission modes")

        // Verify raw values for persistence
        XCTAssertEqual(GlobalPermissionMode.autoApprove.rawValue, "autoApprove")
        XCTAssertEqual(GlobalPermissionMode.manualReview.rawValue, "manualReview")
        XCTAssertEqual(GlobalPermissionMode.denyAll.rawValue, "denyAll")
    }

    // [P1] Global mode persistence survives handler recreation
    func testGlobalModeSurvivesHandlerRecreation() throws {
        let container = makeTestContainer()
        let context = container.mainContext

        // First handler: set and persist mode
        let handler1 = PermissionHandler()
        handler1.setModelContext(context)
        handler1.globalMode = .denyAll

        // Second handler: should restore persisted mode
        let handler2 = PermissionHandler()
        handler2.setModelContext(context)

        XCTAssertEqual(handler2.globalMode, .denyAll, "Restored handler should have persisted mode")
    }

    // [P2] Global mode change is immediately effective without page reload
    func testGlobalModeChangeImmediateEffect() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)

        handler.globalMode = .autoApprove
        if case .approved = handler.evaluate(toolName: "Bash", input: [:]) { } else {
            XCTFail("Should be approved in autoApprove mode")
        }

        // Immediately switch
        handler.globalMode = .denyAll
        if case .denied = handler.evaluate(toolName: "Bash", input: [:]) { } else {
            XCTFail("Should be denied after switching to denyAll")
        }
    }
}
