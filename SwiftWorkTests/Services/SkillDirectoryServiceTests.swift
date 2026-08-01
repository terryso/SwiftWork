import XCTest
import OpenAgentSDK
@testable import SwiftWork

final class SkillDirectoryServiceTests: XCTestCase {
    private var temporaryRoot: URL?

    override func tearDownWithError() throws {
        if let temporaryRoot {
            try? FileManager.default.removeItem(at: temporaryRoot)
        }
        temporaryRoot = nil
    }

    func testCreatesSwiftWorkDirectoryOnDemand() throws {
        let fixture = try makeFixture()
        XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.directories.swiftWork))

        let discoveryDirectories = fixture.service.discoveryDirectories()

        XCTAssertTrue(FileManager.default.fileExists(atPath: fixture.directories.swiftWork))
        XCTAssertEqual(discoveryDirectories, [fixture.directories.swiftWork])
    }

    func testReturnsRootsInPriorityOrderAndSortedNonEmptyPublishers() throws {
        let fixture = try makeFixture()
        try createDirectory(fixture.directories.sharedAgentsConfiguration)
        try createDirectory(fixture.directories.sharedAgents)
        try createSkill(name: "a", description: "A", under: fixture.directories.sharedAgents + "/@z")
        try createSkill(name: "b", description: "B", under: fixture.directories.sharedAgents + "/@a")
        try createDirectory(fixture.directories.sharedAgents + "/@empty")
        try createDirectory(fixture.directories.claudeCode)
        try createDirectory(fixture.directories.codex)
        try createSkill(name: "c", description: "C", under: fixture.directories.swiftWork + "/@publisher")

        XCTAssertEqual(
            fixture.service.discoveryDirectories(),
            [
                fixture.directories.sharedAgentsConfiguration,
                fixture.directories.sharedAgents,
                fixture.directories.sharedAgents + "/@a",
                fixture.directories.sharedAgents + "/@z",
                fixture.directories.claudeCode,
                fixture.directories.codex,
                fixture.directories.swiftWork,
                fixture.directories.swiftWork + "/@publisher",
            ]
        )
    }

    func testDiscoversDirectAndSinglePublisherLayerOnly() throws {
        let fixture = try makeFixture()
        try createSkill(name: "direct", description: "Direct", under: fixture.directories.swiftWork)
        try createSkill(name: "published", description: "Published", under: fixture.directories.swiftWork + "/@p")
        try createSkill(
            name: "too-deep",
            description: "Too deep",
            under: fixture.directories.swiftWork + "/@p/@nested"
        )

        let registry = SkillRegistry()
        registry.registerDiscoveredSkills(from: fixture.service.discoveryDirectories())

        XCTAssertNotNil(registry.find("direct"))
        XCTAssertNotNil(registry.find("published"))
        XCTAssertNil(registry.find("too-deep"))
    }

    func testHigherPriorityRootOverridesSameNamedSkill() throws {
        let fixture = try makeFixture()
        try createSkill(
            name: "duplicate",
            description: "Shared",
            under: fixture.directories.sharedAgentsConfiguration
        )
        try createSkill(
            name: "duplicate",
            description: "Agents",
            under: fixture.directories.sharedAgents
        )
        try createSkill(
            name: "duplicate",
            description: "Claude",
            under: fixture.directories.claudeCode
        )
        try createSkill(
            name: "duplicate",
            description: "Codex",
            under: fixture.directories.codex
        )
        try createSkill(
            name: "duplicate",
            description: "SwiftWork",
            under: fixture.directories.swiftWork
        )

        let registry = SkillRegistry()
        registry.registerDiscoveredSkills(from: fixture.service.discoveryDirectories())

        XCTAssertEqual(registry.find("duplicate")?.description, "SwiftWork")
        XCTAssertTrue(registry.find("duplicate")?.baseDir?.hasPrefix(fixture.directories.swiftWork) == true)
    }

    func testMissingRootsFilesAndEmptyNamespacesAreSkipped() throws {
        let fixture = try makeFixture()
        try createDirectory((fixture.directories.codex as NSString).deletingLastPathComponent)
        try Data("not a directory".utf8).write(to: URL(fileURLWithPath: fixture.directories.codex))
        try createDirectory(fixture.directories.claudeCode + "/@empty")

        let directories = fixture.service.discoveryDirectories()

        XCTAssertFalse(directories.contains(fixture.directories.sharedAgents))
        XCTAssertFalse(directories.contains(fixture.directories.codex))
        XCTAssertFalse(directories.contains(fixture.directories.claudeCode + "/@empty"))
        XCTAssertTrue(directories.contains(fixture.directories.claudeCode))
    }

    private func makeFixture() throws -> (
        service: SkillDirectoryService,
        directories: SkillSourceDirectories
    ) {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("SkillDirectoryServiceTests-\(UUID().uuidString)", isDirectory: true)
        temporaryRoot = root

        let directories = SkillSourceDirectories(
            sharedAgentsConfiguration: root.appendingPathComponent("config-agents").path,
            sharedAgents: root.appendingPathComponent("agents").path,
            claudeCode: root.appendingPathComponent("claude").path,
            codex: root.appendingPathComponent("codex").path,
            swiftWork: root.appendingPathComponent("swiftwork").path
        )
        return (
            SkillDirectoryService(sourceDirectories: directories),
            directories
        )
    }

    private func createDirectory(_ path: String) throws {
        try FileManager.default.createDirectory(
            atPath: path,
            withIntermediateDirectories: true
        )
    }

    private func createSkill(name: String, description: String, under root: String) throws {
        let skillDirectory = (root as NSString).appendingPathComponent(name)
        try createDirectory(skillDirectory)
        let manifest = """
        ---
        name: \(name)
        description: \(description)
        ---
        Execute \(name).
        """
        try Data(manifest.utf8).write(
            to: URL(fileURLWithPath: skillDirectory).appendingPathComponent("SKILL.md")
        )
    }
}
