import Foundation

enum Constants {
    static let appName = "SwiftWork"
    static let defaultModel = "claude-sonnet-4-6"

    static let availableModels = [
        "claude-sonnet-4-6",
        "claude-opus-4-7",
        "claude-haiku-3-5"
    ]
}

enum KeychainConstants {
    static let service = "com.swiftwork.apikeys"
    static let apiKeyAccount = "anthropic-api-key"
}
