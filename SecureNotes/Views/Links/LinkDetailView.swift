// DATEI: Views/Links/LinkDetailView.swift
import SwiftUI

struct LinkDetailView: View {
    @EnvironmentObject var linkViewModel: LinkViewModel
    let link: LinkViewModel.Link
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedURL: String
    @State private var editedDescription: String
    @State private var editedTags: String
    @State private var showingURLError = false
    
    init(link: LinkViewModel.Link) {
        self.link = link
        _editedTitle = State(initialValue: link.title)
        _editedURL = State(initialValue: link.url.absoluteString)
        _editedDescription = State(initialValue: link.description ?? "")
        _editedTags = State(initialValue: link.tags.joined(separator: ", "))
        
        // Startet im Bearbeitungsmodus, wenn es ein neuer Link ist
        let isNewLink = link.title == "Neuer Link" && link.modificationDate.timeIntervalSinceNow > -5 // Weniger als 5 Sekunden alt
        _isEditing = State(initialValue: isNewLink)
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
                        saveLink()
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
                HStack(alignment: .center) {
                    // Favicon
                    if let favicon = link.favicon, let nsImage = NSImage(data: favicon) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .frame(width: 24, height: 24)
                            .cornerRadius(4)
                    } else {
                        Image(systemName: "link")
                            .foregroundColor(.blue)
                            .font(.title)
                    }
                    
                    Text(link.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                // URL mit Öffnen-Button
                HStack {
                    Text(link.url.absoluteString)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button(action: {
                        NSWorkspace.shared.open(link.url)
                    }) {
                        Text("Im Browser öffnen")
                            .font(.caption)
                        Image(systemName: "arrow.up.forward.app")
                    }
                    .buttonStyle(.bordered)
                }
                
                // Tags
                if !link.tags.isEmpty {
                    HStack {
                        ForEach(link.tags, id: \.self) { tag in
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
                
                // Beschreibung/Notizen
                if let description = link.description, !description.isEmpty {
                    Text("Notizen")
                        .font(.headline)
                    
                    Text(description)
                        .lineSpacing(1.2)
                }
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
            
            // URL
            VStack(alignment: .leading, spacing: 4) {
                Text("URL:")
                    .font(.headline)
                
                TextField("https://...", text: $editedURL)
                    .textFieldStyle(.roundedBorder)
                
                if showingURLError {
                    Text("Bitte gib eine gültige URL ein")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding(.horizontal)
            
            // Tags
            TextField("Tags (durch Komma getrennt)", text: $editedTags)
                .font(.subheadline)
                .padding(.horizontal)
                .padding(.top)
            
            Divider()
                .padding()
            
            // Beschreibung
            Text("Notizen:")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            TextEditor(text: $editedDescription)
                .font(.body)
                .padding([.horizontal, .bottom])
        }
    }
    
    private func startEditing() {
        editedTitle = link.title
        editedURL = link.url.absoluteString
        editedDescription = link.description ?? ""
        editedTags = link.tags.joined(separator: ", ")
        isEditing = true
    }
    
    private func cancelEditing() {
        isEditing = false
        showingURLError = false
    }
    
    private func saveLink() {
        guard !editedTitle.isEmpty else { return }
        
        // Überprüfe URL
        guard let url = URL(string: editedURL), url.scheme != nil else {
            showingURLError = true
            return
        }
        
        // Tags verarbeiten
        let processedTags = editedTags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var updatedLink = link
        updatedLink.title = editedTitle
        updatedLink.url = url
        updatedLink.description = editedDescription.isEmpty ? nil : editedDescription
        updatedLink.tags = processedTags
        updatedLink.modificationDate = Date()
        
        // Speichern des aktualisierten Links im LinkViewModel
        if let index = linkViewModel.links.firstIndex(where: { $0.id == link.id }) {
            linkViewModel.links[index] = updatedLink
        }
        
        isEditing = false
        showingURLError = false
    }
}
