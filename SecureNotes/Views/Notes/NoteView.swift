// Ordner: Views/Notes/NoteView.swift
import SwiftUI

struct NoteView: View {
    // Vereinfachte Version ohne Abhängigkeit von spezifischen Models
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var showingFolderPicker = false
    
    // Direkte Eigenschaften statt Model
    @State private var title: String
    @State private var content: String
    
    init(title: String, content: String) {
        _title = State(initialValue: title)
        _content = State(initialValue: content)
    }
    
    var body: some View {
        VStack {
            if isEditing {
                // Bearbeitungsansicht
                EditNoteView(title: $title, content: $content, isEditing: $isEditing)
            } else {
                // Leseansicht
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Menu {
                                Button(action: { isEditing = true }) {
                                    Label("Bearbeiten", systemImage: "pencil")
                                }
                                
                                Button(action: { showingFolderPicker = true }) {
                                    Label("In Ordner verschieben", systemImage: "folder")
                                }
                                
                                Button(role: .destructive, action: { showingDeleteAlert = true }) {
                                    Label("Löschen", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.title2)
                            }
                        }
                        
                        Divider()
                        
                        Text(content)
                            .font(.body)
                            .lineSpacing(1.5)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(isEditing ? "Notiz bearbeiten" : "Notiz")
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { isEditing = true }) {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
        .alert("Notiz löschen", isPresented: $showingDeleteAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Löschen", role: .destructive) {
                deleteNote()
            }
        } message: {
            Text("Möchtest du diese Notiz wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.")
        }
        .sheet(isPresented: $showingFolderPicker) {
            // Temporärer Platzhalter für den FolderPicker
            Text("Ordnerauswahl")
                .frame(width: 300, height: 200)
        }
    }
    
    private func deleteNote() {
        // Hier würde in einer vollständigen App die Notiz gelöscht werden
        print("Notiz gelöscht")
    }
}

// Hilfsansicht zum Bearbeiten
struct EditNoteView: View {
    @Binding var title: String
    @Binding var content: String
    @Binding var isEditing: Bool
    
    var body: some View {
        VStack {
            HStack {
                Text("Notiz bearbeiten").font(.headline)
                Spacer()
                Button("Abbrechen") { isEditing = false }
                Button("Speichern") {
                    // Speichern der Änderungen
                    isEditing = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom)
            
            TextField("Titel", text: $title)
                .font(.title)
                .padding(.bottom)
            
            TextEditor(text: $content)
                .font(.body)
                .padding([.leading, .trailing], -8)
        }
        .padding()
    }
}

// Vorschau für Entwicklungszwecke
struct NoteView_Previews: PreviewProvider {
    static var previews: some View {
        NoteView(title: "Beispielnotiz", content: "Dies ist der Inhalt der Beispielnotiz.")
    }
}
