import SwiftUI
import SwiftData

struct EditMCPServerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let originalConfig: MCPServerConfig
    let store: MCPServerConfigStore
    let scope: MCPServerScope
    let workspacePath: String?
    let agentBridge: AgentBridge?
    let onSave: (MCPServerConfig) -> Void

    @State private var viewModel = AddMCPServerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            formContent
            Divider()
            footer
        }
        .frame(minWidth: 480, minHeight: 360)
        .onAppear {
            viewModel.populateFromConfig(originalConfig)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("编辑 MCP Server")
                    .font(.headline)
                Text(originalConfig.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }

    // MARK: - Form

    private var formContent: some View {
        ScrollView {
            MCPFormFields(viewModel: viewModel)
                .padding(16)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Spacer()
            Button("取消") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            Button("保存") {
                performSave()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!viewModel.isValid || viewModel.isSubmitting)
        }
        .padding(16)
    }

    // MARK: - Actions

    private func performSave() {
        guard viewModel.validate() else { return }

        viewModel.isSubmitting = true
        do {
            let updated = try viewModel.submitEdit(
                originalConfig: originalConfig,
                store: store,
                scope: scope,
                workspacePath: workspacePath
            )
            agentBridge?.updateMCPServers()
            viewModel.isSubmitting = false
            onSave(updated)
            dismiss()
        } catch let error as MCPServerConfigError {
            viewModel.isSubmitting = false
            viewModel.errorMessage = error.errorDescription
        } catch {
            viewModel.isSubmitting = false
            viewModel.errorMessage = error.localizedDescription
        }
    }
}
