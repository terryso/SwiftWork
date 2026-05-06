import XCTest
@testable import SwiftWork

final class KeychainManagerTests: XCTestCase {

    private let testService = "com.swiftwork.apikeys.test"
    private var testDirectory: URL!

    override func setUp() {
        super.setUp()
        testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    override func tearDown() {
        if let testDirectory {
            try? FileManager.default.removeItem(at: testDirectory)
        }
        testDirectory = nil
        super.tearDown()
    }

    private func makeManager() -> KeychainManager {
        KeychainManager(service: testService, baseDirectory: testDirectory)
    }

    func testSaveAndLoadRoundTrip() throws {
        let manager = makeManager()
        let testData = Data("sk-test-api-key-12345".utf8)

        try manager.save(key: "test-api-key", data: testData)

        let loaded = try manager.load(key: "test-api-key")
        XCTAssertEqual(loaded, testData, "Loaded data should match saved data")
    }

    func testSaveAndGetAPIKeyConvenience() throws {
        let manager = makeManager()
        let expectedKey = "sk-ant-test-key-abcdef"

        try manager.saveAPIKey(expectedKey)
        let result = try manager.getAPIKey()
        XCTAssertEqual(result, expectedKey, "getAPIKey should return the saved API key")
    }

    func testSaveDuplicateKeyUpdates() throws {
        let manager = makeManager()
        let firstData = Data("key-v1".utf8)
        let secondData = Data("key-v2".utf8)

        try manager.save(key: "test-dup-key", data: firstData)
        try manager.save(key: "test-dup-key", data: secondData)

        let loaded = try manager.load(key: "test-dup-key")
        XCTAssertEqual(loaded, secondData, "Second save should update the existing value")
    }

    func testDeleteThenLoadReturnsNil() throws {
        let manager = makeManager()
        let testData = Data("to-be-deleted".utf8)

        try manager.save(key: "test-del-key", data: testData)
        try manager.delete(key: "test-del-key")

        let loaded = try manager.load(key: "test-del-key")
        XCTAssertNil(loaded, "Loaded data should be nil after delete")
    }

    func testDeleteNonExistentKeyDoesNotCrash() throws {
        let manager = makeManager()
        try manager.delete(key: "non-existent-key-\(UUID().uuidString)")
    }

    func testLoadNonExistentKeyReturnsNil() throws {
        let manager = makeManager()
        let loaded = try manager.load(key: "non-existent-key-\(UUID().uuidString)")
        XCTAssertNil(loaded, "Loading a non-existent key should return nil")
    }

    func testKeychainManagerConformsToProtocol() {
        let manager = makeManager()
        let _: any KeychainManaging = manager
    }

    func testKeychainManagerIsSendable() {
        let manager = makeManager()
        let _: any Sendable = manager
    }

    func testStorageErrorMapsToAppError() {
        let error = AppError(
            domain: .data,
            code: "SANDBOX_STORE_WRITE_FAILED",
            message: "Failed to write sandbox credential store"
        )
        XCTAssertEqual(error.domain, .data)
        XCTAssertEqual(error.code, "SANDBOX_STORE_WRITE_FAILED")
    }
}
