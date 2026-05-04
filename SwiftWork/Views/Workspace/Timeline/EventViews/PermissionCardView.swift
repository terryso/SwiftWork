import SwiftUI

enum PermissionCardState: Equatable {
    case pending
    case approved
    case denied
}

struct PermissionCardView: View {
    let event: AgentEvent
    let onResult: ((PermissionDialogResult) -> Void)?

    @State private var cardState: PermissionCardState
    @State private var showDetails = false

    init(event: AgentEvent, onResult: ((PermissionDialogResult) -> Void)? = nil) {
        self.event = event
        self.onResult = onResult
        _cardState = State(initialValue: event.metadata["resolved"] != nil ? .denied : .pending)
    }

    private var toolName: String {
        event.metadata["toolName"] as? String ?? ""
    }

    private var toolTypeTag: String {
        PermissionHandler.toolTypeLabel(toolName)
    }

    private var parameters: [String: any Sendable] {
        (event.metadata["parameters"] as? [String: any Sendable]) ?? [:]
    }

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 0) {
                titleRow

                if cardState == .pending {
                    parameterSection
                    actionButtons
                } else {
                    resolvedSummary
                }
            }
            .padding(8)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    // MARK: - Title Row

    private var titleRow: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: cardState == .pending ? "exclamationmark.shield" : resolvedIcon)
                .font(.caption)
                .foregroundStyle(accentColor)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(toolTypeTag)
                        .font(.caption)
                        .fontWeight(.medium)

                    Spacer()

                    Text(statusLabel)
                        .font(.system(size: 9))
                        .fontWeight(.medium)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(statusColor.opacity(0.15))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())
                }

                Text(event.content)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    // MARK: - Parameters

    private var parameterSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(parameters.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                HStack(alignment: .top) {
                    Text(parameterLabel(key))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .frame(width: 60, alignment: .trailing)
                    Text(String(describing: value))
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(.top, 6)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button("拒绝") {
                resolve(.deny)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .foregroundStyle(.red)

            Spacer()

            Button("本会话允许") {
                resolve(.alwaysAllow)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button("允许一次") {
                resolve(.allowOnce)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.top, 8)
    }

    // MARK: - Resolved Summary

    private var resolvedSummary: some View {
        HStack(spacing: 4) {
            Text(cardState == .approved ? "已批准" : "已拒绝")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 2)
    }

    // MARK: - Helpers

    private var accentColor: Color {
        switch cardState {
        case .pending: return .orange
        case .approved: return .green
        case .denied: return .red
        }
    }

    private var statusColor: Color { accentColor }

    private var statusLabel: String {
        switch cardState {
        case .pending: return "待审批"
        case .approved: return "已批准"
        case .denied: return "已拒绝"
        }
    }

    private var resolvedIcon: String {
        cardState == .approved ? "checkmark.shield" : "xmark.shield"
    }

    private var cardBackground: some ShapeStyle {
        switch cardState {
        case .pending: return AnyShapeStyle(Color.orange.opacity(0.06))
        case .approved: return AnyShapeStyle(Color.green.opacity(0.06))
        case .denied: return AnyShapeStyle(Color.red.opacity(0.06))
        }
    }

    private var borderColor: Color {
        accentColor.opacity(0.3)
    }

    private func parameterLabel(_ key: String) -> String {
        switch key {
        case "command": return "命令"
        case "filePath", "filepath", "path": return "文件路径"
        case "cwd": return "工作目录"
        case "pattern": return "匹配模式"
        case "query": return "查询"
        case "description": return "描述"
        default: return key
        }
    }

    private func resolve(_ result: PermissionDialogResult) {
        withAnimation(.easeInOut(duration: 0.2)) {
            cardState = result == .deny ? .denied : .approved
        }
        onResult?(result)
    }
}
