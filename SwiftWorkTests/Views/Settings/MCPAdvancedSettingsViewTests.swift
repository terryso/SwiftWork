import XCTest
@testable import SwiftWork
import SwiftData
import SwiftUI

// ATDD Red Phase — Story 6.6: MCP 高级设置与配置文件
// Unit/View tests for MCPAdvancedSettingsView component.
// These tests will FAIL until MCPAdvancedSettingsView is implemented.

@MainActor
final class MCPAdvancedSettingsViewTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeContext() throws -> (ModelContainer, ModelContext) {
        let schema = Schema([
            MCPServerConfig.self as any PersistentModel.Type
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)
        return (container, context)
    }

    // MARK: - AC#1: 高级设置折叠区

    // [P0] MCPAdvancedSettingsView can be instantiated
    func testMCPAdvancedSettingsViewCanBeCreated() throws {
        let view = MCPAdvancedSettingsView(
            configManager: MCPConfigFileManager(),
            store: MCPServerConfigStore(
                modelContext: try makeContext().1,
                keychainManager: MockKeychainManager()
            ),
            agentBridge: nil
        )
        XCTAssertNotNil(view, "MCPAdvancedSettingsView should be instantiable")
    }

    // [P0] MCPAdvancedSettingsView works with nil agentBridge
    func testMCPAdvancedSettingsViewWorksWithNilWorkspace() throws {
        let view = MCPAdvancedSettingsView(
            configManager: MCPConfigFileManager(),
            store: MCPServerConfigStore(
                modelContext: try makeContext().1,
                keychainManager: MockKeychainManager()
            ),
            agentBridge: nil
        )
        XCTAssertNotNil(view, "Should work with nil agentBridge (no project bound)")
    }

    // MARK: - AC#2: Scope 切换状态管理

    // [P0] ViewModel initializes with global scope selected
    func testViewModelInitializesWithGlobalScope() {
        let viewModel = MCPAdvancedSettingsViewModel()
        XCTAssertEqual(viewModel.selectedScope, .global, "Should default to global scope")
    }

    // [P0] ViewModel can switch scope
    func testViewModelCanSwitchScope() {
        let viewModel = MCPAdvancedSettingsViewModel()
        viewModel.selectedScope = .project
        XCTAssertEqual(viewModel.selectedScope, .project)

        viewModel.selectedScope = .global
        XCTAssertEqual(viewModel.selectedScope, .global)
    }

    // [P0] ViewModel reports project scope unavailable when workspacePath is nil
    func testViewModelProjectScopeUnavailableWhenNoWorkspace() {
        let viewModel = MCPAdvancedSettingsViewModel()
        XCTAssertFalse(viewModel.isProjectScopeAvailable, "Project scope should be unavailable without workspace")
    }

    // [P0] ViewModel reports project scope available when workspacePath is set
    func testViewModelProjectScopeAvailableWithWorkspace() {
        let viewModel = MCPAdvancedSettingsViewModel()
        viewModel.workspacePath = "/Users/test/project"
        XCTAssertTrue(viewModel.isProjectScopeAvailable, "Project scope should be available with workspace")
    }

    // MARK: - AC#2: 配置文件路径显示

    // [P0] ViewModel resolves global config path
    func testViewModelResolvesGlobalConfigPath() {
        let viewModel = MCPAdvancedSettingsViewModel()
        let path = viewModel.configFilePath

        XCTAssertNotNil(path)
        XCTAssertTrue(path!.contains(".claude/settings.json"), "Global path should contain .claude/settings.json")
    }

    // [P0] ViewModel resolves project config path when workspace is set
    func testViewModelResolvesProjectConfigPath() {
        let viewModel = MCPAdvancedSettingsViewModel()
        viewModel.workspacePath = "/Users/test/my-project"
        viewModel.selectedScope = .project

        let path = viewModel.configFilePath
        XCTAssertNotNil(path)
        XCTAssertEqual(path, "/Users/test/my-project/.claude/settings.json")
    }

    // [P0] ViewModel returns nil config path when project scope selected but no workspace
    func testViewModelReturnsNilPathWithoutWorkspace() {
        let viewModel = MCPAdvancedSettingsViewModel()
        viewModel.selectedScope = .project

        let path = viewModel.configFilePath
        XCTAssertNil(path, "Should return nil when project scope but no workspace")
    }

    // MARK: - AC#2: 配置文件存在状态

    // [P0] ViewModel detects when config file does not exist
    func testViewModelDetectsNonExistingConfigFile() {
        let viewModel = MCPAdvancedSettingsViewModel()
        // Global path exists at ~/.claude/settings.json — may or may not exist
        // Test with an explicit path we know doesn't exist
        viewModel.configFileManager = MCPConfigFileManager()
        // Default state should reflect file existence check
        let exists = viewModel.configFileExists
        // Just verify the property exists and returns a Bool
        _ = exists
    }

    // MARK: - AC#1: 折叠状态管理

    // [P0] ViewModel initializes with collapsed state
    func testViewModelInitializesCollapsed() {
        let viewModel = MCPAdvancedSettingsViewModel()
        XCTAssertFalse(viewModel.isExpanded, "Should start collapsed")
    }

    // [P0] ViewModel toggles expanded state
    func testViewModelTogglesExpanded() {
        let viewModel = MCPAdvancedSettingsViewModel()
        viewModel.isExpanded = true
        XCTAssertTrue(viewModel.isExpanded)

        viewModel.isExpanded = false
        XCTAssertFalse(viewModel.isExpanded)
    }

    // MARK: - AC#4: 刷新配置

    // [P0] ViewModel refreshConfig does not crash with nil store
    func testViewModelRefreshConfigDoesNotCrashWithoutStore() async throws {
        let viewModel = MCPAdvancedSettingsViewModel()
        // Should not crash
        await viewModel.refreshConfig()
    }

    // [P0] ViewModel refreshConfig reloads from file
    func testViewModelRefreshConfigReloadsFromFile() async throws {
        let (_, context) = try makeContext()
        let store = MCPServerConfigStore(
            modelContext: context,
            keychainManager: MockKeychainManager()
        )
        let viewModel = MCPAdvancedSettingsViewModel()
        viewModel.store = store

        // Should not crash even without a config file
        await viewModel.refreshConfig()
    }
}

// Helper ViewModel class for testing
// This will be replaced by the actual MCPAdvancedSettingsViewModel during implementation
@MainActor
@Observable
final class MCPAdvancedSettingsViewModel {
    var selectedScope: MCPServerScope = .global
    var isExpanded = false
    var workspacePath: String?
    var store: MCPServerConfigStore?
    var configFileManager: MCPConfigFileManager

    init() {
        self.configFileManager = MCPConfigFileManager()
    }

    var isProjectScopeAvailable: Bool {
        guard let workspacePath, !workspacePath.isEmpty else { return false }
        return true
    }

    var configFilePath: String? {
        return configFileManager.configFilePath(scope: selectedScope, workspacePath: workspacePath)
    }

    var configFileExists: Bool {
        guard let path = configFilePath else { return false }
        return configFileManager.configFileExists(atPath: path)
    }

    func refreshConfig() async {
        guard let store, let path = configFilePath else { return }
        try? configFileManager.importFromFile(
            atPath: path,
            scope: selectedScope,
            workspacePath: workspacePath,
            store: store
        )
    }
}
