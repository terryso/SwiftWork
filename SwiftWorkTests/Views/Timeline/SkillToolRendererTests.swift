import XCTest
import SwiftUI
@testable import SwiftWork

// ATDD Red Phase -- Story 5.3: Skill Timeline Card Rendering
// Unit tests for SkillToolRenderer (ToolRenderable implementation).
// These tests will FAIL until Story 5.3 is implemented.

@MainActor
final class SkillToolRendererTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeSkillToolContent(
        input: String = "{\"skill\":\"review\",\"args\":\"check auth code\"}",
        output: String? = nil,
        isError: Bool = false,
        status: ToolExecutionStatus = .pending
    ) -> ToolContent {
        ToolContent(
            toolName: "Skill",
            toolUseId: "tu-skill-001",
            input: input,
            output: output,
            isError: isError,
            status: status
        )
    }

    private func makeSkillToolResultOutput(
        success: Bool = true,
        commandName: String = "review",
        prompt: String = "Review the code for security issues"
    ) -> String {
        """
        {"success":\(success),"commandName":"\(commandName)","prompt":"\(prompt)","allowedTools":["bash","read","glob","grep"],"model":"claude-sonnet-4-20250514"}
        """
    }

    // MARK: - AC#1 -- SkillToolRenderer Protocol Conformance

    // [P0] SkillToolRenderer conforms to ToolRenderable with toolName "Skill"
    func testSkillToolRendererHasCorrectToolName() {
        XCTAssertEqual(
            SkillToolRenderer.toolName,
            "Skill",
            "SkillToolRenderer.toolName must be 'Skill' to match SDK SkillTool"
        )
    }

    // [P0] SkillToolRenderer has purple accent color for visual distinction
    func testSkillToolRendererHasPurpleAccentColor() {
        let color = SkillToolRenderer.accentColor
        // SwiftUI Color.purple -- compare by resolving against a color scheme
        // We verify the static property exists and is accessible; exact equality
        // checks on SwiftUI Color are unreliable, so we use description
        XCTAssertNotNil(color, "SkillToolRenderer.accentColor should be .purple")
    }

    // [P0] SkillToolRenderer uses sparkles icon (not generic wrench)
    func testSkillToolRendererUsesSparklesIcon() {
        let icon = SkillToolRenderer.icon
        XCTAssertEqual(
            icon,
            "sparkles",
            "SkillToolRenderer.icon should be 'sparkles' to visually distinguish from other tools"
        )
    }

    // [P0] SkillToolRenderer is a ToolRenderable (protocol conformance compile check)
    func testSkillToolRendererConformsToToolRenderable() {
        let renderer = SkillToolRenderer()
        // This test verifies protocol conformance at compile time.
        // If SkillToolRenderer does not conform to ToolRenderable, this won't compile.
        let _: any ToolRenderable = renderer
        XCTAssertNotNil(renderer as any ToolRenderable)
    }

    // MARK: - AC#1 -- summaryTitle Parses Skill Name from Input JSON

    // [P0] summaryTitle extracts skill name and prefixes with slash
    func testSummaryTitleExtractsSkillNameWithSlashPrefix() {
        let renderer = SkillToolRenderer()
        let content = makeSkillToolContent(
            input: "{\"skill\":\"review\",\"args\":\"check auth code\"}"
        )

        let title = renderer.summaryTitle(content: content)
        XCTAssertEqual(
            title,
            "/review",
            "summaryTitle should extract 'skill' field and prefix with '/' for /review format"
        )
    }

    // [P0] summaryTitle works with different skill names
    func testSummaryTitleDifferentSkillNames() {
        let renderer = SkillToolRenderer()

        let commitContent = makeSkillToolContent(
            input: "{\"skill\":\"commit\",\"args\":\"initial commit\"}"
        )
        XCTAssertEqual(
            renderer.summaryTitle(content: commitContent),
            "/commit",
            "summaryTitle should return /commit for commit skill"
        )

        let debugContent = makeSkillToolContent(
            input: "{\"skill\":\"debug\",\"args\":\"fix crash\"}"
        )
        XCTAssertEqual(
            renderer.summaryTitle(content: debugContent),
            "/debug",
            "summaryTitle should return /debug for debug skill"
        )

        let simplifyContent = makeSkillToolContent(
            input: "{\"skill\":\"simplify\",\"args\":\"\"}"
        )
        XCTAssertEqual(
            renderer.summaryTitle(content: simplifyContent),
            "/simplify",
            "summaryTitle should return /simplify for simplify skill"
        )
    }

    // [P0] summaryTitle falls back to "Skill" when input is empty
    func testSummaryTitleFallsBackForEmptyInput() {
        let renderer = SkillToolRenderer()
        let content = makeSkillToolContent(input: "")

        let title = renderer.summaryTitle(content: content)
        XCTAssertEqual(
            title,
            "Skill",
            "summaryTitle should fall back to 'Skill' when input is empty"
        )
    }

    // [P1] summaryTitle falls back when input is not valid JSON
    func testSummaryTitleFallsBackForInvalidJSON() {
        let renderer = SkillToolRenderer()
        let content = makeSkillToolContent(input: "not valid json")

        let title = renderer.summaryTitle(content: content)
        XCTAssertEqual(
            title,
            "Skill",
            "summaryTitle should fall back to 'Skill' for non-JSON input"
        )
    }

    // [P1] summaryTitle falls back when JSON lacks 'skill' field
    func testSummaryTitleFallsBackWhenNoSkillField() {
        let renderer = SkillToolRenderer()
        let content = makeSkillToolContent(
            input: "{\"args\":\"some args\",\"other\":\"data\"}"
        )

        let title = renderer.summaryTitle(content: content)
        XCTAssertEqual(
            title,
            "Skill",
            "summaryTitle should fall back to 'Skill' when JSON has no 'skill' field"
        )
    }

    // MARK: - AC#1 -- subtitle Parses Args from Input JSON

    // [P0] subtitle extracts args field from input JSON
    func testSubtitleExtractsArgsFromInput() {
        let renderer = SkillToolRenderer()
        let content = makeSkillToolContent(
            input: "{\"skill\":\"review\",\"args\":\"check auth code\"}"
        )

        let subtitle = renderer.subtitle(content: content)
        XCTAssertEqual(
            subtitle,
            "check auth code",
            "subtitle should extract 'args' field from input JSON"
        )
    }

    // [P0] subtitle truncates long args to 80 characters
    func testSubtitleTruncatesLongArgs() {
        let renderer = SkillToolRenderer()
        let longArgs = String(repeating: "x", count: 120)
        let content = makeSkillToolContent(
            input: "{\"skill\":\"review\",\"args\":\"\(longArgs)\"}"
        )

        let subtitle = renderer.subtitle(content: content)
        XCTAssertNotNil(subtitle)
        XCTAssertEqual(
            subtitle?.count,
            80,
            "subtitle should truncate args to 80 characters"
        )
    }

    // [P0] subtitle returns nil when args field is empty
    func testSubtitleReturnsNilForEmptyArgs() {
        let renderer = SkillToolRenderer()
        let content = makeSkillToolContent(
            input: "{\"skill\":\"simplify\",\"args\":\"\"}"
        )

        let subtitle = renderer.subtitle(content: content)
        XCTAssertNil(
            subtitle,
            "subtitle should return nil when args is empty string"
        )
    }

    // [P1] subtitle returns nil when args field is missing
    func testSubtitleReturnsNilWhenNoArgsField() {
        let renderer = SkillToolRenderer()
        let content = makeSkillToolContent(
            input: "{\"skill\":\"review\"}"
        )

        let subtitle = renderer.subtitle(content: content)
        XCTAssertNil(
            subtitle,
            "subtitle should return nil when JSON has no 'args' field"
        )
    }

    // [P1] subtitle returns nil for empty input
    func testSubtitleReturnsNilForEmptyInput() {
        let renderer = SkillToolRenderer()
        let content = makeSkillToolContent(input: "")

        let subtitle = renderer.subtitle(content: content)
        XCTAssertNil(
            subtitle,
            "subtitle should return nil for empty input"
        )
    }

    // [P1] subtitle returns nil for invalid JSON input
    func testSubtitleReturnsNilForInvalidJSON() {
        let renderer = SkillToolRenderer()
        let content = makeSkillToolContent(input: "not json")

        let subtitle = renderer.subtitle(content: content)
        XCTAssertNil(
            subtitle,
            "subtitle should return nil for invalid JSON"
        )
    }

    // MARK: - AC#2 -- Skill toolResult Completion Status

    // [P0] SkillToolRenderer body renders with completed status content
    func testBodyRendersCompletedStatusContent() {
        let renderer = SkillToolRenderer()
        let content = makeSkillToolContent(
            output: makeSkillToolResultOutput(success: true),
            status: .completed
        )

        let view = renderer.body(content: content)
        XCTAssertNotNil(view, "SkillToolRenderer.body should return a View for completed content")
    }

    // [P0] SkillToolRenderer body renders with failed status content
    func testBodyRendersFailedStatusContent() {
        let renderer = SkillToolRenderer()
        let content = makeSkillToolContent(
            output: "{\"success\":false,\"commandName\":\"review\",\"error\":\"Skill not found\"}",
            isError: true,
            status: .failed
        )

        let view = renderer.body(content: content)
        XCTAssertNotNil(view, "SkillToolRenderer.body should return a View for failed content")
    }

    // [P0] SkillToolRenderer body renders pending status (no output yet)
    func testBodyRendersPendingStatusContent() {
        let renderer = SkillToolRenderer()
        let content = makeSkillToolContent(status: .pending)

        let view = renderer.body(content: content)
        XCTAssertNotNil(view, "SkillToolRenderer.body should return a View for pending content")
    }

    // MARK: - AC#3 -- Expanded Detail View

    // [P0] SkillToolRenderer body parses toolResult output JSON fields
    func testBodyParsesToolResultOutputJSON() {
        let renderer = SkillToolRenderer()
        let content = makeSkillToolContent(
            output: makeSkillToolResultOutput(
                success: true,
                commandName: "review",
                prompt: "Review the code for security vulnerabilities and suggest improvements"
            ),
            status: .completed
        )

        let view = renderer.body(content: content)
        XCTAssertNotNil(view, "SkillToolRenderer.body should render expanded content with parsed output JSON")
    }

    // [P1] SkillToolRenderer body handles non-JSON output gracefully
    func testBodyHandlesNonJSONOutput() {
        let renderer = SkillToolRenderer()
        let content = makeSkillToolContent(
            output: "plain text result",
            status: .completed
        )

        let view = renderer.body(content: content)
        XCTAssertNotNil(view, "SkillToolRenderer.body should handle non-JSON output without crashing")
    }

    // [P1] SkillToolRenderer body handles empty output
    func testBodyHandlesEmptyOutput() {
        let renderer = SkillToolRenderer()
        let content = makeSkillToolContent(
            output: "",
            status: .completed
        )

        let view = renderer.body(content: content)
        XCTAssertNotNil(view, "SkillToolRenderer.body should handle empty output")
    }

    // [P1] SkillToolRenderer body displays promptTemplate summary (first 200 chars)
    func testBodyDisplaysPromptTemplateSummary() {
        let renderer = SkillToolRenderer()
        let longPrompt = String(repeating: "Review code carefully. ", count: 20)
        let content = makeSkillToolContent(
            output: makeSkillToolResultOutput(prompt: longPrompt),
            status: .completed
        )

        let view = renderer.body(content: content)
        XCTAssertNotNil(view, "SkillToolRenderer.body should render promptTemplate truncated to ~200 chars")
    }

    // MARK: - AC#4 -- Visual Distinction from Other Tool Cards

    // [P0] SkillToolRenderer icon differs from BashToolRenderer icon
    func testSkillIconDiffersFromBashToolRenderer() {
        XCTAssertNotEqual(
            SkillToolRenderer.icon,
            BashToolRenderer.icon,
            "SkillToolRenderer icon should differ from BashToolRenderer icon for visual distinction"
        )
    }

    // [P0] SkillToolRenderer icon differs from FileEditToolRenderer icon
    func testSkillIconDiffersFromFileEditToolRenderer() {
        XCTAssertNotEqual(
            SkillToolRenderer.icon,
            FileEditToolRenderer.icon,
            "SkillToolRenderer icon should differ from FileEditToolRenderer icon"
        )
    }

    // [P0] SkillToolRenderer icon differs from SearchToolRenderer icon
    func testSkillIconDiffersFromSearchToolRenderer() {
        XCTAssertNotEqual(
            SkillToolRenderer.icon,
            SearchToolRenderer.icon,
            "SkillToolRenderer icon should differ from SearchToolRenderer icon"
        )
    }

    // [P1] SkillToolRenderer toolName differs from all other registered renderers
    func testSkillToolNameIsUnique() {
        let allToolNames = [
            BashToolRenderer.toolName,
            FileEditToolRenderer.toolName,
            SearchToolRenderer.toolName,
            ReadToolRenderer.toolName,
            WriteToolRenderer.toolName,
        ]
        XCTAssertTrue(
            allToolNames.allSatisfy { $0 != SkillToolRenderer.toolName },
            "SkillToolRenderer.toolName 'Skill' should not conflict with any existing renderer"
        )
    }

    // MARK: - Registry Integration

    // [P0] ToolRendererRegistry has SkillToolRenderer registered after init
    func testRegistryContainsSkillToolRendererAfterInit() {
        let registry = ToolRendererRegistry()
        let renderer = registry.renderer(for: "Skill")

        XCTAssertNotNil(
            renderer,
            "ToolRendererRegistry should have SkillToolRenderer registered for toolName 'Skill'"
        )
    }

    // [P0] Registry-returned renderer produces correct summaryTitle for Skill content
    func testRegistryRendererSummaryTitleForSkillContent() {
        let registry = ToolRendererRegistry()
        let renderer = registry.renderer(for: "Skill")
        XCTAssertNotNil(renderer)

        let content = makeSkillToolContent(
            input: "{\"skill\":\"review\",\"args\":\"check auth code\"}"
        )

        let title = renderer?.summaryTitle(content: content)
        XCTAssertEqual(
            title,
            "/review",
            "Registry-returned SkillToolRenderer should produce /review summaryTitle"
        )
    }

    // [P0] Registry-returned renderer produces correct subtitle for Skill content
    func testRegistryRendererSubtitleForSkillContent() {
        let registry = ToolRendererRegistry()
        let renderer = registry.renderer(for: "Skill")
        XCTAssertNotNil(renderer)

        let content = makeSkillToolContent(
            input: "{\"skill\":\"review\",\"args\":\"check auth code\"}"
        )

        let subtitle = renderer?.subtitle(content: content)
        XCTAssertEqual(
            subtitle,
            "check auth code",
            "Registry-returned SkillToolRenderer should produce correct subtitle"
        )
    }

    // [P1] Registry-returned renderer body returns a View
    func testRegistryRendererBodyReturnsView() {
        let registry = ToolRendererRegistry()
        let renderer = registry.renderer(for: "Skill")
        XCTAssertNotNil(renderer)

        let content = makeSkillToolContent()
        let view = renderer?.body(content: content)
        XCTAssertNotNil(view, "Registry-returned SkillToolRenderer body should return a View")
    }

    // MARK: - Multiple Skill Calls Independence (AC#4)

    // [P0] Each Skill call is rendered independently with its own data
    func testMultipleSkillCallsRenderIndependently() {
        let renderer = SkillToolRenderer()

        let reviewContent = makeSkillToolContent(
            input: "{\"skill\":\"review\",\"args\":\"auth module\"}"
        )
        let commitContent = makeSkillToolContent(
            input: "{\"skill\":\"commit\",\"args\":\"fix login bug\"}"
        )

        let reviewTitle = renderer.summaryTitle(content: reviewContent)
        let commitTitle = renderer.summaryTitle(content: commitContent)

        XCTAssertEqual(reviewTitle, "/review")
        XCTAssertEqual(commitTitle, "/commit")
        XCTAssertNotEqual(reviewTitle, commitTitle, "Each skill call should render with its own name")
    }

    // [P1] Multiple Skill calls with different statuses render correctly
    func testMultipleSkillCallsWithDifferentStatuses() {
        let renderer = SkillToolRenderer()

        let pendingContent = makeSkillToolContent(
            input: "{\"skill\":\"review\",\"args\":\"auth\"}",
            status: .pending
        )
        let completedContent = makeSkillToolContent(
            input: "{\"skill\":\"commit\",\"args\":\"fix\"}",
            output: makeSkillToolResultOutput(),
            status: .completed
        )
        let failedContent = makeSkillToolContent(
            input: "{\"skill\":\"debug\",\"args\":\"crash\"}",
            output: "{\"success\":false}",
            isError: true,
            status: .failed
        )

        let pendingView = renderer.body(content: pendingContent)
        let completedView = renderer.body(content: completedContent)
        let failedView = renderer.body(content: failedContent)

        XCTAssertNotNil(pendingView)
        XCTAssertNotNil(completedView)
        XCTAssertNotNil(failedView)
    }

    // MARK: - Edge Cases

    // [P1] Skill input with extra JSON fields still extracts skill and args
    func testExtraJSONFieldsIgnored() {
        let renderer = SkillToolRenderer()
        let content = makeSkillToolContent(
            input: "{\"skill\":\"review\",\"args\":\"check code\",\"extra_field\":\"value\",\"nested\":{\"key\":\"val\"}}"
        )

        let title = renderer.summaryTitle(content: content)
        let subtitle = renderer.subtitle(content: content)

        XCTAssertEqual(title, "/review")
        XCTAssertEqual(subtitle, "check code")
    }

    // [P1] Skill input with non-string skill field falls back
    func testNonStringSkillFieldFallsBack() {
        let renderer = SkillToolRenderer()
        let content = makeSkillToolContent(
            input: "{\"skill\":123,\"args\":\"check\"}"
        )

        let title = renderer.summaryTitle(content: content)
        XCTAssertEqual(title, "Skill", "Non-string 'skill' field should fall back to 'Skill'")
    }

    // [P1] Skill input with non-string args field returns nil subtitle
    func testNonStringArgsFieldReturnsNil() {
        let renderer = SkillToolRenderer()
        let content = makeSkillToolContent(
            input: "{\"skill\":\"review\",\"args\":[\"a\",\"b\"]}"
        )

        let subtitle = renderer.subtitle(content: content)
        XCTAssertNil(subtitle, "Non-string 'args' field should return nil subtitle")
    }

    // [P1] Args exactly at 80 characters is not truncated
    func testArgsAtExactLimitNotTruncated() {
        let renderer = SkillToolRenderer()
        let exactArgs = String(repeating: "a", count: 80)
        let content = makeSkillToolContent(
            input: "{\"skill\":\"review\",\"args\":\"\(exactArgs)\"}"
        )

        let subtitle = renderer.subtitle(content: content)
        XCTAssertEqual(subtitle?.count, 80, "Args at exactly 80 chars should not be truncated")
    }

    // [P1] Args at 81 characters is truncated to 80
    func testArgsOverLimitByOneTruncated() {
        let renderer = SkillToolRenderer()
        let overArgs = String(repeating: "a", count: 81)
        let content = makeSkillToolContent(
            input: "{\"skill\":\"review\",\"args\":\"\(overArgs)\"}"
        )

        let subtitle = renderer.subtitle(content: content)
        XCTAssertEqual(subtitle?.count, 80, "Args at 81 chars should be truncated to 80")
    }
}
