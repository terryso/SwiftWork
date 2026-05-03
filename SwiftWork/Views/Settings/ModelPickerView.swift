import SwiftUI

struct ModelPickerView: View {
    @Bindable var settingsViewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Current model display
            currentModelSection

            Divider()

            // Model picker
            modelPickerSection

            Divider()

            // Info note
            infoNote
        }
    }

    // MARK: - Current Model

    private var currentModelSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("模型选择")
                .font(.headline)

            HStack(spacing: 8) {
                Text("当前模型:")
                    .foregroundStyle(.secondary)
                Text(settingsViewModel.selectedModel)
                    .fontWeight(.medium)
            }
        }
    }

    // MARK: - Model Picker

    private var modelPickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("选择模型:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("模型", selection: selectedModelBinding) {
                ForEach(settingsViewModel.availableModels, id: \.self) { model in
                    Text(model).tag(model)
                }
            }
            .pickerStyle(.menu)
        }
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

    // MARK: - Info Note

    private var infoNote: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
            Text("模型更改在下次发送消息时生效")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
