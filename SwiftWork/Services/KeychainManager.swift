import Foundation
import Security

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

struct KeychainManager: KeychainManaging, Sendable {
    private let service: String

    init(service: String = KeychainConstants.service) {
        self.service = service
    }

    // MARK: - Core CRUD

    func save(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let attributes: [String: Any] = query.merging([
            kSecValueData as String: data
        ]) { _, new in new }

        // Try to add first; if item exists, update it
        let addStatus = SecItemAdd(attributes as CFDictionary, nil)

        if addStatus == errSecDuplicateItem {
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]
            let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)

            guard updateStatus == errSecSuccess else {
                throw AppError(
                    domain: .security,
                    code: "KEYCHAIN_SAVE_FAILED",
                    message: "Failed to update existing Keychain item",
                    underlying: NSError(domain: "com.swiftwork.keychain", code: Int(updateStatus), userInfo: [
                        NSLocalizedDescriptionKey: "SecItemUpdate failed with OSStatus \(updateStatus)"
                    ])
                )
            }
            return
        }

        guard addStatus == errSecSuccess else {
            throw AppError(
                domain: .security,
                code: "KEYCHAIN_SAVE_FAILED",
                message: "Failed to save to Keychain",
                underlying: NSError(domain: "com.swiftwork.keychain", code: Int(addStatus), userInfo: [
                    NSLocalizedDescriptionKey: "SecItemAdd failed with OSStatus \(addStatus)"
                ])
            )
        }
    }

    func load(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw AppError(
                domain: .security,
                code: "KEYCHAIN_LOAD_FAILED",
                message: "Failed to load from Keychain",
                underlying: NSError(domain: "com.swiftwork.keychain", code: Int(status), userInfo: [
                    NSLocalizedDescriptionKey: "SecItemCopyMatching failed with OSStatus \(status)"
                ])
            )
        }

        return result as? Data
    }

    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecItemNotFound {
            return
        }

        guard status == errSecSuccess else {
            throw AppError(
                domain: .security,
                code: "KEYCHAIN_DELETE_FAILED",
                message: "Failed to delete from Keychain",
                underlying: NSError(domain: "com.swiftwork.keychain", code: Int(status), userInfo: [
                    NSLocalizedDescriptionKey: "SecItemDelete failed with OSStatus \(status)"
                ])
            )
        }
    }

}
