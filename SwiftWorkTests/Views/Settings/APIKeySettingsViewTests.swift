import XCTest
import SwiftUI
import SwiftData
@testable import SwiftWork

// ATDD Red Phase -- Story 4.2: Application Settings Page
// Tests assert EXPECTED behavior for APIKeySettingsView.
// They will FAIL until APIKeySettingsView is implemented.

@MainActor
final class APIKeySettingsViewTests: XCTestCase {

    // MARK: - Test Helpers

    private var testContainer: ModelContainer!

    private func makeTestContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        testContainer = try! ModelContainer(
            for: PermissionRule.self, AppConfiguration.self, Session.self, Event.self,
            configurations: config
        )
        return testContainer
    }

    private func makeViewModel(
        keychainManager: KeychainManaging = MockKeychainManager()
    ) -> SettingsViewModel {
        SettingsViewModel(keychainManager: keychainManager)
    }

    override func tearDown() async throws {
        testContainer = nil
    }

    // MARK: - AC#1: APIKeySettingsView renders empty state

    // [P0] APIKeySettingsView compiles and accepts SettingsViewModel
    func testAPIKeySettingsViewAcceptsViewModel() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        let view = APIKeySettingsView(settingsViewModel: viewModel)
        XCTAssertNotNil(view, "APIKeySettingsView should accept SettingsViewModel parameter")
    }

    // [P0] APIKeySettingsView renders unconfigured state
    func testAPIKeySettingsViewRendersUnconfiguredState() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        // Verify ViewModel state drives unconfigured UI
        XCTAssertFalse(viewModel.isAPIKeyConfigured, "Should show unconfigured state")
        XCTAssertEqual(viewModel.maskedAPIKey, "", "Should show empty masked key")
    }

    // [P1] APIKeySettingsView renders configured state with masked key
    func testAPIKeySettingsViewRendersConfiguredState() throws {
        let mockKeychain = MockKeychainManager()
        try mockKeychain.save(key: KeychainConstants.apiKeyAccount, data: Data("sk-ant-configured-key-1234567890".utf8))

        let container = makeTestContainer()
        let context = container.mainContext
        let viewModel = makeViewModel(keychainManager: mockKeychain)
        viewModel.configure(modelContext: context)

        XCTAssertTrue(viewModel.isAPIKeyConfigured, "Should show configured state")
        XCTAssertFalse(viewModel.maskedAPIKey.isEmpty, "Should display masked key")
    }

    // [P1] APIKeySettingsView has apiKey property for input
    func testAPIKeySettingsViewAPIKeyProperty() throws {
        let viewModel = makeViewModel()

        // Simulate user typing new key
        viewModel.apiKey = "sk-ant-new-key"
        XCTAssertEqual(viewModel.apiKey, "sk-ant-new-key")
        XCTAssertTrue(viewModel.isValidAPIKey, "Non-empty key should be valid")
    }

    // [P2] APIKeySettingsView base URL input binds to viewModel
    func testAPIKeySettingsViewBaseURLBinding() throws {
        let viewModel = makeViewModel()

        viewModel.baseURL = "https://custom-api.example.com"
        XCTAssertEqual(viewModel.baseURL, "https://custom-api.example.com")
    }
}
