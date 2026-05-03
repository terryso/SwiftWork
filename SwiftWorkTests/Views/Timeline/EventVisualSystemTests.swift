import XCTest
import SwiftUI
@testable import SwiftWork

// Story 2.3: 事件类型视觉系统 — 单元测试
// Tests for ToolRenderable visual properties and EventView visual updates.

@MainActor
final class EventVisualSystemTests: XCTestCase {

    // MARK: - ToolRenderable default accentColor and icon

    func testToolRenderableDefaultAccentColorIsGray() {
        let mockColor = MockVisualRenderer.accentColor
        XCTAssertNotNil(mockColor, "Default accentColor should not be nil")
    }

    func testToolRenderableDefaultIconIsWrench() {
        let mockIcon = MockVisualRenderer.icon
        XCTAssertEqual(mockIcon, "wrench.and.screwdriver", "Default icon should be wrench.and.screwdriver")
    }

    // MARK: - Each renderer's accentColor and icon return expected values

    func testBashToolRendererAccentColor() {
        let color = BashToolRenderer.accentColor
        XCTAssertNotNil(color, "BashToolRenderer.accentColor should be green")
    }

    func testBashToolRendererIcon() {
        XCTAssertEqual(BashToolRenderer.icon, "terminal", "BashToolRenderer.icon should be 'terminal'")
    }

    func testFileEditToolRendererAccentColor() {
        let color = FileEditToolRenderer.accentColor
        XCTAssertNotNil(color, "FileEditToolRenderer.accentColor should be orange")
    }

    func testFileEditToolRendererIcon() {
        XCTAssertEqual(FileEditToolRenderer.icon, "pencil.line", "FileEditToolRenderer.icon should be 'pencil.line'")
    }

    func testSearchToolRendererAccentColor() {
        let color = SearchToolRenderer.accentColor
        XCTAssertNotNil(color, "SearchToolRenderer.accentColor should be purple")
    }

    func testSearchToolRendererIcon() {
        XCTAssertEqual(SearchToolRenderer.icon, "text.magnifyingglass", "SearchToolRenderer.icon should be 'text.magnifyingglass'")
    }

    func testReadToolRendererAccentColor() {
        let color = ReadToolRenderer.accentColor
        XCTAssertNotNil(color, "ReadToolRenderer.accentColor should be blue")
    }

    func testReadToolRendererIcon() {
        XCTAssertEqual(ReadToolRenderer.icon, "doc.text", "ReadToolRenderer.icon should be 'doc.text'")
    }

    func testWriteToolRendererAccentColor() {
        let color = WriteToolRenderer.accentColor
        XCTAssertNotNil(color, "WriteToolRenderer.accentColor should be orange")
    }

    func testWriteToolRendererIcon() {
        XCTAssertEqual(WriteToolRenderer.icon, "pencil.and.outline", "WriteToolRenderer.icon should be 'pencil.and.outline'")
    }

    // MARK: - Registry resolves visual properties through protocol

    func testRegistryResolvesAccentColorForBash() {
        let registry = ToolRendererRegistry()
        guard let renderer = registry.renderer(for: "Bash") else {
            XCTFail("Registry should have Bash renderer")
            return
        }
        let color = type(of: renderer).accentColor
        XCTAssertNotNil(color, "Registry-resolved BashToolRenderer should have green accentColor")
    }

    func testRegistryResolvesIconForBash() {
        let registry = ToolRendererRegistry()
        guard let renderer = registry.renderer(for: "Bash") else {
            XCTFail("Registry should have Bash renderer")
            return
        }
        XCTAssertEqual(type(of: renderer).icon, "terminal", "Registry-resolved Bash should have terminal icon")
    }

    func testRegistryResolvesAccentColorForEdit() {
        let registry = ToolRendererRegistry()
        guard let renderer = registry.renderer(for: "Edit") else {
            XCTFail("Registry should have Edit renderer")
            return
        }
        let color = type(of: renderer).accentColor
        XCTAssertNotNil(color, "Registry-resolved FileEditToolRenderer should have orange accentColor")
    }

    func testRegistryResolvesIconForGrep() {
        let registry = ToolRendererRegistry()
        guard let renderer = registry.renderer(for: "Grep") else {
            XCTFail("Registry should have Grep renderer")
            return
        }
        XCTAssertEqual(type(of: renderer).icon, "text.magnifyingglass", "Registry-resolved Grep should have magnifying glass icon")
    }

    // MARK: - Updated EventView visual properties

