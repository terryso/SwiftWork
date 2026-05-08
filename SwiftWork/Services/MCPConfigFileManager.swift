import Foundation
import AppKit

@MainActor
final class MCPConfigFileManager {

    // MARK: - File System Watching

    private var fileSource: AnyObject?
    private var watchedFileDescriptor: Int32 = -1

    // MARK: - Path Resolution (AC#2)

    func configFilePath(scope: MCPServerScope, workspacePath: String?) -> String? {
        switch scope {
        case .global:
            return FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".claude/settings.json").path
        case .project:
            guard let workspacePath, !workspacePath.isEmpty else { return nil }
            return workspacePath + "/.claude/settings.json"
        }
    }

    // MARK: - File Existence Check (AC#3)

    var revealFileHandler: (String) -> Void = { path in
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }

    func configFileExists(atPath path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    // MARK: - Read Config File (AC#2)

    func readConfigFile(atPath path: String) -> Data? {
        try? Data(contentsOf: URL(fileURLWithPath: path))
    }

    // MARK: - Reveal in Finder (AC#3)

    func revealInFinder(path: String) {
        revealFileHandler(path)
    }

    // MARK: - Parse JSON Config (AC#4)

    func loadMCPConfigsFromFile(atPath path: String) -> [MCPServerConfig] {
        guard let data = readConfigFile(atPath: path) else { return [] }
        return parseConfigData(data)
    }

    private func parseConfigData(_ data: Data) -> [MCPServerConfig] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let mcpServers = json["mcpServers"] as? [String: [String: Any]] else {
            return []
        }

        return mcpServers.compactMap { name, serverDict -> MCPServerConfig? in
            parseServerEntry(name: name, dict: serverDict)
        }
    }

    private func parseServerEntry(name: String, dict: [String: Any]) -> MCPServerConfig? {
        // Determine transport type
        let transportType: TransportType
        if let typeString = dict["type"] as? String {
            switch typeString {
            case "stdio": transportType = .stdio
            case "sse": transportType = .sse
            case "http": transportType = .http
            default:
                // Fallback: infer from available fields
                if dict["command"] != nil {
                    transportType = .stdio
                } else if dict["url"] != nil {
                    transportType = .sse
                } else {
                    return nil
                }
            }
        } else {
            // No explicit type — infer from fields
            if dict["command"] != nil {
                transportType = .stdio
            } else if dict["url"] != nil {
                transportType = .sse
            } else {
                return nil
            }
        }

        // Extract command
        let command = dict["command"] as? String

        // Extract url
        let url = dict["url"] as? String

        // Extract args
        let argsData: Data? = {
            if let args = dict["args"] as? [String] {
                return try? JSONEncoder().encode(args)
            }
            return nil
        }()

        // Extract env
        let envData: Data? = {
            if let env = dict["env"] as? [String: String], !env.isEmpty {
                return try? JSONEncoder().encode(env)
            }
            return nil
        }()

        // Extract headers
        let headersData: Data? = {
            if let headers = dict["headers"] as? [String: String], !headers.isEmpty {
                return try? JSONEncoder().encode(headers)
            }
            return nil
        }()

        // Extract enabled (default true)
        let enabled = dict["enabled"] as? Bool ?? true

        return MCPServerConfig(
            name: name,
            transportType: transportType,
            command: command,
            url: url,
            args: argsData,
            env: envData,
            headers: headersData,
            enabled: enabled,
            scope: .global,
            workspacePath: nil
        )
    }

    // MARK: - Import from File (AC#4)

    func importFromFile(
        atPath path: String,
        scope: MCPServerScope,
        workspacePath: String?,
        store: MCPServerConfigStore
    ) throws {
        let fileConfigs = loadMCPConfigsFromFile(atPath: path)
        let existingConfigs = try store.list()

        for fileConfig in fileConfigs {
            if let existing = existingConfigs.first(where: { $0.name == fileConfig.name }) {
                // Update existing config (dedup: overwrite by name)
                _ = try store.replace(
                    existing,
                    name: fileConfig.name,
                    transportType: fileConfig.transportType,
                    command: fileConfig.command,
                    url: fileConfig.url,
                    args: fileConfig.args,
                    env: fileConfig.env,
                    headers: fileConfig.headers,
                    enabled: fileConfig.enabled,
                    scope: scope,
                    workspacePath: workspacePath
                )
            } else {
                // Add new config
                _ = try store.add(
                    name: fileConfig.name,
                    transportType: fileConfig.transportType,
                    command: fileConfig.command,
                    url: fileConfig.url,
                    args: fileConfig.args,
                    env: fileConfig.env,
                    headers: fileConfig.headers,
                    enabled: fileConfig.enabled,
                    scope: scope,
                    workspacePath: workspacePath
                )
            }
        }
    }

    // MARK: - File System Watching (AC#4)

    func startWatching(path: String, onChange: @escaping () -> Void) {
        stopWatching()

        let descriptor = open(path, O_EVTONLY)
        guard descriptor >= 0 else { return }
        watchedFileDescriptor = descriptor

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .delete, .rename, .attrib],
            queue: DispatchQueue.main
        )

        source.setEventHandler {
            onChange()
        }

        source.setCancelHandler { [descriptor] in
            close(descriptor)
        }

        source.resume()
        fileSource = source
    }

    func stopWatching() {
        if let source = fileSource as? DispatchSource {
            source.cancel()
        }
        fileSource = nil
        watchedFileDescriptor = -1
    }
}
