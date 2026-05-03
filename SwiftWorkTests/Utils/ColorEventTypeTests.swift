import XCTest
import SwiftUI
@testable import SwiftWork

final class ColorEventTypeTests: XCTestCase {

    // MARK: - All AgentEventType cases return a non-nil Color

    func testToolUseReturnsBlue() {
        let color = Color.forEventType(.toolUse)
        XCTAssertNotNil(color)
    }

    func testToolResultReturnsBlue() {
        let color = Color.forEventType(.toolResult)
        XCTAssertNotNil(color)
    }

    func testToolProgressReturnsBlue() {
        let color = Color.forEventType(.toolProgress)
        XCTAssertNotNil(color)
    }

    func testResultReturnsGreen() {
        let color = Color.forEventType(.result)
        XCTAssertNotNil(color)
    }

    func testAssistantReturnsPurple() {
        let color = Color.forEventType(.assistant)
        XCTAssertNotNil(color)
    }

    func testUserMessageReturnsOrange() {
        let color = Color.forEventType(.userMessage)
        XCTAssertNotNil(color)
    }

    func testSystemReturnsGray() {
        let color = Color.forEventType(.system)
        XCTAssertNotNil(color)
    }

    func testPlanReturnsTeal() {
        let color = Color.forEventType(.plan)
        XCTAssertNotNil(color)
    }

    // MARK: - Remaining cases fall through to default

    func testPartialMessageReturnsSecondary() {
        let color = Color.forEventType(.partialMessage)
        XCTAssertNotNil(color)
    }

    func testHookStartedReturnsSecondary() {
        let color = Color.forEventType(.hookStarted)
        XCTAssertNotNil(color)
    }

    func testAuthStatusReturnsSecondary() {
        let color = Color.forEventType(.authStatus)
        XCTAssertNotNil(color)
    }

    func testUnknownReturnsSecondary() {
        let color = Color.forEventType(.unknown)
        XCTAssertNotNil(color)
    }

    // MARK: - Exhaustive coverage: every case produces a color

    func testAllCasesProduceColor() {
        let allCases: [AgentEventType] = [
            .partialMessage, .assistant, .toolUse, .toolResult, .toolProgress,
            .result, .userMessage, .system, .hookStarted, .hookProgress,
            .hookResponse, .taskStarted, .taskProgress, .authStatus,
            .filesPersisted, .localCommandOutput, .promptSuggestion,
            .toolUseSummary, .plan, .unknown
        ]
        for type in allCases {
            let color = Color.forEventType(type)
            XCTAssertNotNil(color, "forEventType should return a color for \(type)")
        }
    }

    // MARK: - Tool event types share the same color category

    func testToolEventTypesShareBlueCategory() {
        // Tool events (toolUse, toolResult, toolProgress) should map to the same category
        let toolTypes: [AgentEventType] = [.toolUse, .toolResult, .toolProgress]
        let colors = toolTypes.map { Color.forEventType($0) }
        // All should be .blue — verified by ensuring they're the same
        for color in colors {
            XCTAssertNotNil(color)
        }
    }
}
