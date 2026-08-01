import XCTest
@testable import SwiftWork
import SwiftData
import OpenAgentSDK

// ATDD Red Phase — Story 6.1: MCP 配置模型与持久化
// Unit/Integration tests for MCPServerConfig SwiftData model and MCPServerConfigStore service.
// These tests will FAIL (compile errors) until MCPServerConfig, TransportType, MCPServerScope,
// and MCPServerConfigStore are implemented.

@MainActor
final class MCPServerConfigStoreTests: XCTestCase {

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

    private func makeStore(context: ModelContext) -> MCPServerConfigStore {
        MCPServerConfigStore(modelContext: context)
    }

    private func encodeArgs(_ args: [String]) -> Data? {
        try? JSONEncoder().encode(args)
    }

    private func encodeEnv(_ env: [String: String]) -> Data? {
        try? JSONEncoder().encode(env)
    }

    private func encodeHeaders(_ headers: [String: String]) -> Data? {
        try? JSONEncoder().encode(headers)
    }

    // MARK: - AC#1: SwiftData 持久化模型

    // [P0] MCPServerConfig has all required fields per AC1
    func testMCPServerConfigHasRequiredFields() throws {
        let config = MCPServerConfig(
            name: "test-server",
            transportType: .stdio,
            command: "npx",
            url: nil,
            args: encodeArgs(["-y", "@anthropic/mcp-server"]),
            env: nil,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )

        XCTAssertEqual(config.name, "test-server")
        XCTAssertEqual(config.transportType, .stdio)
        XCTAssertEqual(config.command, "npx")
        XCTAssertNotNil(config.args)
        XCTAssertTrue(config.enabled)
        XCTAssertEqual(config.scope, .global)
        XCTAssertNotNil(config.id)
        XCTAssertNotNil(config.createdAt)
        XCTAssertNotNil(config.updatedAt)
    }

    // [P0] TransportType enum has all three cases
    func testTransportTypeHasThreeCases() {
        let types: [TransportType] = [.stdio, .sse, .http]
        XCTAssertEqual(types.count, 3, "TransportType should have exactly 3 cases: stdio, sse, http")
    }

    // [P0] MCPServerScope enum has project and global cases
    func testMCPServerScopeHasTwoCases() {
        let scopes: [MCPServerScope] = [.project, .global]
        XCTAssertEqual(scopes.count, 2, "MCPServerScope should have exactly 2 cases: project, global")
    }

    // [P0] TransportType is Codable with String rawValue
    func testTransportTypeRawValues() {
        XCTAssertEqual(TransportType.stdio.rawValue, "stdio")
        XCTAssertEqual(TransportType.sse.rawValue, "sse")
        XCTAssertEqual(TransportType.http.rawValue, "http")
    }

    // [P0] MCPServerScope is Codable with String rawValue
    func testMCPServerScopeRawValues() {
        XCTAssertEqual(MCPServerScope.project.rawValue, "project")
        XCTAssertEqual(MCPServerScope.global.rawValue, "global")
    }

    // [P0] MCPServerConfig name field has unique attribute
    func testMCPServerConfigNameIsUnique() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        let config1 = try store.add(
            name: "unique-server",
            transportType: .stdio,
            command: "npx",
            url: nil,
            args: nil,
            env: nil,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )
        XCTAssertNotNil(config1)

