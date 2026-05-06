import Foundation
import OpenAgentSDK
import Observation

enum SkillAutocompleteMenuState: Equatable {
    case hidden
    case noAvailableSkills
    case noMatches(query: String)
    case results
}

@MainActor
@Observable
final class SkillAutocompleteViewModel {

    var filteredSkills: [Skill] = []
    var selectedIndex: Int?
    var skillsSource: [Skill] = []
    var menuState: SkillAutocompleteMenuState = .hidden

    var isVisible: Bool {
        menuState != .hidden
    }

    var emptyStateTitle: String? {
        switch menuState {
        case .noAvailableSkills:
            "暂无可用 Skills"
        case .noMatches:
            "未匹配到 Skill"
        case .hidden, .results:
            nil
        }
    }

    var emptyStateMessage: String? {
        switch menuState {
        case .noAvailableSkills:
            "Agent 配置完成后，可用技能会自动出现在这里。"
        case .noMatches(let query):
            "/\(query) 没有命中任何已注册且可用的 Skill。按 Enter 会按普通文本发送。"
        case .hidden, .results:
            nil
        }
    }

    func updateSkillsSource(_ skills: [Skill], currentText: String) {
        skillsSource = skills
        updateQuery(currentText)
    }

    func updateQuery(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("/") else {
            dismiss()
            return
        }

        let query = commandFragment(from: trimmed).lowercased()

        guard !skillsSource.isEmpty else {
            filteredSkills = []
            selectedIndex = nil
            menuState = .noAvailableSkills
            return
        }

        if query.isEmpty {
            filteredSkills = skillsSource
        } else {
            filteredSkills = skillsSource.filter { skill in
                skill.name.lowercased().hasPrefix(query)
                    || skill.name.lowercased().contains(query)
                    || skill.aliases.contains { $0.lowercased().hasPrefix(query) }
                    || skill.aliases.contains { $0.lowercased().contains(query) }
            }
            filteredSkills.sort { a, b in
                let aPrefix = a.name.lowercased().hasPrefix(query)
                let bPrefix = b.name.lowercased().hasPrefix(query)
                if aPrefix != bPrefix { return aPrefix }
                return a.name < b.name
            }
        }

        selectedIndex = filteredSkills.isEmpty ? nil : 0
        menuState = filteredSkills.isEmpty ? .noMatches(query: query) : .results
    }

    func selectSkill(at index: Int) -> String? {
        guard case .results = menuState else { return nil }
        guard index >= 0, index < filteredSkills.count else { return nil }
        return "/\(filteredSkills[index].name)"
    }

    func moveSelection(down: Bool) {
        guard case .results = menuState, !filteredSkills.isEmpty else { return }
        guard let current = selectedIndex else {
            selectedIndex = down ? 0 : filteredSkills.count - 1
            return
        }
        if down {
            selectedIndex = (current + 1) % filteredSkills.count
        } else {
            selectedIndex = (current - 1 + filteredSkills.count) % filteredSkills.count
        }
    }

    func dismiss() {
        menuState = .hidden
        filteredSkills = []
        selectedIndex = nil
    }

    private func commandFragment(from trimmedText: String) -> String {
        let afterSlash = String(trimmedText.dropFirst())
        guard let whitespaceIndex = afterSlash.firstIndex(where: { $0.isWhitespace }) else {
            return afterSlash
        }
        return String(afterSlash[..<whitespaceIndex])
    }
}
