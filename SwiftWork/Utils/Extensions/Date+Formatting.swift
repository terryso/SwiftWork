import Foundation

extension Date {
    nonisolated(unsafe) static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    var relativeFormatted: String {
        Self.relativeFormatter.localizedString(for: self, relativeTo: .now)
    }
}