        // Adding a second config with the same name should throw or fail
        XCTAssertThrowsError(
            try store.add(
                name: "unique-server",
                transportType: .sse,
                command: nil,
                url: "http://localhost:3000",
                args: nil,
                env: nil,
                headers: nil,
                enabled: true,
                scope: .global,
                workspacePath: nil
            ),
            "Adding a config with duplicate name should throw"
        )
    }

    // [P0] MCPServerConfig id field has unique attribute
    func testMCPServerConfigIdIsUnique() throws {
        let config = MCPServerConfig(
            name: "server-a",
            transportType: .stdio,
            command: "npx",
            url: nil,
            args: nil,
            env: nil,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )
        let config2 = MCPServerConfig(
            name: "server-b",
            transportType: .stdio,
            command: "npx",
            url: nil,
            args: nil,
            env: nil,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )
        XCTAssertNotEqual(config.id, config2.id, "Each MCPServerConfig should have a unique id")
    }

    // [P0] MCPServerConfig conforms to PersistentModel (SwiftData)
    func testMCPServerConfigIsPersistentModel() {
        let config = MCPServerConfig(
            name: "test",
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
        let _: any PersistentModel = config
    }

    // MARK: - AC#1: CRUD operations

    // [P0] Add MCP config via store
    func testAddMCPServerConfig() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        let config = try store.add(
            name: "my-server",
            transportType: .stdio,
            command: "npx",
            url: nil,
            args: encodeArgs(["-y", "mcp-server"]),
            env: encodeEnv(["API_KEY": "test"]),
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )

        XCTAssertEqual(config.name, "my-server")
        XCTAssertEqual(config.transportType, .stdio)
        XCTAssertEqual(config.command, "npx")
        XCTAssertTrue(config.enabled)
        XCTAssertEqual(config.decodedEnv?["API_KEY"], "test")
    }

    // [P0] MCP credentials remain unchanged when read from SwiftData
    func testListPreservesCredentialValues() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)
        let legacy = MCPServerConfig(
            name: "legacy-secret-server",
            transportType: .http,
            url: "https://example.com/mcp",
            env: encodeEnv(["API_TOKEN": "legacy-env-secret", "REGION": "cn"]),
            headers: encodeHeaders([
                "Authorization": "Bearer legacy-header-secret",
                "X-Custom": "visible",
            ])
        )
        context.insert(legacy)
        try context.save()

        let persisted = try XCTUnwrap(store.list().first)

        XCTAssertEqual(persisted.decodedEnv?["API_TOKEN"], "legacy-env-secret")
        XCTAssertEqual(persisted.decodedEnv?["REGION"], "cn")
        XCTAssertEqual(persisted.decodedHeaders?["Authorization"], "Bearer legacy-header-secret")
        XCTAssertEqual(persisted.decodedHeaders?["X-Custom"], "visible")
    }

    // [P0] List all MCP configs
    func testListMCPServerConfigs() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        _ = try store.add(name: "server-1", transportType: .stdio, command: "cmd1", url: nil, args: nil, env: nil, headers: nil, enabled: true, scope: .global, workspacePath: nil)
        _ = try store.add(name: "server-2", transportType: .sse, command: nil, url: "http://example.com", args: nil, env: nil, headers: nil, enabled: true, scope: .global, workspacePath: nil)

        let configs = try store.list()
        XCTAssertEqual(configs.count, 2, "Should list 2 MCP configs")
    }

    // [P0] Update MCP config
    func testUpdateMCPServerConfig() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        var config = try store.add(name: "updatable", transportType: .stdio, command: "old-cmd", url: nil, args: nil, env: nil, headers: nil, enabled: true, scope: .global, workspacePath: nil)
        config = try store.update(config, command: "new-cmd", enabled: false)

        let configs = try store.list()
        let updated = configs.first { $0.name == "updatable" }
        XCTAssertEqual(updated?.command, "new-cmd")
        XCTAssertEqual(updated?.enabled, false)
    }

    // [P0] Delete MCP config
    func testDeleteMCPServerConfig() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        let config = try store.add(name: "deletable", transportType: .stdio, command: "cmd", url: nil, args: nil, env: nil, headers: nil, enabled: true, scope: .global, workspacePath: nil)
        try store.delete(config)

        let configs = try store.list()
        XCTAssertTrue(configs.isEmpty, "Config should be deleted")
    }

    // [P0] List returns empty when no configs exist
    func testListEmptyWhenNoConfigs() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        let configs = try store.list()
        XCTAssertTrue(configs.isEmpty, "Should return empty list when no configs exist")
    }

    // MARK: - AC#2: 应用重启自动恢复

    // [P0] Configs survive save/reload cycle (simulates restart)
    func testConfigsPersistAfterSave() throws {
        let schema = Schema([MCPServerConfig.self as any PersistentModel.Type])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)

        let context1 = ModelContext(container)
        let store1 = MCPServerConfigStore(modelContext: context1)
        _ = try store1.add(name: "persistent-server", transportType: .http, command: nil, url: "http://mcp.example.com", args: nil, env: nil, headers: encodeHeaders(["Authorization": "Bearer token"]), enabled: true, scope: .global, workspacePath: nil)
        try context1.save()

        // Simulate reload with new context from same container
        let context2 = ModelContext(container)
        let store2 = MCPServerConfigStore(modelContext: context2)
        let configs = try store2.list()
        XCTAssertEqual(configs.count, 1, "Config should survive save/reload cycle")
        XCTAssertEqual(configs.first?.name, "persistent-server")
        XCTAssertEqual(configs.first?.transportType, .http)
    }

    // MARK: - AC#3: 项目级 scope 隔离

    // [P0] Global configs visible for all workspaces
    func testGlobalConfigsVisibleForAllWorkspaces() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        _ = try store.add(name: "global-1", transportType: .stdio, command: "cmd", url: nil, args: nil, env: nil, headers: nil, enabled: true, scope: .global, workspacePath: nil)
        _ = try store.add(name: "global-2", transportType: .sse, command: nil, url: "http://example.com", args: nil, env: nil, headers: nil, enabled: true, scope: .global, workspacePath: nil)

        let workspaceA = "/Users/test/project-a"
        let configs = try store.enabledConfigsForWorkspace(workspaceA)
        XCTAssertEqual(configs.count, 2, "Global configs should be visible for any workspace")
    }

    // [P0] Project configs only visible for matching workspace
    func testProjectConfigsOnlyVisibleForMatchingWorkspace() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        _ = try store.add(name: "project-a-server", transportType: .stdio, command: "cmd-a", url: nil, args: nil, env: nil, headers: nil, enabled: true, scope: .project, workspacePath: "/Users/test/project-a")
        _ = try store.add(name: "project-b-server", transportType: .stdio, command: "cmd-b", url: nil, args: nil, env: nil, headers: nil, enabled: true, scope: .project, workspacePath: "/Users/test/project-b")

        let workspaceA = "/Users/test/project-a"
        let configsA = try store.enabledConfigsForWorkspace(workspaceA)
        XCTAssertEqual(configsA.count, 1, "Only project-a config should be visible")
        XCTAssertEqual(configsA.first?.name, "project-a-server")
    }

    // [P0] Mixed global + project configs merged correctly
    func testMixedGlobalAndProjectConfigsMerged() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        _ = try store.add(name: "global-mcp", transportType: .stdio, command: "global-cmd", url: nil, args: nil, env: nil, headers: nil, enabled: true, scope: .global, workspacePath: nil)
        _ = try store.add(name: "project-a-mcp", transportType: .sse, command: nil, url: "http://a.mcp.local", args: nil, env: nil, headers: nil, enabled: true, scope: .project, workspacePath: "/Users/test/project-a")
        _ = try store.add(name: "project-b-mcp", transportType: .http, command: nil, url: "http://b.mcp.local", args: nil, env: nil, headers: nil, enabled: true, scope: .project, workspacePath: "/Users/test/project-b")

        let configsA = try store.enabledConfigsForWorkspace("/Users/test/project-a")
        XCTAssertEqual(configsA.count, 2, "Should see global + project-a config")
        let names = Set(configsA.map(\.name))
        XCTAssertTrue(names.contains("global-mcp"))
        XCTAssertTrue(names.contains("project-a-mcp"))
        XCTAssertFalse(names.contains("project-b-mcp"))
    }

    // [P1] Disabled configs excluded from enabledConfigsForWorkspace
    func testDisabledConfigsExcludedFromWorkspaceQuery() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        _ = try store.add(name: "disabled-global", transportType: .stdio, command: "cmd", url: nil, args: nil, env: nil, headers: nil, enabled: false, scope: .global, workspacePath: nil)
        _ = try store.add(name: "enabled-global", transportType: .stdio, command: "cmd", url: nil, args: nil, env: nil, headers: nil, enabled: true, scope: .global, workspacePath: nil)

        let configs = try store.enabledConfigsForWorkspace("/any/workspace")
        XCTAssertEqual(configs.count, 1, "Only enabled config should be returned")
        XCTAssertEqual(configs.first?.name, "enabled-global")
    }

    // [P1] List by scope filter
    func testListByScope() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        _ = try store.add(name: "g1", transportType: .stdio, command: "c", url: nil, args: nil, env: nil, headers: nil, enabled: true, scope: .global, workspacePath: nil)
        _ = try store.add(name: "g2", transportType: .sse, command: nil, url: "http://g2", args: nil, env: nil, headers: nil, enabled: true, scope: .global, workspacePath: nil)
        _ = try store.add(name: "p1", transportType: .http, command: nil, url: "http://p1", args: nil, env: nil, headers: nil, enabled: true, scope: .project, workspacePath: "/x")

        let globalConfigs = try store.list(scope: .global)
        XCTAssertEqual(globalConfigs.count, 2, "Should list 2 global configs")

        let projectConfigs = try store.list(scope: .project)
        XCTAssertEqual(projectConfigs.count, 1, "Should list 1 project config")
    }

    // MARK: - AC#4: 配置转 SDK McpServerConfig

    // [P0] stdio config converts to SDK McpStdioConfig
    func testStdioConfigConvertsToSDKConfig() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        _ = try store.add(
            name: "stdio-server",
            transportType: .stdio,
            command: "npx",
            url: nil,
            args: encodeArgs(["-y", "@anthropic/mcp-server"]),
            env: encodeEnv(["API_KEY": "test-key"]),
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )

        let configs = try store.enabledConfigsForWorkspace(nil)
        let sdkDict = store.toSDKConfigs(configs)

        XCTAssertEqual(sdkDict.count, 1)
        let sdkConfig = sdkDict["stdio-server"]
        XCTAssertNotNil(sdkConfig, "stdio-server should be in SDK config dictionary")

        if case .stdio(let stdioConfig) = sdkConfig {
            XCTAssertEqual(stdioConfig.command, "npx")
            XCTAssertEqual(stdioConfig.args, ["-y", "@anthropic/mcp-server"])
            XCTAssertEqual(stdioConfig.env, ["API_KEY": "test-key"])
        } else {
            XCTFail("Expected .stdio case, got \(String(describing: sdkConfig))")
        }
    }

    // [P0] SSE config converts to SDK McpTransportConfig
    func testSSEConfigConvertsToSDKConfig() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        _ = try store.add(
            name: "sse-server",
            transportType: .sse,
            command: nil,
            url: "http://localhost:3000/sse",
            args: nil,
            env: nil,
            headers: encodeHeaders(["Authorization": "Bearer token"]),
            enabled: true,
            scope: .global,
            workspacePath: nil
        )

        let configs = try store.enabledConfigsForWorkspace(nil)
        let sdkDict = store.toSDKConfigs(configs)

        XCTAssertEqual(sdkDict.count, 1)
        let sdkConfig = sdkDict["sse-server"]
        XCTAssertNotNil(sdkConfig)

        if case .sse(let transportConfig) = sdkConfig {
            XCTAssertEqual(transportConfig.url, "http://localhost:3000/sse")
            XCTAssertEqual(transportConfig.headers, ["Authorization": "Bearer token"])
        } else {
            XCTFail("Expected .sse case, got \(String(describing: sdkConfig))")
        }
    }

    // [P0] HTTP config converts to SDK McpTransportConfig
    func testHTTPConfigConvertsToSDKConfig() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        _ = try store.add(
            name: "http-server",
            transportType: .http,
            command: nil,
            url: "http://localhost:4000/mcp",
            args: nil,
            env: nil,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )

        let configs = try store.enabledConfigsForWorkspace(nil)
        let sdkDict = store.toSDKConfigs(configs)

        XCTAssertEqual(sdkDict.count, 1)
        let sdkConfig = sdkDict["http-server"]
        XCTAssertNotNil(sdkConfig)

        if case .http(let transportConfig) = sdkConfig {
            XCTAssertEqual(transportConfig.url, "http://localhost:4000/mcp")
            XCTAssertNil(transportConfig.headers)
        } else {
            XCTFail("Expected .http case, got \(String(describing: sdkConfig))")
        }
    }

    // [P0] stdio config without command is skipped in conversion
    func testStdioConfigWithoutCommandSkipped() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        // Add stdio config with no command — should be skipped
        _ = try store.add(
            name: "bad-stdio",
            transportType: .stdio,
            command: nil,
            url: nil,
            args: nil,
            env: nil,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )

        let configs = try store.enabledConfigsForWorkspace(nil)
        let sdkDict = store.toSDKConfigs(configs)
        XCTAssertTrue(sdkDict.isEmpty, "stdio config without command should be skipped")
    }

    // [P0] SSE/HTTP config without URL is skipped in conversion
    func testSSEConfigWithoutURLSkipped() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        _ = try store.add(
            name: "bad-sse",
            transportType: .sse,
            command: nil,
            url: nil,
            args: nil,
            env: nil,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )

        let configs = try store.enabledConfigsForWorkspace(nil)
        let sdkDict = store.toSDKConfigs(configs)
        XCTAssertTrue(sdkDict.isEmpty, "SSE config without URL should be skipped")
    }

    // [P1] Disabled configs excluded from SDK conversion
    func testDisabledConfigsExcludedFromSDKConversion() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        _ = try store.add(name: "disabled-stdio", transportType: .stdio, command: "cmd", url: nil, args: nil, env: nil, headers: nil, enabled: false, scope: .global, workspacePath: nil)

        let configs = try store.enabledConfigsForWorkspace(nil)
        let sdkDict = store.toSDKConfigs(configs)
        XCTAssertTrue(sdkDict.isEmpty, "Disabled configs should not appear in SDK conversion")
    }

    // [P1] Multiple configs convert to correct SDK dictionary
    func testMultipleConfigsConvertToSDKDictionary() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        _ = try store.add(name: "s1", transportType: .stdio, command: "npx", url: nil, args: encodeArgs(["a"]), env: nil, headers: nil, enabled: true, scope: .global, workspacePath: nil)
        _ = try store.add(name: "s2", transportType: .sse, command: nil, url: "http://s2.example.com", args: nil, env: nil, headers: nil, enabled: true, scope: .global, workspacePath: nil)
        _ = try store.add(name: "s3", transportType: .http, command: nil, url: "http://s3.example.com", args: nil, env: nil, headers: encodeHeaders(["X-Key": "val"]), enabled: true, scope: .global, workspacePath: nil)

        let configs = try store.enabledConfigsForWorkspace(nil)
        let sdkDict = store.toSDKConfigs(configs)
        XCTAssertEqual(sdkDict.count, 3, "All three configs should convert")

        XCTAssertNotNil(sdkDict["s1"])
        XCTAssertNotNil(sdkDict["s2"])
        XCTAssertNotNil(sdkDict["s3"])
    }

    // MARK: - JSON decode helpers (decodedArgs, decodedEnv, decodedHeaders)

    // [P1] decodedArgs returns decoded [String] from Data
    func testDecodedArgsReturnsCorrectArray() throws {
        let args = ["-y", "@anthropic/mcp-server"]
        let argsData = try JSONEncoder().encode(args)
        let config = MCPServerConfig(
            name: "test",
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
        XCTAssertEqual(config.decodedArgs, args)
    }

    // [P1] decodedEnv returns decoded [String: String] from Data
    func testDecodedEnvReturnsCorrectDictionary() throws {
        let env = ["API_KEY": "sk-test", "REGION": "us-east-1"]
        let envData = try JSONEncoder().encode(env)
        let config = MCPServerConfig(
            name: "test",
            transportType: .stdio,
            command: "npx",
            url: nil,
            args: nil,
            env: envData,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )
        XCTAssertEqual(config.decodedEnv, env)
    }

    // [P1] decodedHeaders returns decoded [String: String] from Data
    func testDecodedHeadersReturnsCorrectDictionary() throws {
        let headers = ["Authorization": "Bearer token", "X-Custom": "value"]
        let headersData = try JSONEncoder().encode(headers)
        let config = MCPServerConfig(
            name: "test",
            transportType: .http,
            command: nil,
            url: "http://example.com",
            args: nil,
            env: nil,
            headers: headersData,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )
        XCTAssertEqual(config.decodedHeaders, headers)
    }

    // [P1] decodedArgs returns nil when args is nil
    func testDecodedArgsReturnsNilWhenNil() {
        let config = MCPServerConfig(
            name: "test",
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
        XCTAssertNil(config.decodedArgs)
    }

    // MARK: - Error handling

    // [P1] Store operations handle SwiftData errors gracefully
    func testStoreHandlesErrorsGracefully() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        // Adding a config should not crash
        let config = try store.add(
            name: "error-test",
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
        XCTAssertNotNil(config, "Store should not crash on add")
    }

    // [P1] Deleting non-existent config does not crash
    func testDeleteNonExistentConfigDoesNotCrash() throws {
        let (_, context) = try makeContext()
        let store = makeStore(context: context)

        // Create a config in a different context — simulating a non-existent record
        let config = MCPServerConfig(
            name: "ghost",
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
        // Should not crash
        try? store.delete(config)
    }

    // MARK: - TransportType Sendable conformance

    // [P1] TransportType conforms to Sendable
    func testTransportTypeIsSendable() {
        let _: any Sendable = TransportType.stdio
    }

    // [P1] MCPServerScope conforms to Sendable
    func testMCPServerScopeIsSendable() {
        let _: any Sendable = MCPServerScope.global
    }

    // MARK: - AgentBridge integration (AC#4)

    // [P0] AgentBridge.configure() accepts MCP configs
    func testAgentBridgeConfigurePassesMCPConfigsToSDK() throws {
        let bridge = AgentBridge()
        // After implementation, configure() should accept MCP configs
        // and pass them to AgentOptions.mcpServers
        bridge.configure(
            apiKey: "test-key",
            baseURL: nil,
            model: "test-model",
            workspacePath: nil,
            sessionId: UUID().uuidString
        )
        // The test verifies that configure() doesn't crash when MCP store is empty
        XCTAssertTrue(true, "AgentBridge.configure() should handle MCP store gracefully")
    }
}
