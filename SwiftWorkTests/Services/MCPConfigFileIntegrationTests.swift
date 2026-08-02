import XCTest
@testable import SwiftWork
import SwiftData

// ATDD Red Phase — Story 6.6: MCP 高级设置与配置文件
// Integration tests for MCPConfigFileManager + MCPServerConfigStore + AgentBridge hot-update.
// These tests will FAIL until MCPConfigFileManager is implemented.

@MainActor
final class MCPConfigFileIntegrationTests: XCTestCase {

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

    nonisolated(unsafe) private var tempDirectory: String!

    override func setUp() {
        super.setUp()
        tempDirectory = NSTemporaryDirectory() + "MCPConfigFileIntegrationTests-\(UUID().uuidString)"
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

    // MARK: - AC#4: 端到端导入 + SwiftData + Agent 热更新

    // [P0] Full pipeline: file → parse → import → SwiftData → AgentBridge.updateMCPServers
    func testFullImportPipeline() throws {
        let (_, context) = try makeContext()
        let store = MCPServerConfigStore(modelContext: context, keychainManager: MockKeychainManager())
        let manager = MCPConfigFileManager()
        let bridge = AgentBridge()
        bridge.mcpConfigStore = store

        // Write config file
        let configPath = tempDirectory + "/.claude/settings.json"
        let json = """
        {
          "mcpServers": {
            "integration-server": {
              "command": "npx",
              "args": ["-y", "mcp-server-fs", "/tmp"],
              "env": {"KEY": "value"},
              "type": "stdio"
            }
          }
        }
        """
        try writeConfigFile(path: configPath, json: json)

        // Import into SwiftData
        try manager.importFromFile(atPath: configPath, scope: .global, workspacePath: nil, store: store)

        // Verify SwiftData has the config
        let configs = try store.list()
        XCTAssertEqual(configs.count, 1)
        XCTAssertEqual(configs.first?.name, "integration-server")
        XCTAssertEqual(configs.first?.transportType, .stdio)
        XCTAssertTrue(configs.first?.enabled ?? false)

        // Verify SDK conversion works
        let enabledConfigs = try store.enabledConfigsForWorkspace(nil)
        let sdkDict = store.toSDKConfigs(enabledConfigs)
        XCTAssertNotNil(sdkDict["integration-server"])

        // Hot-update should not crash (agent is not running, so it's a no-op)
        bridge.updateMCPServers()
    }

    // [P0] Import then re-import with changes updates SwiftData correctly
    func testReimportUpdatesConfigs() throws {
        let (_, context) = try makeContext()
        let store = MCPServerConfigStore(modelContext: context, keychainManager: MockKeychainManager())
        let manager = MCPConfigFileManager()

        let configPath = tempDirectory + "/.claude/settings.json"

        // First import
        let firstJSON = """
        {
          "mcpServers": {
            "changing-server": {
              "command": "old-command",
              "args": [],
              "type": "stdio"
            }
          }
        }
        """
        try writeConfigFile(path: configPath, json: firstJSON)
        try manager.importFromFile(atPath: configPath, scope: .global, workspacePath: nil, store: store)

        var configs = try store.list()
        XCTAssertEqual(configs.count, 1)
        XCTAssertEqual(configs.first?.command, "old-command")

        // Second import with changes
        let secondJSON = """
        {
          "mcpServers": {
            "changing-server": {
              "url": "https://new-url.example.com/mcp",
              "type": "sse"
            }
          }
        }
        """
        try writeConfigFile(path: configPath, json: secondJSON)
        try manager.importFromFile(atPath: configPath, scope: .global, workspacePath: nil, store: store)

        configs = try store.list()
        XCTAssertEqual(configs.count, 1, "Should still be 1 config (updated, not duplicated)")
        XCTAssertEqual(configs.first?.transportType, .sse, "Type should be updated to sse")
        XCTAssertEqual(configs.first?.url, "https://new-url.example.com/mcp")
    }

    // [P0] Import with multiple servers preserves dedup behavior
    func testImportMultipleServersDedup() throws {
        let (_, context) = try makeContext()
        let store = MCPServerConfigStore(modelContext: context, keychainManager: MockKeychainManager())
        let manager = MCPConfigFileManager()

        // Pre-add one server to SwiftData
        _ = try store.add(
            name: "existing-server",
            transportType: .stdio,
            command: "old-cmd",
            url: nil,
            args: nil,
            env: nil,
            headers: nil,
            enabled: true,
            scope: .global,
            workspacePath: nil
        )

        let configPath = tempDirectory + "/.claude/settings.json"
        let json = """
        {
          "mcpServers": {
            "existing-server": {
              "command": "new-cmd",
              "type": "stdio"
            },
            "brand-new-server": {
              "url": "https://brand-new.com/mcp",
              "type": "sse"
            }
          }
        }
        """
        try writeConfigFile(path: configPath, json: json)
        try manager.importFromFile(atPath: configPath, scope: .global, workspacePath: nil, store: store)

        let configs = try store.list()
        XCTAssertEqual(configs.count, 2)

        let existing = configs.first { $0.name == "existing-server" }
        XCTAssertEqual(existing?.command, "new-cmd", "Existing should be updated")

        let brandNew = configs.first { $0.name == "brand-new-server" }
        XCTAssertNotNil(brandNew, "New server should be added")
        XCTAssertEqual(brandNew?.transportType, .sse)
    }

    // [P0] Scope-aware import: project-scoped imports don't collide with global
    func testScopeAwareImport() throws {
        let (_, context) = try makeContext()
        let store = MCPServerConfigStore(modelContext: context, keychainManager: MockKeychainManager())
        let manager = MCPConfigFileManager()

        // Import with project scope
        let projectConfigPath = tempDirectory + "/project/.claude/settings.json"
        let projectJSON = """
        {
          "mcpServers": {
            "project-mcp": {
              "command": "project-cmd",
              "type": "stdio"
            }
          }
        }
        """
        try writeConfigFile(path: projectConfigPath, json: projectJSON)
        try manager.importFromFile(
            atPath: projectConfigPath,
            scope: .project,
            workspacePath: "/my/project",
            store: store
        )

        // Import with global scope
        let globalConfigPath = tempDirectory + "/global/.claude/settings.json"
        let globalJSON = """
        {
          "mcpServers": {
            "global-mcp": {
              "url": "https://global.example.com/mcp",
              "type": "sse"
            }
          }
        }
        """
        try writeConfigFile(path: globalConfigPath, json: globalJSON)
        try manager.importFromFile(
            atPath: globalConfigPath,
            scope: .global,
            workspacePath: nil,
            store: store
        )

        let allConfigs = try store.list()
        XCTAssertEqual(allConfigs.count, 2)

        let projectConfigs = try store.list(scope: .project)
        XCTAssertEqual(projectConfigs.count, 1)
        XCTAssertEqual(projectConfigs.first?.name, "project-mcp")
        XCTAssertEqual(projectConfigs.first?.workspacePath, "/my/project")

        let globalConfigs = try store.list(scope: .global)
        XCTAssertEqual(globalConfigs.count, 1)
        XCTAssertEqual(globalConfigs.first?.name, "global-mcp")

        // Workspace query should merge both
        let workspaceConfigs = try store.enabledConfigsForWorkspace("/my/project")
        XCTAssertEqual(workspaceConfigs.count, 2, "Should see both global + project configs for matching workspace")
    }

    // [P0] Empty config file import doesn't clear existing SwiftData configs
    func testEmptyFileImportPreservesExisting() throws {
        let (_, context) = try makeContext()
        let store = MCPServerConfigStore(modelContext: context, keychainManager: MockKeychainManager())
        let manager = MCPConfigFileManager()

        // Pre-add config
        _ = try store.add(
            name: "pre-existing",
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

        // Import empty config file
        let configPath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: configPath, json: "{\"mcpServers\": {}}")
        try manager.importFromFile(atPath: configPath, scope: .global, workspacePath: nil, store: store)

        let configs = try store.list()
        XCTAssertEqual(configs.count, 1, "Pre-existing config should be preserved when file has empty mcpServers")
        XCTAssertEqual(configs.first?.name, "pre-existing")
    }

    // MARK: - AC#4: AgentBridge hot-update integration

    // [P0] AgentBridge.updateMCPServers reads from MCPServerConfigStore after import
    func testAgentBridgeHotUpdateAfterImport() throws {
        let (_, context) = try makeContext()
        let store = MCPServerConfigStore(modelContext: context, keychainManager: MockKeychainManager())
        let bridge = AgentBridge()
        bridge.mcpConfigStore = store

        let manager = MCPConfigFileManager()
        let configPath = tempDirectory + "/.claude/settings.json"
        let json = """
        {
          "mcpServers": {
            "hot-update-server": {
              "command": "npx",
              "args": ["-y", "mcp-server"],
              "type": "stdio"
            }
          }
        }
        """
        try writeConfigFile(path: configPath, json: json)

        try manager.importFromFile(atPath: configPath, scope: .global, workspacePath: nil, store: store)

        // Bridge should be able to read imported configs for hot-update
        let enabledConfigs = try store.enabledConfigsForWorkspace(nil)
        XCTAssertEqual(enabledConfigs.count, 1)

        let sdkDict = store.toSDKConfigs(enabledConfigs)
        XCTAssertNotNil(sdkDict["hot-update-server"])

        // updateMCPServers should not crash (agent not running = no-op internally)
        bridge.updateMCPServers()
    }

    // [P0] Import from file then disable → hot-update reflects disabled state
    func testImportThenDisableReflectsInHotUpdate() throws {
        let (_, context) = try makeContext()
        let store = MCPServerConfigStore(modelContext: context, keychainManager: MockKeychainManager())
        let manager = MCPConfigFileManager()
        let bridge = AgentBridge()
        bridge.mcpConfigStore = store

        let configPath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: configPath, json: """
        {
          "mcpServers": {
            "to-disable": {
              "command": "npx",
              "type": "stdio"
            }
          }
        }
        """)

        try manager.importFromFile(atPath: configPath, scope: .global, workspacePath: nil, store: store)

        // Disable the config
        let configs = try store.list()
        _ = try store.update(configs.first!, enabled: false)

        // Hot-update should now see 0 enabled configs
        let enabledConfigs = try store.enabledConfigsForWorkspace(nil)
        XCTAssertTrue(enabledConfigs.isEmpty, "Disabled config should not be in enabled list")

        bridge.updateMCPServers()
    }

    // MARK: - AC#3: 在 Finder 中显示 + 文件状态

    // [P0] Manager correctly reports file existence for temp test files
    func testManagerReportsCorrectFileExistence() throws {
        let manager = MCPConfigFileManager()
        let existingPath = tempDirectory + "/.claude/settings.json"
        try writeConfigFile(path: existingPath, json: "{}")

        XCTAssertTrue(manager.configFileExists(atPath: existingPath))
        XCTAssertFalse(manager.configFileExists(atPath: tempDirectory + "/nonexistent.json"))
    }

    // [P0] Manager path resolution works for both scopes
    func testManagerPathResolutionBothScopes() {
        let manager = MCPConfigFileManager()

        // Global
        let globalPath = manager.configFilePath(scope: .global, workspacePath: nil)
        XCTAssertNotNil(globalPath)

        // Project with workspace
        let projectPath = manager.configFilePath(scope: .project, workspacePath: "/my/project")
        XCTAssertNotNil(projectPath)
        XCTAssertEqual(projectPath, "/my/project/.claude/settings.json")

        // Project without workspace
        let nilProjectPath = manager.configFilePath(scope: .project, workspacePath: nil)
        XCTAssertNil(nilProjectPath)
    }
}
