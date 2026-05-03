import SwiftUI

/// Debug Panel with three tabs: Raw Event Stream, Token Statistics, Tool Logs.
struct DebugView: View {
    let debugViewModel: DebugViewModel

    @State private var selectedTab: DebugTab = .rawEvents

    private enum DebugTab: String, CaseIterable {
        case rawEvents = "事件流"
        case tokenStats = "Token"
        case toolLogs = "工具日志"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("Debug Tab", selection: $selectedTab) {
                ForEach(DebugTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            Divider()

            // Tab content
            Group {
                switch selectedTab {
                case .rawEvents:
                    RawEventStreamView(debugViewModel: debugViewModel)
                case .tokenStats:
                    TokenStatsView(debugViewModel: debugViewModel)
                case .toolLogs:
                    ToolLogListView(debugViewModel: debugViewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Shared Empty State

struct DebugEmptyStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
