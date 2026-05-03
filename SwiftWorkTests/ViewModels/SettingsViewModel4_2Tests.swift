import XCTest
@testable import SwiftWork
import SwiftData

// ATDD Red Phase -- Story 4.2: Application Settings Page
// Tests assert EXPECTED behavior for updateAPIKey(), updateModel(), loadCurrentConfig(), maskedAPIKey.
// They will FAIL until SettingsViewModel is extended with these methods.

@MainActor
final class SettingsViewModel4_2Tests: XCTestCase {

    // MARK: - Test Helpers

    private func makeViewModel(
        keychainManager: KeychainManaging = MockKeychainManager()
    ) -> SettingsViewModel {
        SettingsViewModel(keychainManager: keychainManager)
    }

    private func makeModelContext() throws -> ModelContext {
        let schema = Schema([AppConfiguration.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    // MARK: - AC#2: updateAPIKey() -- API Key update via KeychainManager

    // [P0] updateAPIKey saves new key to Keychain
    func testUpdateAPIKeySavesToKeychain() throws {
        let mockKeychain = MockKeychainManager()
        let viewModel = makeViewModel(keychainManager: mockKeychain)
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        try viewModel.updateAPIKey("sk-ant-new-valid-key-67890")

        let stored = try mockKeychain.load(key: KeychainConstants.apiKeyAccount)
        XCTAssertNotNil(stored, "updateAPIKey should store the new key in Keychain")
        XCTAssertEqual(stored, Data("sk-ant-new-valid-key-67890".utf8))
    }

    // [P0] updateAPIKey updates isAPIKeyConfigured to true
    func testUpdateAPIKeySetsConfigured() throws {
        let viewModel = makeViewModel()
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        XCTAssertFalse(viewModel.isAPIKeyConfigured, "Should start unconfigured")

        try viewModel.updateAPIKey("sk-ant-new-key")

        XCTAssertTrue(viewModel.isAPIKeyConfigured, "Should be configured after updateAPIKey")
    }

    // [P0] updateAPIKey clears errorMessage on success
    func testUpdateAPIKeyClearsError() throws {
        let viewModel = makeViewModel()
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)
        viewModel.errorMessage = "Previous error"

        try viewModel.updateAPIKey("sk-ant-new-key")

        XCTAssertNil(viewModel.errorMessage, "errorMessage should be nil after successful update")
    }

    // [P1] updateAPIKey rejects empty key
    func testUpdateAPIKeyRejectsEmptyKey() throws {
        let viewModel = makeViewModel()
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        XCTAssertThrowsError(try viewModel.updateAPIKey(""), "Should throw for empty key")
    }

    // [P1] updateAPIKey rejects whitespace-only key
    func testUpdateAPIKeyRejectsWhitespaceKey() throws {
        let viewModel = makeViewModel()
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        XCTAssertThrowsError(try viewModel.updateAPIKey("   "), "Should throw for whitespace-only key")
    }

    // [P2] updateAPIKey updates existing key (replace behavior)
    func testUpdateAPIKeyReplacesExistingKey() throws {
        let mockKeychain = MockKeychainManager()
        try mockKeychain.save(key: KeychainConstants.apiKeyAccount, data: Data("sk-old-key".utf8))

        let viewModel = makeViewModel(keychainManager: mockKeychain)
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        try viewModel.updateAPIKey("sk-new-replacement-key")

        let stored = try mockKeychain.load(key: KeychainConstants.apiKeyAccount)
        XCTAssertEqual(stored, Data("sk-new-replacement-key".utf8), "Should replace old key with new key")
    }

    // MARK: - AC#3: updateModel() -- Model selection update

    // [P0] updateModel persists selected model to AppConfiguration
    func testUpdateModelPersistsToAppConfiguration() throws {
        let viewModel = makeViewModel()
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        try viewModel.updateModel("claude-opus-4-7")

        let descriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate { $0.key == "selectedModel" }
        )
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1, "Should have one selectedModel config entry")
        let savedModel = String(data: results[0].value, encoding: .utf8)
        XCTAssertEqual(savedModel, "claude-opus-4-7")
    }

    // [P0] updateModel updates selectedModel property on ViewModel
    func testUpdateModelUpdatesViewModelProperty() throws {
        let viewModel = makeViewModel()
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        try viewModel.updateModel("claude-haiku-3-5")

        XCTAssertEqual(viewModel.selectedModel, "claude-haiku-3-5", "selectedModel should reflect new model")
    }

