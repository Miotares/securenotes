// DATEI: Services/StorageService.swift
import Foundation
import Combine

class StorageService {
    // Pfade für die Dateispeicherung
    private enum StoragePaths {
        static let notes = "notes.enc"
        static let links = "links.enc"
        static let folders = "folders.enc"
        
        static func getURL(for file: String, in vaultPath: URL? = nil) -> URL {
            if let vaultPath = vaultPath {
                return vaultPath.appendingPathComponent(file)
            } else {
                // Fallback auf das Dokumente-Verzeichnis
                let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                return paths[0].appendingPathComponent(file)
            }
        }
    }
    
    private let encryptionService: EncryptionService
    private var vaultPath: URL?
    private var notesSubject = PassthroughSubject<[Note], Never>()
    private var linksSubject = PassthroughSubject<[Link], Never>()
    private var foldersSubject = PassthroughSubject<[Folder], Never>()
    private var itemsSubject = PassthroughSubject<[AnyItem], Never>()
    
    // Publisher für Änderungen an den gespeicherten Daten
    var notesPublisher: AnyPublisher<[Note], Never> {
        notesSubject.eraseToAnyPublisher()
    }
    
    var linksPublisher: AnyPublisher<[Link], Never> {
        linksSubject.eraseToAnyPublisher()
    }
    
    var foldersPublisher: AnyPublisher<[Folder], Never> {
        foldersSubject.eraseToAnyPublisher()
    }
    
    var itemsPublisher: AnyPublisher<[AnyItem], Never> {
        itemsSubject.eraseToAnyPublisher()
    }
    
    init(encryptionService: EncryptionService = EncryptionService(), vaultPath: URL? = nil) {
        self.encryptionService = encryptionService
        self.vaultPath = vaultPath
    }
    
    // Aktualisiert den aktiven Vault-Pfad
    func setVaultPath(_ path: URL?) {
        self.vaultPath = path
        // Benachrichtige Publisher über Änderungen
        notesSubject.send(loadNotes())
        linksSubject.send(loadLinks())
        foldersSubject.send(loadFolders())
        updateItemsPublisher()
    }
    
    // MARK: - Notizen-Operationen
    
    func loadNotes() -> [Note] {
        let url = StoragePaths.getURL(for: StoragePaths.notes, in: vaultPath)
        
        if !FileManager.default.fileExists(atPath: url.path) {
            return []
        }
        
        do {
            let fileData = try Data(contentsOf: url)
            if fileData.isEmpty {
                return []
            }
            
            let encryptedData = fileData
            let metadataSize = MemoryLayout<Int>.size * 2
            
            guard encryptedData.count > metadataSize else {
                return []
            }
            
            // Extrahiere Nonce-Größe und Nonce
            let nonceSize = encryptedData.prefix(MemoryLayout<Int>.size).withUnsafeBytes { $0.load(as: Int.self) }
            let nonce = encryptedData.subdata(in: MemoryLayout<Int>.size..<(MemoryLayout<Int>.size + nonceSize))
            
            // Extrahiere eigentliche verschlüsselte Daten
            let ciphertext = encryptedData.subdata(in: (MemoryLayout<Int>.size + nonceSize)..<encryptedData.count)
            
            guard let decryptedData = encryptionService.decrypt(encryptedData: ciphertext, nonce: nonce) else {
                print("Fehler beim Entschlüsseln der Notizen")
                return []
            }
            
            let decoder = JSONDecoder()
            let notes = try decoder.decode([Note].self, from: decryptedData)
            return notes
            
        } catch {
            print("Fehler beim Laden der Notizen: \(error)")
            return []
        }
    }
    
    func saveNotes(_ notes: [Note]) {
        guard let (encryptedData, nonce) = encryptionService.encryptObject(notes) else {
            print("Fehler beim Verschlüsseln der Notizen")
            return
        }
        
        let nonceSize = nonce.count
        
        // Erstelle Daten mit Metadaten (Nonce-Größe + Nonce + verschlüsselte Daten)
        var dataToSave = Data()
        withUnsafeBytes(of: nonceSize) { dataToSave.append(contentsOf: $0) }
        dataToSave.append(nonce)
        dataToSave.append(encryptedData)
        
        let url = StoragePaths.getURL(for: StoragePaths.notes, in: vaultPath)
        
        do {
            try dataToSave.write(to: url)
            notesSubject.send(notes)
            updateItemsPublisher()
        } catch {
            print("Fehler beim Speichern der Notizen: \(error)")
        }
    }
    
    func saveNote(_ note: Note) {
        var notes = loadNotes()
        
        // Aktualisiere existierende Notiz oder füge neue hinzu
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        } else {
            notes.append(note)
        }
        
