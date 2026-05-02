import Foundation
import SwiftData
import Observation

enum GlobalPermissionMode: String, Sendable, Equatable {
    case autoApprove
    case manualReview
    case denyAll
}

@MainActor
@Observable
final class PermissionHandler {

    var globalMode: GlobalPermissionMode = .autoApprove

    var auditLog: [PermissionAuditEntry] = []

    @ObservationIgnored
    private var sessionOverrides: [String: PermissionDecision] = [:]

    @ObservationIgnored
    private var modelContext: ModelContext?

    @ObservationIgnored
    private var cachedRules: [PermissionRule] = []

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        reloadRules()
    }

    func reloadRules() {
        guard let modelContext else {
            cachedRules = []
            return
        }
        let descriptor = FetchDescriptor<PermissionRule>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        cachedRules = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Evaluate

    func evaluate(toolName: String, input: [String: Any]) -> PermissionDecision {
        let decision: PermissionDecision

        switch globalMode {
        case .autoApprove:
            decision = .approved
        case .denyAll:
            decision = .denied(reason: "全部拒绝模式")
        case .manualReview:
            decision = evaluateManualReview(toolName: toolName, input: input)
        }

        let isSessionOverride = sessionOverrides[toolName] != nil
        let isApproved: Bool
        if case .approved = decision {
            isApproved = true
        } else {
            isApproved = false
        }
        let auditEntry = PermissionAuditEntry(
            toolName: toolName,
            input: describeInput(input),
            decision: simplifyDecision(decision),
            timestamp: .now,
            sessionOverride: isSessionOverride && isApproved
        )
        auditLog.append(auditEntry)

        return decision
    }

    // MARK: - Session Overrides

    func addSessionOverride(toolName: String, decision: PermissionDecision) {
        sessionOverrides[toolName] = decision
    }

    func clearSessionOverrides() {
        sessionOverrides.removeAll()
    }

    // MARK: - Persistent Rules

    @discardableResult
    func addPersistentRule(toolName: String, pattern: String, decision: Decision) -> Bool {
        let rule = PermissionRule(toolName: toolName, pattern: pattern, decision: decision)
        cachedRules.insert(rule, at: 0)

        guard let modelContext else { return false }
        modelContext.insert(rule)
        try? modelContext.save()
        return true
    }

    // MARK: - Private Helpers

    private func evaluateManualReview(toolName: String, input: [String: Any]) -> PermissionDecision {
        if let matchedRule = matchRule(toolName: toolName, input: input, rules: cachedRules) {
            switch matchedRule.decision {
            case .allow:
                return .approved
            case .deny:
                return .denied(reason: "规则拒绝: \(toolName)")
            }
        }

        if let override = sessionOverrides[toolName] {
            return override
        }

        let description = Self.toolTypeLabel(toolName)
        let parameters = Self.extractKeyParameters(input)
        return .requiresApproval(
            toolName: toolName,
            description: description,
            parameters: parameters
        )
    }

    private func matchRule(toolName: String, input: [String: Any], rules: [PermissionRule]) -> PermissionRule? {
        rules.first { rule in
            rule.toolName == toolName && matchesPattern(rule.pattern, input: input)
        }
    }

    private func matchesPattern(_ pattern: String, input: [String: Any]) -> Bool {
        if pattern == "*" { return true }

        // Remove trailing wildcard for prefix matching
        let prefixPattern: String
        if pattern.hasSuffix("*") {
            prefixPattern = String(pattern.dropLast()).trimmingCharacters(in: .whitespaces)
        } else {
            prefixPattern = pattern
        }

        let matchableKeys: Set<String> = ["command", "filePath", "filepath", "path", "cwd", "pattern", "query", "description"]
        for key in matchableKeys {
            if let value = input[key] {
                let stringValue = String(describing: value)
                if stringValue.hasPrefix(prefixPattern) {
                    return true
                }
            }
        }
        return false
    }

    private func describeInput(_ input: [String: Any]) -> String {
        let keys = ["command", "filePath", "path", "filepath", "pattern", "query", "description"]
        for key in keys {
            if let value = input[key] {
                return String(describing: value)
            }
        }
        if let first = input.values.first {
            return String(describing: first)
        }
        return ""
    }

    private func simplifyDecision(_ decision: PermissionDecision) -> PermissionAuditEntry.AuditDecision {
        switch decision {
        case .approved:
            return .approved
        case .denied:
            return .denied
        case .requiresApproval:
            return .denied
        }
    }
}

// MARK: - Tool Type Helpers

extension PermissionHandler {
    static func toolTypeLabel(_ toolName: String) -> String {
        switch toolName {
        case "Bash": return "终端命令"
        case "Edit", "Write": return "文件编辑"
        case "Read": return "文件读取"
        case "Grep", "Glob": return "文件搜索"
        default: return toolName
        }
    }

    static func extractKeyParameters(_ input: [String: Any]) -> [String: any Sendable] {
        let priorityKeys = ["command", "description", "cwd", "filePath", "path", "filepath", "pattern", "query"]
        var result: [String: any Sendable] = [:]
        for key in priorityKeys {
            if let value = input[key] {
                result[key] = String(describing: value)
            }
        }
        return result
    }
}
