import Foundation
import SwiftData

@MainActor
@Observable
final class SettingsViewModel {
    var apiKey = ""
    var baseURL = ""
    var selectedProvider: AgentProvider = .anthropic
    var selectedModel = ""
    var availableModels: [String] = []
    var isLoadingModels = false
    var modelLoadErrorMessage: String?
    var isAPIKeyConfigured = false
    var isFirstLaunch = true
    var errorMessage: String?
    private(set) var configurationRevision = 0

    var isValidAPIKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasValidModelSelection: Bool {
        !selectedModel.isEmpty && availableModels.contains(selectedModel)
    }

    private let keychainManager: KeychainManaging
    private let modelDiscoveryService: any ModelDiscovering
    private var modelContext: ModelContext?
    private var activeModelRefreshID: UUID?
    private var modelRefreshTask: Task<[String], Error>?

    init(
        keychainManager: KeychainManaging = KeychainManager(),
        modelDiscoveryService: any ModelDiscovering = ModelDiscoveryService()
    ) {
        self.keychainManager = keychainManager
        self.modelDiscoveryService = modelDiscoveryService
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        checkExistingConfig()
    }

    func checkExistingConfig() {
        cancelModelRefresh()
        let previousBaseURL = baseURL
        let previousProvider = selectedProvider
        let previousModel = selectedModel
        let previousConfiguredState = isAPIKeyConfigured

        isAPIKeyConfigured = false
        isFirstLaunch = true
        selectedProvider = .anthropic
        selectedModel = ""
        availableModels = []
        modelLoadErrorMessage = nil

        do {
            if try keychainManager.load(key: KeychainConstants.apiKeyAccount) != nil {
                isAPIKeyConfigured = true
            }
        } catch {
            isAPIKeyConfigured = false
        }

        do {
            if let data = try keychainManager.load(key: KeychainConstants.baseURLAccount),
               let saved = String(data: data, encoding: .utf8) {
                baseURL = saved
            } else {
                baseURL = ""
            }
        } catch {
            baseURL = ""
        }

        var hasInvalidProviderConfiguration = false
        if let context = modelContext {
            if let savedProvider = configurationValue(
                forKey: AppConfigurationKeys.selectedProvider,
                in: context
            ) {
                if let provider = AgentProvider(rawValue: savedProvider) {
                    selectedProvider = provider
                } else {
                    hasInvalidProviderConfiguration = true
                    modelLoadErrorMessage = "已保存的 Provider 配置无法识别，请重新选择协议并获取模型"
                }
            }

            if !hasInvalidProviderConfiguration,
               let savedModel = configurationValue(
                forKey: AppConfigurationKeys.selectedModel,
                in: context
            ), !savedModel.isEmpty {
                selectedModel = savedModel
                availableModels = [savedModel]
            }

            if configurationExists(forKey: AppConfigurationKeys.hasCompletedOnboarding, in: context) {
                isFirstLaunch = false
            }
        }

        if isAPIKeyConfigured {
            isFirstLaunch = false
            if selectedModel.isEmpty,
               selectedProvider == .anthropic,
               !hasInvalidProviderConfiguration {
                selectedModel = Constants.defaultModel
            }
        }

        if previousBaseURL != baseURL
            || previousProvider != selectedProvider
            || previousModel != selectedModel
            || previousConfiguredState != isAPIKeyConfigured {
            markAgentConfigurationChanged()
        }
    }

