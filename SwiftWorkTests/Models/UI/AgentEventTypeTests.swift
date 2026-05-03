import XCTest
@testable import SwiftWork

final class AgentEventTypeTests: XCTestCase {

    // MARK: - AC#4: AgentEventType covers all 18 SDKMessage cases + unknown

    // [P0] AgentEventType enum has all 18 SDK cases plus unknown
    func testAgentEventTypeAllCases() throws {
        let expectedCases: [AgentEventType] = [
            .partialMessage, .assistant, .toolUse, .toolResult, .toolProgress,
            .result, .userMessage, .system,
            .hookStarted, .hookProgress, .hookResponse,
            .taskStarted, .taskProgress,
            .authStatus, .filesPersisted, .localCommandOutput,
            .promptSuggestion, .toolUseSummary,
            .plan,
            .unknown
        ]

        XCTAssertEqual(AgentEventType.allCases.count, expectedCases.count)
        for expected in expectedCases {
            XCTAssertNotNil(expected)
        }
    }

    // [P0] AgentEventType is String Codable
    func testAgentEventTypeIsStringCodable() throws {
        let type = AgentEventType.toolUse
        XCTAssertEqual(type.rawValue, "toolUse")

        // Codable round-trip
        let encoded = try JSONEncoder().encode(type)
        let decoded = try JSONDecoder().decode(AgentEventType.self, from: encoded)
        XCTAssertEqual(decoded, type)
    }

    // [P1] AgentEventType unknown fallback handles unrecognized values
    func testAgentEventTypeUnknownFallback() throws {
        let json = Data("\"someFutureEventName\"".utf8)
        let decoded = try JSONDecoder().decode(AgentEventType.self, from: json)

        XCTAssertEqual(decoded, .unknown)
    }

    // [P1] AgentEventType raw values match SDKMessage case names
    func testAgentEventTypeRawValuesMatchSDK() throws {
        XCTAssertEqual(AgentEventType.partialMessage.rawValue, "partialMessage")
        XCTAssertEqual(AgentEventType.toolUse.rawValue, "toolUse")
        XCTAssertEqual(AgentEventType.toolResult.rawValue, "toolResult")
        XCTAssertEqual(AgentEventType.toolProgress.rawValue, "toolProgress")
        XCTAssertEqual(AgentEventType.result.rawValue, "result")
        XCTAssertEqual(AgentEventType.userMessage.rawValue, "userMessage")
        XCTAssertEqual(AgentEventType.system.rawValue, "system")
        XCTAssertEqual(AgentEventType.authStatus.rawValue, "authStatus")
        XCTAssertEqual(AgentEventType.filesPersisted.rawValue, "filesPersisted")
        XCTAssertEqual(AgentEventType.localCommandOutput.rawValue, "localCommandOutput")
        XCTAssertEqual(AgentEventType.promptSuggestion.rawValue, "promptSuggestion")
        XCTAssertEqual(AgentEventType.toolUseSummary.rawValue, "toolUseSummary")
    }
}
