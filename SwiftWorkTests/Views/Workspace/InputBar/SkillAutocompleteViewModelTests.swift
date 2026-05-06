import XCTest
import OpenAgentSDK
@testable import SwiftWork

// ATDD Red Phase -- Story 5.2: Input Bar Slash Autocomplete
// Acceptance tests for SkillAutocompleteViewModel: slash trigger, fuzzy filter,
// keyboard selection, dismiss, line-start-only trigger, and plain-text passthrough.
// These tests assert EXPECTED behavior that does NOT exist yet.
// They WILL FAIL until SkillAutocompleteViewModel is implemented.

@MainActor
final class SkillAutocompleteViewModelTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeViewModel(skills: [Skill] = []) -> SkillAutocompleteViewModel {
        let vm = SkillAutocompleteViewModel()
        vm.skillsSource = skills
        return vm
    }

    private func makeSkill(
        name: String,
        description: String = "Test skill",
        aliases: [String] = [],
        argumentHint: String? = nil
    ) -> Skill {
        Skill(
            name: name,
            description: description,
            aliases: aliases,
            userInvocable: true,
            promptTemplate: "Template for \(name)",
            argumentHint: argumentHint
        )
    }

    private var sampleSkills: [Skill] {
        [
            makeSkill(name: "commit", description: "Create a git commit", aliases: ["ci"], argumentHint: "[message]"),
            makeSkill(name: "review", description: "Review code changes", aliases: ["cr"]),
            makeSkill(name: "simplify", description: "Simplify code"),
            makeSkill(name: "debug", description: "Debug issues"),
            makeSkill(name: "test", description: "Run tests", aliases: ["t"]),
        ]
    }

    // MARK: - AC#1: Slash Trigger Autocomplete

    // [P0] Empty input does not show menu
    func testEmptyInputDoesNotShowMenu() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("")
        XCTAssertFalse(vm.isVisible, "Menu should not be visible for empty input")
    }

    // [P0] Single "/" shows all userInvocable skills
    func testSlashShowsAllSkills() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("/")
        XCTAssertTrue(vm.isVisible, "Menu should be visible after typing '/'")
        XCTAssertEqual(vm.filteredSkills.count, sampleSkills.count,
            "All skills should be shown when query is just '/'")
    }

    // [P0] "/" with no skills does not show menu
    func testSlashWithNoSkillsDoesNotShowMenu() {
        let vm = makeViewModel(skills: [])
        vm.updateQuery("/")
        XCTAssertTrue(vm.isVisible, "Menu should stay visible to show the empty slash state")
        XCTAssertTrue(vm.filteredSkills.isEmpty, "Filtered skills should be empty")
        XCTAssertEqual(vm.menuState, .noAvailableSkills)
    }

    // [P1] Menu appears with correct initial selection
    func testMenuAppearsWithInitialSelection() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("/")
        XCTAssertTrue(vm.isVisible)
        XCTAssertEqual(vm.selectedIndex, 0,
            "First item should be selected by default")
    }

    // MARK: - AC#2: Fuzzy Filter

    // [P0] Prefix match filters skills
    func testPrefixMatchFiltersSkills() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("/co")
        XCTAssertTrue(vm.isVisible)
        XCTAssertTrue(vm.filteredSkills.contains(where: { $0.name == "commit" }),
            "'/co' should match 'commit' by prefix")
    }

    // [P0] Alias match filters skills
    func testAliasMatchFiltersSkills() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("/ci")
        XCTAssertTrue(vm.isVisible)
        XCTAssertTrue(vm.filteredSkills.contains(where: { $0.name == "commit" }),
            "'/ci' should match 'commit' via alias 'ci'")
    }

    // [P0] No match hides menu
    func testNoMatchHidesMenu() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("/xyz")
        XCTAssertTrue(vm.isVisible, "Menu should stay visible to show the no-match state")
        XCTAssertTrue(vm.filteredSkills.isEmpty)
        XCTAssertEqual(vm.menuState, .noMatches(query: "xyz"))
    }

    // [P1] Prefix matches sorted before contains matches
    func testPrefixMatchesSortedFirst() {
        let skills = [
            makeSkill(name: "code-review", description: "Review code"),
            makeSkill(name: "commit", description: "Create commit"),
            makeSkill(name: "recommit", description: "Recommit"),
        ]
        let vm = makeViewModel(skills: skills)
        vm.updateQuery("/co")
        let names = vm.filteredSkills.map(\.name)
        // "commit" and "code-review" are prefix matches, "recommit" is contains-only
        let prefixNames = names.filter { $0.hasPrefix("co") }
        let containsNames = names.filter { !$0.hasPrefix("co") && $0.contains("co") }
        // All prefix matches should come before contains-only matches
        if !prefixNames.isEmpty && !containsNames.isEmpty {
            let lastPrefixIndex = names.lastIndex(of: prefixNames.last!)!
            let firstContainsIndex = names.firstIndex(of: containsNames.first!)!
            XCTAssertLessThan(lastPrefixIndex, firstContainsIndex,
                "Prefix matches should be sorted before contains-only matches")
        }
    }

    // [P1] Query is case-insensitive
    func testFilterIsCaseInsensitive() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("/COM")
        XCTAssertTrue(vm.isVisible)
        XCTAssertTrue(vm.filteredSkills.contains(where: { $0.name == "commit" }),
            "'/COM' should match 'commit' case-insensitively")
    }

    // [P1] Filter works with alias prefix
    func testAliasPrefixMatch() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("/cr")
        XCTAssertTrue(vm.isVisible)
        XCTAssertTrue(vm.filteredSkills.contains(where: { $0.name == "review" }),
            "'/cr' should match 'review' via alias 'cr' prefix")
    }

    // MARK: - AC#3: Keyboard Select and Confirm

    // [P0] selectSkill returns correct skill name with slash prefix
    func testSelectSkillReturnsSlashPrefixedName() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("/")
        let result = vm.selectSkill(at: 0)
        XCTAssertEqual(result, "/commit",
            "selectSkill should return '/commit' for first skill")
    }

    // [P0] selectSkill returns nil for out-of-bounds index
    func testSelectSkillReturnsNilForOutOfBounds() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("/")
        let result = vm.selectSkill(at: 999)
        XCTAssertNil(result, "selectSkill should return nil for invalid index")
    }

    // [P0] selectSkill returns nil when menu is not visible
    func testSelectSkillReturnsNilWhenMenuNotVisible() {
        let vm = makeViewModel(skills: sampleSkills)
        // Don't trigger menu
        let result = vm.selectSkill(at: 0)
        XCTAssertNil(result, "selectSkill should return nil when menu is not visible")
    }

    // [P1] selectedIndex tracks highlighted item
    func testSelectedIndexTracksHighlight() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("/")
        XCTAssertEqual(vm.selectedIndex, 0)

        // Simulate moving selection down
        vm.moveSelection(down: true)
        XCTAssertEqual(vm.selectedIndex, 1)

        vm.moveSelection(down: true)
        XCTAssertEqual(vm.selectedIndex, 2)
    }

    // [P1] moveSelection wraps around at boundaries
    func testMoveSelectionWrapsAtBoundary() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("/")

        // Move up from first item should wrap to last
        vm.moveSelection(down: false)
        XCTAssertEqual(vm.selectedIndex, sampleSkills.count - 1,
            "Moving up from first should wrap to last item")

        // Move down from last item should wrap to first
        vm.moveSelection(down: true)
        XCTAssertEqual(vm.selectedIndex, 0,
            "Moving down from last should wrap to first item")
    }

    // MARK: - AC#4: Escape/Click-Outside Dismiss

    // [P0] dismiss hides menu and resets state
    func testDismissHidesMenuAndResetsState() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("/")
        XCTAssertTrue(vm.isVisible)

        vm.dismiss()
        XCTAssertFalse(vm.isVisible, "dismiss() should hide the menu")
        XCTAssertTrue(vm.filteredSkills.isEmpty, "dismiss() should clear filtered skills")
        XCTAssertNil(vm.selectedIndex, "dismiss() should clear selectedIndex")
    }

    // [P1] dismiss when menu not visible is a no-op
    func testDismissWhenNotVisibleIsNoOp() {
        let vm = makeViewModel(skills: sampleSkills)
        // Don't trigger menu
        vm.dismiss() // should not crash
        XCTAssertFalse(vm.isVisible)
    }

    // MARK: - AC#5: Non-Matching Slash Text Sent As Plain Text

    // [P0] Non-matching slash text does not trigger autocomplete
    func testNonMatchingSlashTextDoesNotTriggerAutocomplete() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("/hello")
        XCTAssertTrue(vm.isVisible,
            "Non-matching '/hello' should still show slash empty state")
        XCTAssertEqual(vm.menuState, .noMatches(query: "hello"))
    }

    // [P1] Non-matching text with slash prefix has empty filtered skills
    func testNonMatchingTextHasEmptyFilteredSkills() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("/zzzzz")
        XCTAssertTrue(vm.filteredSkills.isEmpty,
            "Non-matching query should result in empty filtered skills")
        XCTAssertNil(vm.selectedIndex,
            "Non-matching query should have nil selectedIndex")
    }

    // MARK: - AC#6: Line-Start Only Trigger

    // [P0] Slash at non-start position does not trigger menu
    func testSlashAtNonStartDoesNotTrigger() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("hello /")
        XCTAssertFalse(vm.isVisible,
            "'hello /' should NOT trigger autocomplete -- slash not at line start")
    }

    // [P0] Slash at start with leading whitespace triggers menu
    func testSlashAtStartWithLeadingWhitespaceTriggers() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("  /")
        XCTAssertTrue(vm.isVisible,
            "'  /' should trigger autocomplete -- slash at start after trimming whitespace")
    }

    // [P1] Text starting with non-slash character does not trigger
    func testNonSlashTextDoesNotTrigger() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("hello")
        XCTAssertFalse(vm.isVisible)
    }

    // [P1] Slash in middle of word does not trigger
    func testSlashInMiddleOfWordDoesNotTrigger() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("hello/world")
        XCTAssertFalse(vm.isVisible,
            "'hello/world' should not trigger -- slash not at line start")
    }

    // MARK: - Edge Cases

    // [P1] Updating query from matching to non-matching dismisses menu
    func testUpdateFromMatchingToNonMatchingDismissesMenu() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("/co")
        XCTAssertTrue(vm.isVisible)

        vm.updateQuery("/xyz")
        XCTAssertTrue(vm.isVisible,
            "Changing from matching to non-matching query should show a no-match state")
        XCTAssertEqual(vm.menuState, .noMatches(query: "xyz"))
    }

    // [P1] Updating query from non-slash to slash triggers menu
    func testUpdateFromNonSlashToSlashTriggersMenu() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("hello")
        XCTAssertFalse(vm.isVisible)

        vm.updateQuery("/")
        XCTAssertTrue(vm.isVisible,
            "Changing to '/' should trigger menu")
    }

    // [P1] Empty skillsSource always shows no menu
    func testEmptySkillsSourceShowsNoMenu() {
        let vm = makeViewModel(skills: [])
        vm.updateQuery("/")
        XCTAssertTrue(vm.isVisible)
        vm.updateQuery("/co")
        XCTAssertTrue(vm.isVisible)
        XCTAssertEqual(vm.menuState, .noAvailableSkills)
    }

    // [P1] Skills with special characters in name are handled
    func testSpecialCharacterSkillNames() {
        let skills = [
            makeSkill(name: "my-skill", description: "Dashed skill"),
            makeSkill(name: "my_skill", description: "Underscored skill"),
        ]
        let vm = makeViewModel(skills: skills)
        vm.updateQuery("/my-")
        XCTAssertTrue(vm.isVisible)
        XCTAssertTrue(vm.filteredSkills.contains(where: { $0.name == "my-skill" }))
    }

    // [P1] selectSkill returns correct skill after filtering
    func testSelectSkillAfterFiltering() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("/re")
        // "review" should match (prefix "re")
        XCTAssertTrue(vm.isVisible)
        let result = vm.selectSkill(at: 0)
        XCTAssertEqual(result, "/review",
            "After filtering to '/re', first match should be '/review'")
    }

    func testRefreshingSkillsSourceWhileSlashMenuActiveShowsNewSkills() {
        let vm = makeViewModel(skills: [])
        vm.updateQuery("/")
        XCTAssertEqual(vm.menuState, .noAvailableSkills)

        vm.updateSkillsSource(sampleSkills, currentText: "/")

        XCTAssertEqual(vm.menuState, .results)
        XCTAssertEqual(vm.filteredSkills.count, sampleSkills.count)
        XCTAssertEqual(vm.selectedIndex, 0)
    }

    func testSlashCommandWithArgumentsStillMatchesCommandToken() {
        let vm = makeViewModel(skills: sampleSkills)
        vm.updateQuery("/commit add release notes")

        XCTAssertEqual(vm.menuState, .results)
        XCTAssertEqual(vm.filteredSkills.map(\.name), ["commit"])
    }
}
