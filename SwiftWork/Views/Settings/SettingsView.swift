import SwiftUI
import SwiftData

struct SettingsView: View {
    let permissionHandler: PermissionHandler

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PermissionRulesView(permissionHandler: permissionHandler)
            }
            .padding(20)
        }
        .frame(minWidth: 480, minHeight: 400)
    }
}
