import XCTest
@testable import SwiftWork
import SwiftData

// ATDD Red Phase — Story 6.2: MCP 添加与编辑弹窗
// Unit tests for AddMCPServerViewModel, MCPTransportMode, and command parsing logic.
// These tests assert EXPECTED behavior. They will FAIL until the ViewModel is implemented.
//
// Coverage:
//   AC1 — AddMCPServerSheet 弹窗组件（ViewModel 状态管理）
//   AC2 — Remote 类型配置（SSE/HTTP）
//   AC3 — Local 类型配置（stdio + command 解析）
//   AC4 — 编辑已有配置（replace + 热更新触发）
//   AC5 — 输入验证（空名称、空 URL、空 Command）

// MARK: - MCPTransportMode Tests (AC1)

final class MCPTransportModeTests: XCTestCase {

    // [P0] MCPTransportMode has exactly two cases: remote and local
    func testTransportModeHasTwoCases() {
        let modes: [MCPTransportMode] = [.remote, .local]
        XCTAssertEqual(modes.count, 2, "MCPTransportMode should have exactly 2 cases: remote, local")
    }

    // [P0] MCPTransportMode rawValues match expected strings
    func testTransportModeRawValues() {
        XCTAssertEqual(MCPTransportMode.remote.rawValue, "remote")
        XCTAssertEqual(MCPTransportMode.local.rawValue, "local")
    }

    // [P0] MCPTransportMode is CaseIterable
    func testTransportModeIsCaseIterable() {
        XCTAssertEqual(MCPTransportMode.allCases.count, 2)
    }
}

// MARK: - AddMCPServerViewModel Tests

