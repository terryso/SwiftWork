import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
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
        TabView {
            generalTab
                .tabItem {
                    Label("通用", systemImage: "gearshape")
                }

            permissionsTab
                .tabItem {
                    Label("权限", systemImage: "lock.shield")
                }
        }
        .frame(minWidth: 520, minHeight: 450)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("关闭") { dismiss() }
            }
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
