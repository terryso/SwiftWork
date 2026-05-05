import Foundation
import OpenAgentSDK
import Observation

@MainActor
@Observable
final class SkillAutocompleteViewModel {

    var filteredSkills: [Skill] = []
    var isVisible: Bool = false
    var selectedIndex: Int?
    var skillsSource: [Skill] = []

    func updateQuery(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("/") else {
            isVisible = false
            filteredSkills = []
            selectedIndex = nil
            return
        }

        let query = String(trimmed.dropFirst()).lowercased()

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
        isVisible = !filteredSkills.isEmpty
    }

    func selectSkill(at index: Int) -> String? {
        guard isVisible else { return nil }
        guard index >= 0, index < filteredSkills.count else { return nil }
        return "/\(filteredSkills[index].name)"
    }

    func moveSelection(down: Bool) {
        guard isVisible, !filteredSkills.isEmpty else { return }
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
        isVisible = false
        filteredSkills = []
        selectedIndex = nil
    }
}
