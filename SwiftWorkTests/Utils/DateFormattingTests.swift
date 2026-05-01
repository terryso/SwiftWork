import XCTest
@testable import SwiftWork

final class DateFormattingTests: XCTestCase {

    func testRelativeFormattedReturnsNonEmptyString() {
        let now = Date.now
        let result = now.relativeFormatted
        XCTAssertFalse(result.isEmpty, "relativeFormatted should return a non-empty string")
    }

    func testRelativeFormattedForCurrentTime() {
        let result = Date.now.relativeFormatted
        XCTAssertTrue(
            result.contains("now") || result.contains("刚刚") || result.contains("in") || result.contains("秒"),
            "Current time should produce a 'now'-like relative string, got: \(result)"
        )
    }

    func testRelativeFormattedForPastDate() {
        let past = Date.now.addingTimeInterval(-3600) // 1 hour ago
        let result = past.relativeFormatted
        XCTAssertFalse(result.isEmpty, "Past date should produce a non-empty relative string")
    }

    func testRelativeFormattedForFutureDate() {
        let future = Date.now.addingTimeInterval(3600) // 1 hour from now
        let result = future.relativeFormatted
        XCTAssertFalse(result.isEmpty, "Future date should produce a non-empty relative string")
    }

    func testDifferentDatesProduceDifferentStrings() {
        let now = Date.now
        let hourAgo = now.addingTimeInterval(-3600)
        let dayAgo = now.addingTimeInterval(-86400)

        let nowStr = now.relativeFormatted
        let hourStr = hourAgo.relativeFormatted
        let dayStr = dayAgo.relativeFormatted

        XCTAssertNotEqual(nowStr, hourStr, "Different dates should produce different strings")
        XCTAssertNotEqual(hourStr, dayStr, "Different dates should produce different strings")
    }
}
