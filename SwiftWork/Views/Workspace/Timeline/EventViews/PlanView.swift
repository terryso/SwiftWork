import SwiftUI

/// Displays an Agent execution plan with steps, status indicators, and dependency visualization.
struct PlanView: View {
    let event: AgentEvent

    @State private var isExpanded = false

    private var planAction: String {
        event.metadata["planAction"] as? String ?? ""
    }

    private var steps: [PlanStep] {
        guard let rawSteps = event.metadata["steps"] as? [[String: any Sendable]] else {
            return PlanStep.parseList(from: event.content)
        }
        return rawSteps.compactMap { raw -> PlanStep? in
            guard let id = raw["id"] as? String,
                  let desc = raw["description"] as? String,
                  let statusStr = raw["status"] as? String,
                  let status = PlanStepStatus(rawValue: statusStr)
            else { return nil }
            let deps = raw["dependencies"] as? [String] ?? []
            return PlanStep(id: id, description: desc, status: status, dependencies: deps)
        }
    }

    private var completedCount: Int {
        steps.filter { $0.status == .completed }.count
    }

    private var summaryText: String {
        if planAction == "enter" {
            return "进入计划模式"
        }
        let total = steps.count
        if total == 0 {
            return "执行计划"
        }
        return "执行计划 (\(total) 步骤, \(completedCount) 完成)"
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.teal)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 0) {
                // Title row (always visible)
                titleRow
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }

                // Expanded step list
                if isExpanded {
                    stepListContent
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(8)
        }
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Title Row

    private var titleRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "list.bullet.clipboard")
                .font(.caption)
                .foregroundStyle(.teal)

            Text(summaryText)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)

            Spacer()

            if !steps.isEmpty {
                Text("\(completedCount)/\(steps.count)")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Step List

    private var stepListContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()

            if steps.isEmpty {
                // Unstructured plan text fallback
                Text(event.content)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            } else {
                ForEach(steps) { step in
                    PlanStepRow(step: step, allSteps: steps)
                }

                // Progress bar
                if !steps.isEmpty {
                    progressBar
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)

                if !steps.isEmpty {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.teal)
                        .frame(
                            width: geo.size.width * CGFloat(completedCount) / CGFloat(steps.count),
                            height: 4
                        )
                }
            }
        }
        .frame(height: 4)
    }
}

// MARK: - PlanStepRow

/// Renders a single plan step with status indicator and dependency indentation.
struct PlanStepRow: View {
    let step: PlanStep
    var allSteps: [PlanStep] = []

    private var indentLevel: Int {
        step.dependencies.isEmpty ? 0 : 1
    }

    var body: some View {
        HStack(spacing: 6) {
            // Dependency indentation
            if indentLevel > 0 {
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(Color.teal.opacity(0.3))
                        .frame(width: 1)
                    Spacer()
                }
                .frame(width: 16)
            }

            // Status icon
            statusIcon

            // Description
            Text(step.description)
                .font(.caption2)
                .foregroundStyle(.primary)
                .lineLimit(2)

            Spacer()
        }
        .padding(.leading, CGFloat(indentLevel) * 16)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch step.status {
        case .pending:
            Image(systemName: "circle")
                .font(.system(size: 10))
                .foregroundStyle(.gray)
        case .inProgress:
            rotatingGear
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 10))
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 10))
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var rotatingGear: some View {
        SwiftUI.TimelineView(.animation) { context in
            let angle = context.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: 1) * 360
            Image(systemName: "gearshape")
                .font(.system(size: 10))
                .foregroundStyle(.blue)
                .rotationEffect(.degrees(angle))
        }
    }
}
