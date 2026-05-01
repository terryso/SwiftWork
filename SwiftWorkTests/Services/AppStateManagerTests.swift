import XCTest
@testable import SwiftWork
import SwiftData

@MainActor
final class AppStateManagerTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeModelContext() throws -> ModelContext {
        let schema = Schema([AppConfiguration.self, Session.self, Event.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    private func makeManager() -> AppStateManager {
        AppStateManager()
    }

    // MARK: - AC#1: Last Active Session ID

    // [P0] saveLastActiveSessionID then loadAppState returns the saved UUID
    func testSaveAndLoadLastActiveSessionID() async throws {
        let context = try makeModelContext()
        let manager = makeManager()
        manager.configure(modelContext: context)

        let sessionID = UUID()
        manager.saveLastActiveSessionID(sessionID)

        // Create a fresh manager to verify persistence
        let freshManager = makeManager()
        freshManager.configure(modelContext: context)
        freshManager.loadAppState()

        XCTAssertEqual(
            freshManager.lastActiveSessionID,
            sessionID,
            "loadAppState should return the previously saved session UUID"
        )
    }

    // [P0] loadAppState populates all cached properties from saved state
    func testLoadAppStateReturnsSavedValues() async throws {
        let context = try makeModelContext()
        let manager = makeManager()
        manager.configure(modelContext: context)

        let sessionID = UUID()
        let frame = NSRect(x: 100, y: 200, width: 1200, height: 800)

        manager.saveLastActiveSessionID(sessionID)
        manager.saveWindowFrame(frame)
        manager.saveInspectorVisibility(true)

        // Load into fresh manager
        let freshManager = makeManager()
        freshManager.configure(modelContext: context)
        freshManager.loadAppState()

        XCTAssertEqual(freshManager.lastActiveSessionID, sessionID)
        XCTAssertEqual(freshManager.windowFrame, frame)
        XCTAssertTrue(freshManager.isInspectorVisible)
    }

    // [P1] saving nil session ID clears the stored value
    func testSaveLastActiveSessionIDNil() async throws {
        let context = try makeModelContext()
        let manager = makeManager()
        manager.configure(modelContext: context)

        let sessionID = UUID()
        manager.saveLastActiveSessionID(sessionID)
        manager.saveLastActiveSessionID(nil)

        let freshManager = makeManager()
        freshManager.configure(modelContext: context)
        freshManager.loadAppState()

        XCTAssertNil(freshManager.lastActiveSessionID, "Saving nil should clear the session ID")
    }

    // MARK: - AC#1: Window Frame

    // [P0] saveWindowFrame then load returns the same NSRect
    func testSaveAndLoadWindowFrame() async throws {
        let context = try makeModelContext()
        let manager = makeManager()
        manager.configure(modelContext: context)

        let frame = NSRect(x: 50, y: 100, width: 1400, height: 900)
        manager.saveWindowFrame(frame)

        let freshManager = makeManager()
        freshManager.configure(modelContext: context)
        freshManager.loadAppState()

        XCTAssertEqual(freshManager.windowFrame, frame, "Loaded frame should match saved frame")
    }

    // [P0] NSStringFromRect/NSRectFromString round-trip preserves origin and size
    func testNSRectSerializationRoundTrip() {
        let original = NSRect(x: 123.456, y: 789.012, width: 1024, height: 768)
        let string = NSStringFromRect(original)
        let restored = NSRectFromString(string)

        XCTAssertEqual(restored.origin.x, original.origin.x, accuracy: 0.001)
        XCTAssertEqual(restored.origin.y, original.origin.y, accuracy: 0.001)
        XCTAssertEqual(restored.size.width, original.size.width, accuracy: 0.001)
        XCTAssertEqual(restored.size.height, original.size.height, accuracy: 0.001)
    }

    // [P1] no saved frame returns nil
    func testWindowFrameDefaultValue() async throws {
        let context = try makeModelContext()
        let manager = makeManager()
        manager.configure(modelContext: context)
        manager.loadAppState()

        XCTAssertNil(manager.windowFrame, "Default window frame should be nil when not saved")
    }

    // MARK: - AC#1: Inspector Visibility

    // [P0] saveInspectorVisibility(true) then load returns true
    func testSaveAndLoadInspectorVisibility() async throws {
        let context = try makeModelContext()
        let manager = makeManager()
        manager.configure(modelContext: context)

        manager.saveInspectorVisibility(true)

        let freshManager = makeManager()
        freshManager.configure(modelContext: context)
        freshManager.loadAppState()

        XCTAssertTrue(freshManager.isInspectorVisible, "Inspector should be visible after saving true")
    }

    // [P0] toggle inspector visibility from false to true persists
    func testInspectorVisibilityPersistedOnToggle() async throws {
        let context = try makeModelContext()
        let manager = makeManager()
        manager.configure(modelContext: context)

        manager.saveInspectorVisibility(false)
        manager.saveInspectorVisibility(true)

        let freshManager = makeManager()
        freshManager.configure(modelContext: context)
        freshManager.loadAppState()

        XCTAssertTrue(freshManager.isInspectorVisible, "Should reflect the most recent save")
    }

    // [P1] no saved inspector state returns false (default)
    func testInspectorVisibilityDefaultValue() async throws {
        let context = try makeModelContext()
        let manager = makeManager()
        manager.configure(modelContext: context)
        manager.loadAppState()

        XCTAssertFalse(manager.isInspectorVisible, "Default inspector visibility should be false")
    }

    // MARK: - AC#2: Edge Cases

    // [P1] fresh install returns nil/false defaults
    func testLoadAppStateReturnsDefaultsWhenEmpty() async throws {
        let context = try makeModelContext()
        let manager = makeManager()
        manager.configure(modelContext: context)
        manager.loadAppState()

        XCTAssertNil(manager.lastActiveSessionID, "No saved session ID should return nil")
        XCTAssertNil(manager.windowFrame, "No saved frame should return nil")
        XCTAssertFalse(manager.isInspectorVisible, "No saved inspector state should return false")
    }

    // [P1] first launch with no prior state returns nil session ID
    func testFirstLaunchReturnsNilSessionID() async throws {
        let context = try makeModelContext()
        let manager = makeManager()
        manager.configure(modelContext: context)
        manager.loadAppState()

        XCTAssertNil(manager.lastActiveSessionID, "First launch should have nil session ID")
    }

    // [P0] saved session ID references a deleted session, restore should handle gracefully
    func testDeletedSessionFallbackToFirst() async throws {
        let context = try makeModelContext()
        let manager = makeManager()
        manager.configure(modelContext: context)

        // Save a session ID
        let deletedSessionID = UUID()
        manager.saveLastActiveSessionID(deletedSessionID)

        // Create sessions but NOT the one with deletedSessionID
        let session1 = Session(title: "First Session")
        let session2 = Session(title: "Second Session")
        context.insert(session1)
        context.insert(session2)
        try context.save()

        // Verify the saved ID does NOT match any existing session
        let freshManager = makeManager()
        freshManager.configure(modelContext: context)
        freshManager.loadAppState()

        let allSessions = try context.fetch(FetchDescriptor<Session>())
        let matchingSession = allSessions.first { $0.id == deletedSessionID }
        XCTAssertNil(matchingSession, "No session should match the deleted ID")

        // The caller (SessionViewModel) is responsible for fallback logic
        // AppStateManager just loads the raw value
        XCTAssertEqual(freshManager.lastActiveSessionID, deletedSessionID)
    }

    // [P1] second save to the same key overwrites the first value
    func testOverwriteExistingValue() async throws {
        let context = try makeModelContext()
        let manager = makeManager()
        manager.configure(modelContext: context)

        let firstID = UUID()
        let secondID = UUID()

        manager.saveLastActiveSessionID(firstID)
        manager.saveLastActiveSessionID(secondID)

        let freshManager = makeManager()
        freshManager.configure(modelContext: context)
        freshManager.loadAppState()

        XCTAssertEqual(freshManager.lastActiveSessionID, secondID, "Second save should overwrite first")
    }

    // MARK: - Configuration

    // [P0] configure stores modelContext for subsequent operations
    func testConfigureSetsModelContext() async throws {
        let context = try makeModelContext()
        let manager = makeManager()

        // Before configure, operations should not crash
        manager.loadAppState()
        XCTAssertNil(manager.lastActiveSessionID)

        // After configure, operations should use modelContext
        manager.configure(modelContext: context)
        manager.saveLastActiveSessionID(UUID())

        let freshManager = makeManager()
        freshManager.configure(modelContext: context)
        freshManager.loadAppState()

        XCTAssertNotNil(freshManager.lastActiveSessionID, "After configure, save/load should work")
    }
}
