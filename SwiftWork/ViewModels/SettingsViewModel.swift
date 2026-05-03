import Foundation
import SwiftData

@MainActor
@Observable
final class SettingsViewModel {
    var apiKey = ""
    var baseURL = ""
    var selectedModel: String = Constants.defaultModel
    var isAPIKeyConfigured = false
    var isFirstLaunch = true
    var errorMessage: String?

    var isValidAPIKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var availableModels: [String] {
        Constants.availableModels
    }

    private let keychainManager: KeychainManaging
    private var modelContext: ModelContext?

    init(keychainManager: KeychainManaging = KeychainManager()) {
        self.keychainManager = keychainManager
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        checkExistingConfig()
    }

    func checkExistingConfig() {
        // 1. Check if API Key exists in Keychain
        do {
            if let _ = try keychainManager.load(key: KeychainConstants.apiKeyAccount) {
                isAPIKeyConfigured = true
            }
        } catch {
            isAPIKeyConfigured = false
        }

        // Load saved base URL
        do {
            if let data = try keychainManager.load(key: KeychainConstants.baseURLAccount),
               let saved = String(data: data, encoding: .utf8) {
                baseURL = saved
            }
        } catch {
            // Ignore — baseURL is optional
        }

        // 2. Check for saved model preference
        if let context = modelContext {
            let modelDescriptor = FetchDescriptor<AppConfiguration>(
                predicate: #Predicate { $0.key == "selectedModel" }
            )
            if let modelConfig = try? context.fetch(modelDescriptor).first,
               let savedModel = String(data: modelConfig.value, encoding: .utf8) {
                selectedModel = savedModel
            }

            // 3. Check hasCompletedOnboarding flag
            let onboardingDescriptor = FetchDescriptor<AppConfiguration>(
                predicate: #Predicate { $0.key == "hasCompletedOnboarding" }
            )
            if let _ = try? context.fetch(onboardingDescriptor).first {
                isFirstLaunch = false
            }
        }

        // Defensive: if API key exists but no onboarding flag, treat as not-first-launch
        if isAPIKeyConfigured {
            isFirstLaunch = false
        }
    }

    func saveAPIKey() throws {
        guard modelContext != nil else {
            throw AppError(
                domain: .ui,
                code: "SETTINGS_NOT_CONFIGURED",
                message: "Settings not configured. Please restart the app."
            )
        }

        do {
            try keychainManager.saveAPIKey(apiKey)

            // Save base URL (only if non-empty)
            if !baseURL.isEmpty {
                try keychainManager.save(key: KeychainConstants.baseURLAccount, data: Data(baseURL.utf8))
            } else {
                try? keychainManager.delete(key: KeychainConstants.baseURLAccount)
            }

            isAPIKeyConfigured = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Story 4.2: Settings Page Methods

    /// Updates the API Key in Keychain. Validates the new key is non-empty.
    func updateAPIKey(_ newKey: String) throws {
        let trimmed = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AppError(
                domain: .ui,
                code: "EMPTY_API_KEY",
                message: "API Key cannot be empty"
            )
        }

        do {
            try keychainManager.saveAPIKey(trimmed)
            isAPIKeyConfigured = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Updates the Base URL and persists to Keychain.
    func updateBaseURL(_ url: String) {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        var normalized = trimmed
        if normalized.hasSuffix("/") {
            normalized.removeLast()
        }
        baseURL = normalized

        if !normalized.isEmpty {
            try? keychainManager.save(key: KeychainConstants.baseURLAccount, data: Data(normalized.utf8))
        } else {
            try? keychainManager.delete(key: KeychainConstants.baseURLAccount)
        }
    }

    /// Updates the selected model and persists to AppConfiguration.
    func updateModel(_ model: String) throws {
        guard let context = modelContext else {
            throw AppError(
                domain: .ui,
                code: "SETTINGS_NOT_CONFIGURED",
                message: "Settings not configured. Please restart the app."
            )
        }

        selectedModel = model

        let descriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate { $0.key == "selectedModel" }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.value = Data(model.utf8)
            existing.updatedAt = .now
        } else {
            let config = AppConfiguration(key: "selectedModel", value: Data(model.utf8))
            context.insert(config)
        }

        try context.save()
    }

    /// Refreshes all configuration state from Keychain and AppConfiguration.
    func loadCurrentConfig() {
        checkExistingConfig()
    }

    /// Returns a masked version of the current API Key for display.
    /// Format: first 8 chars + "****" + last 4 chars for long keys.
    /// For short keys (< 12 chars): first 4 chars + "****".
    var maskedAPIKey: String {
        guard let keyData = try? keychainManager.load(key: KeychainConstants.apiKeyAccount),
              let fullKey = String(data: keyData, encoding: .utf8),
              !fullKey.isEmpty else {
            return ""
        }

        if fullKey.count < 12 {
            let prefix = String(fullKey.prefix(4))
            return "\(prefix)****"
        }

        let prefix = String(fullKey.prefix(8))
        let suffix = String(fullKey.suffix(4))
        return "\(prefix)****\(suffix)"
    }

    func completeSetup() {
        guard let context = modelContext else { return }

        // Save hasCompletedOnboarding flag
        let descriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate { $0.key == "hasCompletedOnboarding" }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.value = Data([1])
            existing.updatedAt = .now
        } else {
            let config = AppConfiguration(key: "hasCompletedOnboarding", value: Data([1]))
            context.insert(config)
        }

        // Save selected model
        let modelDescriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate { $0.key == "selectedModel" }
        )
        if let existing = try? context.fetch(modelDescriptor).first {
            existing.value = Data(selectedModel.utf8)
            existing.updatedAt = .now
        } else {
            let config = AppConfiguration(key: "selectedModel", value: Data(selectedModel.utf8))
            context.insert(config)
        }

        try? context.save()

        isFirstLaunch = false
    }
}
