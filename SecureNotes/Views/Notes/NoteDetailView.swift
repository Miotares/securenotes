// DATEI: Views/Notes/NoteDetailView.swift
import SwiftUI

struct NoteDetailView: View {
    @EnvironmentObject var notesManager: NotesManager
    let note: NotesManager.Note
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedContent: String
    @State private var editedTags: String
    
    init(note: NotesManager.Note) {
        self.note = note
        _editedTitle = State(initialValue: note.title)
        _editedContent = State(initialValue: note.content)
        _editedTags = State(initialValue: note.tags.joined(separator: ", "))
        
        // Startet im Bearbeitungsmodus, wenn es eine neue Notiz ist (oder der Inhalt leer ist)
        let isNewNote = note.content.isEmpty && note.modificationDate.timeIntervalSinceNow > -5 // Weniger als 5 Sekunden alt
        _isEditing = State(initialValue: isNewNote)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar oben
            HStack {
                if isEditing {
                    Button("Abbrechen") {
                        cancelEditing()
                    }
                    Spacer()
                    Button("Speichern") {
                        saveNote()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Spacer()
                    Button("Bearbeiten") {
                        startEditing()
                    }
                }
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            
            Divider()
            
            // Inhalt
            if isEditing {
                editingView
            } else {
                readingView
            }
        }
    }
    
    // Ansicht zum Lesen
    private var readingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(note.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Tags
                if !note.tags.isEmpty {
                    HStack {
                        ForEach(note.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
                
                Divider()
                
                // Inhalt
                Text(note.content)
                    .lineSpacing(1.2)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // Ansicht zum Bearbeiten
    private var editingView: some View {
        VStack(spacing: 0) {
            // Titel
            TextField("Titel", text: $editedTitle)
                .font(.title)
                .padding()
            
            // Tags
            TextField("Tags (durch Komma getrennt)", text: $editedTags)
                .font(.subheadline)
                .padding(.horizontal)
                .padding(.bottom)
            
            Divider()
            
            // Inhalt
            TextEditor(text: $editedContent)
                .font(.body)
                .padding([.leading, .trailing, .bottom])
        }
    }
    
    private func startEditing() {
        editedTitle = note.title
        editedContent = note.content
        editedTags = note.tags.joined(separator: ", ")
        isEditing = true
    }
    
    private func cancelEditing() {
        isEditing = false
    }
    
    private func saveNote() {
        let processedTags = editedTags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var updatedNote = note
        updatedNote.title = editedTitle
        updatedNote.content = editedContent
        updatedNote.tags = processedTags
        updatedNote.modificationDate = Date()
        
        // Speichern der aktualisierten Notiz im NotesManager
        if let index = notesManager.notes.firstIndex(where: { $0.id == note.id }) {
            notesManager.notes[index] = updatedNote
        }
        
        isEditing = false
    }
}
