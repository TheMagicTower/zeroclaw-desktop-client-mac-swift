import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()

    private let service = "com.themagictower.ZeroClawDesktop"

    private enum Key {
        static let bearerToken = "bearer_token"
    }

    // MARK: - Legacy single-connection (used for migration only)

    func saveToken(_ token: String) {
        save(token, forKey: Key.bearerToken)
    }

    func loadToken() -> String? {
        load(forKey: Key.bearerToken)
    }

    func deleteToken() {
        delete(forKey: Key.bearerToken)
    }

    // MARK: - Per-profile tokens

    func saveToken(_ token: String, for profileID: UUID) {
        save(token, forKey: "token_\(profileID.uuidString)")
    }

    func loadToken(for profileID: UUID) -> String? {
        load(forKey: "token_\(profileID.uuidString)")
    }

    func deleteToken(for profileID: UUID) {
        delete(forKey: "token_\(profileID.uuidString)")
    }

    // MARK: - Private

    private func save(_ value: String, forKey key: String) {
        let data = Data(value.utf8)

        // Permissive ACL: nil trusted-app list = any application may access without prompting.
        // This is safe for a personal desktop app; avoids repeated keychain prompts caused
        // by ad-hoc code signing changing the app identity on every build.
        var accessRef: SecAccess?
        SecAccessCreate(service as CFString, nil, &accessRef)

        let deleteQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // kSecAttrAccess and kSecAttrAccessible are mutually exclusive on macOS.
        var addQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecValueData: data
        ]
        if let accessRef { addQuery[kSecAttrAccess] = accessRef }
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private func load(forKey key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(forKey key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
