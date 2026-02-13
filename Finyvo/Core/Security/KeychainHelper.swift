//
//  KeychainHelper.swift
//  Finyvo
//
//  Created by Moises Núñez on 02/12/26.
//  Utilidad para almacenamiento seguro en Keychain.
//

import Foundation
import Security

// MARK: - Keychain Helper

enum KeychainHelper {

    private static let service = "com.finyvo.app"

    // MARK: - CRUD

    /// Guarda un string en el Keychain
    @discardableResult
    static func saveString(_ value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Eliminar entrada existente primero
        delete(for: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Carga un string del Keychain
    static func loadString(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Elimina una entrada del Keychain
    @discardableResult
    static func delete(for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - FX Token Convenience

    /// Token de API para FinyvoRate
    static var fxToken: String? {
        get { loadString(for: Constants.StorageKeys.fxAPIToken) }
        set {
            if let newValue {
                saveString(newValue, for: Constants.StorageKeys.fxAPIToken)
            } else {
                delete(for: Constants.StorageKeys.fxAPIToken)
            }
        }
    }
}