    func saveAPIKey() throws {
        guard modelContext != nil else {
            throw settingsNotConfiguredError()
        }

        do {
            let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            try keychainManager.saveAPIKey(trimmedKey)
            try updateBaseURL(baseURL)
            isAPIKeyConfigured = true
            errorMessage = nil
            markAgentConfigurationChanged()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

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
            markAgentConfigurationChanged()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func updateBaseURL(_ url: String) throws {
        let normalized = normalizedBaseURL(url)

        do {
            if normalized.isEmpty {
                try keychainManager.delete(key: KeychainConstants.baseURLAccount)
            } else {
                try keychainManager.save(
                    key: KeychainConstants.baseURLAccount,
                    data: Data(normalized.utf8)
                )
            }

            let changed = baseURL != normalized
            baseURL = normalized
            if changed {
                markAgentConfigurationChanged()
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func updateProvider(_ provider: AgentProvider) throws {
        guard let context = modelContext else {
            throw settingsNotConfiguredError()
        }

        let changed = selectedProvider != provider
        selectedProvider = provider
        upsertConfiguration(
            key: AppConfigurationKeys.selectedProvider,
            value: provider.rawValue,
            in: context
        )

        if changed {
            cancelModelRefresh()
            invalidateModelSelection(in: context)
            markAgentConfigurationChanged()
        }

        try context.save()
    }

    func updateModel(_ model: String) throws {
        guard availableModels.contains(model) else {
            throw AppError(
                domain: .ui,
                code: "MODEL_NOT_AVAILABLE",
                message: "所选模型不在当前 Provider 返回的模型列表中"
            )
        }
        try persistSelectedModel(model)
    }

    @discardableResult
    func refreshModels(
        apiKey explicitAPIKey: String? = nil,
        baseURL explicitBaseURL: String? = nil,
        clearExisting: Bool = false
    ) async -> Bool {
        modelRefreshTask?.cancel()
        let refreshID = UUID()
        activeModelRefreshID = refreshID
        isLoadingModels = true
        modelLoadErrorMessage = nil

        if clearExisting {
            let hadSelectedModel = !selectedModel.isEmpty
            if let context = modelContext {
                invalidateModelSelection(in: context)
                try? context.save()
            } else {
                selectedModel = ""
                availableModels = []
            }
            if hadSelectedModel {
                markAgentConfigurationChanged()
            }
        }

        defer {
            if activeModelRefreshID == refreshID {
                isLoadingModels = false
                activeModelRefreshID = nil
                modelRefreshTask = nil
            }
        }

        do {
            let key = try resolvedAPIKey(explicitAPIKey)
            let requestedBaseURL = explicitBaseURL ?? baseURL
            let requestedProvider = selectedProvider
            let service = modelDiscoveryService
            let refreshTask = Task {
                try await service.fetchModels(
                    provider: requestedProvider,
                    apiKey: key,
                    baseURL: requestedBaseURL.isEmpty ? nil : requestedBaseURL
                )
            }
            modelRefreshTask = refreshTask

            let models = try await withTaskCancellationHandler {
                try await refreshTask.value
            } onCancel: {
                refreshTask.cancel()
            }

            guard activeModelRefreshID == refreshID,
                  selectedProvider == requestedProvider else { return false }
            guard !models.isEmpty else {
                throw AppError(
                    domain: .network,
                    code: "MODEL_DISCOVERY_EMPTY",
                    message: "模型服务没有返回可用模型"
                )
            }

            if models.contains(selectedModel), !selectedModel.isEmpty {
                try persistSelectedModel(selectedModel)
            } else {
                let hadSelectedModel = !selectedModel.isEmpty
                if let context = modelContext {
                    invalidateModelSelection(in: context)
                } else {
                    selectedModel = ""
                }
                if hadSelectedModel {
                    markAgentConfigurationChanged()
                }
            }

            if let context = modelContext {
                upsertConfiguration(
                    key: AppConfigurationKeys.selectedProvider,
                    value: requestedProvider.rawValue,
                    in: context
                )
                try context.save()
            }
            availableModels = models
            modelLoadErrorMessage = nil
            return true
        } catch is CancellationError {
            return false
        } catch {
            guard activeModelRefreshID == refreshID else { return false }
            modelLoadErrorMessage = error.localizedDescription
            return false
        }
    }

    func cancelModelRefresh() {
        modelRefreshTask?.cancel()
        modelRefreshTask = nil
        activeModelRefreshID = nil
        isLoadingModels = false
    }

    func invalidateModels() {
        cancelModelRefresh()
        let hadSelectedModel = !selectedModel.isEmpty
        if let context = modelContext {
            invalidateModelSelection(in: context)
            try? context.save()
        } else {
            selectedModel = ""
            availableModels = []
        }
        if hadSelectedModel {
            markAgentConfigurationChanged()
        }
        modelLoadErrorMessage = nil
    }

    func loadCurrentConfig() {
        checkExistingConfig()
    }

    var maskedAPIKey: String {
        guard let keyData = try? keychainManager.load(key: KeychainConstants.apiKeyAccount),
              let fullKey = String(data: keyData, encoding: .utf8),
              !fullKey.isEmpty else {
            return ""
        }

        if fullKey.count < 12 {
            return "\(String(fullKey.prefix(4)))****"
        }

        return "\(String(fullKey.prefix(8)))****\(String(fullKey.suffix(4)))"
    }

    func completeSetup() {
        guard let context = modelContext, hasValidModelSelection else { return }

        upsertConfiguration(
            key: AppConfigurationKeys.hasCompletedOnboarding,
            data: Data([1]),
            in: context
        )
        upsertConfiguration(
            key: AppConfigurationKeys.selectedProvider,
            value: selectedProvider.rawValue,
            in: context
        )
        upsertConfiguration(
            key: AppConfigurationKeys.selectedModel,
            value: selectedModel,
            in: context
        )

        do {
            try context.save()
            isFirstLaunch = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resolvedAPIKey(_ explicitAPIKey: String?) throws -> String {
        let explicit = explicitAPIKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !explicit.isEmpty {
            return explicit
        }

        let saved = try keychainManager.getAPIKey()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !saved.isEmpty else {
            throw AppError(
                domain: .security,
                code: "MODEL_DISCOVERY_MISSING_API_KEY",
                message: "请先配置 API Key"
            )
        }
        return saved
    }

    private func persistSelectedModel(_ model: String) throws {
        guard let context = modelContext else {
            throw settingsNotConfiguredError()
        }

        let changed = selectedModel != model
        upsertConfiguration(
            key: AppConfigurationKeys.selectedModel,
            value: model,
            in: context
        )
        try context.save()
        selectedModel = model
        if changed {
            markAgentConfigurationChanged()
        }
    }

    private func invalidateModelSelection(in context: ModelContext) {
        selectedModel = ""
        availableModels = []

        let selectedModelKey = AppConfigurationKeys.selectedModel
        let descriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate { $0.key == selectedModelKey }
        )
        if let existing = try? context.fetch(descriptor).first {
            context.delete(existing)
        }
    }

    private func configurationValue(forKey key: String, in context: ModelContext) -> String? {
        let descriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate { $0.key == key }
        )
        guard let data = try? context.fetch(descriptor).first?.value else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func configurationExists(forKey key: String, in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate { $0.key == key }
        )
        return (try? context.fetch(descriptor).first) != nil
    }

    private func upsertConfiguration(
        key: String,
        value: String,
        in context: ModelContext
    ) {
        upsertConfiguration(key: key, data: Data(value.utf8), in: context)
    }

    private func upsertConfiguration(
        key: String,
        data: Data,
        in context: ModelContext
    ) {
        let descriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate { $0.key == key }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.value = data
            existing.updatedAt = .now
        } else {
            context.insert(AppConfiguration(key: key, value: data))
        }
    }

    private func normalizedBaseURL(_ url: String) -> String {
        url.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private func markAgentConfigurationChanged() {
        configurationRevision &+= 1
    }

    private func settingsNotConfiguredError() -> AppError {
        AppError(
            domain: .ui,
            code: "SETTINGS_NOT_CONFIGURED",
            message: "Settings not configured. Please restart the app."
        )
    }
}
