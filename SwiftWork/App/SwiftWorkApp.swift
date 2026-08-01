import SwiftUI
import SwiftData

@main
struct SwiftWorkApp: App {
    @State private var appState = AppState()
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try SwiftWorkPersistentStore.makeContainer()
        } catch {
            fatalError("Unable to open the SwiftWork data store: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .defaultSize(width: 1200, height: 800)
        .modelContainer(modelContainer)
        .commands {
            // File menu — replace default "New Window" with "New Session"
            CommandGroup(replacing: .newItem) {
                Button("New Session") {
                    appState.sessionViewModel.createSession()
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            // View menu — add Inspector and Debug Panel toggles
            CommandGroup(after: .toolbar) {
                Button("Toggle Inspector") {
                    withAnimation {
                        appState.isInspectorVisible.toggle()
                    }
                }
                .keyboardShortcut("i", modifiers: .command)

                Button("Toggle Debug Panel") {
                    withAnimation {
                        appState.isDebugPanelVisible.toggle()
                    }
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }

            // App menu — replace default "Settings..." with custom binding
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    appState.isSettingsPresented = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

/// Owns the application's explicit SwiftData location.
///
/// Older builds used SwiftData's implicit `default.store`, which allowed an
/// installed release and an Xcode Debug build to mutate the same database.
/// Debug and Release now use separate files under the SwiftWork directory. On
/// first launch, legacy data is copied model-by-model into the isolated store.
@MainActor
enum SwiftWorkPersistentStore {
    static var defaultStoreName: String {
        #if DEBUG
        "SwiftWork-Debug.store"
        #else
        "SwiftWork.store"
        #endif
    }

    static let schema = Schema([
        Session.self,
        Event.self,
        PermissionRule.self,
        AppConfiguration.self,
        MCPServerConfig.self,
    ])

    static func makeContainer(
        applicationSupportDirectory: URL? = nil,
        storeName: String? = nil,
        keychainManager _: KeychainManaging? = nil
    ) throws -> ModelContainer {
        let supportDirectory = try applicationSupportDirectory ?? defaultApplicationSupportDirectory()
        let destinationURL = destinationStoreURL(
            applicationSupportDirectory: supportDirectory,
            storeName: storeName ?? defaultStoreName
        )
        let legacyURL = supportDirectory.appendingPathComponent("default.store")

        try FileManager.default.createDirectory(
            at: destinationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try restrictDirectoryPermissions(at: destinationURL.deletingLastPathComponent())

        if !FileManager.default.fileExists(atPath: destinationURL.path),
           FileManager.default.fileExists(atPath: legacyURL.path) {
            do {
                let migratedContainer = try migrateLegacyStore(
                    from: legacyURL,
                    to: destinationURL
                )
                try restrictStoreFilePermissions(at: destinationURL)
                return migratedContainer
            } catch {
                removeNewStoreFiles(at: destinationURL)
                throw error
            }
        }

        let modelContainer = try container(at: destinationURL)
        try restrictStoreFilePermissions(at: destinationURL)
        return modelContainer
    }

    static func destinationStoreURL(
        applicationSupportDirectory: URL,
        storeName: String
    ) -> URL {
        applicationSupportDirectory
            .appendingPathComponent(Constants.appName, isDirectory: true)
            .appendingPathComponent(storeName)
    }

    private static func defaultApplicationSupportDirectory() throws -> URL {
        guard let directory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw AppError(
                domain: .data,
                code: "APP_SUPPORT_DIRECTORY_UNAVAILABLE",
                message: "Application Support directory is unavailable"
            )
        }
        return directory
    }

    private static func container(at url: URL) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            "SwiftWork",
            schema: schema,
            url: url
        )
        return try ModelContainer(for: schema, configurations: configuration)
    }

    /// MCP headers and environment variables may contain credentials. Keep the
    /// store directory private so any SQLite sidecar created later is protected,
    /// and tighten the files already created by SwiftData as defense in depth.
    private static func restrictDirectoryPermissions(at url: URL) throws {
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: url.path
        )
    }

    private static func restrictStoreFilePermissions(at url: URL) throws {
        for suffix in ["", "-wal", "-shm"] {
            let candidate = URL(fileURLWithPath: url.path + suffix)
            guard FileManager.default.fileExists(atPath: candidate.path) else {
                continue
            }
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: candidate.path
            )
        }
    }

    private static func migrateLegacyStore(
        from legacyURL: URL,
        to destinationURL: URL
    ) throws -> ModelContainer {
        let legacyContainer = try container(at: legacyURL)
        let legacyContext = ModelContext(legacyContainer)

        let legacyMCPConfigs = try legacyContext.fetch(FetchDescriptor<MCPServerConfig>())

        let destinationContainer = try container(at: destinationURL)
        let destinationContext = ModelContext(destinationContainer)

        var sessionsByID: [UUID: Session] = [:]
        for old in try legacyContext.fetch(FetchDescriptor<Session>()) {
            let new = Session(
                title: old.title,
                workspacePath: old.workspacePath,
                workspaceBookmark: old.workspaceBookmark
            )
            new.id = old.id
            new.createdAt = old.createdAt
            new.updatedAt = old.updatedAt
            new.hasUnreadResult = old.hasUnreadResult
            destinationContext.insert(new)
            sessionsByID[old.id] = new
        }

        for old in try legacyContext.fetch(FetchDescriptor<Event>()) {
            let new = Event(
                sessionID: old.sessionID,
                eventType: old.eventType,
                rawData: old.rawData,
                timestamp: old.timestamp,
                order: old.order
            )
            new.id = old.id
            new.session = sessionsByID[old.sessionID]
            destinationContext.insert(new)
        }

        for old in try legacyContext.fetch(FetchDescriptor<PermissionRule>()) {
            let new = PermissionRule(
                toolName: old.toolName,
                pattern: old.pattern,
                decision: old.decision
            )
            new.id = old.id
            new.createdAt = old.createdAt
            destinationContext.insert(new)
        }

        for old in try legacyContext.fetch(FetchDescriptor<AppConfiguration>()) {
            let new = AppConfiguration(key: old.key, value: old.value)
            new.id = old.id
            new.updatedAt = old.updatedAt
            destinationContext.insert(new)
        }

        for old in legacyMCPConfigs {
            let new = MCPServerConfig(
                name: old.name,
                transportType: old.transportType,
                command: old.command,
                url: old.url,
                args: old.args,
                env: old.env,
                headers: old.headers,
                enabled: old.enabled,
                scope: old.scope,
                workspacePath: old.workspacePath
            )
            new.id = old.id
            new.createdAt = old.createdAt
            new.updatedAt = old.updatedAt
            destinationContext.insert(new)
        }

        try destinationContext.save()
        return destinationContainer
    }

    /// Removes only a newly-created destination after a failed migration. The
    /// legacy source is never deleted, so recovery remains possible.
    private static func removeNewStoreFiles(at url: URL) {
        for suffix in ["", "-wal", "-shm"] {
            let candidate = URL(fileURLWithPath: url.path + suffix)
            try? FileManager.default.removeItem(at: candidate)
        }
    }
}
