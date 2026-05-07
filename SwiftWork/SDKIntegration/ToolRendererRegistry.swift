import SwiftUI

@MainActor
@Observable
final class ToolRendererRegistry {
    private var renderers: [String: any ToolRenderable] = [:]
    private let mcpRenderer = MCPToolRenderer()

    init() {
        // 预注册默认骨架渲染器
        register(BashToolRenderer())
        register(FileEditToolRenderer())
        register(SearchToolRenderer())
        register(ReadToolRenderer())
        register(WriteToolRenderer())
        register(SkillToolRenderer())
    }

    func register(_ renderer: any ToolRenderable) {
        renderers[type(of: renderer).toolName] = renderer
    }

    func renderer(for toolName: String) -> (any ToolRenderable)? {
        // 1. Exact match for registered renderers (Bash, FileEdit, Skill, etc.)
        if let exact = renderers[toolName] {
            return exact
        }
        // 2. MCP tool prefix match — "mcp__serverName__toolName"
        if toolName.hasPrefix("mcp__") {
            return mcpRenderer
        }
        return nil
    }
}
