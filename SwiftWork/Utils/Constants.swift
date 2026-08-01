import Foundation

enum Constants {
    static let appName = "SwiftWork"
    static let defaultModel = "claude-sonnet-4-6"
    static let defaultBaseURL = "https://api.anthropic.com"
}

enum AppConfigurationKeys {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let selectedModel = "selectedModel"
    static let selectedProvider = "selectedProvider"
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
    static let debugPanelVisible = "appState.debugPanelVisible"
}
