import SwiftUI
import OpenAgentSDK

/// Displays all registered skills grouped by fixed global source.
struct SkillsListView: View {
    let skills: [Skill]
    let sourceDirectories: SkillSourceDirectories

    init(
        skills: [Skill],
        sourceDirectories: SkillSourceDirectories = .userDefaults()
    ) {
        self.skills = skills
        self.sourceDirectories = sourceDirectories
    }

    @State private var expandedSkillIDs: Set<String> = []

    private var groupedSkills: [(source: SkillSource, skills: [Skill])] {
        let grouped = Dictionary(grouping: skills, by: {
            SkillSource.from($0, directories: sourceDirectories)
        })
        return SkillSource.allCases.compactMap { source in
            guard let list = grouped[source], !list.isEmpty else { return nil }
            return (source: source, skills: list)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
                if skills.isEmpty {
                    emptyState
                } else {
                    ForEach(groupedSkills, id: \.source) { group in
                        Section {
                            ForEach(group.skills, id: \.name) { skill in
                                SkillListItemView(
                                    skill: skill,
                                    isExpanded: expandedSkillIDs.contains(skill.name),
                                    sourceDirectories: sourceDirectories
                                )
                                .onTapGesture {
                                    toggleExpansion(of: skill.name)
                                }
                            }
                        } header: {
                            sectionHeader(for: group.source, count: group.skills.count)
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("没有已注册的 Skill")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("配置 AgentBridge 后，Skill 将在此显示。")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: - Section Header

    private func sectionHeader(for source: SkillSource, count: Int) -> some View {
        HStack {
            Image(systemName: sourceIcon(source))
                .foregroundStyle(.secondary)
            Text(source.displayName)
                .font(.headline)
            Text("(\(count))")
                .foregroundStyle(.secondary)
                .font(.subheadline)
            Spacer()
        }
        .padding(.bottom, 4)
    }

    private func sourceIcon(_ source: SkillSource) -> String {
        switch source {
        case .builtIn: return "star.fill"
        case .swiftWork: return "swift"
        case .claudeCode: return "terminal.fill"
        case .codex: return "chevron.left.forwardslash.chevron.right"
        case .sharedAgents: return "person.2.fill"
        }
    }

    // MARK: - Helpers

    private func toggleExpansion(of name: String) {
        if expandedSkillIDs.contains(name) {
            expandedSkillIDs.remove(name)
        } else {
            expandedSkillIDs.insert(name)
        }
    }
}
