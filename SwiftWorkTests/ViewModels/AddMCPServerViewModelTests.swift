import XCTest
@testable import SwiftWork
import SwiftData

// Unit tests for AddMCPServerViewModel JSON-based input.
//
// Coverage:
//   AC1 — JSON format detection (mcpServers, serverMap, bareConfig)
//   AC2 — Remote type config (SSE) via JSON
//   AC3 — Local type config (stdio) via JSON
//   AC4 — Edit existing config (populateFromConfig + submitEdit)
//   AC5 — Input validation

// MARK: - MCPJSONInputFormat Tests

@MainActor
final class MCPJSONInputFormatTests: XCTestCase {

    // Format 1: mcpServers wrapper
    func testDetectsMcpServersFormat() {
        let vm = AddMCPServerViewModel()
        vm.jsonText = """
        {
          "mcpServers": {
            "my-server": {
              "command": "npx",
              "args": ["-y", "@some/mcp-server"]
            }
          }
        }
        """
        XCTAssertEqual(vm.detectedFormat, .mcpServers)
    }

    // Format 2: bare server map
    func testDetectsServerMapFormat() {
        let vm = AddMCPServerViewModel()
        vm.jsonText = """
        {
          "my-server": {
            "command": "npx",
            "args": ["-y", "@some/mcp-server"]
          }
        }
        """
        XCTAssertEqual(vm.detectedFormat, .serverMap)
    }

    // Format 3: bare single-server config
    func testDetectsBareConfigFormat() {
        let vm = AddMCPServerViewModel()
        vm.jsonText = """
        {
          "command": "npx",
          "args": ["-y", "@some/mcp-server"]
        }
        """
        XCTAssertEqual(vm.detectedFormat, .bareConfig)
    }

    // Invalid: empty string
    func testDetectsInvalidForEmptyString() {
        let vm = AddMCPServerViewModel()
        vm.jsonText = ""
        XCTAssertEqual(vm.detectedFormat, .invalid)
    }

    // Invalid: malformed JSON
    func testDetectsInvalidForMalformedJSON() {
        let vm = AddMCPServerViewModel()
        vm.jsonText = "not json at all"
        XCTAssertEqual(vm.detectedFormat, .invalid)
    }

    // showsNameField is true only for bare config
    func testShowsNameFieldOnlyForBareConfig() {
        let vm = AddMCPServerViewModel()

        vm.jsonText = """
        {"mcpServers": {"a": {"command": "npx"}}}
        """
        XCTAssertFalse(vm.showsNameField)

        vm.jsonText = """
        {"a": {"command": "npx"}}
        """
        XCTAssertFalse(vm.showsNameField)

        vm.jsonText = """
        {"command": "npx"}
        """
        XCTAssertTrue(vm.showsNameField)
    }

