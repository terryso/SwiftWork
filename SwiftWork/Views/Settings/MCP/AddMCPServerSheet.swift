import SwiftUI
import SwiftData

// MARK: - JSON Input Format Detection

enum MCPJSONInputFormat {
    /// `{"mcpServers": {"name": {...}}}`
    case mcpServers
    /// `{"name": {"command": "..."}, ...}`
    case serverMap
    /// `{"command": "...", "args": [...]}` (bare single-server config)
    case bareConfig
    /// Cannot parse / unrecognized
    case invalid
}

// MARK: - ViewModel

@MainActor
@Observable
final class AddMCPServerViewModel {

    // MARK: - Form State

    var jsonText = ""
    var serverName = ""
    var isSubmitting = false
    var errorMessage: String?

    // MARK: - Format Detection

    var detectedFormat: MCPJSONInputFormat {
        detectFormat(jsonText)
    }

    var showsNameField: Bool {
        detectedFormat == .bareConfig
    }

    // MARK: - Validation

    var isValid: Bool {
        let format = detectedFormat
        guard format != .invalid else { return false }
        if format == .bareConfig {
            return !serverName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }

    @discardableResult
    func validate() -> Bool {
        let format = detectedFormat
        if format == .invalid {
            errorMessage = "无法解析 JSON，请检查格式"
            return false
        }
        if format == .bareConfig {
            let trimmedName = serverName.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedName.isEmpty {
                errorMessage = "Server 名称不能为空"
                return false
            }
        }

        // Try parsing to validate structure
        do {
            let configs = try parseConfigs()
            if configs.isEmpty {
                errorMessage = "未找到有效的 MCP Server 配置"
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }

        errorMessage = nil
        return true
    }

    // MARK: - Submit (Add)

    func submit(
        store: MCPServerConfigStore,
        scope: MCPServerScope,
        workspacePath: String?
    ) throws -> [MCPServerConfig] {
        let configs = try parseConfigs()
        var results: [MCPServerConfig] = []

        for (name, config) in configs {
            let added = try store.add(
                name: name,
                transportType: config.transportType,
                command: config.command,
                url: config.url,
                args: config.args,
                env: config.env,
                headers: config.headers,
                enabled: true,
                scope: scope,
                workspacePath: workspacePath
            )
            results.append(added)
        }
        return results
    }

    // MARK: - Submit (Edit)

    func submitEdit(
        originalConfig: MCPServerConfig,
        store: MCPServerConfigStore,
        scope: MCPServerScope,
        workspacePath: String?
    ) throws -> MCPServerConfig {
        let configs = try parseConfigs()
        guard let first = configs.first else {
            throw ParseError.invalidJSON
        }
        let (_, config) = first
        return try store.replace(
            originalConfig,
            name: config.name,
            transportType: config.transportType,
            command: config.command,
            url: config.url,
            args: config.args,
            env: config.env,
            headers: config.headers,
            enabled: originalConfig.enabled,
            scope: scope,
            workspacePath: workspacePath
        )
    }

    // MARK: - Populate from Existing Config (Edit Mode)

    func populateFromConfig(_ config: MCPServerConfig) {
        var dict: [String: Any] = [:]
        if let command = config.command {
            dict["command"] = command
        }
        if let url = config.url {
            dict["url"] = url
        }
        if let args = config.decodedArgs, !args.isEmpty {
            dict["args"] = args
        }
        if let env = config.decodedEnv, !env.isEmpty {
            dict["env"] = env
        }
        if let headers = config.decodedHeaders, !headers.isEmpty {
            dict["headers"] = headers
        }

        let wrapper: [String: Any] = [config.name: dict]
        if let data = try? JSONSerialization.data(
            withJSONObject: wrapper,
            options: [.prettyPrinted, .sortedKeys]
        ) {
            jsonText = String(data: data, encoding: .utf8) ?? ""
        }

        serverName = config.name
        errorMessage = nil
    }

    // MARK: - Reset

    func reset() {
        jsonText = ""
        serverName = ""
        isSubmitting = false
        errorMessage = nil
    }

    // MARK: - Private — Format Detection

    private func detectFormat(_ text: String) -> MCPJSONInputFormat {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let data = trimmed.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .invalid
        }

        // Format 1: {"mcpServers": {...}}
        if let mcpServers = json["mcpServers"] as? [String: [String: Any]] {
            return .mcpServers
        }

        // Format 3: bare config — has command or url at top level
        if json["command"] != nil || json["url"] != nil {
            return .bareConfig
        }

        // Format 2: {"name": {"command": "..."}, ...} — all values are dicts with command/url
        let serverEntries = json.values.compactMap { $0 as? [String: Any] }
        if !serverEntries.isEmpty && serverEntries.allSatisfy({ entry in
            entry["command"] != nil || entry["url"] != nil
        }) {
            return .serverMap
        }

        return .invalid
    }

    // MARK: - Private — JSON Parsing

    private enum ParseError: LocalizedError {
        case invalidJSON
        case missingName

        var errorDescription: String? {
            switch self {
            case .invalidJSON: "无法解析 JSON，请检查格式"
            case .missingName: "Server 名称不能为空"
            }
        }
    }

    private func parseConfigs() throws -> [(name: String, config: MCPServerConfig)] {
        let trimmed = jsonText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ParseError.invalidJSON
        }

        var serverDicts: [(name: String, dict: [String: Any])] = []

        switch detectedFormat {
        case .mcpServers:
            guard let inner = json["mcpServers"] as? [String: [String: Any]] else {
                throw ParseError.invalidJSON
            }
            serverDicts = inner.map { ($0.key, $0.value) }

        case .serverMap:
            let entries = json.compactMap { (key, value) -> (String, [String: Any])? in
                guard let dict = value as? [String: Any] else { return nil }
                return (key, dict)
            }
            serverDicts = entries

        case .bareConfig:
            let name = serverName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else {
                throw ParseError.missingName
            }
            serverDicts = [(name, json)]

        case .invalid:
            throw ParseError.invalidJSON
        }

        var results: [(name: String, config: MCPServerConfig)] = []
        for (name, dict) in serverDicts {
            guard let config = MCPConfigFileManager.parseServerEntry(name: name, dict: dict) else {
                continue
            }
            results.append((name, config))
        }
        return results
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
        .frame(minWidth: 480, minHeight: 360)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("添加 MCP Server")
                    .font(.headline)
                Text("粘贴 JSON 配置来添加 MCP Server")
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
            let configs = try viewModel.submit(
                store: store,
                scope: scope,
                workspacePath: workspacePath
            )
            for config in configs {
                onSave(config)
            }
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
