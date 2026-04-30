import XCTest
@testable import SwiftWork

final class AppConfigurationModelTests: XCTestCase {

    // MARK: - AC#4: AppConfiguration Model Definition

    // [P0] AppConfiguration can be instantiated with required properties
    func testAppConfigurationInstantiation() throws {
        let value = Data("claude-sonnet-4-6".utf8)
        let config = AppConfiguration(
            key: "default_model",
            value: value
        )

        XCTAssertEqual(config.key, "default_model")
        XCTAssertEqual(config.value, value)
        XCTAssertNotNil(config.id)
        XCTAssertNotNil(config.updatedAt)
    }

    // [P0] AppConfiguration has UUID unique primary key
    func testAppConfigurationUUIDPrimaryKey() throws {
        let configA = AppConfiguration(key: "a", value: Data())
        let configB = AppConfiguration(key: "b", value: Data())

        XCTAssertNotEqual(configA.id, configB.id)
    }

    // [P1] AppConfiguration value stores generic Data (JSON or raw)
    func testAppConfigurationValueIsGenericData() throws {
        let jsonValue = try JSONSerialization.data(withJSONObject: ["model": "opus", "temperature": 0.7])
        let config = AppConfiguration(key: "model_config", value: jsonValue)

        let parsed = try JSONSerialization.jsonObject(with: config.value) as? [String: Any]
        XCTAssertEqual(parsed?["model"] as? String, "opus")
    }

    // [P1] AppConfiguration updatedAt reflects modification time
    func testAppConfigurationUpdatedAt() throws {
        let before = Date.now
        let config = AppConfiguration(key: "test", value: Data())
        let after = Date.now

        XCTAssertGreaterThanOrEqual(config.updatedAt, before)
        XCTAssertLessThanOrEqual(config.updatedAt, after)
    }
}
