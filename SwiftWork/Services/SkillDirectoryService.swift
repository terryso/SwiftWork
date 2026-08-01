import Foundation

struct SkillDirectoryService {
    let sourceDirectories: SkillSourceDirectories

    private let fileManager: FileManager
    private let skillHubExecutableCandidates: [String]

    init(
        sourceDirectories: SkillSourceDirectories = .userDefaults(),
        fileManager: FileManager = .default,
        skillHubExecutableCandidates: [String]? = nil
    ) {
        self.sourceDirectories = sourceDirectories
        self.fileManager = fileManager
        self.skillHubExecutableCandidates = skillHubExecutableCandidates
            ?? Self.defaultSkillHubExecutableCandidates()
    }

    var installationDirectory: String {
        sourceDirectories.swiftWork
    }

    var skillHubCommand: String {
        guard let executable = skillHubExecutableCandidates.first(where: {
            fileManager.isExecutableFile(atPath: normalize($0))
        }) else {
            return "skillhub"
        }

        return shellQuoted(normalize(executable))
    }

    func discoveryDirectories() -> [String] {
        ensureInstallationDirectoryExists()

        let roots = [
            sourceDirectories.sharedAgentsConfiguration,
            sourceDirectories.sharedAgents,
            sourceDirectories.claudeCode,
            sourceDirectories.codex,
            sourceDirectories.swiftWork,
        ]

        var result: [String] = []
        var seenPaths = Set<String>()

        for root in roots {
            let normalizedRoot = normalize(root)
            guard isReadableDirectory(normalizedRoot) else { continue }
            append(normalizedRoot, to: &result, seenPaths: &seenPaths)

            for namespace in publisherNamespaces(in: normalizedRoot) {
                append(namespace, to: &result, seenPaths: &seenPaths)
            }
        }

        return result
    }

    private func ensureInstallationDirectoryExists() {
        let path = normalize(installationDirectory)
        guard !fileManager.fileExists(atPath: path) else { return }
        try? fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
    }

    private func publisherNamespaces(in root: String) -> [String] {
        guard let entries = try? fileManager.contentsOfDirectory(atPath: root) else {
            return []
        }

        return entries
            .filter { $0.hasPrefix("@") && $0.count > 1 }
            .sorted()
            .compactMap { entry -> String? in
                let namespace = (root as NSString).appendingPathComponent(entry)
                guard isReadableDirectory(namespace), containsSkillPackage(namespace) else {
                    return nil
                }
                return normalize(namespace)
            }
    }

    private func containsSkillPackage(_ namespace: String) -> Bool {
        guard let entries = try? fileManager.contentsOfDirectory(atPath: namespace) else {
            return false
        }

        return entries.contains { entry in
            let skillDirectory = (namespace as NSString).appendingPathComponent(entry)
            guard isReadableDirectory(skillDirectory) else { return false }
            let manifest = (skillDirectory as NSString).appendingPathComponent("SKILL.md")
            var isDirectory: ObjCBool = false
            return fileManager.fileExists(atPath: manifest, isDirectory: &isDirectory)
                && !isDirectory.boolValue
                && fileManager.isReadableFile(atPath: manifest)
        }
    }

    private func isReadableDirectory(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
            && isDirectory.boolValue
            && fileManager.isReadableFile(atPath: path)
    }

    private func normalize(_ path: String) -> String {
        (path as NSString).standardizingPath
    }

    private func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private static func defaultSkillHubExecutableCandidates() -> [String] {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            (homeDirectory as NSString).appendingPathComponent(".local/bin/skillhub"),
            "/opt/homebrew/bin/skillhub",
            "/usr/local/bin/skillhub",
        ]
    }

    private func append(
        _ path: String,
        to result: inout [String],
        seenPaths: inout Set<String>
    ) {
        guard seenPaths.insert(path).inserted else { return }
        result.append(path)
    }
}
