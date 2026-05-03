import SwiftUI

// MARK: - Type-Specific Event Detail Sections
// Extracted from InspectorView to keep it under 300 lines.

extension InspectorView {

    @ViewBuilder
    func toolEventSection(event: AgentEvent) -> some View {
        let toolUseId = event.metadata["toolUseId"] as? String ?? ""
        if let content = toolContentMap[toolUseId] {
            // Tool name
            labeledRow("工具", value: content.toolName)

            // Status
            labeledRow("状态", value: statusText(content.status))

            // Elapsed time
            if let elapsed = content.elapsedTimeSeconds {
                labeledRow("耗时", value: "\(elapsed)s")
            }

            // Input
            if !content.input.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("参数")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        CopyButton(text: content.input)
                    }
                    Text(content.input)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            // Output
            if let output = content.output, !output.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("输出")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        CopyButton(text: output)
                    }
                    Text(output)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(content.isError ? .red : .secondary)
                        .textSelection(.enabled)
                }
            }
        } else {
            // No matching ToolContent — show available metadata
            if let toolName = event.metadata["toolName"] as? String {
                labeledRow("工具", value: toolName)
            }
            if let input = event.metadata["input"] as? String, !input.isEmpty {
                labeledRow("参数", value: input)
            }
        }
    }

    @ViewBuilder
    func resultEventSection(event: AgentEvent) -> some View {
        if let durationMs = event.metadata["durationMs"] as? Int {
            let seconds = Double(durationMs) / 1000.0
            labeledRow("耗时", value: String(format: "%.1fs", seconds))
        }

        if let cost = event.metadata["totalCostUsd"] as? Double {
            labeledRow("费用", value: String(format: "$%.4f", cost))
        }

        if let numTurns = event.metadata["numTurns"] as? Int {
            labeledRow("Turn 数", value: "\(numTurns)")
        }

        if let usage = event.metadata["usage"] as? [String: Any] {
            VStack(alignment: .leading, spacing: 2) {
                Text("Token 用量")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let input = usage["inputTokens"] as? Int {
                    Text("  Input: \(input)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let output = usage["outputTokens"] as? Int {
                    Text("  Output: \(output)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }

        if let breakdown = event.metadata["costBreakdown"] as? [String: Any] {
            if let data = try? JSONSerialization.data(
                withJSONObject: breakdown,
                options: [.prettyPrinted, .sortedKeys]
            ),
               let str = String(data: data, encoding: .utf8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("费用明细")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(str)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
    }

    @ViewBuilder
    func assistantEventSection(event: AgentEvent) -> some View {
        if let model = event.metadata["model"] as? String {
            labeledRow("模型", value: model)
        }
        if let stopReason = event.metadata["stopReason"] as? String {
            labeledRow("停止原因", value: stopReason)
        }
    }

    @ViewBuilder
    func systemEventSection(event: AgentEvent) -> some View {
        if let subtype = event.metadata["subtype"] as? String {
            labeledRow("子类型", value: subtype)
        }
        if let sessionId = event.metadata["sessionId"] as? String {
            labeledRow("Session ID", value: sessionId)
        }
    }

    @ViewBuilder
    func genericMetadataSection(event: AgentEvent) -> some View {
        ForEach(Array(event.metadata.keys.sorted()), id: \.self) { key in
            if let value = event.metadata[key] {
                labeledRow(key, value: String(describing: value))
            }
        }
    }
}
