import SwiftUI

/// 可扩展的工具卡片渲染协议。
/// 每种工具类型注册一个实现，ToolRendererRegistry 查找并调用。
protocol ToolRenderable: Sendable {
    /// 此渲染器处理的工具名称（与 SDK ToolUseData.toolName 匹配）
    static var toolName: String { get }

    /// 工具类型主题色（左边条、图标着色）
    static var accentColor: Color { get }

    /// 工具类型 SF Symbol 图标名
    static var icon: String { get }

    /// 根据工具内容生成 SwiftUI 视图
    @ViewBuilder @MainActor
    func body(content: ToolContent) -> any View

    /// 可选：生成摘要标题（用于折叠状态显示）
    func summaryTitle(content: ToolContent) -> String

    /// 可选：生成副标题（如文件路径、命令摘要）
    func subtitle(content: ToolContent) -> String?
}

extension ToolRenderable {
    static var accentColor: Color { .gray }

    static var icon: String { "wrench.and.screwdriver" }

    func summaryTitle(content: ToolContent) -> String {
        content.toolName
    }

    func subtitle(content: ToolContent) -> String? {
        nil
    }
}
