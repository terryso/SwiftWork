import XCTest
@testable import SwiftWork

// ATDD Red Phase — Story 1.2: 首次启动引导与 Agent 配置
// Tests assert compatibility constants and Provider defaults.

final class ConstantsTests: XCTestCase {

    // MARK: - AC#3 & AC#6: Model constants

    // [P0] Constants.defaultModel is defined
    func testDefaultModelIsDefined() {
        XCTAssertEqual(Constants.defaultModel, "claude-sonnet-4-6")
    }

    func testProviderDefaultsMatchSDKBaseURLSemantics() {
        XCTAssertEqual(AgentProvider.anthropic.defaultBaseURL, "https://api.anthropic.com")
        XCTAssertEqual(AgentProvider.openAI.defaultBaseURL, "https://api.openai.com/v1")
    }

    func testProviderPersistentValuesMatchSDKProtocolNames() {
        XCTAssertEqual(AgentProvider.anthropic.rawValue, "anthropic")
        XCTAssertEqual(AgentProvider.openAI.rawValue, "openai")
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
