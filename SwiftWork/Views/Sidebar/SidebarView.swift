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
                List(selection: Binding(
                    get: { sessionViewModel.selectedSession?.id },
                    set: { newID in
                        if let newID {
                            sessionViewModel.selectedSession = sessionViewModel.sessions.first { $0.id == newID }
                        } else {
                            sessionViewModel.selectedSession = nil
                        }
                    }
                )) {
                    ForEach(sessionViewModel.sessions) { session in
                        SessionRowView(session: session)
                            .tag(session.id)
                    }
                }
                .listStyle(.sidebar)
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
