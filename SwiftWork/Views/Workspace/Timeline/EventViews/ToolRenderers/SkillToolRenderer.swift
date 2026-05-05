import SwiftUI

struct SkillToolRenderer: ToolRenderable {
    static let toolName = "Skill"
    static let accentColor: Color = .purple
    static let icon: String = "sparkles"

    @MainActor
    func body(content: ToolContent) -> any View {
        SkillToolExpandedContent(content: content)
    }

    func summaryTitle(content: ToolContent) -> String {
        guard let skillName = parseField("skill", from: content.input) else {
            return "Skill"
        }
        return "/\(skillName)"
    }

    func subtitle(content: ToolContent) -> String? {
        guard let args = parseField("args", from: content.input), !args.isEmpty else {
            return nil
        }
        return String(args.prefix(80))
    }

    private func parseField(_ field: String, from input: String) -> String? {
        guard !input.isEmpty,
              let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return json[field] as? String
    }
}

// MARK: - Expanded Content View

private struct SkillToolExpandedContent: View {
    let content: ToolContent

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                // Header with skill name
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(skillDisplayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }

                // Args subtitle
                if let args = skillArgs {
                    Text(args)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                // Status-dependent content
                statusContent
            }
            Spacer()
        }
        .padding(8)
        .background(.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var statusContent: some View {
        switch content.status {
        case .pending:
            HStack(spacing: 4) {
                ProgressView()
                    .controlSize(.mini)
                Text("Executing...")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case .running:
            HStack(spacing: 4) {
                ProgressView()
                    .controlSize(.mini)
                Text("Running...")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case .completed:
            completedContent
        case .failed:
            failedContent
        }
    }

    @ViewBuilder
    private var completedContent: some View {
        if let output = content.output, !output.isEmpty {
            if let result = parseOutputJSON(output) {
                // Parsed JSON output
                HStack(spacing: 4) {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(result.success ? .green : .red)
                    if let commandName = result.commandName {
                        Text(commandName)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                }
                if let prompt = result.promptSummary {
                    Text(prompt)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            } else {
                // Non-JSON output: display raw text
                Text(output)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
    }

    @ViewBuilder
    private var failedContent: some View {
        HStack(spacing: 4) {
            Image(systemName: "xmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.red)
            if let output = content.output, !output.isEmpty {
                Text(output.prefix(200))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            } else {
                Text("Failed")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Helpers

    private var skillDisplayName: String {
        guard let skillName = parseFieldFromInput("skill") else {
            return "Skill"
        }
        return "/\(skillName)"
    }

    private var skillArgs: String? {
        guard let args = parseFieldFromInput("args"), !args.isEmpty else {
            return nil
        }
        return String(args.prefix(80))
    }

    private func parseFieldFromInput(_ field: String) -> String? {
        guard !content.input.isEmpty,
              let data = content.input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return json[field] as? String
    }

    private func parseOutputJSON(_ output: String) -> SkillResultData? {
        guard !output.isEmpty,
              let data = output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        let success = json["success"] as? Bool ?? true
        let commandName = json["commandName"] as? String
        let prompt = json["prompt"] as? String

        return SkillResultData(
            success: success,
            commandName: commandName,
            promptSummary: prompt.map { String($0.prefix(200)) }
        )
    }
}

private struct SkillResultData {
    let success: Bool
    let commandName: String?
    let promptSummary: String?
}
