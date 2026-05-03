import XCTest
@testable import SwiftWork
import SwiftData

@MainActor
final class WindowStateTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeModelContext() throws -> ModelContext {
        let schema = Schema([AppConfiguration.self, Session.self, Event.self, PermissionRule.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    // MARK: - AC#2: Window Frame Persistence Round-Trip (P0)

    // [P0] saveWindowFrame -> loadAppState round-trip preserves frame
    func testWindowFrameRoundTrip() throws {
        let context = try makeModelContext()
        let manager = AppStateManager()
        manager.configure(modelContext: context)

        let originalFrame = NSRect(x: 100, y: 200, width: 1200, height: 800)
        manager.saveWindowFrame(originalFrame)

        // Reload
        let restoredManager = AppStateManager()
        restoredManager.configure(modelContext: context)
        restoredManager.loadAppState()

        XCTAssertEqual(
            restoredManager.windowFrame,
            originalFrame,
            "Window frame should survive save/load round-trip"
        )
    }

    // [P0] Restored NSRect is not zero rect
    func testRestoredFrameNotZero() throws {
        let context = try makeModelContext()
        let manager = AppStateManager()
        manager.configure(modelContext: context)

        let frame = NSRect(x: 50, y: 75, width: 1400, height: 900)
        manager.saveWindowFrame(frame)

        let restoredManager = AppStateManager()
        restoredManager.configure(modelContext: context)
        restoredManager.loadAppState()

        let restored = try XCTUnwrap(restoredManager.windowFrame, "Restored frame should not be nil")
        XCTAssertNotEqual(
            restored,
            NSRect.zero,
            "Restored window frame should not be zero rect"
        )
        XCTAssertEqual(restored.origin.x, 50)
        XCTAssertEqual(restored.origin.y, 75)
        XCTAssertEqual(restored.size.width, 1400)
        XCTAssertEqual(restored.size.height, 900)
    }

    // [P0] Fullscreen frame is saved and restored correctly
    func testFullscreenFramePreserved() throws {
        let context = try makeModelContext()
        let manager = AppStateManager()
        manager.configure(modelContext: context)

        // Simulate a fullscreen frame (large dimensions matching screen)
        let fullscreenFrame = NSRect(x: 0, y: 0, width: 2560, height: 1440)
        manager.saveWindowFrame(fullscreenFrame)

        let restoredManager = AppStateManager()
        restoredManager.configure(modelContext: context)
        restoredManager.loadAppState()

        XCTAssertEqual(
            restoredManager.windowFrame,
            fullscreenFrame,
            "Fullscreen frame should be saved and restored correctly"
        )
    }

    // MARK: - AC#2: Window State Persistence Across Multiple Saves (P1)

    // [P1] Most recent window frame overwrites previous
    func testWindowFrameOverwrite() throws {
        let context = try makeModelContext()
        let manager = AppStateManager()
        manager.configure(modelContext: context)

        let firstFrame = NSRect(x: 10, y: 20, width: 800, height: 600)
        manager.saveWindowFrame(firstFrame)

        let secondFrame = NSRect(x: 200, y: 300, width: 1600, height: 1000)
        manager.saveWindowFrame(secondFrame)

        let restoredManager = AppStateManager()
        restoredManager.configure(modelContext: context)
        restoredManager.loadAppState()

        XCTAssertEqual(
            restoredManager.windowFrame,
            secondFrame,
            "Most recent window frame should overwrite previous saves"
        )
        XCTAssertNotEqual(
            restoredManager.windowFrame,
            firstFrame,
            "Old frame should not be restored"
        )
    }

    // [P1] Other persisted state is not affected by window frame save
    func testWindowFrameSaveDoesNotAffectOtherState() throws {
        let context = try makeModelContext()
        let manager = AppStateManager()
        manager.configure(modelContext: context)

        // Save inspector visibility
        manager.saveInspectorVisibility(true)

        // Save window frame
        manager.saveWindowFrame(NSRect(x: 100, y: 200, width: 1200, height: 800))

        // Reload
        let restoredManager = AppStateManager()
        restoredManager.configure(modelContext: context)
        restoredManager.loadAppState()

        // Both should be preserved
        XCTAssertNotNil(restoredManager.windowFrame, "Window frame should be preserved")
        XCTAssertTrue(
            restoredManager.isInspectorVisible,
            "Inspector visibility should not be affected by window frame save"
        )
    }

    // MARK: - AC#3: Window State With No Prior Save (P0)

    // [P0] loadAppState with no prior save returns nil windowFrame
    func testNoSavedFrameReturnsNil() throws {
        let context = try makeModelContext()
        let manager = AppStateManager()
        manager.configure(modelContext: context)

        manager.loadAppState()

        XCTAssertNil(
            manager.windowFrame,
            "Window frame should be nil when no frame was previously saved"
        )
    }

    // MARK: - AC#3: Split View / Resized Window Frame (P1)

    // [P1] Small window frame (split view) is saved and restored
    func testSplitViewFramePreserved() throws {
        let context = try makeModelContext()
        let manager = AppStateManager()
        manager.configure(modelContext: context)

        // Simulate split view: half-screen width
        let splitFrame = NSRect(x: 0, y: 0, width: 640, height: 900)
        manager.saveWindowFrame(splitFrame)

        let restoredManager = AppStateManager()
        restoredManager.configure(modelContext: context)
        restoredManager.loadAppState()

        XCTAssertEqual(
            restoredManager.windowFrame,
            splitFrame,
            "Split view frame should be preserved exactly"
        )
    }

    // [P1] Unusual but valid window positions are preserved
    func testUnusualWindowPositionPreserved() throws {
        let context = try makeModelContext()
        let manager = AppStateManager()
        manager.configure(modelContext: context)

        // Negative origin (off-screen, can happen with multi-monitor)
        let offScreenFrame = NSRect(x: -500, y: -300, width: 1200, height: 800)
        manager.saveWindowFrame(offScreenFrame)

        let restoredManager = AppStateManager()
        restoredManager.configure(modelContext: context)
        restoredManager.loadAppState()

        XCTAssertEqual(
            restoredManager.windowFrame,
            offScreenFrame,
            "Off-screen window position should be preserved for multi-monitor scenarios"
        )
    }

    // MARK: - AC#3: NavigationSplitView Layout Adaptation (P2)

    // [P2] AppState exposes isInspectorVisible for layout adaptation
    func testInspectorVisibilityForLayoutAdaptation() throws {
        let appState = AppState()

        // Initial state: inspector not visible
        XCTAssertFalse(appState.isInspectorVisible)

        // Toggle on
        appState.isInspectorVisible = true
        XCTAssertTrue(appState.isInspectorVisible, "Inspector visibility should be toggleable for layout adaptation")
    }

    // [P2] AppState exposes isDebugPanelVisible for layout adaptation
    func testDebugPanelVisibilityForLayoutAdaptation() throws {
        let appState = AppState()

        // Initial state: debug panel not visible
        XCTAssertFalse(appState.isDebugPanelVisible)

        // Toggle on
        appState.isDebugPanelVisible = true
        XCTAssertTrue(appState.isDebugPanelVisible, "Debug panel visibility should be toggleable for layout adaptation")
    }

    // MARK: - Integration: AppStateManager Persistence Completeness (P1)

    // [P1] All window-related state persists together
    func testAllWindowRelatedStatePersistsTogether() throws {
        let context = try makeModelContext()
        let manager = AppStateManager()
        manager.configure(modelContext: context)

        // Save all window-related state
        manager.saveWindowFrame(NSRect(x: 42, y: 84, width: 1024, height: 768))
        manager.saveInspectorVisibility(true)
        manager.saveDebugPanelVisibility(false)

        // Reload
        let restoredManager = AppStateManager()
        restoredManager.configure(modelContext: context)
        restoredManager.loadAppState()

        XCTAssertNotNil(restoredManager.windowFrame)
        XCTAssertEqual(restoredManager.windowFrame?.origin.x, 42)
        XCTAssertEqual(restoredManager.windowFrame?.size.width, 1024)
        XCTAssertTrue(restoredManager.isInspectorVisible)
        XCTAssertFalse(restoredManager.isDebugPanelVisible)
    }
}
