import Foundation
import SwiftData

@Model
final class AppConfiguration {
    @Attribute(.unique) var id: UUID
    var key: String
    var value: Data
    var updatedAt: Date

    init(
        key: String,
        value: Data
    ) {
        self.id = UUID()
        self.key = key
        self.value = value
        self.updatedAt = Date.now
    }
}
