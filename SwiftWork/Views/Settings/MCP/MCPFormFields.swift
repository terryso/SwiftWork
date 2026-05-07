import SwiftUI

struct MCPFormFields: View {
    @Bindable var viewModel: AddMCPServerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            nameField
            transportPicker
            dynamicFields
            errorBanner
        }
    }

    // MARK: - Name

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Server 名称")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("例如 my-mcp-server", text: $viewModel.name)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Transport Picker

    private var transportPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("传输类型")
                .font(.caption)
                .foregroundStyle(.secondary)
            MCPTransportTypePicker(selectedMode: $viewModel.transportMode)
        }
    }

    // MARK: - Dynamic URL / Command

    @ViewBuilder
    private var dynamicFields: some View {
        switch viewModel.transportMode {
        case .remote:
            urlField
        case .local:
            commandField
        }
    }

    private var urlField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("URL")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("例如 http://localhost:3000/sse", text: $viewModel.url)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var commandField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Command")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("例如 npx -y @modelcontextprotocol/server-filesystem /tmp", text: $viewModel.command)
                .textFieldStyle(.roundedBorder)
            Text("第一个 token 为命令，其余为参数")
                .font(.caption2)
                .foregroundStyle(.tertiary)
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
}
