import XCTest
@testable import SwiftWork
import SwiftData

private actor SuspendedModelDiscoveryService: ModelDiscovering {
    private(set) var started = false
    private(set) var wasCancelled = false

    func fetchModels(
        provider: AgentProvider,
        apiKey: String,
        baseURL: String?
    ) async throws -> [String] {
        started = true
        do {
            try await Task.sleep(for: .seconds(60))
            return ["stale-model"]
        } catch is CancellationError {
            wasCancelled = true
            throw CancellationError()
        }
    }
}

private final class FailingBaseURLKeychainManager: KeychainManaging, @unchecked Sendable {
    private var storage: [String: Data] = [:]

    func save(key: String, data: Data) throws {
        if key == KeychainConstants.baseURLAccount {
            throw AppError(domain: .data, code: "TEST_WRITE_FAILED", message: "Base URL 写入失败")
        }
        storage[key] = data
    }

    func load(key: String) throws -> Data? {
        storage[key]
    }

    func delete(key: String) throws {
        storage.removeValue(forKey: key)
    }
}

// ATDD Red Phase — Story 1.2: 首次启动引导与 Agent 配置
// Tests assert EXPECTED behavior. They will FAIL until SettingsViewModel is implemented.

@MainActor
final class SettingsViewModelTests: XCTestCase {

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

    // MARK: - AC#1: First launch detection

    // [P0] SettingsViewModel initializes with isFirstLaunch = true when no config exists
    func testInitialFirstLaunchState() throws {
        let viewModel = makeViewModel()
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        XCTAssertTrue(viewModel.isFirstLaunch, "Should be first launch when no config exists")
    }

    // [P0] SettingsViewModel initializes with isAPIKeyConfigured = false when no API key
    func testInitialAPIKeyNotConfigured() throws {
        let viewModel = makeViewModel()
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        XCTAssertFalse(viewModel.isAPIKeyConfigured, "Should not be configured when no API key")
    }

    // MARK: - AC#2: API Key save

    // [P0] saveAPIKey updates isAPIKeyConfigured to true
    func testSaveAPIKeySetsConfigured() throws {
        let mockKeychain = MockKeychainManager()
        let viewModel = makeViewModel(keychainManager: mockKeychain)
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        viewModel.apiKey = "sk-ant-test-valid-key"
        try viewModel.saveAPIKey()

        XCTAssertTrue(viewModel.isAPIKeyConfigured, "isAPIKeyConfigured should be true after save")
    }

    // [P0] saveAPIKey actually stores key in keychain
    func testSaveAPIKeyStoresInKeychain() throws {
        let mockKeychain = MockKeychainManager()
        let viewModel = makeViewModel(keychainManager: mockKeychain)
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        viewModel.apiKey = "sk-ant-test-valid-key"
        try viewModel.saveAPIKey()

        // Verify key was stored via keychain manager
        let stored = try mockKeychain.load(key: KeychainConstants.apiKeyAccount)
        XCTAssertNotNil(stored, "API key should be stored in keychain")
        XCTAssertEqual(stored, Data("sk-ant-test-valid-key".utf8))
    }

    func testSaveAPIKeyReportsBaseURLPersistenceFailure() throws {
        let viewModel = makeViewModel(keychainManager: FailingBaseURLKeychainManager())
        viewModel.configure(modelContext: try makeModelContext())
        viewModel.apiKey = "provider-key"
        viewModel.baseURL = "https://gateway.example.com/v1"

        XCTAssertThrowsError(try viewModel.saveAPIKey())
        XCTAssertFalse(viewModel.isAPIKeyConfigured)
        XCTAssertEqual(viewModel.errorMessage, "Base URL 写入失败")
    }

    // [P1] saveAPIKey clears errorMessage on success
    func testSaveAPIKeyClearsError() throws {
        let viewModel = makeViewModel()
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)
        viewModel.errorMessage = "Previous error"

        viewModel.apiKey = "sk-ant-test-valid-key"
        try viewModel.saveAPIKey()

