// Ordner: Views/Links/LinkEditorView.swift
import SwiftUI

struct LinkEditorView: View {
    @Binding var link: Link
    @Binding var isEditing: Bool
    @State private var title: String
    @State private var urlString: String
    @State private var description: String
    @State private var tags: String
    @State private var showingURLError = false
    
    init(link: Binding<Link>, isEditing: Binding<Bool>) {
        self._link = link
        self._isEditing = isEditing
        self._title = State(initialValue: link.wrappedValue.title)
        self._urlString = State(initialValue: link.wrappedValue.url.absoluteString)
        self._description = State(initialValue: link.wrappedValue.description ?? "")
        self._tags = State(initialValue: link.wrappedValue.tags.joined(separator: ", "))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Link bearbeiten")
                    .font(.headline)
                
                Spacer()
                
                Button("Abbrechen") {
                    isEditing = false
                }
                
                Button("Speichern") {
                    if saveLink() {
                        isEditing = false
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            
            Divider()
            
            TextField("Titel", text: $title)
                .font(.title)
            
            TextField("URL", text: $urlString)
                .textFieldStyle(.roundedBorder)
                // Entfernt die autocapitalization-Eigenschaft, die in UIKit existiert
                .disableAutocorrection(true)
            
            if showingURLError {
                Text("Bitte gib eine gültige URL ein")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            TextField("Tags (durch Komma getrennt)", text: $tags)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            Text("Notizen")
                .font(.headline)
            
            TextEditor(text: $description)
                .frame(minHeight: 150)
                .font(.body)
                .padding([.leading, .trailing], -8)
                .scrollContentBackground(.hidden)
            
            Spacer()
        }
        .padding()
    }
    
    private func saveLink() -> Bool {
        guard !title.isEmpty else { return false }
        
        // Überprüfe URL
        guard let url = URL(string: urlString), url.scheme != nil else {
            showingURLError = true
            return false
        }
        
        let storageService = StorageService()
        
        let processedTags = tags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var updatedLink = link
        updatedLink.title = title
        updatedLink.url = url
        updatedLink.description = description.isEmpty ? nil : description
        updatedLink.tags = processedTags
        updatedLink.modificationDate = Date()
        
        storageService.saveLink(updatedLink)
        link = updatedLink
        
        return true
    }
}
