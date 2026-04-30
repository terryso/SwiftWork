import Foundation
import SwiftData

@MainActor
@Observable
final class SettingsViewModel {
    var apiKey = ""
    var selectedModel: String = Constants.defaultModel
    var isAPIKeyConfigured = false
    var isFirstLaunch = true
    var errorMessage: String?

    var isValidAPIKey: Bool {
        !apiKey.isEmpty && apiKey.hasPrefix("sk-")
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
            isAPIKeyConfigured = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
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
