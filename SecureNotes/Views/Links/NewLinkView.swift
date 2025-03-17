// DATEI: Views/Links/NewLinkView.swift
import SwiftUI

struct NewLinkView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var viewModel: LinkViewModel
    
    @State private var title = ""
    @State private var urlString = "https://"
    @State private var description = ""
    @State private var tagText = ""
    @State private var showingURLError = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Neuer Link")
                    .font(.headline)
                Spacer()
                
                Button("Abbrechen") {
                    isPresented = false
                }
                
                Button("Speichern") {
                    if saveLink() {
                        isPresented = false
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty || urlString.isEmpty)
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("Titel", text: $title)
                        .font(.title)
                        .textFieldStyle(.plain)
                    
                    TextField("URL", text: $urlString)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                    
                    if showingURLError {
                        Text("Bitte gib eine gültige URL ein")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    TextField("Tags (durch Komma getrennt)", text: $tagText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Notizen")
                        .font(.headline)
                    
                    TextEditor(text: $description)
                        .frame(minHeight: 150)
                        .font(.body)
                        .padding([.leading, .trailing], -8)
                        .scrollContentBackground(.hidden)
                }
                .padding()
            }
        }
        .frame(width: 500, height: 450)
    }
    
    private func saveLink() -> Bool {
        guard !title.isEmpty else { return false }
        
        // Überprüfe URL
        guard let url = URL(string: urlString), url.scheme != nil else {
            showingURLError = true
            return false
        }
        
        // Tags verarbeiten
        let processedTags = tagText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Erstelle einen neuen Link und füge ihn dem ViewModel hinzu
        let newLink = LinkViewModel.Link(
            title: title,
            url: url,
            description: description.isEmpty ? nil : description,
            tags: processedTags
        )
        
        viewModel.addLink(newLink)
        return true
    }
}
