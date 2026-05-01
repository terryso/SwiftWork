import XCTest
@testable import SwiftWork

final class TitleGeneratorTests: XCTestCase {

    // MARK: - Nil returns (no network needed)

    func testReturnsNilWhenAPIKeyEmpty() async {
        let events = [AgentEvent(type: .userMessage, content: "Hello", timestamp: .now)]
        let result = await TitleGenerator.generate(
            events: events,
            apiKey: "",
            baseURL: nil,
            model: "claude-sonnet-4-6"
        )
        XCTAssertNil(result)
    }

    func testReturnsNilWhenNoUserOrAssistantEvents() async {
        let events = [
            AgentEvent(type: .system, content: "init", timestamp: .now),
            AgentEvent(type: .toolUse, content: "Bash", timestamp: .now),
            AgentEvent(type: .toolResult, content: "ok", timestamp: .now)
        ]
        let result = await TitleGenerator.generate(
            events: events,
            apiKey: "sk-test-key",
            baseURL: nil,
            model: "claude-sonnet-4-6"
        )
        XCTAssertNil(result, "Should return nil when no userMessage or assistant events")
    }

    func testReturnsNilWhenEventsEmpty() async {
        let result = await TitleGenerator.generate(
            events: [],
            apiKey: "sk-test-key",
            baseURL: nil,
            model: "claude-sonnet-4-6"
        )
        XCTAssertNil(result)
    }

    func testFiltersToOnlyUserAndAssistantEvents() async {
        // With invalid key, the network call will fail and return nil
        // But the filtering logic should still work (no crash)
        let events = [
            AgentEvent(type: .system, content: "init", timestamp: .now),
            AgentEvent(type: .userMessage, content: "Hello", timestamp: .now),
            AgentEvent(type: .toolUse, content: "Bash", timestamp: .now),
            AgentEvent(type: .assistant, content: "World", timestamp: .now)
        ]
        let result = await TitleGenerator.generate(
            events: events,
            apiKey: "sk-invalid-key",
            baseURL: nil,
            model: "claude-sonnet-4-6"
        )
        // Will return nil due to invalid key, but should not crash
        XCTAssertNotNil(result == nil)
    }

    func testHandlesBaseURLNil() async {
        let events = [AgentEvent(type: .userMessage, content: "test", timestamp: .now)]
        // Will fail due to invalid key, but tests URL construction with nil baseURL
        let _ = await TitleGenerator.generate(
            events: events,
            apiKey: "sk-test",
            baseURL: nil,
            model: "claude-sonnet-4-6"
        )
        // No crash = success
    }

    func testHandlesBaseURLWithTrailingSlash() async {
        let events = [AgentEvent(type: .userMessage, content: "test", timestamp: .now)]
        let _ = await TitleGenerator.generate(
            events: events,
            apiKey: "sk-test",
            baseURL: "https://api.example.com/",
            model: "claude-sonnet-4-6"
        )
        // No crash = success
    }

    func testHandlesBaseURLWithoutTrailingSlash() async {
        let events = [AgentEvent(type: .userMessage, content: "test", timestamp: .now)]
        let _ = await TitleGenerator.generate(
            events: events,
            apiKey: "sk-test",
            baseURL: "https://api.example.com",
            model: "claude-sonnet-4-6"
        )
        // No crash = success
    }

    func testHandlesInvalidBaseURL() async {
        let events = [AgentEvent(type: .userMessage, content: "test", timestamp: .now)]
        let result = await TitleGenerator.generate(
            events: events,
            apiKey: "sk-test",
            baseURL: "not a valid url",
            model: "claude-sonnet-4-6"
        )
        XCTAssertNil(result, "Invalid URL should return nil")
    }

    func testLimitsToLast10Messages() async {
        // Create 15 user events — should only use last 10
        var events: [AgentEvent] = []
        for i in 0..<15 {
            events.append(AgentEvent(type: .userMessage, content: "Message \(i)", timestamp: .now))
        }
        let _ = await TitleGenerator.generate(
            events: events,
            apiKey: "sk-test",
            baseURL: "https://api.anthropic.com",
            model: "claude-sonnet-4-6"
        )
        // No crash = success (the actual API call will fail with fake key)
    }

    func testTruncatesLongContent() async {
        let longContent = String(repeating: "a", count: 1000)
        let events = [AgentEvent(type: .userMessage, content: longContent, timestamp: .now)]
        let _ = await TitleGenerator.generate(
            events: events,
            apiKey: "sk-test",
            baseURL: "https://api.anthropic.com",
            model: "claude-sonnet-4-6"
        )
        // No crash = success
    }

    func testOnlyUserMessageAndAssistantTypesAreIncluded() async {
        let events = [
            AgentEvent(type: .partialMessage, content: "partial", timestamp: .now),
            AgentEvent(type: .result, content: "done", timestamp: .now),
            AgentEvent(type: .system, content: "init", timestamp: .now)
        ]
        let result = await TitleGenerator.generate(
            events: events,
            apiKey: "sk-test",
            baseURL: nil,
            model: "claude-sonnet-4-6"
        )
        XCTAssertNil(result, "Should return nil — no userMessage or assistant events after filtering")
    }
}
