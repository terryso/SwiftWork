import XCTest
@testable import SwiftWork
import SwiftData

@MainActor
final class AppStateIntegrationTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeModelContext() throws -> ModelContext {
        let schema = Schema([AppConfiguration.self, Session.self, Event.self, PermissionRule.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    // MARK: - AppState Shared State Integration (P0)

    // [P0] AppState can be created and configured with ModelContext
    func testAppStateConfigurationWithModelContext() throws {
        let context = try makeModelContext()
        let appState = AppState()

        appState.sessionViewModel.configure(modelContext: context)
        appState.settingsViewModel.configure(modelContext: context)

        // AppState should hold configured ViewModels
        XCTAssertTrue(
            appState.sessionViewModel.sessions.isEmpty,
            "SessionViewModel should be configured and start with empty sessions"
        )
    }

    // [P0] Multiple components reading from same AppState see consistent state
    func testSharedStateConsistencyAcrossReaders() throws {
        let context = try makeModelContext()
        let appState = AppState()
        appState.sessionViewModel.configure(modelContext: context)

        // Simulate Cmd+N
        appState.sessionViewModel.createSession()

        // Both "ContentView" and "SidebarView" should see the same state
        XCTAssertEqual(
            appState.sessionViewModel.sessions.count,
            1,
            "All components reading AppState should see the same session count"
        )
        XCTAssertNotNil(
            appState.sessionViewModel.selectedSession,
            "All components reading AppState should see the selected session"
        )
    }

    // [P0] Menu command state changes are observable by SwiftUI views
    func testMenuCommandStateChangesAreObservable() throws {
        let appState = AppState()

        // Simulate menu command toggling Inspector
        appState.isInspectorVisible.toggle()
        XCTAssertTrue(appState.isInspectorVisible, "State change should be immediately visible")

        // Simulate menu command toggling Debug Panel
        appState.isDebugPanelVisible.toggle()
        XCTAssertTrue(appState.isDebugPanelVisible, "State change should be immediately visible")

        // Simulate menu command opening settings
        appState.isSettingsPresented = true
        XCTAssertTrue(appState.isSettingsPresented, "State change should be immediately visible")
    }

    // MARK: - State Persistence Integration (P1)

    // [P1] Inspector visibility state can be persisted via AppStateManager
    func testInspectorVisibilityPersistedViaAppStateManager() throws {
        let context = try makeModelContext()
        let appState = AppState()
        let manager = AppStateManager()
        manager.configure(modelContext: context)
        appState.sessionViewModel.setAppStateManager(manager)

        // Toggle inspector via "menu command"
        appState.isInspectorVisible = true

        // Simulate the onChange handler that persists visibility
        manager.saveInspectorVisibility(appState.isInspectorVisible)

        // Reload from persistence
        let restoredManager = AppStateManager()
        restoredManager.configure(modelContext: context)
        restoredManager.loadAppState()

        XCTAssertTrue(
            restoredManager.isInspectorVisible,
            "Inspector visibility should be persisted and restorable"
        )
    }

    // [P1] Debug Panel visibility state can be persisted via AppStateManager
    func testDebugPanelVisibilityPersistedViaAppStateManager() throws {
        let context = try makeModelContext()
        let manager = AppStateManager()
        manager.configure(modelContext: context)

        // Toggle debug panel via "menu command"
        manager.saveDebugPanelVisibility(true)

        // Reload from persistence
        let restoredManager = AppStateManager()
        restoredManager.configure(modelContext: context)
        restoredManager.loadAppState()

        XCTAssertTrue(
            restoredManager.isDebugPanelVisible,
            "Debug Panel visibility should be persisted and restorable"
        )
    }

    // MARK: - ContentView + AppState Migration (P1)

    // [P1] AppState holds the same state types that ContentView previously held
    func testAppStateProvidesContentViewEquivalentState() throws {
        let appState = AppState()

        // These are the exact state properties ContentView needs:
        // - sessionViewModel (was @State)
        // - settingsViewModel (was @State)
        // - isSettingsPresented (was @State)
        // - isInspectorVisible (was @State)
        // - isDebugPanelVisible (was @State)

        // Verify types exist and are accessible
        let _: SessionViewModel = appState.sessionViewModel
        let _: SettingsViewModel = appState.settingsViewModel
        let _: Bool = appState.isSettingsPresented
        let _: Bool = appState.isInspectorVisible
        let _: Bool = appState.isDebugPanelVisible

        XCTAssertTrue(true, "AppState should provide all state types that ContentView needs")
    }

    // [P1] AppState can be used to create session and persist selection
    func testCreateSessionAndPersistSelection() throws {
        let context = try makeModelContext()
        let appState = AppState()
        appState.sessionViewModel.configure(modelContext: context)

        let manager = AppStateManager()
        manager.configure(modelContext: context)
        appState.sessionViewModel.setAppStateManager(manager)

        // Simulate Cmd+N
        appState.sessionViewModel.createSession()

        let createdSessionID = appState.sessionViewModel.selectedSession?.id
        XCTAssertNotNil(createdSessionID, "Cmd+N should create and select a session")

        // Verify the selection was persisted via AppStateManager
        XCTAssertEqual(
            manager.lastActiveSessionID,
            createdSessionID,
            "Created session ID should be persisted for app restart restore"
        )
    }
}
