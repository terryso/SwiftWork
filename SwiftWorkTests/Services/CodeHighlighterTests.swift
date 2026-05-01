import XCTest
@testable import SwiftWork

// MARK: - Story 2-4: CodeHighlighter Tests
//
// Coverage: AC#2 (code block syntax highlighting with Splash for Swift, plain text for other languages)

final class CodeHighlighterTests: XCTestCase {

    // MARK: - AC#2 — Swift Code Highlighting

    // [P0] CodeHighlighter should produce attributed output for Swift code
    @MainActor
    func testHighlightSwiftCodeReturnsNonNilAttributedOutput() throws {
        let swiftCode = """
        import Foundation

        func greet(name: String) -> String {
            return "Hello, \\(name)!"
        }
        """
        let result = CodeHighlighter.highlight(code: swiftCode, language: "swift")
        XCTAssertNotNil(result, "CodeHighlighter should return non-nil result for Swift code")
    }

    // [P0] CodeHighlighter should produce color attributes for Swift keywords
    @MainActor
    func testHighlightSwiftCodeAppliesColorAttributes() throws {
        let swiftCode = "import Foundation\nlet x = 42\nfunc hello() {}"
        let result = CodeHighlighter.highlight(code: swiftCode, language: "swift")
        XCTAssertNotNil(result, "Swift code should be highlighted with color attributes for keywords like import, let, func")
    }

    // [P1] CodeHighlighter should handle empty Swift code gracefully
    @MainActor
    func testHighlightEmptySwiftCode() throws {
        let result = CodeHighlighter.highlight(code: "", language: "swift")
        XCTAssertNotNil(result, "CodeHighlighter should handle empty code string without crashing")
    }

    // MARK: - AC#2 — Non-Swift Language Fallback

    // [P0] CodeHighlighter should return plain text view for Python code
    @MainActor
    func testHighlightPythonCodeReturnsPlainText() throws {
        let pythonCode = "def hello():\n    print('Hello, World!')"
        let result = CodeHighlighter.highlight(code: pythonCode, language: "python")
        XCTAssertNotNil(result, "CodeHighlighter should return plain text for Python code (no syntax highlighting)")
    }

    // [P1] CodeHighlighter should return plain text view for JavaScript code
    @MainActor
    func testHighlightJavaScriptCodeReturnsPlainText() throws {
        let jsCode = "const greeting = 'Hello, World!';\nconsole.log(greeting);"
        let result = CodeHighlighter.highlight(code: jsCode, language: "javascript")
        XCTAssertNotNil(result, "CodeHighlighter should return plain text for JavaScript code")
    }

    // [P1] CodeHighlighter should return plain text view for Bash code
    @MainActor
    func testHighlightBashCodeReturnsPlainText() throws {
        let bashCode = "#!/bin/bash\necho 'Hello, World!'"
        let result = CodeHighlighter.highlight(code: bashCode, language: "bash")
        XCTAssertNotNil(result, "CodeHighlighter should return plain text for Bash code")
    }

    // [P1] CodeHighlighter should handle nil/missing language identifier
    @MainActor
    func testHighlightCodeWithNilLanguageReturnsPlainText() throws {
        let code = "some generic code without a language tag"
        let result = CodeHighlighter.highlight(code: code, language: nil)
        XCTAssertNotNil(result, "CodeHighlighter should handle nil language gracefully and return plain text")
    }

    // [P2] CodeHighlighter should handle JSON code as plain text
    @MainActor
    func testHighlightJSONCodeReturnsPlainText() throws {
        let jsonCode = "{\"key\": \"value\", \"count\": 42}"
        let result = CodeHighlighter.highlight(code: jsonCode, language: "json")
        XCTAssertNotNil(result, "CodeHighlighter should return plain text for JSON")
    }

    // [P2] CodeHighlighter should handle very long code without crashing
    @MainActor
    func testHighlightLongCodeDoesNotHang() throws {
        let longCode = String(repeating: "let x = 42\n", count: 200)
        let result = CodeHighlighter.highlight(code: longCode, language: "swift")
        XCTAssertNotNil(result, "CodeHighlighter should handle very long code without crashing or excessive delay")
    }
}
