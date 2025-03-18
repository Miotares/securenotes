// DATEI: Services/AuthService.swift
import Foundation
import LocalAuthentication
import Security
import CryptoKit

class AuthService {
    // Keychain-Konstanten
    private enum KeychainKeys {
        static let passwordHash = "com.securenotes.passwordHash"
        static let passwordSalt = "com.securenotes.passwordSalt"
        static let encryptionKey = "com.securenotes.encryptionKey"
        static let service = "SecureNotes"
    }
    
    private let encryptionService: EncryptionService
    
    init(encryptionService: EncryptionService = EncryptionService()) {
        self.encryptionService = encryptionService
        
        // Alle vorhandenen Schlüssel migrieren
        migrateKeychainEntries()
    }
    
    // Migriert Keychain-Einträge zum neuen Format ohne Abfragen
    private func migrateKeychainEntries() {
        // Versuche alle Einträge zu lesen und neu zu speichern
        if let hashData = retrieveLegacyFromKeychain(key: KeychainKeys.passwordHash) {
            _ = saveToKeychainSecurely(data: hashData, key: KeychainKeys.passwordHash)
        }
        
        if let saltData = retrieveLegacyFromKeychain(key: KeychainKeys.passwordSalt) {
            _ = saveToKeychainSecurely(data: saltData, key: KeychainKeys.passwordSalt)
        }
        
        if let keyData = retrieveLegacyFromKeychain(key: KeychainKeys.encryptionKey) {
            _ = saveToKeychainSecurely(data: keyData, key: KeychainKeys.encryptionKey)
        }
    }
    
    // Prüft, ob bereits ein Passwort eingerichtet wurde
    func hasSetupPassword() -> Bool {
        return retrieveFromKeychainSecurely(key: KeychainKeys.passwordHash) != nil &&
               retrieveFromKeychainSecurely(key: KeychainKeys.passwordSalt) != nil
    }
    
    // Richtet ein neues Passwort ein
    func setupPassword(_ password: String) -> Bool {
        guard !password.isEmpty else { return false }
        
        // Generiere Salt
        let salt = encryptionService.generateSalt()
        
        // Berechne Passwort-Hash
        guard let passwordData = password.data(using: .utf8) else { return false }
        let passwordHash = SHA256.hash(data: passwordData + salt)
        let passwordHashData = Data(passwordHash)
        
        // Speichere Hash und Salt im Keychain
        return saveToKeychainSecurely(data: passwordHashData, key: KeychainKeys.passwordHash) &&
               saveToKeychainSecurely(data: salt, key: KeychainKeys.passwordSalt)
    }
    
    // Überprüft ein eingegebenes Passwort
    func verifyPassword(_ password: String) -> Bool {
        guard let storedHashData = retrieveFromKeychainSecurely(key: KeychainKeys.passwordHash),
              let salt = retrieveFromKeychainSecurely(key: KeychainKeys.passwordSalt),
              let passwordData = password.data(using: .utf8) else {
            return false
        }
        
        let inputHash = SHA256.hash(data: passwordData + salt)
        let inputHashData = Data(inputHash)
        
        return storedHashData == inputHashData
    }
    
    // Speichert den Verschlüsselungsschlüssel im Keychain für die Verwendung mit biometrischer Authentifizierung
    func storeKeyInKeychain(_ key: SymmetricKey) -> Bool {
        return saveToKeychainSecurely(data: key.withUnsafeBytes { Data($0) },
                              key: KeychainKeys.encryptionKey)
    }
    
    // Ruft den Verschlüsselungsschlüssel aus dem Keychain ab
    func retrieveKeyFromKeychain() -> SymmetricKey? {
        guard let keyData = retrieveFromKeychainSecurely(key: KeychainKeys.encryptionKey) else {
            return nil
        }
        return SymmetricKey(data: keyData)
    }
    
    // Prüft, ob biometrische Authentifizierung verfügbar ist
    var canUseBiometrics: Bool {
        var error: NSError?
        let context = LAContext()
        
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        return canEvaluate && error == nil &&
               retrieveFromKeychainSecurely(key: KeychainKeys.encryptionKey) != nil
    }
    
    // Führt eine biometrische Authentifizierung durch
    func authenticateWithBiometrics(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        let reason = "Entsperre SecureNotes mit Touch ID"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            completion(success, error)
        }
    }
    
    // MARK: - Keychain-Methoden ohne Authentifizierungsabfragen
    
    // Speichert Daten sicher im Keychain ohne Authentifizierungsabfragen
    private func saveToKeychainSecurely(data: Data, key: String) -> Bool {
        // Lösche eventuell vorhandenen Eintrag
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: KeychainKeys.service
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Erstelle neuen Eintrag mit spezifischen Attributen, um Authentifizierung zu vermeiden
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: KeychainKeys.service,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrIsInvisible as String: true,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUIFail  // Verhindert jegliche UI
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // Liest Daten sicher aus dem Keychain ohne Authentifizierungsabfragen
    private func retrieveFromKeychainSecurely(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: KeychainKeys.service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUIFail  // Verhindert jegliche UI
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        
        return data
    }
    
    // MARK: - Legacy-Methoden (zur Migration alter Einträge)
    
    // Alt: Lesen von Daten im alten Format (mit möglichen Abfragen)
    private func retrieveLegacyFromKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUISkip
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess, let data = item as? Data {
            return data
        }
        
        return nil
    }
}
