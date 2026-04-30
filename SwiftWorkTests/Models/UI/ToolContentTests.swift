import XCTest
@testable import SwiftWork

final class ToolContentTests: XCTestCase {

    // MARK: - AC#4: ToolContent UI Model

    // [P0] ToolContent can be created with tool call data
    func testToolContentInstantiation() throws {
        let content = ToolContent(
            toolName: "Read",
            toolUseId: "abc-123",
            input: "{}",
            output: "file contents here",
            isError: false
        )

        XCTAssertEqual(content.toolName, "Read")
        XCTAssertEqual(content.toolUseId, "abc-123")
        XCTAssertFalse(content.isError)
    }

    // [P1] ToolContent input is JSON string (not dictionary)
    func testToolContentInputIsJSONString() throws {
        let input = #"{"filePath": "/test/file.swift"}"#
        let content = ToolContent(
            toolName: "Read",
            toolUseId: "xyz",
            input: input,
            output: nil,
            isError: false
        )

        XCTAssertEqual(content.input, input)
        // Verify it's valid JSON
        let parsed = try JSONSerialization.jsonObject(with: Data(input.utf8))
        XCTAssertNotNil(parsed)
    }

    // [P1] ToolContent output is optional (pending tools have nil output)
    func testToolContentOutputIsOptional() throws {
        let content = ToolContent(
            toolName: "Bash",
            toolUseId: "pending",
            input: #"{"command": "ls"}"#,
            output: nil,
            isError: false
        )

        XCTAssertNil(content.output)
    }

    // [P1] ToolContent isError distinguishes success from failure
    func testToolContentIsError() throws {
        let success = ToolContent(toolName: "Read", toolUseId: "ok", input: "{}", output: "contents", isError: false)
        let failure = ToolContent(toolName: "Bash", toolUseId: "err", input: "{}", output: "command not found", isError: true)

        XCTAssertFalse(success.isError)
        XCTAssertTrue(failure.isError)
    }
}
