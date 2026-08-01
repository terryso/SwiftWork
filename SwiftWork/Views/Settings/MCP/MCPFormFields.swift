import SwiftUI

struct MCPFormFields: View {
    @Bindable var viewModel: AddMCPServerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            jsonEditor
            if viewModel.showsNameField {
                nameField
            }
            errorBanner
        }
    }

    // MARK: - JSON Editor

    private var jsonEditor: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("JSON 配置")
                .font(.caption)
                .foregroundStyle(.secondary)
            ZStack(alignment: .topLeading) {
                // Placeholder
                if viewModel.jsonText.isEmpty {
                    Text(placeholder)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $viewModel.jsonText)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(4)
            }
            .frame(minHeight: 180)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(viewModel.jsonText.isEmpty ? Color.clear : Color.accentColor.opacity(0.3), lineWidth: 1)
            )

            HStack {
                Text("支持 mcpServers、单服务器或裸配置；header/env 将按 JSON 原文保存")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                if viewModel.detectedFormat != .invalid && !viewModel.jsonText.isEmpty {
                    Button {
                        viewModel.normalizeJSON()
                    } label: {
                        Label("格式化", systemImage: "wand.and.stars")
                            .font(.caption2)
                    }
                    .buttonStyle(.borderless)
                    .help("整理为标准 mcpServers 格式（camelCase + 缩进）")
                }
            }
        }
    }

    // MARK: - Name Field

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Server 名称")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("例如 my-mcp-server", text: $viewModel.serverName)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Error Banner

    @ViewBuilder
    private var errorBanner: some View {
        if let error = viewModel.errorMessage {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    // MARK: - Placeholder

    private var placeholder: String {
        """
        {
          "mcpServers": {
            "server-name": {
              "command": "npx",
              "args": ["-y", "@some/mcp-server"]
            }
          }
        }
        """
    }
}
