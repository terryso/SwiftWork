import SwiftUI
import OpenAgentSDK

/// A single row in the Skills list that shows a collapsed summary or expanded detail.
struct SkillListItemView: View {
    let skill: Skill
    let isExpanded: Bool
    let sourceDirectories: SkillSourceDirectories

    init(
        skill: Skill,
        isExpanded: Bool,
        sourceDirectories: SkillSourceDirectories = .userDefaults()
    ) {
        self.skill = skill
        self.isExpanded = isExpanded
        self.sourceDirectories = sourceDirectories
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Collapsed row
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                    .font(.caption)

                Text("/\(skill.name)")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)

                if !skill.description.isEmpty {
                    Text(skill.description)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(.secondary)
                        .font(.body)
                }

                Spacer()

                sourceBadge

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 6)

            // Expanded detail
            if isExpanded {
                expandedContent
                    .padding(.top, 4)
                    .padding(.bottom, 8)
            }
        }
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isExpanded ? Color.purple.opacity(0.05) : Color.clear)
        )
    }

    // MARK: - Source Badge

    private var sourceBadge: some View {
        let source = SkillSource.from(skill, directories: sourceDirectories)
        return Text(source.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(sourceColor(source).opacity(0.15))
            )
            .foregroundStyle(sourceColor(source))
    }

    private func sourceColor(_ source: SkillSource) -> Color {
        switch source {
        case .builtIn: return .blue
        case .swiftWork: return .purple
        case .claudeCode: return .orange
        case .codex: return .green
        case .sharedAgents: return .teal
        }
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !skill.description.isEmpty {
                detailRow(label: "描述", value: skill.description)
            }

            if !skill.aliases.isEmpty {
                aliasesRow
            }

            if let whenToUse = skill.whenToUse, !whenToUse.isEmpty {
                detailRow(label: "触发条件", value: whenToUse)
            }

            if let argumentHint = skill.argumentHint, !argumentHint.isEmpty {
                detailRow(label: "参数", value: argumentHint)
            }

            if let restrictions = skill.toolRestrictions, !restrictions.isEmpty {
                toolRestrictionsRow(restrictions)
            }

            if let baseDir = skill.baseDir {
                baseDirRow(baseDir)
            }

            if !skill.supportingFiles.isEmpty {
                supportingFilesRow
            }
        }
    }

    // MARK: - Detail Rows

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
            Text(value)
                .font(.body)
        }
    }

    private var aliasesRow: some View {
        HStack(alignment: .top) {
            Text("别名")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
            FlowLayout(spacing: 4) {
                ForEach(skill.aliases, id: \.self) { alias in
                    Text("/\(alias)")
                        .font(.system(.caption, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.purple.opacity(0.1))
                        )
                        .foregroundStyle(.purple)
                }
            }
        }
    }

    private func toolRestrictionsRow(_ restrictions: [ToolRestriction]) -> some View {
        HStack(alignment: .top) {
            Text("工具")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
            FlowLayout(spacing: 4) {
                ForEach(restrictions.map(\.rawValue), id: \.self) { name in
                    Text(name)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.1))
                        )
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func baseDirRow(_ path: String) -> some View {
        HStack(alignment: .top) {
            Text("路径")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
            Text(path)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Button {
                let url = URL(fileURLWithPath: path)
                NSWorkspace.shared.open(url)
            } label: {
                Label("在 Finder 中打开", systemImage: "folder")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
        }
    }

    private var supportingFilesRow: some View {
        HStack(alignment: .top) {
            Text("文件")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
            VStack(alignment: .leading, spacing: 2) {
                ForEach(skill.supportingFiles, id: \.self) { file in
                    Text(file)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

// MARK: - FlowLayout (inline helper for tag-style layouts)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(
                x: bounds.minX + position.x,
                y: bounds.minY + position.y
            ), proposal: .unspecified)
        }
    }

    private struct ArrangeResult {
        var size: CGSize
        var positions: [CGPoint]
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> ArrangeResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalWidth = max(totalWidth, x)
            totalHeight = y + rowHeight
        }

        return ArrangeResult(
            size: CGSize(width: totalWidth, height: totalHeight),
            positions: positions
        )
    }
}
