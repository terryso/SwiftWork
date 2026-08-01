import SwiftUI

struct ModelPickerView: View {
    @Bindable var settingsViewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            currentModelSection
            Divider()
            modelPickerSection
            Divider()
            infoNote
        }
        .task {
            guard settingsViewModel.isAPIKeyConfigured,
                  !settingsViewModel.isLoadingModels else { return }
            _ = await settingsViewModel.refreshModels()
        }
    }

    private var currentModelSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("模型选择")
                .font(.headline)

            HStack(spacing: 8) {
                Text(settingsViewModel.selectedProvider.displayName)
                    .foregroundStyle(.secondary)
                Text(settingsViewModel.selectedModel.isEmpty ? "未选择" : settingsViewModel.selectedModel)
                    .fontWeight(.medium)
            }
        }
    }

    @ViewBuilder
    private var modelPickerSection: some View {
        if settingsViewModel.isLoadingModels {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("正在从 Provider 获取模型…")
                    .foregroundStyle(.secondary)
            }
        } else if settingsViewModel.availableModels.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(settingsViewModel.modelLoadErrorMessage ?? "请先保存 Provider、Base URL 和 API Key")
                    .foregroundStyle(settingsViewModel.modelLoadErrorMessage == nil ? Color.secondary : Color.red)
                    .font(.caption)

                if settingsViewModel.isAPIKeyConfigured {
                    refreshButton
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Picker("模型", selection: selectedModelBinding) {
                    ForEach(settingsViewModel.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    Text("共 \(settingsViewModel.availableModels.count) 个模型")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    refreshButton
                }

                if let error = settingsViewModel.modelLoadErrorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var refreshButton: some View {
        Button("重新获取") {
            Task { _ = await settingsViewModel.refreshModels() }
        }
        .controlSize(.small)
    }

    private var selectedModelBinding: Binding<String> {
        Binding(
            get: { settingsViewModel.selectedModel },
            set: { newModel in
                do {
                    try settingsViewModel.updateModel(newModel)
                } catch {
                    settingsViewModel.errorMessage = error.localizedDescription
                }
            }
        )
    }

    private var infoNote: some View {
        Label("模型来自当前 Provider API；若任务正在运行，更改会在任务结束后生效", systemImage: "info.circle")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
