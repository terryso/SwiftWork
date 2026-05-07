import SwiftUI
import OpenAgentSDK

struct MCPServerDetailView: View {
    let config: MCPServerConfig
    let sdkStatus: McpServerStatus?
    let isAgentRunning: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onReconnect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            // Connection type
            detailRow(label: "连接类型", value: config.transportType == .stdio ? "Local (stdio)" : "Remote (\(config.transportType.rawValue))")

            // Technical detail
            technicalDetail

            // Tools list (only when agent running and tools available)
            if let tools = sdkStatus?.tools, !tools.isEmpty {
                toolsSection(tools)
            }

            // Error display (AC7)
            if let error = sdkStatus?.error {
                errorSection(error)
            }

            // Action buttons
            actionButtons
        }
        .padding(.leading, 18)
        .padding(.trailing, 4)
    }

    // MARK: - Detail Row

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
        }
    }

    // MARK: - Technical Detail

    private var technicalDetail: some View {
        Group {
            if config.transportType == .stdio {
                if let command = config.command {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Command")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(fullCommand)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            } else {
                if let url = config.url {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("URL")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(url)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }

    private var fullCommand: String {
        guard let command = config.command else { return "" }
        let args = config.decodedArgs ?? []
        return args.isEmpty ? command : ([command] + args).joined(separator: " ")
    }

    // MARK: - Tools Section

    private func toolsSection(_ tools: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("工具列表 (\(tools.count))")
                .font(.caption)
                .foregroundStyle(.secondary)
            WrappingHStack(tools: tools)
        }
    }

    // MARK: - Error Section (AC7)

    private func errorSection(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("错误信息")
                .font(.caption)
                .foregroundStyle(.red)
            Text(error)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.red)
                .textSelection(.enabled)
        }
        .padding(8)
        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 8) {
            // Toggle enable/disable
            Button {
                onToggle()
            } label: {
                Label(
                    config.enabled ? "禁用" : "启用",
                    systemImage: "power"
                )
                .font(.caption)
            }
            .buttonStyle(.bordered)

            // Edit
            Button {
                onEdit()
            } label: {
                Label("编辑", systemImage: "pencil")
                    .font(.caption)
            }
            .buttonStyle(.bordered)

            // Reconnect (only when agent running)
            if isAgentRunning {
                Button {
                    onReconnect()
                } label: {
                    Label("重连", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            // Delete
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("删除", systemImage: "trash")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Wrapping HStack for tool tags

private struct WrappingHStack: View {
    let tools: [String]

    var body: some View {
        FlowLayout(spacing: 4) {
            ForEach(tools, id: \.self) { tool in
                Text(tool)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.fill.tertiary, in: Capsule())
            }
        }
    }
}

// Simple flow layout for wrapping tags
private struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
