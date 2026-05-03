import SwiftUI
import SwiftData

struct SettingsView: View {
    private enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "通用"
        case permissions = "权限"

        var id: Self { self }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SettingsTab = .general
    let settingsViewModel: SettingsViewModel?
    let permissionHandler: PermissionHandler

    init(settingsViewModel: SettingsViewModel, permissionHandler: PermissionHandler) {
        self.settingsViewModel = settingsViewModel
        self.permissionHandler = permissionHandler
    }

    init(permissionHandler: PermissionHandler) {
        self.settingsViewModel = nil
        self.permissionHandler = permissionHandler
    }

    var body: some View {
        VStack(spacing: 0) {
            tabPicker

            Divider()

            activeTabContent
        }
        .frame(minWidth: 520, minHeight: 450)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("关闭") { dismiss() }
            }
        }
    }

    private var tabPicker: some View {
        HStack {
            Spacer()

            Picker("设置分类", selection: $selectedTab) {
                ForEach(SettingsTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 200)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var activeTabContent: some View {
        switch selectedTab {
        case .general:
            generalTab
        case .permissions:
            permissionsTab
        }
    }

    // MARK: - General Tab

    private var generalTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let vm = settingsViewModel {
                    APIKeySettingsView(settingsViewModel: vm)
                    Divider()
                    ModelPickerView(settingsViewModel: vm)
                } else {
                    Text("设置不可用")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(20)
        }
        .onAppear {
            settingsViewModel?.loadCurrentConfig()
        }
    }

    // MARK: - Permissions Tab

    private var permissionsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PermissionRulesView(permissionHandler: permissionHandler)
            }
            .padding(20)
        }
    }
}
