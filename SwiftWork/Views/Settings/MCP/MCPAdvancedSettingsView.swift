import SwiftUI

struct MCPAdvancedSettingsView: View {
    let configManager: MCPConfigFileManager
    let store: MCPServerConfigStore
    let agentBridge: AgentBridge?

    @State private var isExpanded = false
    @State private var selectedScope: MCPServerScope = .global
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Collapsible header
            headerButton

            // Expandable content
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .alert("刷新配置失败", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("好的", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onDisappear {
            configManager.stopWatching()
        }
        .onChange(of: selectedScope) {
            startFileWatchingIfNeeded()
        }
    }

    // MARK: - Header

    private var headerButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        } label: {
            HStack {
                Image(systemName: "gearshape")
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("高级设置")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Text("管理配置文件")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            // Scope toggle
            scopeToggle

            // Config file path
            configFilePathSection

            // Action buttons
            actionButtons
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Scope Toggle

    private var scopeToggle: some View {
        HStack(spacing: 0) {
            scopeButton(title: "Project", scope: .project, isDisabled: workspacePath == nil)
            scopeButton(title: "Global", scope: .global, isDisabled: false)
        }
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 6))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func scopeButton(title: String, scope: MCPServerScope, isDisabled: Bool) -> some View {
        Button {
            selectedScope = scope
        } label: {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(selectedScope == scope ? Color.accentColor.opacity(0.2) : Color.clear)
                .foregroundStyle(isDisabled ? .tertiary : .primary)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    // MARK: - Config File Path

    private var configFilePathSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("配置文件")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let path = currentPath {
                Text(path)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)

                if !configManager.configFileExists(atPath: path) {
                    Text("文件尚未创建")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            } else {
                Text("Project scope 需要 workspace 路径")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 8) {
            // Reveal in Finder
            Button {
                if let path = currentPath {
                    configManager.revealInFinder(path: path)
                }
            } label: {
                Label("在 Finder 中显示", systemImage: "folder")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .disabled(currentPath == nil || !configManager.configFileExists(atPath: currentPath ?? ""))

            // Refresh config
            Button {
                refreshConfig()
            } label: {
                Label("刷新配置", systemImage: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .onAppear {
            startFileWatchingIfNeeded()
        }
    }

    // MARK: - Computed Properties

    private var workspacePath: String? {
        agentBridge?.activeWorkspaceRoot
    }

    private var currentPath: String? {
        configManager.configFilePath(scope: selectedScope, workspacePath: workspacePath)
    }

    // MARK: - Actions

    // MARK: - File Watching

    private func startFileWatchingIfNeeded() {
        configManager.stopWatching()
        guard let path = currentPath, configManager.configFileExists(atPath: path) else { return }
        configManager.startWatching(path: path) { [store] in
            do {
                try configManager.importFromFile(
                    atPath: path,
                    scope: selectedScope,
                    workspacePath: workspacePath,
                    store: store
                )
                agentBridge?.updateMCPServers()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Actions

    private func refreshConfig() {
        guard let path = currentPath else { return }
        do {
            try configManager.importFromFile(
                atPath: path,
                scope: selectedScope,
                workspacePath: workspacePath,
                store: store
            )
            agentBridge?.updateMCPServers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
