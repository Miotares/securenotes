// DATEI: Models/Vault.swift
import Foundation

struct Vault: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var path: URL
    var isEncrypted: Bool
    var lastOpened: Date?
    
    init(id: UUID = UUID(), name: String, path: URL, isEncrypted: Bool = true, lastOpened: Date? = nil) {
        self.id = id
        self.name = name
        self.path = path
        self.isEncrypted = isEncrypted
        self.lastOpened = lastOpened
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Vault, rhs: Vault) -> Bool {
        return lhs.id == rhs.id
    }
}

// Verwaltet die verfügbaren Tresore
class VaultManager {
    static let shared = VaultManager()
    
    private let vaultsKey = "com.securenotes.vaults"
    private(set) var vaults: [Vault] = []
    private(set) var currentVault: Vault?
    
    init() {
        loadVaults()
    }
    
    // Lädt die Liste der verfügbaren Tresore
    func loadVaults() {
        if let data = UserDefaults.standard.data(forKey: vaultsKey) {
            do {
                vaults = try JSONDecoder().decode([Vault].self, from: data)
            } catch {
                print("Fehler beim Laden der Tresore: \(error)")
                vaults = []
            }
        }
    }
    
    // Speichert die Liste der Tresore
    private func saveVaultsList() {
        do {
            let data = try JSONEncoder().encode(vaults)
            UserDefaults.standard.set(data, forKey: vaultsKey)
        } catch {
            print("Fehler beim Speichern der Tresore: \(error)")
        }
    }
    
    // Fügt einen neuen Tresor hinzu
    func addVault(_ vault: Vault) {
        if !vaults.contains(where: { $0.id == vault.id }) {
            vaults.append(vault)
            saveVaultsList()
        }
    }
    
    // Entfernt einen Tresor
    func removeVault(id: UUID) {
        vaults.removeAll { $0.id == id }
        saveVaultsList()
    }
    
    // Setzt den aktuellen Tresor
    func setCurrentVault(_ vault: Vault) {
        currentVault = vault
        // Aktualisiere Last-Opened-Datum
        if let index = vaults.firstIndex(where: { $0.id == vault.id }) {
            vaults[index].lastOpened = Date()
            saveVaultsList()
        }
    }
    
    // Erstellt einen neuen Tresor an einem bestimmten Pfad
    func createVault(name: String, at path: URL, encrypted: Bool) -> Vault {
        let vault = Vault(name: name, path: path, isEncrypted: encrypted)
        
        // Stelle sicher, dass das Verzeichnis existiert
        do {
            // Erstelle das Verzeichnis für den Tresor
            try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
            
            // Erstelle leere Dateien für Notizen, Links und Ordner
            let notesPath = path.appendingPathComponent("notes.enc")
            let linksPath = path.appendingPathComponent("links.enc")
            let foldersPath = path.appendingPathComponent("folders.enc")
            
            // Initialisiere leere Dateien mit minimalen verschlüsselten Inhalten
            if !FileManager.default.fileExists(atPath: notesPath.path) {
                FileManager.default.createFile(atPath: notesPath.path, contents: Data(), attributes: nil)
            }
            
            if !FileManager.default.fileExists(atPath: linksPath.path) {
                FileManager.default.createFile(atPath: linksPath.path, contents: Data(), attributes: nil)
            }
            
            if !FileManager.default.fileExists(atPath: foldersPath.path) {
                FileManager.default.createFile(atPath: foldersPath.path, contents: Data(), attributes: nil)
            }
            
            // Erzwinge die Erstellung von leeren Anfangsdaten
            let storageService = StorageService(vaultPath: path)
            // Initialisiere mit leeren Daten
            storageService.saveNotes([])
            storageService.saveLinks([])
            storageService.saveFolders([])
            
            addVault(vault)
            return vault
        } catch {
            print("Fehler beim Erstellen des Tresor-Verzeichnisses: \(error)")
            // Hier könntest du einen Fehler zurückgeben oder eine Ausnahme werfen
            return vault
        }
    }
}
