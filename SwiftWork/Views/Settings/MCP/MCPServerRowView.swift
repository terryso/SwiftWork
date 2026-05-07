import SwiftUI

struct MCPServerRowView: View {
    let config: MCPServerConfig
    let status: MCPServerDisplayStatus
    let isExpanded: Bool

    var body: some View {
        HStack(spacing: 10) {
            statusDot

            VStack(alignment: .leading, spacing: 2) {
                Text(config.name)
                    .font(.body)
                    .fontWeight(.medium)
                HStack(spacing: 6) {
                    typeTag
                    Text(status.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    // MARK: - Status Dot

    private var statusDot: some View {
        Circle()
            .fill(status.color)
            .frame(width: 8, height: 8)
    }

    // MARK: - Type Tag

    private var typeTag: some View {
        Text(config.transportType == .stdio ? "Local" : "Remote")
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.quaternary, in: Capsule())
    }
}
