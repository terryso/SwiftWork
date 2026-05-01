import SwiftUI

struct SidebarView: View {
    let sessionViewModel: SessionViewModel

    var body: some View {
        Group {
            if sessionViewModel.sessions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("点击 + 创建新会话")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    List(selection: Binding(
                        get: { sessionViewModel.selectedSession?.id },
                        set: { newID in
                            if let newID, let session = sessionViewModel.sessions.first(where: { $0.id == newID }) {
                                sessionViewModel.selectSession(session)
                            }
                        }
                    )) {
                        ForEach(sessionViewModel.sessions) { session in
                            SessionRowView(session: session)
                                .tag(session.id)
                                .id(session.id)
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
        }
        .navigationTitle("SwiftWork")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    sessionViewModel.createSession()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}
