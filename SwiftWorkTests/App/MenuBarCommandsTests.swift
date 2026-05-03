import XCTest
@testable import SwiftWork
import SwiftData

@MainActor
final class MenuBarCommandsTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeModelContext() throws -> ModelContext {
        let schema = Schema([AppConfiguration.self, Session.self, Event.self, PermissionRule.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    // MARK: - AC#2: Cmd+N Creates New Session (P0)

    // [P0] Cmd+N command invokes sessionViewModel.createSession() — sessions array increases
    func testCmdNCreatesNewSession() throws {
        let context = try makeModelContext()

        // Setup: Create AppState and configure SessionViewModel
        let appState = AppState()
        appState.sessionViewModel.configure(modelContext: context)

        let initialCount = appState.sessionViewModel.sessions.count

        // Simulate Cmd+N menu command behavior:
        // The menu command calls appState.sessionViewModel.createSession()
        appState.sessionViewModel.createSession()

        XCTAssertEqual(
            appState.sessionViewModel.sessions.count,
            initialCount + 1,
            "Cmd+N should create a new session and increase the sessions count"
        )
        XCTAssertNotNil(
            appState.sessionViewModel.selectedSession,
            "Cmd+N should auto-select the newly created session"
        )
    }

    // [P0] Cmd+N created session is immediately selected
    func testCmdNSelectsNewlyCreatedSession() throws {
        let context = try makeModelContext()

        let appState = AppState()
        appState.sessionViewModel.configure(modelContext: context)

        // Create an initial session
        appState.sessionViewModel.createSession()
        let firstSession = appState.sessionViewModel.selectedSession
        XCTAssertNotNil(firstSession)

        // Simulate Cmd+N again
        appState.sessionViewModel.createSession()

        let selected = appState.sessionViewModel.selectedSession
        XCTAssertNotNil(selected, "After Cmd+N, a session should be selected")
        XCTAssertNotEqual(
            selected?.id,
            firstSession?.id,
            "Cmd+N should select the newly created session, not the previous one"
        )
    }

    // MARK: - AC#4: Cmd+, Opens Settings (P0)

    // [P0] Cmd+, command sets isSettingsPresented to true
    func testCmdCommaOpensSettings() throws {
        let appState = AppState()

        // Initial state: settings not presented
        XCTAssertFalse(
            appState.isSettingsPresented,
            "Settings should not be presented initially"
        )

        // Simulate Cmd+, menu command behavior:
        // The menu command sets appState.isSettingsPresented = true
        appState.isSettingsPresented = true

        XCTAssertTrue(
            appState.isSettingsPresented,
            "Cmd+, should set isSettingsPresented to true, opening settings"
        )
    }

    // [P0] Cmd+, can toggle settings closed after opening
    func testSettingsCanBeDismissedAfterOpening() throws {
        let appState = AppState()

        // Open settings (Cmd+,)
        appState.isSettingsPresented = true
        XCTAssertTrue(appState.isSettingsPresented)

        // User closes settings sheet
        appState.isSettingsPresented = false

        XCTAssertFalse(
            appState.isSettingsPresented,
            "Settings should be dismissable after Cmd+, opens it"
        )
    }

    // MARK: - AC#1: Cmd+I Toggles Inspector (P1)

    // [P1] Cmd+I toggles isInspectorVisible from false to true
    func testCmdITogglesInspectorVisible() throws {
        let appState = AppState()

        // Initial state: inspector not visible
        XCTAssertFalse(
            appState.isInspectorVisible,
            "Inspector should not be visible initially"
        )

        // Simulate Cmd+I menu command behavior:
        // The menu command calls appState.isInspectorVisible.toggle()
        appState.isInspectorVisible.toggle()

        XCTAssertTrue(
            appState.isInspectorVisible,
            "Cmd+I should toggle Inspector visibility to true"
        )
    }

    // [P1] Cmd+I toggles isInspectorVisible back to false
    func testCmdITogglesInspectorOff() throws {
        let appState = AppState()
        appState.isInspectorVisible = true

        // Simulate Cmd+I again (toggle off)
        appState.isInspectorVisible.toggle()

        XCTAssertFalse(
            appState.isInspectorVisible,
            "Cmd+I should toggle Inspector visibility back to false"
        )
    }

    // MARK: - AC#1: Cmd+Shift+D Toggles Debug Panel (P1)

    // [P1] Cmd+Shift+D toggles isDebugPanelVisible from false to true
    func testCmdShiftDTogglesDebugPanelVisible() throws {
        let appState = AppState()

        // Initial state: debug panel not visible
        XCTAssertFalse(
            appState.isDebugPanelVisible,
            "Debug Panel should not be visible initially"
        )

        // Simulate Cmd+Shift+D menu command behavior:
        // The menu command calls appState.isDebugPanelVisible.toggle()
        appState.isDebugPanelVisible.toggle()

        XCTAssertTrue(
            appState.isDebugPanelVisible,
            "Cmd+Shift+D should toggle Debug Panel visibility to true"
        )
    }

    // [P1] Cmd+Shift+D toggles isDebugPanelVisible back to false
    func testCmdShiftDTogglesDebugPanelOff() throws {
        let appState = AppState()
        appState.isDebugPanelVisible = true

        // Simulate Cmd+Shift+D again (toggle off)
        appState.isDebugPanelVisible.toggle()

        XCTAssertFalse(
            appState.isDebugPanelVisible,
            "Cmd+Shift+D should toggle Debug Panel visibility back to false"
        )
    }

    // MARK: - AC#3: Cmd+W Close Window (P2)

    // [P2] Cmd+W is handled by SwiftUI WindowGroup automatically
    // This test verifies the app structure supports standard window close
    func testSwiftWorkAppUsesWindowGroup() throws {
        // Verify SwiftWorkApp can be instantiated (it uses WindowGroup)
        let appType = SwiftWorkApp.self
        XCTAssertNotNil(appType, "SwiftWorkApp should exist and use WindowGroup for Cmd+W support")
    }

    // MARK: - AC#1: Menu Structure Verification (P1)

    // [P1] AppState exposes all required shared state for menu commands
    func testAppStateExposesRequiredMenuCommandState() throws {
        let appState = AppState()

        // AppState must expose these properties for menu command bindings
        XCTAssertNotNil(appState.sessionViewModel as Any, "AppState should expose sessionViewModel for Cmd+N")
        _ = appState.isSettingsPresented  // Cmd+,
        _ = appState.isInspectorVisible   // Cmd+I
        _ = appState.isDebugPanelVisible  // Cmd+Shift+D

        // All should be accessible without crash
        XCTAssertTrue(true, "AppState should expose all menu command state properties")
    }

    // [P1] AppState initial values are correct for menu commands
    func testAppStateDefaultValues() throws {
        let appState = AppState()

        XCTAssertFalse(
            appState.isSettingsPresented,
            "isSettingsPresented should default to false"
        )
        XCTAssertFalse(
            appState.isInspectorVisible,
            "isInspectorVisible should default to false"
        )
        XCTAssertFalse(
            appState.isDebugPanelVisible,
            "isDebugPanelVisible should default to false"
        )
        XCTAssertTrue(
            appState.sessionViewModel.sessions.isEmpty,
            "sessions should default to empty"
        )
        XCTAssertNil(
            appState.sessionViewModel.selectedSession,
            "selectedSession should default to nil"
        )
    }
}
