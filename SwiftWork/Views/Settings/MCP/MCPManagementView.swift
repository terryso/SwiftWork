import SwiftUI

struct MCPManagementView: View {
    let store: MCPServerConfigStore
    let agentBridge: AgentBridge?

    @State private var viewModel: MCPManagementViewModel

    init(store: MCPServerConfigStore, agentBridge: AgentBridge?) {
        self.store = store
        self.agentBridge = agentBridge
        self._viewModel = State(initialValue: MCPManagementViewModel(store: store, agentBridge: agentBridge))
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if viewModel.isShowingEmptyState {
                emptyState
            } else {
                serverList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            Task {
                await viewModel.loadServers()
                await viewModel.refreshStatus()
            }
        }
        .sheet(isPresented: $viewModel.showAddSheet, onDismiss: {
            Task { await viewModel.onAddSheetDismiss() }
        }) {
            AddMCPServerSheet(
                store: store,
                scope: .global,
                workspacePath: nil,
                onSave: { _ in }
            )
        }
        .sheet(item: $viewModel.editingConfig, onDismiss: {
            Task { await viewModel.onEditSheetDismiss() }
        }) { config in
            EditMCPServerSheet(
                originalConfig: config,
                store: store,
                scope: .global,
                workspacePath: nil,
                agentBridge: agentBridge,
                onSave: { _ in }
            )
        }
        .confirmationDialog(
            "确认删除 MCP Server",
            isPresented: $viewModel.showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                Task { await viewModel.performDelete() }
            }
            Button("取消", role: .cancel) {
                viewModel.serverToDelete = nil
            }
        } message: {
            if let name = viewModel.serverToDelete {
                Text("确定要删除「\(name)」吗？此操作无法撤销。")
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("MCP Servers")
                .font(.headline)
            Spacer()
            Button {
                viewModel.showAddSheet = true
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Empty State (AC8)

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "powerplug")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("尚未配置 MCP Server")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("点击上方 + 按钮添加 MCP Server。")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Server List

    private var serverList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.servers, id: \.id) { config in
                    let status = viewModel.statusForServer(config)
                    let isSelected = viewModel.selectedServerName == config.name

                    MCPServerRowView(
                        config: config,
                        status: status,
                        isExpanded: isSelected
                    )
                    .padding(.horizontal, 20)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectServer(name: config.name)
                    }

                    if isSelected {
                        MCPServerDetailView(
                            config: config,
                            sdkStatus: viewModel.serverStatuses[config.name],
                            isAgentRunning: agentBridge?.isRunning ?? false,
                            onToggle: {
                                Task {
                                    await viewModel.toggleServer(name: config.name, enabled: !config.enabled)
                                }
                            },
                            onEdit: {
                                viewModel.editingConfig = config
                            },
                            onReconnect: {
                                Task {
                                    await viewModel.reconnectServer(name: config.name)
                                }
                            },
                            onDelete: {
                                viewModel.confirmDelete(name: config.name)
                            }
                        )
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if !isSelected {
                        Divider().padding(.horizontal, 20)
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }
}
