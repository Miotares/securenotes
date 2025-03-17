//
//  NoteEditorView.swift
//  SecureNotes
//
//  Created by Merlin Kreuzkam on 17.03.25.
//


// DATEI: NoteEditorView.swift
import SwiftUI

struct NoteEditorView: View {
    @Binding var note: Note
    @Binding var isEditing: Bool
    @State private var title: String
    @State private var content: String
    @State private var tags: String
    @FocusState private var focusField: Field?
    
    enum Field: Hashable {
        case title, content
    }
    
    init(note: Binding<Note>, isEditing: Binding<Bool>) {
        self._note = note
        self._isEditing = isEditing
        self._title = State(initialValue: note.wrappedValue.title)
        self._content = State(initialValue: note.wrappedValue.content)
        self._tags = State(initialValue: note.wrappedValue.tags.joined(separator: ", "))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Notiz bearbeiten")
                    .font(.headline)
                
                Spacer()
                
                Button("Abbrechen") {
                    isEditing = false
                }
                
                Button("Speichern") {
                    saveNote()
                    isEditing = false
                }
                .buttonStyle(.borderedProminent)
            }
            
            Divider()
            
            TextField("Titel", text: $title)
                .font(.title)
                .focused($focusField, equals: .title)
                .onAppear {
                    focusField = .title
                }
            
            TextField("Tags (durch Komma getrennt)", text: $tags)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            TextEditor(text: $content)
                .frame(minHeight: 200)
                .focused($focusField, equals: .content)
                .font(.body)
                .padding([.leading, .trailing], -8)
                .scrollContentBackground(.hidden)
            
            Spacer()
        }
        .padding()
    }
    
    private func saveNote() {
        let storageService = StorageService()
        
        let processedTags = tags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var updatedNote = note
        updatedNote.title = title
        updatedNote.content = content
        updatedNote.tags = processedTags
        updatedNote.modificationDate = Date()
        
        storageService.saveNote(updatedNote)
        note = updatedNote
    }
}