    // [P1] updateModel replaces existing model preference
    func testUpdateModelReplacesExistingPreference() throws {
        let viewModel = makeViewModel()
        let context = try makeModelContext()

        // Pre-save a model preference
        let existingConfig = AppConfiguration(key: "selectedModel", value: Data("claude-sonnet-4-6".utf8))
        context.insert(existingConfig)
        try context.save()

        viewModel.configure(modelContext: context)
        try viewModel.updateModel("claude-opus-4-7")

        let descriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate { $0.key == "selectedModel" }
        )
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1, "Should have exactly one selectedModel entry (updated, not duplicated)")
        let savedModel = String(data: results[0].value, encoding: .utf8)
        XCTAssertEqual(savedModel, "claude-opus-4-7", "Should update to new model")
    }

    // [P2] updateModel with same model is idempotent
    func testUpdateModelSameModelIsIdempotent() throws {
        let viewModel = makeViewModel()
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        try viewModel.updateModel("claude-sonnet-4-6")
        try viewModel.updateModel("claude-sonnet-4-6")

        let descriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate { $0.key == "selectedModel" }
        )
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1, "Should not duplicate entries for same model")
    }

    // MARK: - maskedAPIKey -- API Key masking for display

    // [P0] maskedAPIKey returns empty string when no key configured
    func testMaskedAPIKeyEmptyWhenNotConfigured() throws {
        let viewModel = makeViewModel()
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        XCTAssertEqual(viewModel.maskedAPIKey, "", "Should return empty string when no key is configured")
    }

    // [P0] maskedAPIKey shows first 8 and last 4 characters for long keys
    func testMaskedAPIKeyShowsCorrectMasking() throws {
        let mockKeychain = MockKeychainManager()
        try mockKeychain.save(key: KeychainConstants.apiKeyAccount, data: Data("sk-ant-api03-abcdefghijklmnop1234567890WXYZ".utf8))

        let viewModel = makeViewModel(keychainManager: mockKeychain)
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        // Key is "sk-ant-api03-abcdefghijklmnop1234567890WXYZ" (40 chars)
        // Expected mask: first 8 + "****" + last 4 = "sk-ant-a****XYZ"
        let masked = viewModel.maskedAPIKey
        XCTAssertTrue(masked.hasPrefix("sk-ant-a"), "Should start with first 8 characters")
        XCTAssertTrue(masked.hasSuffix("XYZ"), "Should end with last 4 characters")
        XCTAssertTrue(masked.contains("****"), "Should contain mask indicator")
    }

    // [P1] maskedAPIKey handles short keys (< 12 characters)
    func testMaskedAPIKeyShortKeyHandling() throws {
        let mockKeychain = MockKeychainManager()
        try mockKeychain.save(key: KeychainConstants.apiKeyAccount, data: Data("short".utf8))

        let viewModel = makeViewModel(keychainManager: mockKeychain)
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        let masked = viewModel.maskedAPIKey
        // For keys < 12 chars: show first 4 + ****
        XCTAssertTrue(masked.contains("****"), "Should contain mask indicator for short keys")
    }

    // [P2] maskedAPIKey handles exactly 12-character key
    func testMaskedAPIKeyExactBoundaryKey() throws {
        let mockKeychain = MockKeychainManager()
        // Exactly 12 characters
        try mockKeychain.save(key: KeychainConstants.apiKeyAccount, data: Data("sk-ant-12345".utf8))

        let viewModel = makeViewModel(keychainManager: mockKeychain)
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        let masked = viewModel.maskedAPIKey
        XCTAssertFalse(masked.isEmpty, "Should return non-empty mask for configured key")
        XCTAssertTrue(masked.contains("****"), "Should contain mask indicator")
    }

    // MARK: - loadCurrentConfig() -- Refresh all configuration state

    // [P0] loadCurrentConfig refreshes isAPIKeyConfigured from Keychain
    func testLoadCurrentConfigRefreshesAPIKeyState() throws {
        let mockKeychain = MockKeychainManager()
        let viewModel = makeViewModel(keychainManager: mockKeychain)
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        XCTAssertFalse(viewModel.isAPIKeyConfigured, "Should start unconfigured")

        // Simulate key being added externally (e.g., via WelcomeView)
        try mockKeychain.save(key: KeychainConstants.apiKeyAccount, data: Data("sk-external-key".utf8))

        viewModel.loadCurrentConfig()

        XCTAssertTrue(viewModel.isAPIKeyConfigured, "Should detect newly added key after loadCurrentConfig")
    }

    // [P0] loadCurrentConfig refreshes selectedModel from AppConfiguration
    func testLoadCurrentConfigRefreshesModelPreference() throws {
        let viewModel = makeViewModel()
        let context = try makeModelContext()

        // Pre-save a model preference
        let modelConfig = AppConfiguration(key: "selectedModel", value: Data("claude-haiku-3-5".utf8))
        context.insert(modelConfig)
        try context.save()

        viewModel.configure(modelContext: context)

        // ViewModel should have loaded the saved model via configure -> checkExistingConfig
        XCTAssertEqual(viewModel.selectedModel, "claude-haiku-3-5")

        // Now change the persisted model externally
        modelConfig.value = Data("claude-opus-4-7".utf8)
        try context.save()

        viewModel.loadCurrentConfig()

        XCTAssertEqual(viewModel.selectedModel, "claude-opus-4-7", "Should refresh to latest persisted model")
    }

    // [P1] loadCurrentConfig loads base URL from Keychain
    func testLoadCurrentConfigLoadsBaseURL() throws {
        let mockKeychain = MockKeychainManager()
        try mockKeychain.save(key: KeychainConstants.baseURLAccount, data: Data("https://custom-api.example.com".utf8))

        let viewModel = makeViewModel(keychainManager: mockKeychain)
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        viewModel.loadCurrentConfig()

        XCTAssertEqual(viewModel.baseURL, "https://custom-api.example.com", "Should load saved base URL")
    }

    // [P1] loadCurrentConfig handles missing base URL gracefully
    func testLoadCurrentConfigMissingBaseURL() throws {
        let viewModel = makeViewModel()
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        viewModel.loadCurrentConfig()

        XCTAssertEqual(viewModel.baseURL, "", "Should default to empty string when no base URL saved")
    }

    // [P2] loadCurrentConfig updates maskedAPIKey after key change
    func testLoadCurrentConfigUpdatesMaskedKey() throws {
        let mockKeychain = MockKeychainManager()
        let viewModel = makeViewModel(keychainManager: mockKeychain)
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        XCTAssertEqual(viewModel.maskedAPIKey, "", "No key initially")

        try mockKeychain.save(key: KeychainConstants.apiKeyAccount, data: Data("sk-ant-newly-added-key-1234567890".utf8))

        viewModel.loadCurrentConfig()

        XCTAssertNotEqual(viewModel.maskedAPIKey, "", "Should now show masked key after loadCurrentConfig")
    }
}
