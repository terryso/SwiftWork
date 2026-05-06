import Foundation

// MARK: - KeychainManaging Protocol

protocol KeychainManaging: Sendable {
    func save(key: String, data: Data) throws
    func load(key: String) throws -> Data?
    func delete(key: String) throws
}

extension KeychainManaging {
    func saveAPIKey(_ key: String) throws {
        try save(key: KeychainConstants.apiKeyAccount, data: Data(key.utf8))
    }

    func getAPIKey() throws -> String? {
        guard let data = try load(key: KeychainConstants.apiKeyAccount) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func deleteAPIKey() throws {
        try delete(key: KeychainConstants.apiKeyAccount)
    }
}

// MARK: - KeychainManager

/// Legacy name kept for compatibility. Storage is backed by the app sandbox,
/// not the macOS Keychain.
struct KeychainManager: KeychainManaging, Sendable {
    private let service: String
    private let baseDirectory: URL?

    init(service: String = KeychainConstants.service, baseDirectory: URL? = nil) {
        self.service = service
        self.baseDirectory = baseDirectory
    }

    func save(key: String, data: Data) throws {
        var entries = try loadEntries()
        entries[key] = data
        try persist(entries)
    }

    func load(key: String) throws -> Data? {
        let entries = try loadEntries()
        return entries[key]
    }

    func delete(key: String) throws {
        var entries = try loadEntries()
        entries.removeValue(forKey: key)
        try persist(entries)
    }

    private func loadEntries() throws -> [String: Data] {
        let fileURL = try storageFileURL()
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return [:]
        }

        do {
            let data = try Data(contentsOf: fileURL)
            guard !data.isEmpty else { return [:] }

            let propertyList = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            )

            guard let entries = propertyList as? [String: Data] else {
                throw AppError(
                    domain: .data,
                    code: "SANDBOX_STORE_INVALID_FORMAT",
                    message: "Sandbox credential store is corrupted"
                )
            }

            return entries
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError(
                domain: .data,
                code: "SANDBOX_STORE_READ_FAILED",
                message: "Failed to read sandbox credential store",
                underlying: error
            )
        }
    }

    private func persist(_ entries: [String: Data]) throws {
        let fileURL = try storageFileURL()
        let directoryURL = fileURL.deletingLastPathComponent()

        do {
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )

            if entries.isEmpty {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try FileManager.default.removeItem(at: fileURL)
                }
                return
            }

            let data = try PropertyListSerialization.data(
                fromPropertyList: entries,
                format: .binary,
                options: 0
            )
            try data.write(to: fileURL, options: .atomic)
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError(
                domain: .data,
                code: "SANDBOX_STORE_WRITE_FAILED",
                message: "Failed to write sandbox credential store",
                underlying: error
            )
        }
    }

    private func storageFileURL() throws -> URL {
        if let baseDirectory {
            return sanitizedStorageFileURL(in: baseDirectory)
        }

        guard let appSupportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw AppError(
                domain: .data,
                code: "SANDBOX_STORE_DIRECTORY_UNAVAILABLE",
                message: "Application Support directory is unavailable"
            )
        }

        return sanitizedStorageFileURL(in: appSupportDirectory.appendingPathComponent(Constants.appName, isDirectory: true))
    }

    private func sanitizedStorageFileURL(in directory: URL) -> URL {
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-")
        let sanitizedService = String(service.unicodeScalars.map { scalar in
            allowedCharacters.contains(scalar) ? Character(scalar) : "-"
        })
        return directory
            .appendingPathComponent("Secrets", isDirectory: true)
            .appendingPathComponent("\(sanitizedService).plist")
    }
}
