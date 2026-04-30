import XCTest
@testable import SwiftWork

// ATDD Red Phase — Story 1.2: 首次启动引导与 Agent 配置
// Tests assert EXPECTED behavior for Constants extensions.
// They will FAIL until KeychainConstants and availableModels are added.

final class ConstantsTests: XCTestCase {

    // MARK: - AC#3 & AC#6: Model constants

    // [P0] Constants.defaultModel is defined
    func testDefaultModelIsDefined() {
        XCTAssertEqual(Constants.defaultModel, "claude-sonnet-4-6")
    }

    // [P0] Constants.availableModels contains expected models
    func testAvailableModelsContainsAllModels() {
        let models = Constants.availableModels
        XCTAssertEqual(models.count, 3, "Should have 3 available models")
        XCTAssertTrue(models.contains("claude-sonnet-4-6"))
        XCTAssertTrue(models.contains("claude-opus-4-7"))
        XCTAssertTrue(models.contains("claude-haiku-3-5"))
    }

    // [P1] defaultModel is the first in availableModels
    func testDefaultModelIsFirstInList() {
        let models = Constants.availableModels
        XCTAssertEqual(models.first, Constants.defaultModel,
                       "Default model should be first in available models list")
    }

    // MARK: - AC#2 & AC#6: Keychain constants

    // [P0] KeychainConstants.service is defined
    func testKeychainConstantsService() {
        XCTAssertEqual(KeychainConstants.service, "com.swiftwork.apikeys")
    }

    // [P0] KeychainConstants.apiKeyAccount is defined
    func testKeychainConstantsApiKeyAccount() {
        XCTAssertEqual(KeychainConstants.apiKeyAccount, "anthropic-api-key")
    }
}
