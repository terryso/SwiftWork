import Foundation
import SwiftData
import OpenAgentSDK

enum MCPServerConfigError: LocalizedError {
    case duplicateName(String)

    var errorDescription: String? {
        switch self {
        case .duplicateName(let name):
            return "MCP server configuration with name '\(name)' already exists"
        }
    }
}

@MainActor
final class MCPServerConfigStore {
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Compatibility initializer for callers that used to inject credential
    /// storage. MCP headers and environment values now persist in SwiftData.
    init(modelContext: ModelContext, keychainManager _: KeychainManaging) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD

    @discardableResult
    func add(
        name: String,
        transportType: TransportType,
        command: String?,
        url: String?,
        args: Data?,
        env: Data?,
        headers: Data?,
        enabled: Bool,
        scope: MCPServerScope,
        workspacePath: String?
    ) throws -> MCPServerConfig {
        let existing = try list()
        if existing.contains(where: { $0.name == name }) {
            throw MCPServerConfigError.duplicateName(name)
        }

        let config = MCPServerConfig(
            name: name,
            transportType: transportType,
            command: command,
            url: url,
            args: args,
            env: env,
            headers: headers,
            enabled: enabled,
            scope: scope,
            workspacePath: workspacePath
        )
        modelContext.insert(config)
        try modelContext.save()
        return config
    }

    @discardableResult
    func update(
        _ config: MCPServerConfig,
        name: String? = nil,
        transportType: TransportType? = nil,
        command: String? = nil,
        url: String? = nil,
        args: Data? = nil,
        env: Data? = nil,
        headers: Data? = nil,
        enabled: Bool? = nil,
        scope: MCPServerScope? = nil,
        workspacePath: String? = nil
    ) throws -> MCPServerConfig {
        if let name { config.name = name }
        if let transportType { config.transportType = transportType }
        if command != nil { config.command = command }
        if url != nil { config.url = url }
        if args != nil { config.args = args }
        if env != nil { config.env = env }
        if headers != nil { config.headers = headers }
        if let enabled { config.enabled = enabled }
        if let scope { config.scope = scope }
        if workspacePath != nil { config.workspacePath = workspacePath }
        config.updatedAt = Date.now
        try modelContext.save()
        return config
    }

    /// Full replacement — sets ALL fields unconditionally.
    /// Use from edit modals where the caller has all field values.
    @discardableResult
    func replace(
        _ config: MCPServerConfig,
        name: String,
        transportType: TransportType,
        command: String?,
        url: String?,
        args: Data?,
        env: Data?,
        headers: Data?,
        enabled: Bool,
        scope: MCPServerScope,
        workspacePath: String?
    ) throws -> MCPServerConfig {
        if config.name != name {
            let existing = try list()
            if existing.contains(where: { $0.name == name }) {
                throw MCPServerConfigError.duplicateName(name)
            }
        }

        config.name = name
        config.transportType = transportType
        config.command = command
        config.url = url
        config.args = args
        config.env = env
        config.headers = headers
        config.enabled = enabled
        config.scope = scope
        config.workspacePath = workspacePath
        config.updatedAt = Date.now
        try modelContext.save()
        return config
    }

    func delete(_ config: MCPServerConfig) throws {
        modelContext.delete(config)
        try modelContext.save()
    }

    func list() throws -> [MCPServerConfig] {
        let descriptor = FetchDescriptor<MCPServerConfig>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    func list(scope: MCPServerScope) throws -> [MCPServerConfig] {
        try list().filter { $0.scope == scope }
    }

    // MARK: - Scope Filtering

    func enabledConfigsForWorkspace(_ workspacePath: String?) throws -> [MCPServerConfig] {
        try list().filter { config in
            guard config.enabled else { return false }
            switch config.scope {
            case .global:
                return true
            case .project:
                return config.workspacePath == workspacePath
            }
        }
    }

    // MARK: - SDK Conversion

    func toSDKConfigs(_ configs: [MCPServerConfig]) -> [String: McpServerConfig] {
        Dictionary(uniqueKeysWithValues: configs.compactMap { config -> (String, McpServerConfig)? in
            toSDKConfig(config)
        })
    }

    private func toSDKConfig(_ config: MCPServerConfig) -> (String, McpServerConfig)? {
        switch config.transportType {
        case .stdio:
            guard let command = config.command, !command.isEmpty else { return nil }
            return (
                config.name,
                .stdio(McpStdioConfig(
                    command: command,
                    args: config.decodedArgs,
                    env: config.decodedEnv
                ))
            )

        case .sse:
            guard let url = config.url, !url.isEmpty else { return nil }
            return (config.name, .sse(McpTransportConfig(url: url, headers: config.decodedHeaders)))

        case .http:
            guard let url = config.url, !url.isEmpty else { return nil }
            return (config.name, .http(McpTransportConfig(url: url, headers: config.decodedHeaders)))
        }
    }
}
