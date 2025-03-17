// DATEI: ViewModels/FolderViewModel.swift
import SwiftUI
import Combine

class FolderViewModel: ObservableObject {
    @Published var folders: [Folder] = []
    
    struct Folder: Identifiable, Hashable {
        var id: UUID
        var name: String
        var color: Color
        var creationDate: Date
        var modificationDate: Date
        
        init(id: UUID = UUID(), name: String, color: Color = .blue,
             creationDate: Date = Date(), modificationDate: Date = Date()) {
            self.id = id
            self.name = name
            self.color = color
            self.creationDate = creationDate
            self.modificationDate = modificationDate
        }
        
        // Implementiere Hashable
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: Folder, rhs: Folder) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    init() {
        loadFolders()
    }
    
    func loadFolders() {
        // Beispiel-Daten
        folders = [
            Folder(name: "Arbeit", color: .blue),
            Folder(name: "Privat", color: .green),
            Folder(name: "Projekte", color: .orange)
        ]
    }
    
    // Wir verwenden jetzt die direkte Array-Manipulation statt dieser Methoden
    // Diese können aber als Convenience-Methoden behalten werden
    func deleteFolder(_ id: UUID) {
        folders.removeAll { $0.id == id }
    }
}
