import XCTest
@testable import SwiftWork
import AppKit

final class WindowAccessorTests: XCTestCase {

    // MARK: - AC#1: NSRect Serialization

    // [P0] NSStringFromRect -> NSRectFromString round-trip preserves values
    func testNSRectFromStringRoundTrip() {
        let original = NSRect(x: 100, y: 200, width: 1200, height: 800)
        let string = NSStringFromRect(original)
        let restored = NSRectFromString(string)

        XCTAssertEqual(restored.origin.x, original.origin.x, accuracy: 0.001)
        XCTAssertEqual(restored.origin.y, original.origin.y, accuracy: 0.001)
        XCTAssertEqual(restored.size.width, original.size.width, accuracy: 0.001)
        XCTAssertEqual(restored.size.height, original.size.height, accuracy: 0.001)
    }

    // [P0] Serialized string is non-empty and parseable
    func testNSStringFromRectProducesValidString() {
        let rect = NSRect(x: 0, y: 0, width: 800, height: 600)
        let string = NSStringFromRect(rect)

        XCTAssertFalse(string.isEmpty, "Serialized rect string should not be empty")

        // Should be parseable back to a valid rect
        let restored = NSRectFromString(string)
        XCTAssertEqual(restored.origin.x, rect.origin.x, accuracy: 0.001)
        XCTAssertEqual(restored.size.width, rect.size.width, accuracy: 0.001)
    }

    // [P1] Empty string returns zero rect (not crash)
    func testNSRectFromStringHandlesEmptyString() {
        let restored = NSRectFromString("")

        XCTAssertEqual(restored.origin.x, 0)
        XCTAssertEqual(restored.origin.y, 0)
        XCTAssertEqual(restored.size.width, 0)
        XCTAssertEqual(restored.size.height, 0)
    }

    // [P0] Full precision test: origin.x, origin.y, width, height all preserved
    func testNSRectSerializationPreservesOriginAndSize() {
        let testCases = [
            NSRect(x: 0, y: 0, width: 0, height: 0),
            NSRect(x: 1, y: 1, width: 1, height: 1),
            NSRect(x: -100, y: -200, width: 500, height: 300),
            NSRect(x: 0.5, y: 0.25, width: 1920.75, height: 1080.5),
            NSRect(x: 100, y: 200, width: 1200, height: 800),
            NSRect(x: 50, y: 75, width: 1400, height: 900)
        ]

        for (index, original) in testCases.enumerated() {
            let string = NSStringFromRect(original)
            let restored = NSRectFromString(string)

            XCTAssertEqual(restored.origin.x, original.origin.x, accuracy: 0.001, "Case \(index): origin.x mismatch")
            XCTAssertEqual(restored.origin.y, original.origin.y, accuracy: 0.001, "Case \(index): origin.y mismatch")
            XCTAssertEqual(restored.size.width, original.size.width, accuracy: 0.001, "Case \(index): width mismatch")
            XCTAssertEqual(restored.size.height, original.size.height, accuracy: 0.001, "Case \(index): height mismatch")
        }
    }
}
