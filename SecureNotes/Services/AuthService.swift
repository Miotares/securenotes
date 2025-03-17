// Ordner: Services/AuthService.swift
import Foundation
import LocalAuthentication
import Security
import CryptoKit  // Wichtiger Import für SymmetricKey

class AuthService {
    // Keychain-Konstanten
    private enum KeychainKeys {
        static let passwordHash = "com.securenotes.passwordHash"
        static let passwordSalt = "com.securenotes.passwordSalt"
        static let encryptionKey = "com.securenotes.encryptionKey"
    }
    
    private let encryptionService: EncryptionService
    
    init(encryptionService: EncryptionService = EncryptionService()) {
        self.encryptionService = encryptionService
    }
    
    // Prüft, ob bereits ein Passwort eingerichtet wurde
    func hasSetupPassword() -> Bool {
        return retrieveFromKeychain(key: KeychainKeys.passwordHash) != nil &&
               retrieveFromKeychain(key: KeychainKeys.passwordSalt) != nil
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
        return saveToKeychain(data: passwordHashData, key: KeychainKeys.passwordHash) &&
               saveToKeychain(data: salt, key: KeychainKeys.passwordSalt)
    }
    
    // Überprüft ein eingegebenes Passwort
    func verifyPassword(_ password: String) -> Bool {
        guard let storedHashData = retrieveFromKeychain(key: KeychainKeys.passwordHash),
              let salt = retrieveFromKeychain(key: KeychainKeys.passwordSalt),
              let passwordData = password.data(using: .utf8) else {
            return false
        }
        
        let inputHash = SHA256.hash(data: passwordData + salt)
        let inputHashData = Data(inputHash)
        
        return storedHashData == inputHashData
    }
    
    // Speichert den Verschlüsselungsschlüssel im Keychain für die Verwendung mit biometrischer Authentifizierung
    func storeKeyInKeychain(_ key: SymmetricKey) -> Bool {
        return saveToKeychain(data: key.withUnsafeBytes { Data($0) },
                              key: KeychainKeys.encryptionKey,
                              withBiometrics: true)
    }
    
    // Ruft den Verschlüsselungsschlüssel aus dem Keychain ab
    func retrieveKeyFromKeychain() -> SymmetricKey? {
        guard let keyData = retrieveFromKeychain(key: KeychainKeys.encryptionKey) else {
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
               retrieveFromKeychain(key: KeychainKeys.encryptionKey) != nil
    }
    
    // Führt eine biometrische Authentifizierung durch
    func authenticateWithBiometrics(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        let reason = "Entsperre SecureNotes mit Touch ID"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            completion(success, error)
        }
    }
    
    // MARK: - Keychain-Hilfsmethoden
    
    // Speichert Daten im Keychain
    private func saveToKeychain(data: Data, key: String, withBiometrics: Bool = false) -> Bool {
        // Lösche eventuell vorhandenen Eintrag
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Erstelle neuen Eintrag
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Füge biometrische Einschränkungen hinzu, wenn erforderlich
        if withBiometrics {
            let context = LAContext()
            context.touchIDAuthenticationAllowableReuseDuration = 10
            
            var error: NSError?
            guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                return false
            }
            
            query[kSecUseAuthenticationContext as String] = context
        }
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // Ruft Daten aus dem Keychain ab
    private func retrieveFromKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        
        return data
    }
}
