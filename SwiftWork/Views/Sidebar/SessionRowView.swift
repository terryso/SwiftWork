import SwiftUI

struct SessionRowView: View {
    let session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(session.title)
                .lineLimit(1)
                .font(.body)
            Text(session.updatedAt.relativeFormatted)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
