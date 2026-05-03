import Foundation

/// Status of a plan step in its execution lifecycle.
enum PlanStepStatus: String, Sendable, Equatable {
    case pending
    case inProgress
    case completed
    case failed
}

/// A single step within an execution plan, with optional dependencies on other steps.
struct PlanStep: Identifiable, Sendable {
    let id: String
    let description: String
    let status: PlanStepStatus
    let dependencies: [String]

    /// Parses plan text into structured steps.
    /// Attempts numbered list, then markdown list, then returns empty.
    static func parseList(from text: String) -> [PlanStep] {
        var steps: [PlanStep] = []

        // Try numbered list: "1. step" or "1) step"
        let numberedPattern = try? NSRegularExpression(
            pattern: #"^\s*(\d+)[.)]\s+(.+)$"#,
            options: .anchorsMatchLines
        )
        if let regex = numberedPattern {
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, range: range)
            if !matches.isEmpty {
                for (index, match) in matches.enumerated() {
                    if let descRange = Range(match.range(at: 2), in: text) {
                        let desc = String(text[descRange]).trimmingCharacters(in: .whitespaces)
                        let deps: [String] = index > 0 ? ["step-\(index)"] : []
                        steps.append(PlanStep(
                            id: "step-\(index + 1)",
                            description: desc,
                            status: .pending,
                            dependencies: deps
                        ))
                    }
                }
                return steps
            }
        }

        // Try markdown list: "- step" or "* step"
        let markdownPattern = try? NSRegularExpression(
            pattern: #"^\s*[-*]\s+(.+)$"#,
            options: .anchorsMatchLines
        )
        if let regex = markdownPattern {
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, range: range)
            if !matches.isEmpty {
                for (index, match) in matches.enumerated() {
                    if let descRange = Range(match.range(at: 1), in: text) {
                        let desc = String(text[descRange]).trimmingCharacters(in: .whitespaces)
                        let deps: [String] = index > 0 ? ["step-\(index)"] : []
                        steps.append(PlanStep(
                            id: "step-\(index + 1)",
                            description: desc,
                            status: .pending,
                            dependencies: deps
                        ))
                    }
                }
            }
        }

        return steps
    }
}

/// Aggregated plan data containing metadata and an ordered list of steps.
struct PlanData: Sendable {
    let planId: String
    let content: String?
    let approved: Bool
    let steps: [PlanStep]
}
