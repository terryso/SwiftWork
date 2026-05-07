import SwiftUI
import SwiftData

@MainActor
@Observable
final class AddMCPServerViewModel {

    // MARK: - Form State

    var name = ""
    var transportMode: MCPTransportMode = .remote
    var url = ""
    var command = ""
    var isSubmitting = false
    var errorMessage: String?

    // MARK: - Validation

    var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }

        switch transportMode {
        case .remote:
            return !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .local:
            return !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    @discardableResult
    func validate() -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            errorMessage = "Server 名称不能为空"
            return false
        }

        switch transportMode {
        case .remote:
            if url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = "URL 不能为空"
                return false
            }
        case .local:
            if command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = "Command 不能为空"
                return false
            }
        }

        errorMessage = nil
        return true
    }

    // MARK: - Submit (Add)

    func submit(
        store: MCPServerConfigStore,
        scope: MCPServerScope,
        workspacePath: String?
    ) throws -> MCPServerConfig {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        switch transportMode {
        case .remote:
            return try store.add(
                name: trimmedName,
                transportType: .sse,
                command: nil,
                url: url.trimmingCharacters(in: .whitespacesAndNewlines),
                args: nil,
                env: nil,
                headers: nil,
                enabled: true,
                scope: scope,
                workspacePath: workspacePath
            )

        case .local:
            let (cmd, args) = parseCommand(command)
            let argsData = args.isEmpty ? nil : try? JSONEncoder().encode(args)
            return try store.add(
                name: trimmedName,
                transportType: .stdio,
                command: cmd,
                url: nil,
                args: argsData,
                env: nil,
                headers: nil,
                enabled: true,
                scope: scope,
                workspacePath: workspacePath
            )
        }
    }

    // MARK: - Submit (Edit)

    func submitEdit(
        originalConfig: MCPServerConfig,
        store: MCPServerConfigStore,
        scope: MCPServerScope,
        workspacePath: String?
    ) throws -> MCPServerConfig {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        switch transportMode {
        case .remote:
            return try store.replace(
                originalConfig,
                name: trimmedName,
                transportType: .sse,
                command: nil,
                url: url.trimmingCharacters(in: .whitespacesAndNewlines),
                args: nil,
                env: nil,
                headers: nil,
                enabled: originalConfig.enabled,
                scope: scope,
                workspacePath: workspacePath
            )

        case .local:
            let (cmd, args) = parseCommand(command)
            let argsData = args.isEmpty ? nil : try? JSONEncoder().encode(args)
            return try store.replace(
                originalConfig,
                name: trimmedName,
                transportType: .stdio,
                command: cmd,
                url: nil,
                args: argsData,
                env: nil,
                headers: nil,
                enabled: originalConfig.enabled,
                scope: scope,
                workspacePath: workspacePath
            )
        }
    }

    // MARK: - Populate from Existing Config (Edit Mode)

    func populateFromConfig(_ config: MCPServerConfig) {
        name = config.name

        switch config.transportType {
        case .sse, .http:
            transportMode = .remote
            url = config.url ?? ""
            command = ""
        case .stdio:
            transportMode = .local
            url = ""
            if let cmd = config.command {
                let decodedArgs = config.decodedArgs ?? []
                if decodedArgs.isEmpty {
                    command = cmd
                } else {
                    command = ([cmd] + decodedArgs).joined(separator: " ")
                }
            } else {
                command = ""
            }
        }

        errorMessage = nil
    }

    // MARK: - Reset

    func reset() {
        name = ""
        transportMode = .remote
        url = ""
        command = ""
        isSubmitting = false
        errorMessage = nil
    }

    // MARK: - Private

    private func parseCommand(_ input: String) -> (command: String, args: [String]) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let tokens = trimmed.split(separator: " ").map(String.init)
        guard let first = tokens.first else { return ("", []) }
        return (first, Array(tokens.dropFirst()))
    }
}

// MARK: - AddMCPServerSheet

struct AddMCPServerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let store: MCPServerConfigStore
    let scope: MCPServerScope
    let workspacePath: String?
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
        .frame(minWidth: 460, minHeight: 320)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("添加 MCP Server")
                    .font(.headline)
                Text("配置一个新的 MCP Server 连接")
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

            Button("添加") {
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
            let config = try viewModel.submit(
                store: store,
                scope: scope,
                workspacePath: workspacePath
            )
            onSave(config)
            viewModel.isSubmitting = false
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
