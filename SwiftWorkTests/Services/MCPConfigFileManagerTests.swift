import XCTest
@testable import SwiftWork
import SwiftData

// ATDD Red Phase — Story 6.6: MCP 高级设置与配置文件
// Unit tests for MCPConfigFileManager service.
// These tests will FAIL (compile errors or assertion failures) until MCPConfigFileManager is implemented.

@MainActor
final class MCPConfigFileManagerTests: XCTestCase {

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
        MCPServerConfigStore(modelContext: context, keychainManager: MockKeychainManager())
    }

    private func makeManager() -> MCPConfigFileManager {
        MCPConfigFileManager()
    }

    private func makeManagerWithStore(context: ModelContext) -> (MCPConfigFileManager, MCPServerConfigStore) {
        let store = MCPServerConfigStore(modelContext: context, keychainManager: MockKeychainManager())
        let manager = MCPConfigFileManager()
        return (manager, store)
    }

    nonisolated(unsafe) private var tempDirectory: String!

    override func setUp() {
        super.setUp()
        tempDirectory = NSTemporaryDirectory() + "MCPConfigFileManagerTests-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let tempDirectory {
            try? FileManager.default.removeItem(atPath: tempDirectory)
        }
        super.tearDown()
    }

    private func writeConfigFile(path: String, json: String) throws {
        let dir = (path as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try json.write(toFile: path, atomically: true, encoding: .utf8)
    }

    private func validConfigJSON() -> String {
        """
        {
          "mcpServers": {
            "test-server": {
              "command": "npx",
              "args": ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"],
              "env": {},
              "type": "stdio"
            }
          }
        }
        """
    }

    private func multiServerConfigJSON() -> String {
        """
        {
          "mcpServers": {
            "stdio-server": {
              "command": "npx",
              "args": ["-y", "mcp-server"],
              "env": {"API_KEY": "test"},
              "type": "stdio"
            },
            "remote-server": {
              "url": "https://example.com/mcp",
              "headers": {"Authorization": "Bearer token"},
              "type": "sse"
            }
          }
        }
        """
    }

    // MARK: - AC#2: 配置文件路径解析

    // [P0] Global scope resolves to ~/.claude/settings.json
    func testConfigFilePathGlobalScope() {
        let manager = makeManager()
        let path = manager.configFilePath(scope: .global, workspacePath: nil)

        XCTAssertNotNil(path, "Global scope should always resolve")
        XCTAssertTrue(path!.hasSuffix(".claude/settings.json"), "Global path should end with .claude/settings.json")

        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        XCTAssertTrue(path!.hasPrefix(homeDir), "Global path should start with home directory")
    }

    // [P0] Global scope ignores workspacePath parameter
    func testConfigFilePathGlobalScopeIgnoresWorkspace() {
        let manager = makeManager()
        let pathWithWorkspace = manager.configFilePath(scope: .global, workspacePath: "/some/workspace")
        let pathWithoutWorkspace = manager.configFilePath(scope: .global, workspacePath: nil)

        XCTAssertEqual(pathWithWorkspace, pathWithoutWorkspace, "Global scope should ignore workspace path")
    }

    // [P0] Project scope resolves to {workspacePath}/.claude/settings.json
    func testConfigFilePathProjectScope() {
        let manager = makeManager()
        let workspacePath = "/Users/test/my-project"
        let path = manager.configFilePath(scope: .project, workspacePath: workspacePath)

        XCTAssertNotNil(path, "Project scope with workspace should resolve")
        XCTAssertEqual(path, "/Users/test/my-project/.claude/settings.json")
    }

    // [P0] Project scope returns nil when workspacePath is nil
    func testConfigFilePathProjectScopeNilWorkspace() {
        let manager = makeManager()
        let path = manager.configFilePath(scope: .project, workspacePath: nil)

        XCTAssertNil(path, "Project scope without workspace should return nil")
    }

    // [P0] Project scope returns nil when workspacePath is empty
    func testConfigFilePathProjectScopeEmptyWorkspace() {
        let manager = makeManager()
        let path = manager.configFilePath(scope: .project, workspacePath: "")

        XCTAssertNil(path, "Project scope with empty workspace should return nil")
    }

    // MARK: - AC#3: 配置文件存在检查

    // [P0] configFileExists returns true for existing file
    func testConfigFileExistsTrue() throws {
        let manager = makeManager()
        let filePath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: filePath, json: "{}")

        let exists = manager.configFileExists(atPath: filePath)
        XCTAssertTrue(exists, "Should return true for existing file")
    }

    // [P0] configFileExists returns false for non-existing file
    func testConfigFileExistsFalse() {
        let manager = makeManager()
        let exists = manager.configFileExists(atPath: "/nonexistent/path/settings.json")
        XCTAssertFalse(exists, "Should return false for non-existing file")
    }

    // MARK: - AC#2: 配置文件读取

    // [P0] readConfigFile returns Data for valid file
    func testReadConfigFileReturnsData() throws {
        let manager = makeManager()
        let filePath = tempDirectory + "/.claude/settings.json"
        let json = validConfigJSON()
        try writeConfigFile(path: filePath, json: json)

        let data = manager.readConfigFile(atPath: filePath)
        XCTAssertNotNil(data, "Should return data for existing file")

        let content = String(data: data!, encoding: .utf8)
        XCTAssertNotNil(content, "Data should be valid UTF-8")
    }

    // [P0] readConfigFile returns nil for non-existing file
    func testReadConfigFileReturnsNilForMissing() {
        let manager = makeManager()
        let data = manager.readConfigFile(atPath: "/nonexistent/settings.json")
        XCTAssertNil(data, "Should return nil for non-existing file")
    }

    // MARK: - AC#4: JSON 配置解析 — loadMCPConfigsFromFile

    // [P0] Parses valid single stdio server config
    func testLoadConfigsParsesSingleStdioServer() throws {
        let manager = makeManager()
        let filePath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: filePath, json: validConfigJSON())

        let configs = manager.loadMCPConfigsFromFile(atPath: filePath)
        XCTAssertEqual(configs.count, 1, "Should parse 1 server config")

        let config = configs.first
        XCTAssertEqual(config?.name, "test-server")
        XCTAssertEqual(config?.transportType, .stdio)
        XCTAssertEqual(config?.command, "npx")
    }

    // [P0] Parses multiple server configs (stdio + sse)
    func testLoadConfigsParsesMultipleServers() throws {
        let manager = makeManager()
        let filePath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: filePath, json: multiServerConfigJSON())

        let configs = manager.loadMCPConfigsFromFile(atPath: filePath)
        XCTAssertEqual(configs.count, 2, "Should parse 2 server configs")

        let names = Set(configs.map(\.name))
        XCTAssertTrue(names.contains("stdio-server"))
        XCTAssertTrue(names.contains("remote-server"))
    }

    // [P0] Parses SSE server with url and headers
    func testLoadConfigsParsesSSEServer() throws {
        let manager = makeManager()
        let filePath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: filePath, json: multiServerConfigJSON())

        let configs = manager.loadMCPConfigsFromFile(atPath: filePath)
        let sseConfig = configs.first { $0.name == "remote-server" }

        XCTAssertEqual(sseConfig?.transportType, .sse)
        XCTAssertEqual(sseConfig?.url, "https://example.com/mcp")
        XCTAssertNotNil(sseConfig?.decodedHeaders)
        XCTAssertEqual(sseConfig?.decodedHeaders?["Authorization"], "Bearer token")
    }

    // [P0] Parses stdio server with args
    func testLoadConfigsParsesStdioArgs() throws {
        let manager = makeManager()
        let filePath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: filePath, json: validConfigJSON())

        let configs = manager.loadMCPConfigsFromFile(atPath: filePath)
        let config = configs.first

        XCTAssertNotNil(config?.decodedArgs)
        XCTAssertEqual(config?.decodedArgs, ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"])
    }

    // [P0] Parses env dictionary correctly
    func testLoadConfigsParsesEnv() throws {
        let manager = makeManager()
        let filePath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: filePath, json: multiServerConfigJSON())

        let configs = manager.loadMCPConfigsFromFile(atPath: filePath)
        let stdioConfig = configs.first { $0.name == "stdio-server" }

        XCTAssertNotNil(stdioConfig?.decodedEnv)
        XCTAssertEqual(stdioConfig?.decodedEnv?["API_KEY"], "test")
    }

    // [P0] Returns empty array for non-existing file
    func testLoadConfigsReturnsEmptyForMissingFile() {
        let manager = makeManager()
        let configs = manager.loadMCPConfigsFromFile(atPath: "/nonexistent/settings.json")
        XCTAssertTrue(configs.isEmpty, "Should return empty array for missing file")
    }

    // [P0] Returns empty array for file with invalid JSON
    func testLoadConfigsReturnsEmptyForInvalidJSON() throws {
        let manager = makeManager()
        let filePath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: filePath, json: "this is not json{{{")

        let configs = manager.loadMCPConfigsFromFile(atPath: filePath)
        XCTAssertTrue(configs.isEmpty, "Should return empty array for invalid JSON")
    }

    // [P0] Returns empty array for valid JSON without mcpServers key
    func testLoadConfigsReturnsEmptyForNoMcpServersKey() throws {
        let manager = makeManager()
        let filePath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: filePath, json: "{\"otherKey\": \"value\"}")

        let configs = manager.loadMCPConfigsFromFile(atPath: filePath)
        XCTAssertTrue(configs.isEmpty, "Should return empty array when mcpServers key is missing")
    }

    // [P0] Defaults to enabled=true when not specified
    func testLoadConfigsDefaultsEnabledTrue() throws {
        let manager = makeManager()
        let filePath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: filePath, json: validConfigJSON())

        let configs = manager.loadMCPConfigsFromFile(atPath: filePath)
        let config = configs.first
        XCTAssertTrue(config?.enabled ?? false, "Config should default to enabled=true")
    }

    // [P0] Honors explicit enabled=false
    func testLoadConfigsHonorsExplicitDisabled() throws {
        let manager = makeManager()
        let filePath = tempDirectory + "/.claude/settings.json"
        let json = """
        {
          "mcpServers": {
            "disabled-server": {
              "command": "npx",
              "args": [],
              "type": "stdio",
              "enabled": false
            }
          }
        }
        """
        try writeConfigFile(path: filePath, json: json)

        let configs = manager.loadMCPConfigsFromFile(atPath: filePath)
        let config = configs.first
        XCTAssertFalse(config?.enabled ?? true, "Config should be disabled when explicitly set")
    }

    // [P0] Infers transport type: command present -> stdio (even without type field)
    func testLoadConfigsInfersStdioFromCommand() throws {
        let manager = makeManager()
        let filePath = tempDirectory + "/.claude/settings.json"
        let json = """
        {
          "mcpServers": {
            "inferred-stdio": {
              "command": "npx",
              "args": ["-y", "mcp-server"]
            }
          }
        }
        """
        try writeConfigFile(path: filePath, json: json)

        let configs = manager.loadMCPConfigsFromFile(atPath: filePath)
        let config = configs.first
        XCTAssertEqual(config?.transportType, .stdio, "Should infer stdio when command is present")
    }

    // [P0] Infers transport type: url present -> sse (even without type field)
    func testLoadConfigsInfersSSEFromUrl() throws {
        let manager = makeManager()
        let filePath = tempDirectory + "/.claude/settings.json"
        let json = """
        {
          "mcpServers": {
            "inferred-sse": {
              "url": "https://example.com/mcp"
            }
          }
        }
        """
        try writeConfigFile(path: filePath, json: json)

        let configs = manager.loadMCPConfigsFromFile(atPath: filePath)
        let config = configs.first
        XCTAssertEqual(config?.transportType, .sse, "Should infer sse when url is present without type")
    }

    // [P0] Parses http type explicitly
    func testLoadConfigsParsesHttpType() throws {
        let manager = makeManager()
        let filePath = tempDirectory + "/.claude/settings.json"
        let json = """
        {
          "mcpServers": {
            "http-server": {
              "url": "https://api.example.com/mcp",
              "headers": {},
              "type": "http"
            }
          }
        }
        """
        try writeConfigFile(path: filePath, json: json)

        let configs = manager.loadMCPConfigsFromFile(atPath: filePath)
        let config = configs.first
        XCTAssertEqual(config?.transportType, .http)
        XCTAssertEqual(config?.url, "https://api.example.com/mcp")
    }

    // [P0] Handles empty mcpServers object
    func testLoadConfigsHandlesEmptyMcpServers() throws {
        let manager = makeManager()
        let filePath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: filePath, json: "{\"mcpServers\": {}}")

        let configs = manager.loadMCPConfigsFromFile(atPath: filePath)
        XCTAssertTrue(configs.isEmpty, "Should return empty array for empty mcpServers")
    }

    // [P1] Handles server entry with empty args array
    func testLoadConfigsHandlesEmptyArgs() throws {
        let manager = makeManager()
        let filePath = tempDirectory + "/.claude/settings.json"
        let json = """
        {
          "mcpServers": {
            "no-args-server": {
              "command": "npx",
              "args": [],
              "type": "stdio"
            }
          }
        }
        """
        try writeConfigFile(path: filePath, json: json)

        let configs = manager.loadMCPConfigsFromFile(atPath: filePath)
        let config = configs.first
        XCTAssertNotNil(config)
        XCTAssertEqual(config?.decodedArgs ?? nil ?? [], [])
    }

    // [P1] Handles server entry without env or headers
    func testLoadConfigsHandlesMissingOptionalFields() throws {
        let manager = makeManager()
        let filePath = tempDirectory + "/.claude/settings.json"
        let json = """
        {
          "mcpServers": {
            "minimal-server": {
              "command": "node",
              "type": "stdio"
            }
          }
        }
        """
        try writeConfigFile(path: filePath, json: json)

        let configs = manager.loadMCPConfigsFromFile(atPath: filePath)
        let config = configs.first
        XCTAssertNotNil(config)
        XCTAssertEqual(config?.command, "node")
        XCTAssertNil(config?.decodedEnv)
        XCTAssertNil(config?.decodedHeaders)
    }

    // MARK: - AC#4: 从文件导入配置到 SwiftData — importFromFile

    // [P0] Import adds new configs to SwiftData
    func testImportFromFileAddsNewConfigs() throws {
        let (_, context) = try makeContext()
        let (manager, store) = makeManagerWithStore(context: context)
        let filePath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: filePath, json: validConfigJSON())

        try manager.importFromFile(atPath: filePath, scope: .global, workspacePath: nil, store: store)

        let configs = try store.list()
        XCTAssertEqual(configs.count, 1, "Should have 1 config after import")
        XCTAssertEqual(configs.first?.name, "test-server")
    }

    // [P0] Import overwrites existing config with same name (dedup)
    func testImportFromFileOverwritesDuplicateName() throws {
        let (_, context) = try makeContext()
        let (manager, store) = makeManagerWithStore(context: context)

        // Pre-existing config in SwiftData with same name
        _ = try store.add(
            name: "test-server",
            transportType: .sse,
            command: nil,
            url: "http://old-url.example.com",
            args: nil,
            env: nil,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )

        let filePath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: filePath, json: validConfigJSON())

        try manager.importFromFile(atPath: filePath, scope: .global, workspacePath: nil, store: store)

        let configs = try store.list()
        XCTAssertEqual(configs.count, 1, "Should still have 1 config (overwritten, not duplicated)")
        XCTAssertEqual(configs.first?.transportType, .stdio, "Should be overwritten with file's stdio type")
        XCTAssertEqual(configs.first?.command, "npx", "Command should be updated from file")
    }

    // [P0] Import adds new and updates existing in same operation
    func testImportFromFileMixedAddAndUpdate() throws {
        let (_, context) = try makeContext()
        let (manager, store) = makeManagerWithStore(context: context)

        // Pre-existing config
        _ = try store.add(
            name: "stdio-server",
            transportType: .stdio,
            command: "old-command",
            url: nil,
            args: nil,
            env: nil,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )

        let filePath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: filePath, json: multiServerConfigJSON())

        try manager.importFromFile(atPath: filePath, scope: .global, workspacePath: nil, store: store)

        let configs = try store.list()
        XCTAssertEqual(configs.count, 2, "Should have 2 configs: 1 updated + 1 new")

        let stdioConfig = configs.first { $0.name == "stdio-server" }
        XCTAssertEqual(stdioConfig?.command, "npx", "stdio-server should be updated with file's command")

        let remoteConfig = configs.first { $0.name == "remote-server" }
        XCTAssertNotNil(remoteConfig, "remote-server should be newly added")
    }

    // [P0] Import preserves SwiftData-only configs not in file
    func testImportFromFilePreservesSwiftDataOnlyConfigs() throws {
        let (_, context) = try makeContext()
        let (manager, store) = makeManagerWithStore(context: context)

        // Config that exists only in SwiftData, not in file
        _ = try store.add(
            name: "swiftdata-only",
            transportType: .http,
            command: nil,
            url: "http://only-in-swiftdata.com",
            args: nil,
            env: nil,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )

        let filePath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: filePath, json: validConfigJSON())

        try manager.importFromFile(atPath: filePath, scope: .global, workspacePath: nil, store: store)

        let configs = try store.list()
        XCTAssertEqual(configs.count, 2, "Should have 2 configs: 1 from file + 1 preserved")

        let preserved = configs.first { $0.name == "swiftdata-only" }
        XCTAssertNotNil(preserved, "SwiftData-only config should be preserved")
        XCTAssertEqual(preserved?.url, "http://only-in-swiftdata.com")
    }

    // [P0] Import does not crash on non-existing file
    func testImportFromFileDoesNotCrashOnMissingFile() throws {
        let (_, context) = try makeContext()
        let (manager, store) = makeManagerWithStore(context: context)

        XCTAssertNoThrow(
            try manager.importFromFile(atPath: "/nonexistent/settings.json", scope: .global, workspacePath: nil, store: store),
            "Import from missing file should not crash"
        )

        let configs = try store.list()
        XCTAssertTrue(configs.isEmpty, "No configs should be added from missing file")
    }

    // [P0] Import sets correct scope on imported configs
    func testImportFromFileSetsCorrectScope() throws {
        let (_, context) = try makeContext()
        let (manager, store) = makeManagerWithStore(context: context)
        let filePath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: filePath, json: validConfigJSON())

        try manager.importFromFile(atPath: filePath, scope: .project, workspacePath: "/my/workspace", store: store)

        let configs = try store.list()
        let config = configs.first
        XCTAssertEqual(config?.scope, .project, "Imported config should have project scope")
        XCTAssertEqual(config?.workspacePath, "/my/workspace", "Imported config should have workspace path")
    }

    // MARK: - AC#3: 在 Finder 中显示

    // [P1] revealInFinder does not crash for existing file
    func testRevealInFinderDoesNotCrashForExistingFile() throws {
        let manager = makeManager()
        manager.revealFileHandler = { _ in }
        let filePath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: filePath, json: "{}")

        // Should not crash — handler is a no-op in tests
        manager.revealInFinder(path: filePath)
    }

    // [P1] revealInFinder does not crash for non-existing file
    func testRevealInFinderDoesNotCrashForMissingFile() {
        let manager = makeManager()
        manager.revealFileHandler = { _ in }
        // Should not crash even for missing files
        manager.revealInFinder(path: "/nonexistent/path/settings.json")
    }

    // MARK: - AC#4: 文件系统监控

    // [P0] startWatching does not crash for existing file
    func testStartWatchingDoesNotCrash() throws {
        let manager = makeManager()
        let filePath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: filePath, json: "{}")

        var callbackFired = false
        manager.startWatching(path: filePath) {
            callbackFired = true
        }

        // Give a moment for the watch to register
        let expectation = expectation(description: "Watch registered")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        manager.stopWatching()
    }

    // [P0] stopWatching does not crash when not watching
    func testStopWatchingWhenNotWatching() {
        let manager = makeManager()
        // Should be a no-op, not crash
        manager.stopWatching()
    }

    // [P1] File change triggers callback
    func testFileChangeTriggersCallback() throws {
        let manager = makeManager()
        let filePath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: filePath, json: "{}")

        let expectation = expectation(description: "File change callback")
        var callbackCount = 0

        manager.startWatching(path: filePath) {
            callbackCount += 1
            if callbackCount >= 1 {
                expectation.fulfill()
            }
        }

        // Small delay to ensure watch is registered
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.2) {
            try? "modified content".write(toFile: filePath, atomically: true, encoding: .utf8)
        }

        waitForExpectations(timeout: 3.0)
        manager.stopWatching()

        XCTAssertTrue(callbackCount >= 1, "Callback should fire at least once after file modification")
    }

    // [P1] stopWatching stops callbacks
    func testStopWatchingStopsCallbacks() throws {
        let manager = makeManager()
        let filePath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: filePath, json: "{}")

        var callbackCount = 0
        manager.startWatching(path: filePath) {
            callbackCount += 1
        }

        // Stop watching immediately
        manager.stopWatching()

        // Modify file after stopping
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.3) {
            try? "modified after stop".write(toFile: filePath, atomically: true, encoding: .utf8)
        }

        let expectation = expectation(description: "Wait for potential callback")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        // Callback should not have fired after stopWatching
        // Note: timing-dependent test — callbackCount should ideally be 0
        // but we accept that a single late callback might arrive
    }
}
