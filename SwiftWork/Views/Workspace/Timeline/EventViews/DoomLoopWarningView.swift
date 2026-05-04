import SwiftUI

enum DoomLoopAction: Sendable {
    case allow
    case stop
}

struct DoomLoopWarningView: View {
    let event: AgentEvent
    let onAction: ((DoomLoopAction) -> Void)?

    @State private var isResolved: Bool

    init(event: AgentEvent, onAction: ((DoomLoopAction) -> Void)? = nil) {
        self.event = event
        self.onAction = onAction
        _isResolved = State(initialValue: event.metadata["resolved"] != nil)
    }

    private var toolName: String {
        event.metadata["toolName"] as? String ?? ""
    }

    private var callCount: Int {
        event.metadata["callCount"] as? Int ?? 3
    }

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(isResolved ? Color.green : Color.orange)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: isResolved ? "checkmark.circle" : "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(isResolved ? .green : .orange)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("检测到死循环")
                                .font(.caption)
                                .fontWeight(.medium)

                            Spacer()

                            Text(isResolved ? "已处理" : "警告")
                                .font(.system(size: 9))
                                .fontWeight(.medium)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background((isResolved ? Color.green : Color.orange).opacity(0.15))
                                .foregroundStyle(isResolved ? .green : .orange)
                                .clipShape(Capsule())
                        }

                        if !isResolved {
                            Text("Agent 使用相同输入重复调用 \(toolName) \(callCount) 次")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text("拒绝以停止循环，或允许 Agent 继续尝试。")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        } else {
                            Text(event.content)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if !isResolved {
                    HStack(spacing: 8) {
                        Button("停止") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isResolved = true
                            }
                            onAction?(.stop)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .foregroundStyle(.red)

                        Spacer()

                        Button("允许继续") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isResolved = true
                            }
                            onAction?(.allow)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(8)
        }
        .background(isResolved ? Color.green.opacity(0.04) : Color.orange.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke((isResolved ? Color.green : Color.orange).opacity(0.3), lineWidth: 1)
        )
    }
}
