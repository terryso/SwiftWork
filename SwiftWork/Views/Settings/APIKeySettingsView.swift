import SwiftUI

struct APIKeySettingsView: View {
    @Bindable var settingsViewModel: SettingsViewModel
    @State private var showAPIKey = false
    @State private var newAPIKey = ""
    @State private var newBaseURL = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Status indicator
            statusSection

            Divider()

            // API Key input
            apiKeyInputSection

            Divider()

            // Base URL input
            baseURLInputSection

            Divider()

            // Save button
            saveButton
        }
        .onAppear {
            newBaseURL = settingsViewModel.baseURL
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("API Key")
                .font(.headline)

            HStack(spacing: 8) {
                Image(systemName: settingsViewModel.isAPIKeyConfigured ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(settingsViewModel.isAPIKeyConfigured ? .green : .red)
                Text(settingsViewModel.isAPIKeyConfigured ? "已配置" : "未配置")
                    .font(.body)
            }

            if settingsViewModel.isAPIKeyConfigured {
                Text(settingsViewModel.maskedAPIKey)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - API Key Input

    private var apiKeyInputSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("更新 API Key")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                if showAPIKey {
                    TextField("sk-...", text: $newAPIKey)
                        .textFieldStyle(.roundedBorder)
                } else {
                    SecureField("sk-...", text: $newAPIKey)
                        .textFieldStyle(.roundedBorder)
                }

                Button(action: { showAPIKey.toggle() }) {
                    Image(systemName: showAPIKey ? "eye.slash" : "eye")
                }
                .buttonStyle(.borderless)
            }
        }
    }

    // MARK: - Base URL Input

    private var baseURLInputSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Base URL")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField(Constants.defaultBaseURL, text: $newBaseURL)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        HStack {
            Spacer()

            if let error = settingsViewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            Button("保存更改") {
                performSave()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!hasChanges)
        }
    }

    // MARK: - Actions

    private var hasChanges: Bool {
        let trimmedKey = newAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let keyChanged = !trimmedKey.isEmpty
        let urlChanged = newBaseURL != settingsViewModel.baseURL
        return keyChanged || urlChanged
    }

    private func performSave() {
        normalizeBaseURL()

        let trimmedKey = newAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedKey.isEmpty {
            do {
                try settingsViewModel.updateAPIKey(newAPIKey)
                newAPIKey = ""
            } catch {
                // errorMessage already set by updateAPIKey()
                return
            }
        }

        // Always persist base URL changes
        if newBaseURL != settingsViewModel.baseURL {
            settingsViewModel.updateBaseURL(newBaseURL)
        }
    }

    private func normalizeBaseURL() {
        var url = newBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if url.hasSuffix("/") {
            url.removeLast()
        }
        newBaseURL = url
    }
}
