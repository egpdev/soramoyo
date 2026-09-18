import Foundation
import Security

enum KeychainStore {
    private static let service = "local.aura.weather"
    private static let account = "gemini-api-key"

    static func saveGeminiKey(_ key: String) throws {
        let data = Data(key.utf8)
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query.merging([kSecValueData as String: data]) { _, new in new } as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.saveFailed(status) }
    }

    static func geminiKey() -> String? {
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query.merging([kSecReturnData as String: true]) { _, new in new } as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func hasGeminiKey() -> Bool {
        var result: CFTypeRef?
        let status = SecItemCopyMatching(
            query.merging([kSecReturnAttributes as String: true]) { _, new in new } as CFDictionary,
            &result
        )
        return status == errSecSuccess
    }

    private static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
    }

    enum KeychainError: LocalizedError {
        case saveFailed(OSStatus)
        var errorDescription: String? { "Couldn’t save the key to macOS Keychain." }
    }
}
