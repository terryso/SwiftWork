import SwiftUI
import SwiftData

struct PermissionRulesView: View {
    @Bindable var permissionHandler: PermissionHandler

    @Query(
        sort: \PermissionRule.createdAt,
        order: .reverse
    ) private var rules: [PermissionRule]

    @State private var ruleToDelete: PermissionRule?
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            globalModeSection

            Divider()

            rulesSection
        }
    }

    // MARK: - Global Mode Section

    private var globalModeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("全局权限模式")
                .font(.headline)

            Picker("全局权限模式", selection: $permissionHandler.globalMode) {
                Text("自动批准").tag(GlobalPermissionMode.autoApprove)
                Text("手动审批").tag(GlobalPermissionMode.manualReview)
                Text("全部拒绝").tag(GlobalPermissionMode.denyAll)
            }
            .pickerStyle(.segmented)
            .help(modeDescription)

            Text(modeDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var modeDescription: String {
        switch permissionHandler.globalMode {
        case .autoApprove:
            return "所有工具调用自动批准，无需用户确认"
        case .manualReview:
            return "每次工具调用都需要用户审批"
        case .denyAll:
            return "拒绝所有工具调用"
        }
    }

    // MARK: - Rules List Section

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("权限规则（\(rules.count) 条）")
                .font(.headline)

            if rules.isEmpty {
                emptyStateView
            } else {
                rulesList
            }
        }
    }

    private var emptyStateView: some View {
        Text("暂无权限规则。在手动审批模式下，Agent 工具调用时可通过「始终允许」创建规则。")
            .font(.body)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 24)
    }

    private var rulesList: some View {
        List {
            ForEach(rules) { rule in
                ruleRow(rule)
            }
            .onDelete { offsets in
                if offsets.count == 1, let index = offsets.first {
                    ruleToDelete = rules[index]
                    showDeleteConfirmation = true
                } else {
                    for index in offsets {
                        permissionHandler.deleteRule(rules[index])
                    }
                }
            }
        }
        .listStyle(.inset)
        .frame(minHeight: 120)
        .alert("删除权限规则", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) {
                ruleToDelete = nil
            }
            Button("删除", role: .destructive) {
                if let rule = ruleToDelete {
                    permissionHandler.deleteRule(rule)
                    ruleToDelete = nil
                }
            }
        } message: {
            if let rule = ruleToDelete {
                Text("确定要删除 \(PermissionHandler.toolTypeLabel(rule.toolName)) 的规则吗？")
            }
        }
    }

    @ViewBuilder
    private func ruleRow(_ rule: PermissionRule) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(PermissionHandler.toolTypeLabel(rule.toolName))
                        .font(.body)
                        .fontWeight(.medium)

                    Text(rule.pattern)
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Spacer()

                    decisionBadge(rule.decision)

                    Text(rule.createdAt.formatted(.dateTime.year().month().day()))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func decisionBadge(_ decision: Decision) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(decision == .allow ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(decision == .allow ? "允许" : "拒绝")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(decision == .allow ? .green : .red)
        }
    }
}