        saveNotes(notes)
    }
    
    func deleteNote(_ id: UUID) {
        var notes = loadNotes()
        notes.removeAll { $0.id == id }
        saveNotes(notes)
    }
    
    // MARK: - Link-Operationen
    
    func loadLinks() -> [Link] {
        let url = StoragePaths.getURL(for: StoragePaths.links, in: vaultPath)
        
        if !FileManager.default.fileExists(atPath: url.path) {
            return []
        }
        
        do {
            let fileData = try Data(contentsOf: url)
            if fileData.isEmpty {
                return []
            }
            
            let encryptedData = fileData
            let metadataSize = MemoryLayout<Int>.size * 2
            
            guard encryptedData.count > metadataSize else {
                return []
            }
            
            // Extrahiere Nonce-Größe und Nonce
            let nonceSize = encryptedData.prefix(MemoryLayout<Int>.size).withUnsafeBytes { $0.load(as: Int.self) }
            let nonce = encryptedData.subdata(in: MemoryLayout<Int>.size..<(MemoryLayout<Int>.size + nonceSize))
            
            // Extrahiere eigentliche verschlüsselte Daten
            let ciphertext = encryptedData.subdata(in: (MemoryLayout<Int>.size + nonceSize)..<encryptedData.count)
            
            guard let decryptedData = encryptionService.decrypt(encryptedData: ciphertext, nonce: nonce) else {
                print("Fehler beim Entschlüsseln der Links")
                return []
            }
            
            let decoder = JSONDecoder()
            let links = try decoder.decode([Link].self, from: decryptedData)
            return links
            
        } catch {
            print("Fehler beim Laden der Links: \(error)")
            return []
        }
    }
    
    func saveLinks(_ links: [Link]) {
        guard let (encryptedData, nonce) = encryptionService.encryptObject(links) else {
            print("Fehler beim Verschlüsseln der Links")
            return
        }
        
        let nonceSize = nonce.count
        
        // Erstelle Daten mit Metadaten (Nonce-Größe + Nonce + verschlüsselte Daten)
        var dataToSave = Data()
        withUnsafeBytes(of: nonceSize) { dataToSave.append(contentsOf: $0) }
        dataToSave.append(nonce)
        dataToSave.append(encryptedData)
        
        let url = StoragePaths.getURL(for: StoragePaths.links, in: vaultPath)
        
        do {
            try dataToSave.write(to: url)
            linksSubject.send(links)
            updateItemsPublisher()
        } catch {
            print("Fehler beim Speichern der Links: \(error)")
        }
    }
    
    func saveLink(_ link: Link) {
        var links = loadLinks()
        
        // Aktualisiere existierenden Link oder füge neuen hinzu
        if let index = links.firstIndex(where: { $0.id == link.id }) {
            links[index] = link
        } else {
            links.append(link)
        }
        
        saveLinks(links)
    }
    
    func deleteLink(_ id: UUID) {
        var links = loadLinks()
        links.removeAll { $0.id == id }
        saveLinks(links)
    }
    
    // MARK: - Ordner-Operationen
    
    func loadFolders() -> [Folder] {
        let url = StoragePaths.getURL(for: StoragePaths.folders, in: vaultPath)
        
        if !FileManager.default.fileExists(atPath: url.path) {
            return []
        }
        
        do {
            let fileData = try Data(contentsOf: url)
            if fileData.isEmpty {
                return []
            }
            
            let encryptedData = fileData
            let metadataSize = MemoryLayout<Int>.size * 2
            
            guard encryptedData.count > metadataSize else {
                return []
            }
            
            // Extrahiere Nonce-Größe und Nonce
            let nonceSize = encryptedData.prefix(MemoryLayout<Int>.size).withUnsafeBytes { $0.load(as: Int.self) }
            let nonce = encryptedData.subdata(in: MemoryLayout<Int>.size..<(MemoryLayout<Int>.size + nonceSize))
            
            // Extrahiere eigentliche verschlüsselte Daten
            let ciphertext = encryptedData.subdata(in: (MemoryLayout<Int>.size + nonceSize)..<encryptedData.count)
            
            guard let decryptedData = encryptionService.decrypt(encryptedData: ciphertext, nonce: nonce) else {
                print("Fehler beim Entschlüsseln der Ordner")
                return []
            }
            
            let decoder = JSONDecoder()
            let folders = try decoder.decode([Folder].self, from: decryptedData)
            return folders
            
        } catch {
            print("Fehler beim Laden der Ordner: \(error)")
            return []
        }
    }
    
    func saveFolders(_ folders: [Folder]) {
        guard let (encryptedData, nonce) = encryptionService.encryptObject(folders) else {
            print("Fehler beim Verschlüsseln der Ordner")
            return
        }
        
        let nonceSize = nonce.count
        
        // Erstelle Daten mit Metadaten (Nonce-Größe + Nonce + verschlüsselte Daten)
        var dataToSave = Data()
        withUnsafeBytes(of: nonceSize) { dataToSave.append(contentsOf: $0) }
        dataToSave.append(nonce)
        dataToSave.append(encryptedData)
        
        let url = StoragePaths.getURL(for: StoragePaths.folders, in: vaultPath)
        
        do {
            try dataToSave.write(to: url)
            foldersSubject.send(folders)
        } catch {
            print("Fehler beim Speichern der Ordner: \(error)")
        }
    }
    
    func saveFolder(_ folder: Folder) {
        var folders = loadFolders()
        
        // Aktualisiere existierenden Ordner oder füge neuen hinzu
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[index] = folder
        } else {
            folders.append(folder)
        }
        
        saveFolders(folders)
    }
    
    func deleteFolder(_ id: UUID) {
        var folders = loadFolders()
        folders.removeAll { $0.id == id }
        saveFolders(folders)
        
        // Aktualisiere Verweise auf diesen Ordner in Notizen und Links
        var notes = loadNotes()
        var notesUpdated = false
        
        for i in 0..<notes.count {
            if notes[i].folderId == id {
                notes[i].folderId = nil
                notes[i].modificationDate = Date()
                notesUpdated = true
            }
        }
        
        if notesUpdated {
            saveNotes(notes)
        }
        
        var links = loadLinks()
        var linksUpdated = false
        
        for i in 0..<links.count {
            if links[i].folderId == id {
                links[i].folderId = nil
                links[i].modificationDate = Date()
                linksUpdated = true
            }
        }
        
        if linksUpdated {
            saveLinks(links)
        }
    }
    
    // MARK: - Hilfsmethoden
    
    private func updateItemsPublisher() {
        let notes = loadNotes()
        let links = loadLinks()
        
        let noteItems = notes.map { AnyItem.note($0) }
        let linkItems = links.map { AnyItem.link($0) }
        
        itemsSubject.send(noteItems + linkItems)
    }
}
