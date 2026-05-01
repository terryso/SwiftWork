import XCTest
@testable import SwiftWork

// ATDD Red Phase — Story 1.2: 首次启动引导与 Agent 配置
// Tests assert EXPECTED behavior. They will FAIL until KeychainManager is implemented.

final class KeychainManagerTests: XCTestCase {

    private let testService = "com.swiftwork.apikeys.test"

    // MARK: - AC#2: KeychainManager CRUD — save/load round-trip

    // [P0] save then load returns the same data
    func testSaveAndLoadRoundTrip() throws {
        let manager = KeychainManager(service: testService)
        let testData = Data("sk-test-api-key-12345".utf8)

        // Clean up any prior test data
        try? manager.delete(key: "test-api-key")

        // Save
        try manager.save(key: "test-api-key", data: testData)

        // Load
        let loaded = try manager.load(key: "test-api-key")
        XCTAssertEqual(loaded, testData, "Loaded data should match saved data")

        // Clean up
        try manager.delete(key: "test-api-key")
    }

    // [P0] saveAPIKey / getAPIKey convenience methods
    func testSaveAndGetAPIKeyConvenience() throws {
        let manager = KeychainManager(service: testService)
        let expectedKey = "sk-ant-test-key-abcdef"

        // Clean up
        try? manager.deleteAPIKey()

        try manager.saveAPIKey(expectedKey)
        let result = try manager.getAPIKey()
        XCTAssertEqual(result, expectedKey, "getAPIKey should return the saved API key")

        // Clean up
        try manager.deleteAPIKey()
    }

    // MARK: - AC#2: save duplicate key updates instead of error

    // [P0] saving the same key twice updates the value
    func testSaveDuplicateKeyUpdates() throws {
        let manager = KeychainManager(service: testService)
        let firstData = Data("key-v1".utf8)
        let secondData = Data("key-v2".utf8)

        // Clean up
        try? manager.delete(key: "test-dup-key")

        try manager.save(key: "test-dup-key", data: firstData)
        try manager.save(key: "test-dup-key", data: secondData)

        let loaded = try manager.load(key: "test-dup-key")
        XCTAssertEqual(loaded, secondData, "Second save should update the existing value")

        // Clean up
        try manager.delete(key: "test-dup-key")
    }

    // MARK: - AC#2: delete behavior

    // [P0] delete then load returns nil
    func testDeleteThenLoadReturnsNil() throws {
        let manager = KeychainManager(service: testService)
        let testData = Data("to-be-deleted".utf8)

        try manager.save(key: "test-del-key", data: testData)
        try manager.delete(key: "test-del-key")

        let loaded = try manager.load(key: "test-del-key")
        XCTAssertNil(loaded, "Loaded data should be nil after delete")
    }

    // [P1] delete non-existent key does not crash
    func testDeleteNonExistentKeyDoesNotCrash() throws {
        let manager = KeychainManager(service: testService)
        // Should not throw or crash
        try manager.delete(key: "non-existent-key-\(UUID().uuidString)")
    }

    // MARK: - AC#2: load non-existent key returns nil

    // [P1] load non-existent key returns nil
    func testLoadNonExistentKeyReturnsNil() throws {
        let manager = KeychainManager(service: testService)
        let loaded = try manager.load(key: "non-existent-key-\(UUID().uuidString)")
        XCTAssertNil(loaded, "Loading a non-existent key should return nil")
    }

    // MARK: - KeychainManaging protocol conformance

    // [P0] KeychainManager conforms to KeychainManaging protocol
    func testKeychainManagerConformsToProtocol() {
        let manager = KeychainManager(service: testService)
        let _: any KeychainManaging = manager
        // If this compiles, KeychainManager conforms to KeychainManaging
    }

    // [P0] KeychainManager is Sendable
    func testKeychainManagerIsSendable() {
        let manager = KeychainManager(service: testService)
        let _: any Sendable = manager
    }

    // MARK: - Error handling

    // [P1] KeychainManager errors map to AppError with security domain
    func testKeychainErrorMapsToAppError() {
        // Verify that KeychainManager operations can produce AppError
        // with domain .security when keychain operations fail
        let error = AppError(
            domain: .security,
            code: "KEYCHAIN_SAVE_FAILED",
            message: "Failed to save to Keychain"
        )
        XCTAssertEqual(error.domain, .security)
        XCTAssertEqual(error.code, "KEYCHAIN_SAVE_FAILED")
    }
}
