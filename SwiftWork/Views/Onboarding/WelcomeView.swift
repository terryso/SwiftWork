import SwiftUI

struct WelcomeView: View {
    @Bindable var viewModel: SettingsViewModel
    var onComplete: () -> Void

    @State private var showAPIKey = false

    init(viewModel: SettingsViewModel = SettingsViewModel(), onComplete: @escaping () -> Void = {}) {
        self.viewModel = viewModel
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Welcome to SwiftWork")
                .font(.title)
                .fontWeight(.bold)

            Text("Configure your agent to get started")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 16) {
                // API Key input
                VStack(alignment: .leading, spacing: 4) {
                    Text("API Key")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        if showAPIKey {
                            TextField("sk-...", text: $viewModel.apiKey)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("sk-...", text: $viewModel.apiKey)
                                .textFieldStyle(.roundedBorder)
                        }

                        Button(action: { showAPIKey.toggle() }) {
                            Image(systemName: showAPIKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                    }
                }

                // Base URL input
                VStack(alignment: .leading, spacing: 4) {
                    Text("Base URL")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField(Constants.defaultBaseURL, text: $viewModel.baseURL)
                        .textFieldStyle(.roundedBorder)
                        #if os(macOS)
                        .onSubmit { normalizeBaseURL() }
                        #endif
                }

                // Model picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Model")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("Model", selection: $viewModel.selectedModel) {
                        ForEach(viewModel.availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .frame(maxWidth: 400)

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            Button(action: performSave) {
                Text("Get Started")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isValidAPIKey)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private func performSave() {
        normalizeBaseURL()
        do {
            try viewModel.saveAPIKey()
            viewModel.completeSetup()
            onComplete()
        } catch {
            // errorMessage already set by saveAPIKey()
        }
    }

    private func normalizeBaseURL() {
        var url = viewModel.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if url.hasSuffix("/") {
            url.removeLast()
        }
        viewModel.baseURL = url
    }
}
