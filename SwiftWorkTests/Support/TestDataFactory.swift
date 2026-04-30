import Foundation
@testable import SwiftWork

enum TestDataFactory {

    // MARK: - Session Factories

    static func makeSession(
        title: String = "Test Session",
        workspacePath: String? = nil
    ) -> Session {
        Session(title: title, workspacePath: workspacePath)
    }

    static func makeSessions(count: Int, titlePrefix: String = "Session") -> [Session] {
        (0..<count).map { makeSession(title: "\(titlePrefix) \($0)") }
    }

    // MARK: - Event Factories

    static func makeEvent(
        sessionID: UUID = UUID(),
        eventType: String = "partialMessage",
        rawData: Data = Data("{}".utf8),
        timestamp: Date = .now,
        order: Int = 0
    ) -> Event {
        Event(
            sessionID: sessionID,
            eventType: eventType,
            rawData: rawData,
            timestamp: timestamp,
            order: order
        )
    }

    static func makeEvents(count: Int, sessionID: UUID = UUID()) -> [Event] {
        let types = ["partialMessage", "assistant", "toolUse", "toolResult", "toolProgress", "result"]
        return (0..<count).map { i in
            makeEvent(
                sessionID: sessionID,
                eventType: types[i % types.count],
                order: i
            )
        }
    }

    // MARK: - PermissionRule Factories

    static func makePermissionRule(
        toolName: String = "Read",
        pattern: String = "*",
        decision: Decision = .allow
    ) -> PermissionRule {
        PermissionRule(toolName: toolName, pattern: pattern, decision: decision)
    }

    // MARK: - AppConfiguration Factories

    static func makeAppConfiguration(
        key: String = "test_key",
        value: Data = Data("test_value".utf8)
    ) -> AppConfiguration {
        AppConfiguration(key: key, value: value)
    }

    // MARK: - AgentEventType Factories

    static let allSDKEventTypes: [String] = [
        "partialMessage", "assistant", "toolUse", "toolResult", "toolProgress",
        "result", "userMessage", "system",
        "hookStarted", "hookProgress", "hookResponse",
        "taskStarted", "taskProgress",
        "authStatus", "filesPersisted", "localCommandOutput",
        "promptSuggestion", "toolUseSummary"
    ]

    // MARK: - JSON Helpers

    static func jsonData(_ dict: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: dict)
    }

    static func jsonString(_ string: String) -> Data {
        Data(string.utf8)
    }
}
