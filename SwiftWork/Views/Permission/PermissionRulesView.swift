import SwiftUI
import SwiftData

// MARK: - Pattern Template

private enum PatternTemplate: String, CaseIterable {
    case allowAll = "全部允许"
    case pathPrefix = "路径/命令前缀"
    case exactMatch = "精确匹配"
    case custom = "自定义"

    func resolvePattern(_ input: String) -> String {
        switch self {
        case .allowAll: "*"
        case .pathPrefix: input.isEmpty ? "" : (input.hasSuffix("*") ? input : input + "*")
        case .exactMatch: input
        case .custom: input
        }
    }

    var needsInput: Bool { self != .allowAll }
}

// MARK: - Tool Option

private let toolOptions: [(name: String, label: String)] = [
    ("Bash", "终端命令"),
    ("Edit", "文件编辑"),
    ("Write", "文件写入"),
    ("Read", "文件读取"),
    ("Grep", "文件搜索 (Grep)"),
    ("Glob", "文件搜索 (Glob)"),
]

// MARK: - PermissionRulesView

struct PermissionRulesView: View {
    @Bindable var permissionHandler: PermissionHandler

    @Query(
        sort: \PermissionRule.createdAt,
        order: .reverse
    ) private var rules: [PermissionRule]

    @State private var ruleToDelete: PermissionRule?
    @State private var showDeleteConfirmation = false
    @State private var showAddSheet = false
    @State private var editingRuleId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            globalModeSection

            Divider()

            rulesSection
        }
        .sheet(isPresented: $showAddSheet) {
            AddRuleSheet(permissionHandler: permissionHandler)
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

            if permissionHandler.globalMode == .autoApprove {
                autoApproveWarningBanner
            }
        }
    }

    private var autoApproveWarningBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("自动批准模式下所有工具调用无需确认，请确保你信任当前 Agent 的行为")
                .font(.caption)
                .foregroundStyle(.orange)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
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
            HStack {
                Text("权限规则（\(rules.count) 条）")
                    .font(.headline)

                Spacer()

                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("新增权限规则")
            }

            if rules.isEmpty {
                emptyStateView
            } else {
                rulesList
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Text("暂无权限规则")
                .font(.body)
                .foregroundStyle(.secondary)
            Text("点击上方 \"+\" 按钮手动新增规则，或在手动审批模式下审批工具调用时创建会话级授权。")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
    }

    private var rulesList: some View {
        List {
            ForEach(rules) { rule in
                if editingRuleId == rule.id {
                    EditRuleRow(
                        rule: rule,
                        permissionHandler: permissionHandler,
                        onCancel: { withAnimation(.easeInOut(duration: 0.2)) { editingRuleId = nil } },
                        onSave: { withAnimation(.easeInOut(duration: 0.2)) { editingRuleId = nil } }
                    )
                } else {
                    ruleRow(rule)
                }
            }
            .onDelete { offsets in
                editingRuleId = nil
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
                    if editingRuleId == rule.id { editingRuleId = nil }
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

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    editingRuleId = rule.id
                }
            } label: {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("编辑规则")

            Button {
                ruleToDelete = rule
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("删除规则")
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

// MARK: - AddRuleSheet

private struct AddRuleSheet: View {
    let permissionHandler: PermissionHandler

    @Environment(\.dismiss) private var dismiss

    @State private var selectedToolIndex = 0
    @State private var selectedTemplate: PatternTemplate = .allowAll
    @State private var patternInput = ""
    @State private var decision: Decision = .allow

    private var resolvedPattern: String {
        selectedTemplate.resolvePattern(patternInput)
    }

    private var isValid: Bool {
        !resolvedPattern.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("新增权限规则")
                .font(.headline)

            toolPicker
            templatePicker
            decisionPicker

            Divider()

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("确认") { createRule() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
        }
        .padding(20)
        .frame(width: 380)
    }

    private var toolPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("工具")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Picker("工具", selection: $selectedToolIndex) {
                ForEach(0..<toolOptions.count, id: \.self) { index in
                    Text(toolOptions[index].label).tag(index)
                }
            }
            .labelsHidden()
        }
    }

    private var templatePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("匹配范围")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(PatternTemplate.allCases, id: \.self) { template in
                HStack(spacing: 8) {
                    RadioButton(selected: selectedTemplate == template) {
                        selectedTemplate = template
                    }
                    Text(template.rawValue)
                        .font(.body)

                    if template.needsInput && selectedTemplate == template {
                        TextField("输入匹配内容", text: $patternInput)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var decisionPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("决策")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Picker("决策", selection: $decision) {
                Text("允许").tag(Decision.allow)
                Text("拒绝").tag(Decision.deny)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private func createRule() {
        let toolName = toolOptions[selectedToolIndex].name
        permissionHandler.addPersistentRule(
            toolName: toolName,
            pattern: resolvedPattern,
            decision: decision
        )
        dismiss()
    }
}

// MARK: - EditRuleRow

private struct EditRuleRow: View {
    let rule: PermissionRule
    let permissionHandler: PermissionHandler
    let onCancel: () -> Void
    let onSave: () -> Void

    @State private var pattern: String
    @State private var decision: Decision

    init(rule: PermissionRule, permissionHandler: PermissionHandler, onCancel: @escaping () -> Void, onSave: @escaping () -> Void) {
        self.rule = rule
        self.permissionHandler = permissionHandler
        self.onCancel = onCancel
        self.onSave = onSave
        _pattern = State(initialValue: rule.pattern)
        _decision = State(initialValue: rule.decision)
    }

    private var isValid: Bool { !pattern.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(PermissionHandler.toolTypeLabel(rule.toolName))
                    .font(.body)
                    .fontWeight(.medium)

                Spacer()

                Button("取消") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("保存") {
                    permissionHandler.updateRule(rule, pattern: pattern.trimmingCharacters(in: .whitespaces), decision: decision)
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(!isValid)
            }

            HStack(spacing: 8) {
                Text("Pattern:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 55, alignment: .trailing)
                TextField("匹配模式", text: $pattern)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption, design: .monospaced))
            }

            HStack(spacing: 8) {
                Text("决策:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 55, alignment: .trailing)
                Picker("决策", selection: $decision) {
                    Text("允许").tag(Decision.allow)
                    Text("拒绝").tag(Decision.deny)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color(NSColor.controlAccentColor).opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - RadioButton Helper

private struct RadioButton: View {
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: selected ? "circle.fill" : "circle")
                .font(.caption)
                .foregroundStyle(selected ? Color.accentColor : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("选择")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
