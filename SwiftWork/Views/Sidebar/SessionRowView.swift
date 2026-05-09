import SwiftUI

struct SessionRowView: View {
    let session: Session
    let isRenaming: Bool
    @Binding var renameText: String
    let onCommitRename: () -> Void
    let onCancelRename: () -> Void

    @FocusState private var isRenameFocused: Bool

    init(session: Session) {
        self.session = session
        self.isRenaming = false
        self._renameText = .constant("")
        self.onCommitRename = {}
        self.onCancelRename = {}
    }

    init(
        session: Session,
        isRenaming: Bool,
        renameText: Binding<String>,
        onCommitRename: @escaping () -> Void,
        onCancelRename: @escaping () -> Void
    ) {
        self.session = session
        self.isRenaming = isRenaming
        self._renameText = renameText
        self.onCommitRename = onCommitRename
        self.onCancelRename = onCancelRename
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if isRenaming {
                TextField("会话名称", text: $renameText)
                    .lineLimit(1)
                    .font(.body)
                    .focused($isRenameFocused)
                    .onSubmit {
                        onCommitRename()
                    }
                    .onExitCommand {
                        onCancelRename()
                    }
            } else {
                Text(session.title)
                    .lineLimit(1)
                    .font(.body)
            }
            if let workspacePath = session.workspacePath, !workspacePath.isEmpty {
                let displayPath = (workspacePath as NSString).abbreviatingWithTildeInPath
                Text(displayPath)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .accessibilityLabel("工作目录: \(workspacePath)")
            }
            Text(session.updatedAt.relativeFormatted)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .onChange(of: isRenaming) { _, newValue in
            if newValue {
                isRenameFocused = true
            }
        }
    }
}
