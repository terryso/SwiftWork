import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let permissionHandler: PermissionHandler

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PermissionRulesView(permissionHandler: permissionHandler)
            }
            .padding(20)
        }
        .frame(minWidth: 520, minHeight: 450)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("关闭") { dismiss() }
            }
        }
    }
}
