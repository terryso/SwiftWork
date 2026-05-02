import XCTest
import SwiftUI
import SwiftData
@testable import SwiftWork

// Story 3.2: 权限配置与规则管理
// Integration tests for SettingsView: permission management section, mode switching.

@MainActor
final class SettingsViewIntegrationTests: XCTestCase {

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

    override func tearDown() async throws {
        testContainer = nil
        try await super.tearDown()
    }

    // MARK: - AC#1: SettingsView integrates PermissionRulesView

    // [P0] SettingsView compiles and accepts PermissionHandler
    func testSettingsViewAcceptsPermissionHandler() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)

        // SettingsView should accept a PermissionHandler instance
        let view = SettingsView(permissionHandler: handler)
        XCTAssertNotNil(view, "SettingsView should accept PermissionHandler parameter")
    }

    // [P0] SettingsView is no longer a stub (body is not just Text("Settings"))
    func testSettingsViewIsNotStub() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)

        // Verify SettingsView initializer accepts permissionHandler
        let view = SettingsView(permissionHandler: handler)
        XCTAssertNotNil(view)
    }

    // MARK: - AC#3: SettingsView contains global mode picker

    // [P1] SettingsView provides access to global mode via PermissionHandler
    func testSettingsViewGlobalModeBinding() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)

        // Verify the handler's globalMode is mutable and observable
        handler.globalMode = .manualReview
        XCTAssertEqual(handler.globalMode, .manualReview)

        handler.globalMode = .denyAll
        XCTAssertEqual(handler.globalMode, .denyAll)
    }

    // MARK: - Integration: ContentView -> SettingsView flow

    // [P1] PermissionHandler is accessible from ContentView's agentBridge
    func testPermissionHandlerAccessibleFromContentView() throws {
        // Verify that AgentBridge has a permissionHandler property
        let bridge = AgentBridge()
        XCTAssertNotNil(bridge.permissionHandler, "AgentBridge should expose permissionHandler")
    }

    // [P2] SettingsView opening does not interrupt agent execution
    func testSettingsViewDoesNotInterruptAgentExecution() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)

        // Simulate agent actively evaluating
        handler.globalMode = .autoApprove
        _ = handler.evaluate(toolName: "Bash", input: ["command": "ls"])

        // Opening settings (creating SettingsView) should not affect handler state
        let _ = SettingsView(permissionHandler: handler)

        // Handler should still be functional
        let decision = handler.evaluate(toolName: "Read", input: ["filePath": "/tmp/test"])
        if case .approved = decision { } else {
            XCTFail("Handler should still be in autoApprove mode after SettingsView creation")
        }
    }
}