    // URL-based config detected as bare config
    func testDetectsBareConfigWithUrl() {
        let vm = AddMCPServerViewModel()
        vm.jsonText = """
        {"url": "http://localhost:3000/sse"}
        """
        XCTAssertEqual(vm.detectedFormat, .bareConfig)
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

    // MARK: - AC1: Initial State

    func testViewModelInitializesWithEmptyJsonText() {
        let vm = makeViewModel()
        XCTAssertTrue(vm.jsonText.isEmpty)
    }

    func testViewModelInitializesWithEmptyServerName() {
        let vm = makeViewModel()
        XCTAssertTrue(vm.serverName.isEmpty)
    }

    func testViewModelInitializesWithNoError() {
        let vm = makeViewModel()
        XCTAssertNil(vm.errorMessage)
    }

    func testViewModelInitializesNotSubmitting() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.isSubmitting)
    }

    // MARK: - AC5: Validation

    func testValidationFailsForEmptyJson() {
        let vm = makeViewModel()
        vm.jsonText = ""
        XCTAssertFalse(vm.isValid)
    }

    func testValidationFailsForInvalidJson() {
        let vm = makeViewModel()
        vm.jsonText = "not json"
        XCTAssertFalse(vm.isValid)
    }

    func testValidationPassesForValidMcpServersFormat() {
        let vm = makeViewModel()
        vm.jsonText = """
        {"mcpServers": {"my-server": {"command": "npx"}}}
        """
        XCTAssertTrue(vm.isValid)
    }

    func testValidationPassesForValidServerMapFormat() {
        let vm = makeViewModel()
        vm.jsonText = """
        {"my-server": {"command": "npx"}}
        """
        XCTAssertTrue(vm.isValid)
    }

    func testValidationFailsForBareConfigWithEmptyName() {
        let vm = makeViewModel()
        vm.jsonText = """
        {"command": "npx"}
        """
        vm.serverName = ""
        XCTAssertFalse(vm.isValid)
    }

    func testValidationPassesForBareConfigWithName() {
        let vm = makeViewModel()
        vm.jsonText = """
        {"command": "npx"}
        """
        vm.serverName = "my-server"
        XCTAssertTrue(vm.isValid)
    }

    func testValidateSetsErrorMessageForInvalidInput() {
        let vm = makeViewModel()
        vm.jsonText = ""
        let result = vm.validate()
        XCTAssertFalse(result)
        XCTAssertNotNil(vm.errorMessage)
    }

    func testValidateClearsErrorMessageForValidInput() {
        let vm = makeViewModel()
        vm.jsonText = """
        {"my-server": {"command": "npx"}}
        """
        vm.errorMessage = "Previous error"
        let result = vm.validate()
        XCTAssertTrue(result)
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - AC2: Remote (SSE) via JSON

    func testSubmitRemoteConfigFromServerMapFormat() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let vm = makeViewModel()

        vm.jsonText = """
        {
          "remote-sse-server": {
            "url": "http://localhost:3000/sse"
          }
        }
        """

        let configs = try vm.submit(store: store, scope: .global, workspacePath: nil)
        XCTAssertEqual(configs.count, 1)
        let config = configs.first!
        XCTAssertEqual(config.name, "remote-sse-server")
        XCTAssertEqual(config.transportType, .sse)
        XCTAssertEqual(config.url, "http://localhost:3000/sse")
        XCTAssertNil(config.command)
    }

    func testSubmitRemoteConfigPersistsToSwiftData() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let vm = makeViewModel()

        vm.jsonText = """
        {
          "persistent-remote": {
            "url": "http://mcp.example.com/sse"
          }
        }
        """

        _ = try vm.submit(store: store, scope: .global, workspacePath: nil)

        let configs = try store.list()
        XCTAssertEqual(configs.count, 1)
        XCTAssertEqual(configs.first?.name, "persistent-remote")
        XCTAssertEqual(configs.first?.transportType, .sse)
    }

    func testSubmitRemoteConfigWithProjectScope() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let vm = makeViewModel()

        vm.jsonText = """
        {
          "project-remote": {
            "url": "http://localhost:4000/sse"
          }
        }
        """

        let configs = try vm.submit(
            store: store,
            scope: .project,
            workspacePath: "/Users/test/my-project"
        )
        let config = configs.first!
        XCTAssertEqual(config.scope, .project)
        XCTAssertEqual(config.workspacePath, "/Users/test/my-project")
    }

    // MARK: - AC3: Local (stdio) via JSON

    func testSubmitLocalConfigFromMcpServersFormat() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let vm = makeViewModel()

        vm.jsonText = """
        {
          "mcpServers": {
            "local-stdio-server": {
              "command": "npx",
              "args": ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"]
            }
          }
        }
        """

        let configs = try vm.submit(store: store, scope: .global, workspacePath: nil)
        XCTAssertEqual(configs.count, 1)
        let config = configs.first!
        XCTAssertEqual(config.name, "local-stdio-server")
        XCTAssertEqual(config.transportType, .stdio)
        XCTAssertEqual(config.command, "npx")
        XCTAssertEqual(config.decodedArgs, ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"])
    }

    func testSubmitLocalConfigFromBareConfigFormat() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let vm = makeViewModel()

        vm.jsonText = """
        {
          "command": "python3",
          "args": ["/scripts/mcp-server.py", "--port", "8080"]
        }
        """
        vm.serverName = "bare-local"

        let configs = try vm.submit(store: store, scope: .global, workspacePath: nil)
        XCTAssertEqual(configs.count, 1)
        let config = configs.first!
        XCTAssertEqual(config.name, "bare-local")
        XCTAssertEqual(config.command, "python3")
        XCTAssertEqual(config.decodedArgs, ["/scripts/mcp-server.py", "--port", "8080"])
    }

    func testSubmitLocalConfigWithNoArgs() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let vm = makeViewModel()

        vm.jsonText = """
        {"mcp-server": {"command": "mcp-server"}}
        """

        let configs = try vm.submit(store: store, scope: .global, workspacePath: nil)
        let config = configs.first!
        XCTAssertEqual(config.command, "mcp-server")
        XCTAssertTrue(config.decodedArgs == nil || config.decodedArgs?.isEmpty == true)
    }

    // MARK: - Multi-server batch add

    func testSubmitMultipleServersFromMcpServersFormat() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let vm = makeViewModel()

        vm.jsonText = """
        {
          "mcpServers": {
            "server-a": {"command": "cmd-a"},
            "server-b": {"url": "http://example.com/sse"}
          }
        }
        """

        let configs = try vm.submit(store: store, scope: .global, workspacePath: nil)
        XCTAssertEqual(configs.count, 2)
        let names = Set(configs.map(\.name))
        XCTAssertEqual(names, ["server-a", "server-b"])
    }

    // MARK: - AC4: Edit

    func testPopulateFromRemoteConfig() {
        let vm = makeViewModel()

        let existing = MCPServerConfig(
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

        vm.populateFromConfig(existing)

        // Should serialize as server map format
        XCTAssertFalse(vm.jsonText.isEmpty, "jsonText should not be empty after populate")
        XCTAssertTrue(vm.jsonText.contains("existing-server"), "jsonText should contain server name, got: \(vm.jsonText)")
        XCTAssertTrue(vm.jsonText.contains("existing.example.com"), "jsonText should contain URL host, got: \(vm.jsonText)")
    }

    func testPopulateFromLocalConfig() {
        let vm = makeViewModel()

        let args = ["-y", "mcp-server"]
        let argsData = try? JSONEncoder().encode(args)
        let existing = MCPServerConfig(
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

        vm.populateFromConfig(existing)

        XCTAssertTrue(vm.jsonText.contains("existing-stdio"))
        XCTAssertTrue(vm.jsonText.contains("npx"))
        XCTAssertTrue(vm.jsonText.contains("mcp-server"))
    }

    func testSubmitEditUpdatesConfig() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

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

        let vm = makeViewModel()
        vm.jsonText = """
        {
          "updated-server": {
            "url": "http://updated.example.com/sse"
          }
        }
        """

        let updated = try vm.submitEdit(
            originalConfig: original,
            store: store,
            scope: .global,
            workspacePath: nil
        )

        XCTAssertEqual(updated.name, "updated-server")
        XCTAssertEqual(updated.url, "http://updated.example.com/sse")
    }

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

        let vm = makeViewModel()
        vm.jsonText = """
        {"id-preserve-test": {"url": "http://new.example.com"}}
        """

        let updated = try vm.submitEdit(
            originalConfig: original,
            store: store,
            scope: .global,
            workspacePath: nil
        )

        XCTAssertEqual(updated.id, originalID)
    }

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

        Thread.sleep(forTimeInterval: 0.01)

        let vm = makeViewModel()
        vm.jsonText = """
        {"timestamp-test": {"command": "new-cmd"}}
        """

        let updated = try vm.submitEdit(
            originalConfig: original,
            store: store,
            scope: .global,
            workspacePath: nil
        )

        XCTAssertGreaterThanOrEqual(updated.updatedAt, originalUpdatedAt)
    }

    // MARK: - Duplicate Name

    func testSubmitWithDuplicateNameThrows() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

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

        let vm = makeViewModel()
        vm.jsonText = """
        {"duplicate-name": {"url": "http://second.example.com"}}
        """

        XCTAssertThrowsError(
            try vm.submit(store: store, scope: .global, workspacePath: nil)
        )
    }

    // MARK: - Reset

    func testResetClearsAllFormState() {
        let vm = makeViewModel()
        vm.jsonText = """
        {"my-server": {"command": "npx"}}
        """
        vm.serverName = "some-name"
        vm.errorMessage = "Some error"

        vm.reset()

        XCTAssertTrue(vm.jsonText.isEmpty)
        XCTAssertTrue(vm.serverName.isEmpty)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.isSubmitting)
    }
}
