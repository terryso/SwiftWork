import SwiftUI

@MainActor
@Observable
final class ToolRendererRegistry {
    private var renderers: [String: any ToolRenderable] = [:]

    init() {
        // 预注册默认骨架渲染器
        register(BashToolRenderer())
        register(FileEditToolRenderer())
        register(SearchToolRenderer())
    }

    func register(_ renderer: any ToolRenderable) {
        renderers[type(of: renderer).toolName] = renderer
    }

    func renderer(for toolName: String) -> (any ToolRenderable)? {
        renderers[toolName]
    }
}