@MainActor
final class AddMCPServerViewModelTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeViewModel() -> AddMCPServerViewModel {
        AddMCPServerViewModel()
    }

    private func makeContext() throws -> (ModelContainer, ModelContext) {
        let schema = Schema([
            MCPServerConfig.self as any PersistentModel.Type
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)
        return (container, context)
    }

    private func makeStore(context: ModelContext) -> MCPServerConfigStore {
        MCPServerConfigStore(modelContext: context)
    }

    private func encodeArgs(_ args: [String]) -> Data? {
        try? JSONEncoder().encode(args)
    }

    // MARK: - AC1: AddMCPServerSheet ViewModel 初始状态

    // [P0] ViewModel initializes with empty name
    func testViewModelInitializesWithEmptyName() {
        let viewModel = makeViewModel()
        XCTAssertTrue(viewModel.name.isEmpty, "name should be empty on init")
    }

    // [P0] ViewModel initializes with remote transport mode
    func testViewModelInitializesWithRemoteMode() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.transportMode, .remote, "Default transport mode should be remote")
    }

    // [P0] ViewModel initializes with empty URL
    func testViewModelInitializesWithEmptyURL() {
        let viewModel = makeViewModel()
        XCTAssertTrue(viewModel.url.isEmpty, "url should be empty on init")
    }

    // [P0] ViewModel initializes with empty command
    func testViewModelInitializesWithEmptyCommand() {
        let viewModel = makeViewModel()
        XCTAssertTrue(viewModel.command.isEmpty, "command should be empty on init")
    }

    // [P0] ViewModel initializes with no error message
    func testViewModelInitializesWithNoError() {
        let viewModel = makeViewModel()
        XCTAssertNil(viewModel.errorMessage, "errorMessage should be nil on init")
    }

    // [P0] ViewModel initializes with isSubmitting false
    func testViewModelInitializesNotSubmitting() {
        let viewModel = makeViewModel()
        XCTAssertFalse(viewModel.isSubmitting, "isSubmitting should be false on init")
    }

    // MARK: - AC5: 输入验证

    // [P0] isValid is false when name is empty (Remote mode)
    func testValidationFailsWhenNameIsEmptyRemoteMode() {
        let viewModel = makeViewModel()
        viewModel.name = ""
        viewModel.transportMode = .remote
        viewModel.url = "http://example.com/sse"
        XCTAssertFalse(viewModel.isValid, "Should be invalid with empty name in Remote mode")
    }

    // [P0] isValid is false when name is whitespace only
    func testValidationFailsWhenNameIsWhitespace() {
        let viewModel = makeViewModel()
        viewModel.name = "   "
        viewModel.transportMode = .remote
        viewModel.url = "http://example.com/sse"
        XCTAssertFalse(viewModel.isValid, "Should be invalid with whitespace-only name")
    }

    // [P0] isValid is false when URL is empty (Remote mode)
    func testValidationFailsWhenURLEmptyInRemoteMode() {
        let viewModel = makeViewModel()
        viewModel.name = "my-server"
        viewModel.transportMode = .remote
        viewModel.url = ""
        XCTAssertFalse(viewModel.isValid, "Should be invalid with empty URL in Remote mode")
    }

    // [P0] isValid is false when URL is whitespace only (Remote mode)
    func testValidationFailsWhenURLIsWhitespaceInRemoteMode() {
        let viewModel = makeViewModel()
        viewModel.name = "my-server"
        viewModel.transportMode = .remote
        viewModel.url = "   "
        XCTAssertFalse(viewModel.isValid, "Should be invalid with whitespace-only URL in Remote mode")
    }

    // [P0] isValid is false when command is empty (Local mode)
    func testValidationFailsWhenCommandEmptyInLocalMode() {
        let viewModel = makeViewModel()
        viewModel.name = "my-server"
        viewModel.transportMode = .local
        viewModel.command = ""
        XCTAssertFalse(viewModel.isValid, "Should be invalid with empty command in Local mode")
    }

    // [P0] isValid is false when command is whitespace only (Local mode)
    func testValidationFailsWhenCommandIsWhitespaceInLocalMode() {
        let viewModel = makeViewModel()
        viewModel.name = "my-server"
        viewModel.transportMode = .local
        viewModel.command = "   "
        XCTAssertFalse(viewModel.isValid, "Should be invalid with whitespace-only command in Local mode")
    }

    // [P0] isValid is true when name and URL are provided (Remote mode)
    func testValidationPassesWithValidRemoteConfig() {
        let viewModel = makeViewModel()
        viewModel.name = "my-server"
        viewModel.transportMode = .remote
        viewModel.url = "http://example.com/sse"
        XCTAssertTrue(viewModel.isValid, "Should be valid with name and URL in Remote mode")
    }

    // [P0] isValid is true when name and command are provided (Local mode)
    func testValidationPassesWithValidLocalConfig() {
        let viewModel = makeViewModel()
        viewModel.name = "my-server"
        viewModel.transportMode = .local
        viewModel.command = "npx -y @modelcontextprotocol/server-filesystem /tmp"
        XCTAssertTrue(viewModel.isValid, "Should be valid with name and command in Local mode")
    }

    // [P1] validate() returns false and sets errorMessage for invalid input
    func testValidateSetsErrorMessageForInvalidInput() {
        let viewModel = makeViewModel()
        viewModel.name = ""
        let result = viewModel.validate()
        XCTAssertFalse(result, "validate() should return false for invalid input")
        XCTAssertNotNil(viewModel.errorMessage, "errorMessage should be set after validate() fails")
    }

    // [P1] validate() returns true and clears errorMessage for valid input
    func testValidateClearsErrorMessageForValidInput() {
        let viewModel = makeViewModel()
        viewModel.name = "my-server"
        viewModel.transportMode = .remote
        viewModel.url = "http://example.com/sse"
        viewModel.errorMessage = "Previous error"
        let result = viewModel.validate()
        XCTAssertTrue(result, "validate() should return true for valid input")
        XCTAssertNil(viewModel.errorMessage, "errorMessage should be nil after validate() succeeds")
    }

    // MARK: - AC2: Remote 类型配置（SSE）

    // [P0] Submit remote config creates SSE config via store.add()
    func testSubmitRemoteConfigCreatesSSEConfig() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel()

        viewModel.name = "remote-sse-server"
        viewModel.transportMode = .remote
        viewModel.url = "http://localhost:3000/sse"

        let config = try viewModel.submit(
            store: store,
            scope: .global,
            workspacePath: nil
        )

        XCTAssertEqual(config.name, "remote-sse-server")
        XCTAssertEqual(config.transportType, .sse)
        XCTAssertEqual(config.url, "http://localhost:3000/sse")
        XCTAssertNil(config.command)
    }

    // [P1] Submit remote config saves to SwiftData
    func testSubmitRemoteConfigPersistsToSwiftData() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel()

        viewModel.name = "persistent-remote"
        viewModel.transportMode = .remote
        viewModel.url = "http://mcp.example.com/sse"

        _ = try viewModel.submit(store: store, scope: .global, workspacePath: nil)

        let configs = try store.list()
        XCTAssertEqual(configs.count, 1, "Config should be persisted in SwiftData")
        XCTAssertEqual(configs.first?.name, "persistent-remote")
        XCTAssertEqual(configs.first?.transportType, .sse)
    }

    // [P1] Submit remote config with project scope
    func testSubmitRemoteConfigWithProjectScope() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel()

        viewModel.name = "project-remote"
        viewModel.transportMode = .remote
        viewModel.url = "http://localhost:4000/sse"

        let config = try viewModel.submit(
            store: store,
            scope: .project,
            workspacePath: "/Users/test/my-project"
        )

        XCTAssertEqual(config.scope, .project)
        XCTAssertEqual(config.workspacePath, "/Users/test/my-project")
    }

    // MARK: - AC3: Local 类型配置（stdio + command 解析）

    // [P0] Submit local config creates stdio config with parsed command
    func testSubmitLocalConfigCreatesStdioConfig() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel()

        viewModel.name = "local-stdio-server"
        viewModel.transportMode = .local
        viewModel.command = "npx -y @modelcontextprotocol/server-filesystem /tmp"

        let config = try viewModel.submit(
            store: store,
            scope: .global,
            workspacePath: nil
        )

        XCTAssertEqual(config.name, "local-stdio-server")
        XCTAssertEqual(config.transportType, .stdio)
        XCTAssertEqual(config.command, "npx")
        XCTAssertNotNil(config.args)

        let decodedArgs = config.decodedArgs
        XCTAssertEqual(decodedArgs, ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"])
    }

    // [P0] Command parsing extracts command as first token
    func testCommandParsingExtractsFirstTokenAsCommand() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel()

        viewModel.name = "parsed-cmd"
        viewModel.transportMode = .local
        viewModel.command = "python3 /scripts/mcp-server.py --port 8080"

        let config = try viewModel.submit(store: store, scope: .global, workspacePath: nil)

        XCTAssertEqual(config.command, "python3")
        XCTAssertEqual(config.decodedArgs, ["/scripts/mcp-server.py", "--port", "8080"])
    }

    // [P1] Command with no args produces empty args array
    func testCommandWithNoArgsProducesEmptyArgs() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel()

        viewModel.name = "no-args-cmd"
        viewModel.transportMode = .local
        viewModel.command = "mcp-server"

        let config = try viewModel.submit(store: store, scope: .global, workspacePath: nil)

        XCTAssertEqual(config.command, "mcp-server")
        // Args should be nil or empty
        XCTAssertTrue(config.decodedArgs == nil || config.decodedArgs?.isEmpty == true)
    }

    // [P1] Local config with project scope
    func testSubmitLocalConfigWithProjectScope() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let viewModel = makeViewModel()

        viewModel.name = "project-local"
        viewModel.transportMode = .local
        viewModel.command = "npx -y some-mcp-server"

        let config = try viewModel.submit(
            store: store,
            scope: .project,
            workspacePath: "/Users/test/workspace"
        )

        XCTAssertEqual(config.scope, .project)
        XCTAssertEqual(config.workspacePath, "/Users/test/workspace")
    }

    // MARK: - AC4: 编辑已有配置

    // [P0] Edit mode pre-fills ViewModel with existing config data
    func testEditModePreFillsViewModelWithExistingConfig() {
        let viewModel = makeViewModel()

        let existingConfig = MCPServerConfig(
            name: "existing-server",
            transportType: .sse,
            command: nil,
            url: "http://existing.example.com/sse",
            args: nil,
            env: nil,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )

        viewModel.populateFromConfig(existingConfig)

        XCTAssertEqual(viewModel.name, "existing-server")
        XCTAssertEqual(viewModel.transportMode, .remote)
        XCTAssertEqual(viewModel.url, "http://existing.example.com/sse")
    }

    // [P0] Edit mode pre-fills ViewModel with existing stdio config
    func testEditModePreFillsViewModelWithExistingStdioConfig() {
        let viewModel = makeViewModel()

        let args = ["-y", "mcp-server"]
        let argsData = try? JSONEncoder().encode(args)
        let existingConfig = MCPServerConfig(
            name: "existing-stdio",
            transportType: .stdio,
            command: "npx",
            url: nil,
            args: argsData,
            env: nil,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )

        viewModel.populateFromConfig(existingConfig)

        XCTAssertEqual(viewModel.name, "existing-stdio")
        XCTAssertEqual(viewModel.transportMode, .local)
        // Command should be reconstructed from command + args
        XCTAssertEqual(viewModel.command, "npx -y mcp-server")
    }

    // [P0] Submit edit calls store.replace() with updated values
    func testSubmitEditCallsStoreReplace() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        // Create initial config
        let original = try store.add(
            name: "original-server",
            transportType: .sse,
            command: nil,
            url: "http://original.example.com/sse",
            args: nil,
            env: nil,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )

        let viewModel = makeViewModel()
        viewModel.populateFromConfig(original)
        viewModel.name = "updated-server"
        viewModel.url = "http://updated.example.com/sse"

        let updated = try viewModel.submitEdit(
            originalConfig: original,
            store: store,
            scope: .global,
            workspacePath: nil
        )

        XCTAssertEqual(updated.name, "updated-server")
        XCTAssertEqual(updated.url, "http://updated.example.com/sse")
    }

    // [P1] Edit preserves config ID
    func testEditPreservesConfigID() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        let original = try store.add(
            name: "id-preserve-test",
            transportType: .sse,
            command: nil,
            url: "http://test.example.com",
            args: nil,
            env: nil,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )
        let originalID = original.id

        let viewModel = makeViewModel()
        viewModel.populateFromConfig(original)
        viewModel.url = "http://new.example.com"

        let updated = try viewModel.submitEdit(
            originalConfig: original,
            store: store,
            scope: .global,
            workspacePath: nil
        )

        XCTAssertEqual(updated.id, originalID, "Edit should preserve the config ID")
    }

    // [P1] Edit updates updatedAt timestamp
    func testEditUpdatesTimestamp() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        let original = try store.add(
            name: "timestamp-test",
            transportType: .stdio,
            command: "cmd",
            url: nil,
            args: nil,
            env: nil,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )
        let originalUpdatedAt = original.updatedAt

        // Small delay to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)

        let viewModel = makeViewModel()
        viewModel.populateFromConfig(original)
        viewModel.command = "new-cmd"

        let updated = try viewModel.submitEdit(
            originalConfig: original,
            store: store,
            scope: .global,
            workspacePath: nil
        )

        XCTAssertGreaterThanOrEqual(updated.updatedAt, originalUpdatedAt, "updatedAt should be updated on edit")
    }

    // MARK: - AC5: 重复名称错误处理

    // [P0] Submit with duplicate name sets errorMessage
    func testSubmitWithDuplicateNameSetsErrorMessage() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        // Add first config
        _ = try store.add(
            name: "duplicate-name",
            transportType: .sse,
            command: nil,
            url: "http://first.example.com",
            args: nil,
            env: nil,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )

        // Try to add duplicate
        let viewModel = makeViewModel()
        viewModel.name = "duplicate-name"
        viewModel.transportMode = .remote
        viewModel.url = "http://second.example.com"

        XCTAssertThrowsError(
            try viewModel.submit(store: store, scope: .global, workspacePath: nil),
            "Submitting duplicate name should throw"
        )
    }

    // [P1] Error message contains the duplicate name
    func testDuplicateNameErrorMessageContainsName() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        _ = try store.add(
            name: "unique-conflict",
            transportType: .sse,
            command: nil,
            url: "http://first.example.com",
            args: nil,
            env: nil,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )

        let viewModel = makeViewModel()
        viewModel.name = "unique-conflict"
        viewModel.transportMode = .remote
        viewModel.url = "http://second.example.com"

        do {
            _ = try viewModel.submit(store: store, scope: .global, workspacePath: nil)
            XCTFail("Should have thrown duplicate name error")
        } catch let error as MCPServerConfigError {
            if case .duplicateName(let name) = error {
                XCTAssertEqual(name, "unique-conflict", "Error should contain the duplicate name")
            } else {
                XCTFail("Wrong error type")
            }
        }
    }

    // MARK: - Reset

    // [P1] reset() clears all form state
    func testResetClearsAllFormState() {
        let viewModel = makeViewModel()
        viewModel.name = "some-name"
        viewModel.transportMode = .local
        viewModel.url = "http://example.com"
        viewModel.command = "npx something"
        viewModel.errorMessage = "Some error"

        viewModel.reset()

        XCTAssertTrue(viewModel.name.isEmpty)
        XCTAssertEqual(viewModel.transportMode, .remote)
        XCTAssertTrue(viewModel.url.isEmpty)
        XCTAssertTrue(viewModel.command.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isSubmitting)
    }
}
