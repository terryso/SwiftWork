import Foundation

enum Constants {
    static let appName = "SwiftWork"
    static let defaultModel = "claude-sonnet-4-6"
    static let defaultBaseURL = "https://api.anthropic.com"

    static let availableModels = [
        "claude-sonnet-4-6",
        "claude-opus-4-7",
        "claude-haiku-3-5"
    ]
}

enum KeychainConstants {
    static let service = "com.swiftwork.apikeys"
    static let apiKeyAccount = "anthropic-api-key"
    static let baseURLAccount = "anthropic-base-url"
}

enum AppStateKeys {
    static let lastActiveSessionID = "appState.lastActiveSessionID"
    static let windowFrame = "appState.windowFrame"
    static let inspectorVisible = "appState.inspectorVisible"
}
