import Foundation
import SwiftData
import AppKit

@MainActor
@Observable
final class AppStateManager {
    static let lastActiveSessionIDKey = AppStateKeys.lastActiveSessionID
    static let windowFrameKey = AppStateKeys.windowFrame
    static let inspectorVisibleKey = AppStateKeys.inspectorVisible

    private var modelContext: ModelContext?

    var lastActiveSessionID: UUID?
    var windowFrame: NSRect?
    var isInspectorVisible: Bool = false

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadAppState() {
        lastActiveSessionID = loadUUID(key: Self.lastActiveSessionIDKey)
        windowFrame = loadNSRect(key: Self.windowFrameKey)
        isInspectorVisible = loadBool(key: Self.inspectorVisibleKey)
    }

    func saveLastActiveSessionID(_ id: UUID?) {
        if let id {
            saveString(id.uuidString, forKey: Self.lastActiveSessionIDKey)
        } else {
            removeValue(forKey: Self.lastActiveSessionIDKey)
        }
        lastActiveSessionID = id
    }

    func saveWindowFrame(_ frame: NSRect) {
        let string = NSStringFromRect(frame)
        saveString(string, forKey: Self.windowFrameKey)
        windowFrame = frame
    }

    func saveInspectorVisibility(_ visible: Bool) {
        saveString(visible ? "true" : "false", forKey: Self.inspectorVisibleKey)
        isInspectorVisible = visible
    }

    // MARK: - Private Helpers

    private func saveString(_ string: String, forKey key: String) {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate<AppConfiguration> { $0.key == key }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.value = Data(string.utf8)
            existing.updatedAt = .now
        } else {
            let config = AppConfiguration(key: key, value: Data(string.utf8))
            modelContext.insert(config)
        }
        try? modelContext.save()
    }

    private func loadString(forKey key: String) -> String? {
        guard let modelContext else { return nil }
        let descriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate<AppConfiguration> { $0.key == key }
        )
        guard let config = try? modelContext.fetch(descriptor).first,
              let value = String(data: config.value, encoding: .utf8) else {
            return nil
        }
        return value
    }

    private func removeValue(forKey key: String) {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate<AppConfiguration> { $0.key == key }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
            try? modelContext.save()
        }
    }

    private func loadUUID(key: String) -> UUID? {
        guard let string = loadString(forKey: key) else { return nil }
        return UUID(uuidString: string)
    }

    private func loadNSRect(key: String) -> NSRect? {
        guard let string = loadString(forKey: key), !string.isEmpty else { return nil }
        let rect = NSRectFromString(string)
        // NSRectFromString returns zero rect for invalid strings;
        // treat zero rect as nil (no saved state)
        if rect == .zero { return nil }
        return rect
    }

    private func loadBool(key: String) -> Bool {
        guard let string = loadString(forKey: key) else { return false }
        return string == "true"
    }
}
