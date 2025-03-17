// Ordner: Services/EncryptionService.swift
import Foundation
import CryptoKit
import Security

class EncryptionService {
    // Konstanten für die Verschlüsselung
    private enum Constants {
        static let keySize = SymmetricKeySize.bits256
        static let saltSize = 16  // 16 Bytes (128 Bits)
        static let iterationCount = 100_000  // Iterationen
    }
    
    // Der aktuelle Verschlüsselungsschlüssel im Speicher (nur während der App-Nutzung)
    private var currentKey: SymmetricKey?
    
    // Generiert einen Salt für die Schlüsselableitung
    func generateSalt() -> Data {
        var salt = Data(count: Constants.saltSize)
        _ = salt.withUnsafeMutableBytes { saltBytes in
            SecRandomCopyBytes(kSecRandomDefault, Constants.saltSize, saltBytes.baseAddress!)
        }
        return salt
    }
    
    // Leitet einen Schlüssel aus dem Passwort und einem Salt ab
    func deriveKey(from password: String, salt: Data? = nil) -> SymmetricKey? {
        guard !password.isEmpty else { return nil }
        
        let salt = salt ?? generateSalt()
        guard let passwordData = password.data(using: .utf8) else { return nil }
        
        // Verwende eine einfachere Methode zur Schlüsselableitung mit CryptoKit in macOS
        let key = SymmetricKey(data: SHA256.hash(data: passwordData + salt))
        return key
    }
    
    // Setzt den aktuellen Schlüssel für die Verschlüsselung während der App-Nutzung
    func setCurrentKey(_ key: SymmetricKey) {
        self.currentKey = key
    }
    
    // Entfernt den Schlüssel aus dem Speicher
    func clearCurrentKey() {
        self.currentKey = nil
    }
    
    // Verschlüsselt Daten mit dem aktuellen Schlüssel
    func encrypt(_ data: Data) -> (encryptedData: Data, nonce: Data)? {
        guard let key = currentKey else {
            print("Verschlüsselungsfehler: Kein Schlüssel gesetzt")
            return nil
        }
        
        do {
            // In macOS einfachere Verwendung von AES-GCM
            let sealedBox = try AES.GCM.seal(data, using: key)
            
            // Statt der problematischen if-let-Zuweisung:
            let nonceData = sealedBox.nonce.withUnsafeBytes {
                return Data($0)
            }
            
            return (sealedBox.ciphertext, nonceData)
        } catch {
            print("Verschlüsselungsfehler: \(error)")
            return nil
        }
    }
    
    // Entschlüsselt Daten mit dem aktuellen Schlüssel
    func decrypt(encryptedData: Data, nonce: Data) -> Data? {
        guard let key = currentKey else {
            print("Entschlüsselungsfehler: Kein Schlüssel gesetzt")
            return nil
        }
        
        do {
            // Für macOS angepasste Entschlüsselung
            let nonce = try AES.GCM.Nonce(data: nonce)
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: encryptedData, tag: Data())
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            print("Entschlüsselungsfehler: \(error)")
            return nil
        }
    }
    
    // Hilfsmethode zum Verschlüsseln eines Objekts
    func encryptObject<T: Encodable>(_ object: T) -> (encryptedData: Data, nonce: Data)? {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(object)
            return encrypt(data)
        } catch {
            print("Fehler beim Kodieren des Objekts: \(error)")
            return nil
        }
    }
    
    // Hilfsmethode zum Entschlüsseln eines Objekts
    func decryptObject<T: Decodable>(encryptedData: Data, nonce: Data, as type: T.Type) -> T? {
        guard let decryptedData = decrypt(encryptedData: encryptedData, nonce: nonce) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: decryptedData)
        } catch {
            print("Fehler beim Dekodieren des Objekts: \(error)")
            return nil
        }
    }
}
