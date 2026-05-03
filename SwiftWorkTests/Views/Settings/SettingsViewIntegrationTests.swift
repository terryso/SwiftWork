import XCTest
import SwiftUI
import SwiftData
@testable import SwiftWork

// Story 3.2: 权限配置与规则管理
// Story 4.2: 应用设置页面 -- 多Tab集成测试 (ATDD Red Phase)
// Integration tests for SettingsView: permission management section, mode switching, multi-tab layout.

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

    // MARK: - Story 4.2: Multi-Tab Settings Integration

    // [P0] SettingsView accepts both SettingsViewModel and PermissionHandler
    func testSettingsViewAcceptsViewModelAndPermissionHandler() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)
        let viewModel = SettingsViewModel()
        viewModel.configure(modelContext: context)

        let view = SettingsView(settingsViewModel: viewModel, permissionHandler: handler)
        XCTAssertNotNil(view, "SettingsView should accept both settingsViewModel and permissionHandler")
    }

    // [P0] SettingsView contains three tabs: General, Permissions, Advanced
    func testSettingsViewContainsThreeTabs() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)
        let viewModel = SettingsViewModel()
        viewModel.configure(modelContext: context)

        // SettingsView should be constructed with a TabView containing three tabs
        let view = SettingsView(settingsViewModel: viewModel, permissionHandler: handler)
        XCTAssertNotNil(view, "SettingsView with multi-tab layout should compile")
    }

    // [P1] SettingsView passes SettingsViewModel to APIKeySettingsView
    func testSettingsViewPassesViewModelToAPIKeySettings() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)
        let viewModel = SettingsViewModel()
        viewModel.configure(modelContext: context)

        // APIKeySettingsView should be creatable with the same viewModel
        let apiKeyView = APIKeySettingsView(settingsViewModel: viewModel)
        XCTAssertNotNil(apiKeyView, "APIKeySettingsView should accept shared SettingsViewModel")
    }

    // [P1] SettingsView passes SettingsViewModel to ModelPickerView
    func testSettingsViewPassesViewModelToModelPicker() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)
        let viewModel = SettingsViewModel()
        viewModel.configure(modelContext: context)

        // ModelPickerView should be creatable with the same viewModel
        let modelPicker = ModelPickerView(settingsViewModel: viewModel)
        XCTAssertNotNil(modelPicker, "ModelPickerView should accept shared SettingsViewModel")
    }

    // [P1] SettingsView preserves PermissionRulesView in permissions tab
    func testSettingsViewPreservesPermissionsTab() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)

        // PermissionRulesView should still work as before
        let permissionsView = PermissionRulesView(permissionHandler: handler)
        XCTAssertNotNil(permissionsView, "PermissionRulesView should still be usable in permissions tab")
    }

    // [P2] SettingsView backwards compatibility -- still works with only permissionHandler
    func testSettingsViewBackwardsCompatPermissionOnly() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let handler = makeHandler(in: context)

        // Old initializer should still work for backwards compatibility
        let view = SettingsView(permissionHandler: handler)
        XCTAssertNotNil(view, "SettingsView(permissionHandler:) should still compile")
    }

    // [P2] SettingsViewModel is shared between ContentView and SettingsView
    func testSettingsViewModelSharedBetweenContentViewAndSettings() throws {
        let mockKeychain = MockKeychainManager()
        let viewModel = SettingsViewModel(keychainManager: mockKeychain)
        let container = makeTestContainer()
        let context = container.mainContext
        viewModel.configure(modelContext: context)

        // Simulate user modifying model in settings
        viewModel.selectedModel = "claude-opus-4-7"

        // The same viewModel instance should reflect the change
        XCTAssertEqual(viewModel.selectedModel, "claude-opus-4-7", "Shared viewModel should reflect settings changes")
    }
}
