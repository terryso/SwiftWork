import SwiftUI

struct SidebarView: View {
    let sessionViewModel: SessionViewModel

    @State private var sessionToDelete: Session?
    @State private var renamingSessionID: UUID?
    @State private var renameText: String = ""

    var body: some View {
        Group {
            if sessionViewModel.sessions.isEmpty {
                emptyStateView
            } else {
                sessionListView
            }
        }
        .navigationTitle("SwiftWork")
        .toolbar { toolbarContent }
        .alert("删除会话", isPresented: Binding(
            get: { sessionToDelete != nil },
            set: { if !$0 { sessionToDelete = nil } }
        )) {
            Button("取消", role: .cancel) {
                sessionToDelete = nil
            }
            Button("删除", role: .destructive) {
                if let session = sessionToDelete {
                    sessionViewModel.deleteSession(session)
                    sessionToDelete = nil
                }
            }
        } message: {
            if let session = sessionToDelete {
                Text("确定要删除「\(session.title)」吗？此操作不可撤销。")
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("点击 + 创建新会话")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sessionListView: some View {
        ScrollViewReader { proxy in
            List(selection: sessionSelection) {
                ForEach(sessionViewModel.sessions) { session in
                    sessionRow(for: session)
                }
            }
            .listStyle(.sidebar)
            .onChange(of: sessionViewModel.selectedSession?.id) { _, newID in
                if let newID {
                    withAnimation {
                        proxy.scrollTo(newID, anchor: .top)
                    }
                }
            }
        }
    }

    private var sessionSelection: Binding<UUID?> {
        Binding(
            get: { sessionViewModel.selectedSession?.id },
            set: { newID in
                if let newID, let session = sessionViewModel.sessions.first(where: { $0.id == newID }) {
                    sessionViewModel.selectSession(session)
                }
            }
        )
    }

    @ViewBuilder
    private func sessionRow(for session: Session) -> some View {
        SessionRowView(
            session: session,
            isRenaming: renamingSessionID == session.id,
            renameText: $renameText,
            onCommitRename: { commitRename(for: session) },
            onCancelRename: { cancelRename() }
        )
        .tag(session.id)
        .id(session.id)
        .contextMenu {
            Button {
                startRenaming(session)
            } label: {
                Label("重命名", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) {
                sessionToDelete = session
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                sessionViewModel.createSession()
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    private func startRenaming(_ session: Session) {
        renameText = session.title
        renamingSessionID = session.id
    }

    private func commitRename(for session: Session) {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            sessionViewModel.updateSessionTitle(session, title: trimmed)
        }
        renamingSessionID = nil
        renameText = ""
    }

    private func cancelRename() {
        renamingSessionID = nil
        renameText = ""
    }
}
