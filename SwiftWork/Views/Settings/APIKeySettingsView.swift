import SwiftUI

struct APIKeySettingsView: View {
    @Bindable var settingsViewModel: SettingsViewModel
    @State private var showAPIKey = false
    @State private var newAPIKey = ""
    @State private var newBaseURL = ""
    @State private var newProvider: AgentProvider = .anthropic

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            statusSection
            Divider()
            providerSection
            Divider()
            apiKeyInputSection
            Divider()
            baseURLInputSection
            Divider()
            saveButton
        }
        .onAppear {
            newBaseURL = settingsViewModel.baseURL
            newProvider = settingsViewModel.selectedProvider
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Provider 配置")
                .font(.headline)

            HStack(spacing: 8) {
                Image(systemName: settingsViewModel.isAPIKeyConfigured ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(settingsViewModel.isAPIKeyConfigured ? .green : .red)
                Text(settingsViewModel.isAPIKeyConfigured ? "API Key 已配置" : "API Key 未配置")
            }

            if settingsViewModel.isAPIKeyConfigured {
                Text(settingsViewModel.maskedAPIKey)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var providerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("API 协议")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("API 协议", selection: $newProvider) {
                ForEach(AgentProvider.allCases) { provider in
                    Text(provider.displayName).tag(provider)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var apiKeyInputSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("更新 API Key")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Group {
                    if showAPIKey {
                        TextField("API Key", text: $newAPIKey)
                    } else {
                        SecureField("API Key", text: $newAPIKey)
                    }
                }
                .textFieldStyle(.roundedBorder)

                Button(action: { showAPIKey.toggle() }) {
                    Image(systemName: showAPIKey ? "eye.slash" : "eye")
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private var baseURLInputSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Base URL")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField(newProvider.defaultBaseURL, text: $newBaseURL)
                .textFieldStyle(.roundedBorder)

            Text(newProvider == .openAI
                 ? "OpenAI-compatible 地址通常包含版本路径，例如 /v1"
                 : "Anthropic 地址不包含 /v1")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var saveButton: some View {
        HStack {
            Spacer()

            if let error = settingsViewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            Button("保存并获取模型") {
                Task { await performSave() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!hasChanges || settingsViewModel.isLoadingModels)
        }
    }

    private var hasChanges: Bool {
        !newAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || normalizedBaseURL != settingsViewModel.baseURL
            || newProvider != settingsViewModel.selectedProvider
    }

    private var normalizedBaseURL: String {
        newBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private func performSave() async {
        do {
            if newProvider != settingsViewModel.selectedProvider {
                try settingsViewModel.updateProvider(newProvider)
            }

            let trimmedKey = newAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedKey.isEmpty {
                try settingsViewModel.updateAPIKey(trimmedKey)
                newAPIKey = ""
            }

            if normalizedBaseURL != settingsViewModel.baseURL {
                try settingsViewModel.updateBaseURL(normalizedBaseURL)
            }

            _ = await settingsViewModel.refreshModels(clearExisting: true)
        } catch {
            settingsViewModel.errorMessage = error.localizedDescription
        }
    }
}
