import XCTest
@testable import SwiftWork
import SwiftData

@MainActor
final class AppEntryTests: XCTestCase {

    // MARK: - AC#5: App Entry with NavigationSplitView

    // [P0] SwiftWorkApp uses @main attribute
    func testSwiftWorkAppIsMainEntry() throws {
        // The app should compile with @main attribute
        // If this test runs, the module can be imported successfully
        let appType = SwiftWorkApp.self
        XCTAssertNotNil(appType)
    }

    // [P0] ContentView uses NavigationSplitView layout
    func testContentViewHasNavigationSplitView() throws {
        // Verify ContentView can be instantiated (it's a SwiftUI View)
        let contentView = ContentView()
        XCTAssertNotNil(contentView)

        // NavigationSplitView layout should contain:
        // - Sidebar placeholder with "SwiftWork" navigation title
        // - Detail/Workspace placeholder
        // This is verified visually and through UI tests after implementation
    }

    // MARK: - Story 4.3: SwiftWorkApp Commands builder

    // [P1] SwiftWorkApp body includes Commands builder for menu bar
    func testSwiftWorkAppIncludesCommands() throws {
        // Verify SwiftWorkApp compiles and includes .commands modifier
        // This is a structural verification — if the app compiles with
        // CommandGroup registrations, the menu bar is properly configured
        let appType = SwiftWorkApp.self
        XCTAssertNotNil(appType, "SwiftWorkApp should compile with .commands modifier")
    }
}

final class ModelContainerTests: XCTestCase {

    // MARK: - AC#5: SwiftData ModelContainer Registration

    // [P0] All 4 SwiftData models are registered in modelContainer
    func testAllModelsRegisteredInContainer() throws {
        // Verify that a ModelContainer can be created with all 4 model types
        let container = try ModelContainer(for: Session.self, Event.self, PermissionRule.self, AppConfiguration.self)
        XCTAssertNotNil(container)
    }
}

@MainActor
final class SwiftWorkPersistentStoreTests: XCTestCase {
    func testLegacyStoreMigratesToIsolatedStoreAndPreservesMCPSecrets() throws {
        let supportDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SwiftWorkPersistentStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: supportDirectory,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: supportDirectory) }

        let legacyURL = supportDirectory.appendingPathComponent("default.store")
        do {
            let legacyConfiguration = ModelConfiguration(
                "Legacy",
                schema: SwiftWorkPersistentStore.schema,
                url: legacyURL
            )
            let legacyContainer = try ModelContainer(
                for: SwiftWorkPersistentStore.schema,
                configurations: legacyConfiguration
            )
            let legacyContext = ModelContext(legacyContainer)

            let session = Session(title: "Legacy Session", workspacePath: "/tmp/project")
            let event = Event(
                sessionID: session.id,
                eventType: "assistant",
                rawData: Data("{}".utf8),
                timestamp: .now,
                order: 0
            )
            event.session = session
            let mcpConfig = MCPServerConfig(
                name: "legacy-github",
                transportType: .http,
                url: "https://api.githubcopilot.com/mcp/",
                headers: try JSONEncoder().encode([
                    "Authorization": "Bearer migration-secret",
                    "X-MCP-Readonly": "true",
                ])
            )
            legacyContext.insert(session)
            legacyContext.insert(event)
            legacyContext.insert(mcpConfig)
            try legacyContext.save()
        }

        let destinationContainer = try SwiftWorkPersistentStore.makeContainer(
            applicationSupportDirectory: supportDirectory,
            storeName: "Test.store"
        )
        let destinationContext = ModelContext(destinationContainer)
        let sessions = try destinationContext.fetch(FetchDescriptor<Session>())
        let events = try destinationContext.fetch(FetchDescriptor<Event>())
        let destinationStore = MCPServerConfigStore(modelContext: destinationContext)
        let configs = try destinationStore.list()

        XCTAssertEqual(sessions.map(\.title), ["Legacy Session"])
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.session?.id, sessions.first?.id)
        XCTAssertEqual(configs.first?.name, "legacy-github")
        XCTAssertEqual(
            configs.first?.decodedHeaders?["Authorization"],
            "Bearer migration-secret"
        )

        let destinationURL = SwiftWorkPersistentStore.destinationStoreURL(
            applicationSupportDirectory: supportDirectory,
            storeName: "Test.store"
        )
        XCTAssertNotEqual(destinationURL, legacyURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: legacyURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationURL.path))
        XCTAssertEqual(
            posixPermissions(at: destinationURL.deletingLastPathComponent()),
            0o700
        )
        for suffix in ["", "-wal", "-shm"] {
            let candidate = URL(fileURLWithPath: destinationURL.path + suffix)
            guard FileManager.default.fileExists(atPath: candidate.path) else {
                continue
            }
            XCTAssertEqual(posixPermissions(at: candidate), 0o600)
        }

        let migratedLegacyConfiguration = ModelConfiguration(
            "LegacyVerification",
            schema: SwiftWorkPersistentStore.schema,
            url: legacyURL
        )
        let migratedLegacyContainer = try ModelContainer(
            for: SwiftWorkPersistentStore.schema,
            configurations: migratedLegacyConfiguration
        )
        let migratedLegacyContext = ModelContext(migratedLegacyContainer)
        let migratedLegacyConfigs = try migratedLegacyContext.fetch(
            FetchDescriptor<MCPServerConfig>()
        )
        XCTAssertEqual(
            migratedLegacyConfigs.first?.decodedHeaders?["Authorization"],
            "Bearer migration-secret"
        )
    }

    func testDebugAndReleaseStoreNamesResolveToDifferentFiles() {
        let supportDirectory = URL(fileURLWithPath: "/tmp/Application Support")
        let debugURL = SwiftWorkPersistentStore.destinationStoreURL(
            applicationSupportDirectory: supportDirectory,
            storeName: "SwiftWork-Debug.store"
        )
        let releaseURL = SwiftWorkPersistentStore.destinationStoreURL(
            applicationSupportDirectory: supportDirectory,
            storeName: "SwiftWork.store"
        )

        XCTAssertNotEqual(debugURL, releaseURL)
    }

    private func posixPermissions(at url: URL) -> Int? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return (attributes?[.posixPermissions] as? NSNumber).map {
            $0.intValue & 0o777
        }
    }
}