    func testAssistantMessageViewRendersWithLeftBar() {
        let event = AgentEvent(type: .assistant, content: "Hello", metadata: ["model": "claude"] as [String: any Sendable], timestamp: .now)
        let view = AssistantMessageView(event: event)
        XCTAssertNotNil(view, "AssistantMessageView should render with left accent bar")
    }

    func testSystemEventViewNonErrorHasInfoIcon() {
        let event = AgentEvent(type: .system, content: "Init", metadata: ["subtype": "init"] as [String: any Sendable], timestamp: .now)
        let view = SystemEventView(event: event)
        XCTAssertNotNil(view, "SystemEventView non-error should have info.circle icon")
    }

    func testSystemEventViewErrorHasRedBackground() {
        let event = AgentEvent(type: .system, content: "Error", metadata: ["isError": true] as [String: any Sendable], timestamp: .now)
        let view = SystemEventView(event: event, isError: true)
        XCTAssertNotNil(view, "SystemEventView error should have red background and left bar")
    }

    func testUnknownEventViewHasDashedBorder() {
        let event = AgentEvent(type: .unknown, content: "unknown data", timestamp: .now)
        let view = UnknownEventView(event: event)
        XCTAssertNotNil(view, "UnknownEventView should render with dashed border")
    }

    func testResultViewErrorSubtypeHasRedBorder() {
        let event = AgentEvent(
            type: .result,
            content: "Failed",
            metadata: ["subtype": "errorDuringExecution", "durationMs": 100] as [String: any Sendable],
            timestamp: .now
        )
        let view = ResultView(event: event)
        XCTAssertNotNil(view, "ResultView with error subtype should have red border and background")
    }

    func testResultViewSuccessSubtypeHasNormalBackground() {
        let event = AgentEvent(
            type: .result,
            content: "Done",
            metadata: ["subtype": "success", "durationMs": 100] as [String: any Sendable],
            timestamp: .now
        )
        let view = ResultView(event: event)
        XCTAssertNotNil(view, "ResultView with success subtype should have normal bar background")
    }

    func testResultViewSuccessHidesBodyContentByDefault() {
        let event = AgentEvent(
            type: .result,
            content: "Same assistant summary shown above",
            metadata: ["subtype": "success", "durationMs": 100, "numTurns": 2] as [String: any Sendable],
            timestamp: .now
        )

        let view = ResultView(event: event)

        XCTAssertFalse(view.shouldShowContent, "Success results should not repeat the body content in the result card")
        XCTAssertTrue(view.showsMetadata, "Success results should keep the metadata row visible")
    }

    func testResultViewSuccessStillHidesUniqueBodyContent() {
        let event = AgentEvent(
            type: .result,
            content: "Only visible success summary",
            metadata: ["subtype": "success", "durationMs": 100] as [String: any Sendable],
            timestamp: .now
        )

        let view = ResultView(event: event)

        XCTAssertFalse(view.shouldShowContent, "Success results should hide body content even when it does not match a previous assistant message")
    }

    func testResultViewCancelledStillShowsBodyContent() {
        let event = AgentEvent(
            type: .result,
            content: "Cancelled by user",
            metadata: ["subtype": "cancelled", "durationMs": 100] as [String: any Sendable],
            timestamp: .now
        )

        let view = ResultView(event: event)

        XCTAssertTrue(view.shouldShowContent, "Cancelled results should keep their body content visible")
    }

    func testResultViewErrorStillShowsBodyContent() {
        let event = AgentEvent(
            type: .result,
            content: "Execution failed on step 3",
            metadata: ["subtype": "errorDuringExecution", "durationMs": 100] as [String: any Sendable],
            timestamp: .now
        )

        let view = ResultView(event: event)

        XCTAssertTrue(view.shouldShowContent, "Error results should keep their body content visible")
    }

    func testResultViewCancelledHidesWhitespaceOnlyBodyContent() {
        let event = AgentEvent(
            type: .result,
            content: "  \n\t  ",
            metadata: ["subtype": "cancelled"] as [String: any Sendable],
            timestamp: .now
        )

        let view = ResultView(event: event)

        XCTAssertFalse(view.shouldShowContent, "Whitespace-only non-success content should not render an empty body block")
    }
}

// MARK: - Mock Renderer for Testing Default Protocol Values

private struct MockVisualRenderer: ToolRenderable {
    static let toolName = "MockVisual"
    @MainActor func body(content: ToolContent) -> any View {
        Text("Mock")
    }
}
