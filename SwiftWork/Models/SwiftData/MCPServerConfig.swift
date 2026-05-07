import Foundation
import SwiftData

enum TransportType: String, Codable, Sendable {
    case stdio
    case sse
    case http
}

enum MCPServerScope: String, Codable, Sendable {
    case project
    case global
}

@Model
final class MCPServerConfig {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var name: String
    var transportType: TransportType
    var command: String?
    var url: String?
    var args: Data?
    var env: Data?
    var headers: Data?
    var enabled: Bool
    var scope: MCPServerScope
    var workspacePath: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        name: String,
        transportType: TransportType,
        command: String? = nil,
        url: String? = nil,
        args: Data? = nil,
        env: Data? = nil,
        headers: Data? = nil,
        enabled: Bool = true,
        scope: MCPServerScope = .global,
        workspacePath: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.transportType = transportType
        self.command = command
        self.url = url
        self.args = args
        self.env = env
        self.headers = headers
        self.enabled = enabled
        self.scope = scope
        self.workspacePath = workspacePath
        self.createdAt = Date.now
        self.updatedAt = Date.now
    }

    var decodedArgs: [String]? {
        args.flatMap { try? JSONDecoder().decode([String].self, from: $0) }
    }

    var decodedEnv: [String: String]? {
        env.flatMap { try? JSONDecoder().decode([String: String].self, from: $0) }
    }

    var decodedHeaders: [String: String]? {
        headers.flatMap { try? JSONDecoder().decode([String: String].self, from: $0) }
    }
}
