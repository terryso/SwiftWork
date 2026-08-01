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
                providerSection
                apiKeySection
                baseURLSection
                modelSection
            }
            .frame(maxWidth: 400)

            if let error = viewModel.errorMessage ?? viewModel.modelLoadErrorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            Button("Get Started", action: performSave)
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.isValidAPIKey || !viewModel.hasValidModelSelection)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .onChange(of: viewModel.selectedProvider) { _, _ in
            viewModel.invalidateModels()
        }
        .onChange(of: viewModel.apiKey) { _, _ in
            if !viewModel.availableModels.isEmpty {
                viewModel.invalidateModels()
            }
        }
        .onChange(of: viewModel.baseURL) { _, _ in
            if !viewModel.availableModels.isEmpty {
                viewModel.invalidateModels()
            }
        }
    }

    private var providerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("API Provider")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("API Provider", selection: $viewModel.selectedProvider) {
                ForEach(AgentProvider.allCases) { provider in
                    Text(provider.displayName).tag(provider)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("API Key")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Group {
                    if showAPIKey {
                        TextField("API Key", text: $viewModel.apiKey)
                    } else {
                        SecureField("API Key", text: $viewModel.apiKey)
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

    private var baseURLSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Base URL")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField(viewModel.selectedProvider.defaultBaseURL, text: $viewModel.baseURL)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Model")
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.isLoadingModels {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("正在获取模型…")
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.availableModels.isEmpty {
                Button("获取模型") {
                    Task { await fetchModels() }
                }
                .disabled(!viewModel.isValidAPIKey)
            } else {
                Picker("Model", selection: selectedModelBinding) {
                    ForEach(viewModel.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)

                Button("重新获取") {
                    Task { await fetchModels() }
                }
                .controlSize(.small)
            }
        }
    }

    private var selectedModelBinding: Binding<String> {
        Binding(
            get: { viewModel.selectedModel },
            set: { newModel in
                do {
                    try viewModel.updateModel(newModel)
                } catch {
                    viewModel.errorMessage = error.localizedDescription
                }
            }
        )
    }

    private func fetchModels() async {
        normalizeBaseURL()
        _ = await viewModel.refreshModels(
            apiKey: viewModel.apiKey,
            baseURL: viewModel.baseURL,
            clearExisting: true
        )
    }

    private func performSave() {
        normalizeBaseURL()
        do {
            try viewModel.saveAPIKey()
            viewModel.completeSetup()
            if !viewModel.isFirstLaunch {
                onComplete()
            }
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func normalizeBaseURL() {
        viewModel.baseURL = viewModel.baseURL
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}
