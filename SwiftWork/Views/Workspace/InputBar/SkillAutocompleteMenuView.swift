import SwiftUI
import OpenAgentSDK

struct SkillAutocompleteMenuView: View {
    let viewModel: SkillAutocompleteViewModel
    let onSelect: (String) -> Void

    var body: some View {
        if viewModel.isVisible {
            VStack(spacing: 0) {
                if viewModel.filteredSkills.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        if let title = viewModel.emptyStateTitle {
                            Text(title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                        if let message = viewModel.emptyStateMessage {
                            Text(message)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.filteredSkills.enumerated()), id: \.element.name) { index, skill in
                                SkillRowView(
                                    skill: skill,
                                    isSelected: index == viewModel.selectedIndex
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if let result = viewModel.selectSkill(at: index) {
                                        onSelect(result)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
    }
}

private struct SkillRowView: View {
    let skill: Skill
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("/\(skill.name)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)

                    if let hint = skill.argumentHint, !hint.isEmpty {
                        Text(hint)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    if !skill.aliases.isEmpty {
                        Text(skill.aliases.map { "/\($0)" }.joined(separator: ", "))
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }

                Text(skill.description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
    }
}
