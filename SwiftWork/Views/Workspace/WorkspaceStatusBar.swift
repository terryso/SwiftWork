import SwiftUI

/// Bottom status bar that displays MCP connection status.
/// Positioned between the Timeline and InputBar in WorkspaceView.
struct WorkspaceStatusBar: View {
    let viewModel: MCPStatusViewModel

    var body: some View {
        HStack(spacing: 6) {
            mcpStatusContent
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
    }

    // MARK: - MCP Status Content

    @ViewBuilder
    private var mcpStatusContent: some View {
        if viewModel.showsPending {
            // Pending/connecting state — show loading indicator
            mcpPendingIndicator
        } else if viewModel.hasConnections {
            // Connected state — green dot + count
            mcpConnectedIndicator
            if viewModel.showsWarning {
                Text("·").foregroundStyle(.secondary)
                mcpWarningIndicator
            }
        } else if viewModel.showsWarning {
            // Only failures
            mcpWarningIndicator
        } else if viewModel.totalConfiguredCount > 0 {
            // Configured but offline
            mcpConfiguredIndicator
        } else {
            // Nothing configured — ready state
            Text("就绪")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Status Components

    private var mcpConnectedIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "cube.box")
                .font(.system(size: 10))
                .foregroundStyle(.green)
            Circle()
                .fill(.green)
                .frame(width: 6, height: 6)
            Text(viewModel.connectedCount == 1
                 ? "1 MCP 已连接"
                 : "\(viewModel.connectedCount) MCP 已连接")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private var mcpWarningIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(.orange)
                .frame(width: 6, height: 6)
            Text("\(viewModel.failedCount) 个 MCP 连接失败")
                .font(.system(size: 11))
                .foregroundStyle(.orange)
        }
    }

    private var mcpPendingIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "cube.box")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            ProgressView()
                .controlSize(.mini)
            Text("正在连接...")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private var mcpConfiguredIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "cube.box")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            Text("\(viewModel.totalConfiguredCount) MCP 已配置")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }
}
