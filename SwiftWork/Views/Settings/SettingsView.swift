import SwiftUI
import SwiftData
import OpenAgentSDK

struct SettingsView: View {
    private enum Layout {
        static let minWidth: CGFloat = 520
        static let minHeight: CGFloat = 450
        static let fixedHeight: CGFloat = 620
    }

    private enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "通用"
        case permissions = "权限"
        case skills = "Skills"
        case mcp = "MCP Servers"

        var id: Self { self }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SettingsTab = .general
    let settingsViewModel: SettingsViewModel?
    let permissionHandler: PermissionHandler
    let agentBridge: AgentBridge?

    init(settingsViewModel: SettingsViewModel, permissionHandler: PermissionHandler) {
        self.settingsViewModel = settingsViewModel
        self.permissionHandler = permissionHandler
        self.agentBridge = nil
    }

    init(permissionHandler: PermissionHandler) {
        self.settingsViewModel = nil
        self.permissionHandler = permissionHandler
        self.agentBridge = nil
    }

    init(settingsViewModel: SettingsViewModel, permissionHandler: PermissionHandler, agentBridge: AgentBridge) {
        self.settingsViewModel = settingsViewModel
        self.permissionHandler = permissionHandler
        self.agentBridge = agentBridge
    }

    init(permissionHandler: PermissionHandler, agentBridge: AgentBridge) {
        self.settingsViewModel = nil
        self.permissionHandler = permissionHandler
        self.agentBridge = agentBridge
    }

    var body: some View {
        VStack(spacing: 0) {
            tabPicker

            Divider()

            activeTabContent
        }
        .frame(
            minWidth: Layout.minWidth,
            minHeight: Layout.minHeight,
            idealHeight: Layout.fixedHeight,
            maxHeight: Layout.fixedHeight
        )
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
            .frame(width: 340)

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
        case .skills:
            skillsTab
        case .mcp:
            mcpTab
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

    // MARK: - Skills Tab

    private var skillsTab: some View {
        Group {
            if let bridge = agentBridge {
                SkillsListView(
                    skills: bridge.allRegisteredSkills,
                    sourceDirectories: bridge.skillSourceDirectories
                )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                Text("Skill 列表不可用")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - MCP Servers Tab

    private var mcpTab: some View {
        Group {
            if let bridge = agentBridge, let store = bridge.mcpConfigStore {
                MCPManagementView(
                    store: store,
                    agentBridge: bridge
                )
            } else {
                Text("MCP 管理不可用")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
