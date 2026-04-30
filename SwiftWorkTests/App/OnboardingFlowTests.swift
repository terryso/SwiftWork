import XCTest
@testable import SwiftWork
import SwiftData

// ATDD Red Phase — Story 1.2: 首次启动引导与 Agent 配置
// Tests assert EXPECTED behavior for the onboarding flow in ContentView.
// They will FAIL until onboarding logic is implemented.

@MainActor
final class OnboardingFlowTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeModelContext() throws -> ModelContext {
        let schema = Schema([AppConfiguration.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    // MARK: - AC#1: First launch shows WelcomeView

    // [P0] ContentView can be instantiated
    func testContentViewInstantiation() {
        let contentView = ContentView()
        XCTAssertNotNil(contentView, "ContentView should be instantiable")
    }

    // [P0] WelcomeView can be instantiated
    func testWelcomeViewInstantiation() {
        let welcomeView = WelcomeView()
        XCTAssertNotNil(welcomeView, "WelcomeView should be instantiable")
    }

    // MARK: - AC#5: Non-first launch skips onboarding

    // [P1] When API key exists and onboarding completed, should show main view
    func testNonFirstLaunchSkipsOnboarding() throws {
        let mockKeychain = MockKeychainManager()
        try mockKeychain.save(key: KeychainConstants.apiKeyAccount, data: Data("sk-test-key".utf8))

        let context = try makeModelContext()
        let onboardingConfig = AppConfiguration(key: "hasCompletedOnboarding", value: Data([1]))
        context.insert(onboardingConfig)
        try context.save()

        let viewModel = SettingsViewModel(keychainManager: mockKeychain)
        viewModel.configure(modelContext: context)

        XCTAssertFalse(viewModel.isFirstLaunch, "Non-first launch should have isFirstLaunch = false")
        XCTAssertTrue(viewModel.isAPIKeyConfigured, "Non-first launch should have isAPIKeyConfigured = true")
    }

    // MARK: - AC#1 & AC#5: First launch shows onboarding

    // [P1] When no API key exists, should show onboarding
    func testFirstLaunchShowsOnboarding() throws {
        let mockKeychain = MockKeychainManager()
        let context = try makeModelContext()

        let viewModel = SettingsViewModel(keychainManager: mockKeychain)
        viewModel.configure(modelContext: context)

        XCTAssertTrue(viewModel.isFirstLaunch, "First launch should have isFirstLaunch = true")
        XCTAssertFalse(viewModel.isAPIKeyConfigured, "First launch should have isAPIKeyConfigured = false")
    }

    // MARK: - AC#6: App startup reads config from Keychain

    // [P1] App correctly reads existing API key on startup
    func testAppReadsExistingKeyOnStartup() throws {
        let mockKeychain = MockKeychainManager()
        let expectedKey = "sk-existing-startup-key"
        try mockKeychain.save(key: KeychainConstants.apiKeyAccount, data: Data(expectedKey.utf8))

        let context = try makeModelContext()
        let onboardingConfig = AppConfiguration(key: "hasCompletedOnboarding", value: Data([1]))
        context.insert(onboardingConfig)
        try context.save()

        let viewModel = SettingsViewModel(keychainManager: mockKeychain)
        viewModel.configure(modelContext: context)

        XCTAssertTrue(viewModel.isAPIKeyConfigured, "Should detect existing API key on startup")
    }

    // MARK: - AC#6: Defensive — has key but no onboarding flag

    // [P2] If key exists but no onboarding flag, treat as completed (defensive)
    func testKeyExistsButNoOnboardingFlag() throws {
        let mockKeychain = MockKeychainManager()
        try mockKeychain.save(key: KeychainConstants.apiKeyAccount, data: Data("sk-test-key".utf8))

        let context = try makeModelContext()
        // No onboarding config saved

        let viewModel = SettingsViewModel(keychainManager: mockKeychain)
        viewModel.configure(modelContext: context)

        // Per story: "有 Key 就能用" — defensive behavior
        XCTAssertTrue(viewModel.isAPIKeyConfigured, "Should detect API key even without onboarding flag")
    }
}
