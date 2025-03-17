// Ordner: Views/Notes/NewNoteView.swift
import SwiftUI

struct NewNoteView: View {
    @Binding var isPresented: Bool
    @State private var title = ""
    @State private var content = ""
    @State private var tagText = ""
    @EnvironmentObject var viewModel: NotesManager // Hier umbenannt
    
    var body: some View {
        VStack(spacing: 0) {
            // Headerbereich
            HStack {
                Text("Neue Notiz")
                    .font(.headline)
                Spacer()
                Button("Abbrechen") {
                    isPresented = false
                }
                Button("Speichern") {
                    saveNote()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            
            Divider()
            
            // Eingabebereich
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("Titel", text: $title)
                        .font(.title)
                        .textFieldStyle(.plain)
                    
                    TextField("Tags (durch Komma getrennt)", text: $tagText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("Gib hier deine Notiz ein...")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                            .font(.body)
                            .opacity(content.isEmpty ? 0.25 : 1)
                    }
                }
                .padding()
            }
        }
        .frame(width: 600, height: 500)
    }
    
    private func saveNote() {
        let processedTags = tagText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Rufe die addNote-Methode auf
        viewModel.addNote(title, content: content, tags: processedTags)
    }
}

// Vorschau für Entwicklungszwecke
struct NewNoteView_Previews: PreviewProvider {
    static var previews: some View {
        NewNoteView(isPresented: .constant(true))
            .environmentObject(NotesManager()) // Hier umbenannt
    }
}
