import SwiftUI

struct PermissionDialogView: View {
    let request: PendingPermissionRequest
    let onResult: (PermissionDialogResult) -> Void

    @State private var showFullJSON = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            detailSection
            if showFullJSON {
                jsonSection
            }
            buttonSection
        }
        .padding(20)
        .frame(width: 480)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shield.checkered")
                .font(.title2)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(toolTypeTag)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(Capsule())

                    Text("请求执行操作")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(request.description)
                    .font(.headline)
            }
        }
    }

    // MARK: - Detail

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(request.parameters.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                HStack(alignment: .top) {
                    Text(parameterLabel(key))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 80, alignment: .trailing)
                    Text(String(describing: value))
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - JSON

    private var jsonSection: some View {
        ScrollView {
            Text(formatJSON(request.input))
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        }
        .frame(maxHeight: 150)
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Buttons

    private var buttonSection: some View {
        VStack(spacing: 8) {
            Button {
                showFullJSON.toggle()
            } label: {
                Text(showFullJSON ? "隐藏详细信息" : "显示详细信息")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                Button("拒绝") {
                    onResult(.deny)
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.red)

                Spacer()

                Button("始终允许") {
                    onResult(.alwaysAllow)
                }
                .buttonStyle(.bordered)

                Button("允许一次") {
                    onResult(.allowOnce)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Helpers

    private var toolTypeTag: String {
        request.toolTypeTag
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

    private func formatJSON(_ dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(
            withJSONObject: dict,
            options: [.prettyPrinted, .sortedKeys]
        ) else {
            return String(describing: dict)
        }
        return String(data: data, encoding: .utf8) ?? String(describing: dict)
    }
}
