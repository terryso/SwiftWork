import SwiftUI

/// Renderer for MCP (Model Context Protocol) tool calls.
/// MCP tools use namespaced names: `mcp__{serverName}__{toolName}`.
/// The ToolRendererRegistry returns this renderer via prefix matching
/// when a tool name starts with "mcp__".
struct MCPToolRenderer: ToolRenderable {
    static let toolName = "mcp__*"
    static let accentColor: Color = .blue
    static let icon: String = "cube.box"

    @MainActor
    func body(content: ToolContent) -> any View {
        MCPToolExpandedContent(content: content)
    }

    func summaryTitle(content: ToolContent) -> String {
        let parts = content.toolName.components(separatedBy: "__")
        if parts.count >= 3 {
            return parts.dropFirst(2).joined(separator: "__")
        }
        return content.toolName
    }

    func subtitle(content: ToolContent) -> String? {
        let parts = content.toolName.components(separatedBy: "__")
        if parts.count >= 2 {
            return "via \(parts[1])"
        }
        return nil
    }
}

// MARK: - Expanded Content View

private struct MCPToolExpandedContent: View {
    let content: ToolContent

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                // Header with MCP icon and tool name
                HStack(spacing: 4) {
                    Image(systemName: "cube.box")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(parsedToolName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }

                // Server source label
                if let serverLabel = serverSourceLabel {
                    HStack(spacing: 2) {
                        Image(systemName: "server.rack")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text(serverLabel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Status-dependent content
                statusContent
            }
            Spacer()
        }
        .padding(8)
        .background(.blue.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var statusContent: some View {
        switch content.status {
        case .pending:
            HStack(spacing: 4) {
                ProgressView()
                    .controlSize(.mini)
                Text("Waiting...")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case .running:
            HStack(spacing: 4) {
                ProgressView()
                    .controlSize(.mini)
                Text("Running...")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case .completed:
            completedContent
        case .failed:
            failedContent
        }
    }

    @ViewBuilder
    private var completedContent: some View {
        if let output = content.output, !output.isEmpty {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                Text(String(output.prefix(120)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
    }

    @ViewBuilder
    private var failedContent: some View {
        HStack(spacing: 4) {
            Image(systemName: "xmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.red)
            if let output = content.output, !output.isEmpty {
                Text(String(output.prefix(120)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            } else {
                Text("Failed")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Helpers

    private var parsedToolName: String {
        let parts = content.toolName.components(separatedBy: "__")
        if parts.count >= 3 {
            return parts.dropFirst(2).joined(separator: "__")
        }
        return content.toolName
    }

    private var serverSourceLabel: String? {
        let parts = content.toolName.components(separatedBy: "__")
        if parts.count >= 2 {
            return "via \(parts[1])"
        }
        return nil
    }
}