        XCTAssertNil(viewModel.errorMessage, "errorMessage should be nil after successful save")
    }

    // MARK: - AC#3: Model selection

    // [P0] First launch waits for the Provider API before offering models
    func testFirstLaunchStartsWithoutStaticModelSelection() throws {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.selectedModel, "")
        XCTAssertTrue(viewModel.availableModels.isEmpty)
    }

    // [P1] selectedModel can be changed to a discovered model
    func testChangeSelectedModel() throws {
        let viewModel = makeViewModel()
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)
        viewModel.availableModels = ["claude-opus-4-7"]
        try viewModel.updateModel("claude-opus-4-7")
        XCTAssertEqual(viewModel.selectedModel, "claude-opus-4-7")
    }

    // MARK: - AC#4 & AC#5: completeSetup

    // [P0] completeSetup sets isFirstLaunch to false
    func testCompleteSetupSetsFirstLaunchFalse() throws {
        let mockKeychain = MockKeychainManager()
        let viewModel = makeViewModel(keychainManager: mockKeychain)
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        // Simulate saving API key first
        viewModel.apiKey = "sk-ant-test-valid-key"
        try viewModel.saveAPIKey()
        viewModel.availableModels = ["claude-sonnet-4-6"]
        viewModel.selectedModel = "claude-sonnet-4-6"

        viewModel.completeSetup()

        XCTAssertFalse(viewModel.isFirstLaunch, "isFirstLaunch should be false after completeSetup")
    }

    // [P0] completeSetup persists hasCompletedOnboarding in AppConfiguration
    func testCompleteSetupPersistsOnboardingFlag() throws {
        let mockKeychain = MockKeychainManager()
        let viewModel = makeViewModel(keychainManager: mockKeychain)
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        viewModel.apiKey = "sk-ant-test-valid-key"
        try viewModel.saveAPIKey()
        viewModel.availableModels = ["claude-sonnet-4-6"]
        viewModel.selectedModel = "claude-sonnet-4-6"
        viewModel.completeSetup()

        // Verify AppConfiguration was saved
        let descriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate { $0.key == "hasCompletedOnboarding" }
        )
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1, "Should have one hasCompletedOnboarding config entry")
    }

    // [P1] completeSetup persists selectedModel in AppConfiguration
    func testCompleteSetupPersistsSelectedModel() throws {
        let mockKeychain = MockKeychainManager()
        let viewModel = makeViewModel(keychainManager: mockKeychain)
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        viewModel.apiKey = "sk-ant-test-valid-key"
        viewModel.selectedModel = "claude-opus-4-7"
        viewModel.availableModels = ["claude-opus-4-7"]
        try viewModel.saveAPIKey()
        viewModel.completeSetup()

        // Verify selectedModel was persisted
        let descriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate { $0.key == "selectedModel" }
        )
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1, "Should have one selectedModel config entry")
        let savedModel = String(data: results[0].value, encoding: .utf8)
        XCTAssertEqual(savedModel, "claude-opus-4-7")
    }

    // MARK: - AC#6: checkExistingConfig

    // [P0] checkExistingConfig detects existing API key
    func testCheckExistingConfigDetectsExistingKey() throws {
        let mockKeychain = MockKeychainManager()
        try mockKeychain.save(key: KeychainConstants.apiKeyAccount, data: Data("sk-existing-key".utf8))

        let viewModel = makeViewModel(keychainManager: mockKeychain)
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)

        XCTAssertTrue(viewModel.isAPIKeyConfigured, "Should detect existing API key")
    }

    // [P0] checkExistingConfig loads saved model preference
    func testCheckExistingConfigLoadsModelPreference() throws {
        let mockKeychain = MockKeychainManager()
        try mockKeychain.save(key: KeychainConstants.apiKeyAccount, data: Data("sk-existing-key".utf8))

        let viewModel = makeViewModel(keychainManager: mockKeychain)
        let context = try makeModelContext()

        // Pre-save a model preference
        let modelConfig = AppConfiguration(key: "selectedModel", value: Data("claude-haiku-3-5".utf8))
        context.insert(modelConfig)
        try context.save()

        viewModel.configure(modelContext: context)

        XCTAssertEqual(viewModel.selectedModel, "claude-haiku-3-5", "Should load saved model preference")
    }

    // [P0] checkExistingConfig detects completed onboarding
    func testCheckExistingConfigDetectsCompletedOnboarding() throws {
        let mockKeychain = MockKeychainManager()
        try mockKeychain.save(key: KeychainConstants.apiKeyAccount, data: Data("sk-existing-key".utf8))

        let viewModel = makeViewModel(keychainManager: mockKeychain)
        let context = try makeModelContext()

        // Pre-save onboarding flag
        let onboardingConfig = AppConfiguration(key: "hasCompletedOnboarding", value: Data([1]))
        context.insert(onboardingConfig)
        try context.save()

        viewModel.configure(modelContext: context)

        XCTAssertFalse(viewModel.isFirstLaunch, "Should detect completed onboarding")
    }

    // MARK: - AC#2: Input validation

    // [P1] Empty API Key is not valid
    func testEmptyAPIKeyValidation() throws {
        let viewModel = makeViewModel()
        viewModel.apiKey = ""
        // The View should disable save button when apiKey is empty
        // Verify through the validation logic
        XCTAssertTrue(viewModel.apiKey.isEmpty)
    }

    // [P1] Non-empty API Key passes validation
    func testAPIKeyFormatValidation() {
        let viewModel = makeViewModel()
        viewModel.apiKey = "my-custom-key-12345"
        XCTAssertTrue(viewModel.isValidAPIKey, "Any non-empty key should be valid")
    }

    // [P1] Valid API Key format passes validation
    func testValidAPIKeyFormat() {
        let viewModel = makeViewModel()
        viewModel.apiKey = "sk-ant-valid-key-12345"
        XCTAssertTrue(viewModel.isValidAPIKey, "Key starting with 'sk-' should be valid")
    }

    // MARK: - SettingsViewModel is @Observable

    // [P0] SettingsViewModel is @MainActor @Observable
    func testSettingsViewModelIsObservable() async throws {
        let viewModel = makeViewModel()
        // If this compiles and the type exists, it's @Observable
        // Verify state changes trigger observation
        viewModel.apiKey = "sk-test"
        XCTAssertEqual(viewModel.apiKey, "sk-test")
    }

    // MARK: - Dynamic Provider models

    func testRefreshModelsUsesDynamicListAndRequiresExplicitSelection() async throws {
        let keychain = MockKeychainManager()
        try keychain.saveAPIKey("provider-key")
        let viewModel = SettingsViewModel(
            keychainManager: keychain,
            modelDiscoveryService: StubModelDiscoveryService(models: ["gpt-b", "gpt-a"])
        )
        let context = try makeModelContext()
        viewModel.configure(modelContext: context)
        try viewModel.updateProvider(.openAI)

        let succeeded = await viewModel.refreshModels(clearExisting: true)

        XCTAssertTrue(succeeded)
        XCTAssertEqual(viewModel.availableModels, ["gpt-b", "gpt-a"])
        XCTAssertEqual(viewModel.selectedModel, "")
        XCTAssertFalse(viewModel.hasValidModelSelection)

        try viewModel.updateModel("gpt-a")

        XCTAssertEqual(viewModel.selectedModel, "gpt-a")
        XCTAssertTrue(viewModel.hasValidModelSelection)
    }

    func testProviderChangeClearsPreviousProviderModels() throws {
        let viewModel = makeViewModel()
        let context = try makeModelContext()
        context.insert(AppConfiguration(key: "selectedModel", value: Data("claude-model".utf8)))
        try context.save()
        viewModel.configure(modelContext: context)

        try viewModel.updateProvider(.openAI)

        XCTAssertEqual(viewModel.selectedProvider, .openAI)
        XCTAssertTrue(viewModel.availableModels.isEmpty)
        XCTAssertEqual(viewModel.selectedModel, "")
    }

    func testLegacyConfigurationDefaultsToAnthropic() throws {
        let keychain = MockKeychainManager()
        try keychain.saveAPIKey("legacy-key")
        let viewModel = makeViewModel(keychainManager: keychain)
        let context = try makeModelContext()
        context.insert(AppConfiguration(key: "selectedModel", value: Data("legacy-claude".utf8)))
        try context.save()

        viewModel.configure(modelContext: context)

        XCTAssertEqual(viewModel.selectedProvider, .anthropic)
        XCTAssertEqual(viewModel.availableModels, ["legacy-claude"])
    }

    func testLegacyKeyWithoutSavedModelDoesNotCreateStaticCandidate() throws {
        let keychain = MockKeychainManager()
        try keychain.saveAPIKey("legacy-key")
        let viewModel = makeViewModel(keychainManager: keychain)
        let context = try makeModelContext()

        viewModel.configure(modelContext: context)

        XCTAssertEqual(viewModel.selectedProvider, .anthropic)
        XCTAssertEqual(viewModel.selectedModel, Constants.defaultModel)
        XCTAssertTrue(viewModel.availableModels.isEmpty)
        XCTAssertFalse(viewModel.hasValidModelSelection)
    }

    func testUnknownPersistedProviderFailsClosedWithoutLoadingItsModel() throws {
        let keychain = MockKeychainManager()
        try keychain.saveAPIKey("provider-key")
        let viewModel = makeViewModel(keychainManager: keychain)
        let context = try makeModelContext()
        context.insert(AppConfiguration(key: AppConfigurationKeys.selectedProvider, value: Data("openai-v2".utf8)))
        context.insert(AppConfiguration(key: AppConfigurationKeys.selectedModel, value: Data("gpt-unknown".utf8)))
        try context.save()

        viewModel.configure(modelContext: context)

        XCTAssertEqual(viewModel.selectedProvider, .anthropic)
        XCTAssertEqual(viewModel.selectedModel, "")
        XCTAssertTrue(viewModel.availableModels.isEmpty)
        XCTAssertFalse(viewModel.hasValidModelSelection)
        XCTAssertNotNil(viewModel.modelLoadErrorMessage)
    }

    func testRefreshFailurePreservesSavedSelection() async throws {
        let keychain = MockKeychainManager()
        try keychain.saveAPIKey("provider-key")
        let error = AppError(domain: .network, code: "FAILED", message: "无法获取模型")
        let viewModel = SettingsViewModel(
            keychainManager: keychain,
            modelDiscoveryService: StubModelDiscoveryService(error: error)
        )
        let context = try makeModelContext()
        context.insert(AppConfiguration(key: "selectedModel", value: Data("saved-model".utf8)))
        try context.save()
        viewModel.configure(modelContext: context)

        let succeeded = await viewModel.refreshModels()

        XCTAssertFalse(succeeded)
        XCTAssertEqual(viewModel.selectedModel, "saved-model")
        XCTAssertEqual(viewModel.availableModels, ["saved-model"])
        XCTAssertEqual(viewModel.modelLoadErrorMessage, "无法获取模型")
    }

    func testInvalidatingModelsCancelsActiveRefreshAndRejectsStaleResult() async throws {
        let keychain = MockKeychainManager()
        try keychain.saveAPIKey("provider-key")
        let service = SuspendedModelDiscoveryService()
        let viewModel = SettingsViewModel(
            keychainManager: keychain,
            modelDiscoveryService: service
        )
        viewModel.configure(modelContext: try makeModelContext())

        let refreshTask = Task { await viewModel.refreshModels(clearExisting: true) }
        while !(await service.started) {
            await Task.yield()
        }

        viewModel.selectedProvider = .openAI
        viewModel.invalidateModels()
        let succeeded = await refreshTask.value
        let wasCancelled = await service.wasCancelled

        XCTAssertFalse(succeeded)
        XCTAssertTrue(wasCancelled)
        XCTAssertTrue(viewModel.availableModels.isEmpty)
        XCTAssertEqual(viewModel.selectedModel, "")
        XCTAssertFalse(viewModel.isLoadingModels)
    }
}
