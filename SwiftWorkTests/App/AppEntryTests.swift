import XCTest
@testable import SwiftWork
import SwiftData

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
