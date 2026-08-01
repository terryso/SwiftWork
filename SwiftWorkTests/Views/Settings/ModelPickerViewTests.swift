import XCTest
import SwiftUI
import SwiftData
@testable import SwiftWork

// ATDD Red Phase -- Story 4.2: Application Settings Page
// Tests assert EXPECTED behavior for ModelPickerView.
// They will FAIL until ModelPickerView is implemented.

@MainActor
final class ModelPickerViewTests: XCTestCase {

    // MARK: - Test Helpers

    private var testContainer: ModelContainer!

    private func makeTestContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        testContainer = try! ModelContainer(
            for: AppConfiguration.self,
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

    // MARK: - AC#1: ModelPickerView renders model list

    // [P0] ModelPickerView compiles and accepts SettingsViewModel
    func testModelPickerViewAcceptsViewModel() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)

        let view = ModelPickerView(settingsViewModel: viewModel)
        XCTAssertNotNil(view, "ModelPickerView should accept SettingsViewModel parameter")
    }

    // [P0] ModelPickerView does not expose a static fallback list
    func testModelPickerViewStartsWithoutStaticModels() throws {
        let viewModel = makeViewModel()
        XCTAssertTrue(viewModel.availableModels.isEmpty)
    }

    // [P0] ModelPickerView reflects current selected model
    func testModelPickerViewShowsCurrentModel() throws {
        let viewModel = makeViewModel()

        XCTAssertEqual(viewModel.selectedModel, "", "No model is selected before API discovery")
    }

    // [P1] ModelPickerView selection updates ViewModel
    func testModelPickerViewSelectionUpdatesViewModel() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)
        viewModel.availableModels = ["claude-opus-4-7"]

        try viewModel.updateModel("claude-opus-4-7")

        XCTAssertEqual(viewModel.selectedModel, "claude-opus-4-7", "Should reflect new selection")
    }

    // [P1] ModelPickerView model change persists via updateModel
    func testModelPickerViewPersistsModelChange() throws {
        let container = makeTestContainer()
        let context = container.mainContext
        let viewModel = makeViewModel()
        viewModel.configure(modelContext: context)
        viewModel.availableModels = ["claude-haiku-3-5"]

        try viewModel.updateModel("claude-haiku-3-5")

        // Verify persistence
        let descriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate { $0.key == "selectedModel" }
        )
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
        let saved = String(data: results[0].value, encoding: .utf8)
        XCTAssertEqual(saved, "claude-haiku-3-5", "Model change should persist")
    }

    // [P2] ModelPickerView requires discovery on first launch
    func testModelPickerViewRequiresDiscoveryOnFirstLaunch() throws {
        let viewModel = makeViewModel()

        XCTAssertTrue(viewModel.isFirstLaunch, "Should be first launch")
        XCTAssertFalse(viewModel.hasValidModelSelection)
    }
}
