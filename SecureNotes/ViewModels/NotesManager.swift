// DATEI: ViewModels/NotesManager.swift
import SwiftUI
import Combine

class NotesManager: ObservableObject {
    @Published var notes: [Note] = []
    
    struct Note: Identifiable, Equatable {
        var id: UUID
        var title: String
        var content: String
        var tags: [String]
        var folderId: UUID?
        var creationDate: Date
        var modificationDate: Date
        
        init(id: UUID = UUID(),
             title: String,
             content: String,
             tags: [String] = [],
             folderId: UUID? = nil,
             creationDate: Date = Date(),
             modificationDate: Date = Date()) {
            self.id = id
            self.title = title
            self.content = content
            self.tags = tags
            self.folderId = folderId
            self.creationDate = creationDate
            self.modificationDate = modificationDate
        }
        
        var preview: String {
            if content.count > 50 {
                return String(content.prefix(50)) + "..."
            }
            return content
        }
        
        // Implementieren von Equatable
        static func == (lhs: Note, rhs: Note) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    init() {
        loadNotes()
    }
    
    func loadNotes() {
        // Beispieldaten
        notes = [
            Note(title: "Willkommen bei SecureNotes", content: "Dies ist deine erste Notiz. Sie ist verschlüsselt und sicher."),
            Note(title: "Einkaufsliste", content: "Milch, Brot, Käse, Äpfel"),
            Note(title: "Projektideen", content: "1. Mobile App entwickeln\n2. Webseite aktualisieren\n3. Blog starten")
        ]
    }
    
    func addNote(_ title: String, content: String, tags: [String], folderId: UUID? = nil) {
        let newNote = Note(
            title: title,
            content: content,
            tags: tags,
            folderId: folderId
        )
        notes.append(newNote)
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        }
    }
    
    func moveNoteToFolder(_ noteId: UUID, folderId: UUID?) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].folderId = folderId
            notes[index].modificationDate = Date()
        }
    }
    
    func deleteNote(_ id: UUID) {
        notes.removeAll { $0.id == id }
    }
    
    func deleteNotes(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
    }
}
