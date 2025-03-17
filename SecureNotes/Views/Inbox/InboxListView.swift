// DATEI: Views/Inbox/InboxListView.swift
import SwiftUI

struct InboxListView: View {
    @EnvironmentObject var notesManager: NotesManager
    @EnvironmentObject var linkViewModel: LinkViewModel
    @State private var searchText = ""
    @Binding var selectedNote: NotesManager.Note?
    @Binding var selectedLink: LinkViewModel.Link?
    
    var body: some View {
        VStack(spacing: 0) {
            // Suchleiste
            VStack(spacing: 0) {
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Suchen...", text: $searchText)
                            .textFieldStyle(.plain)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(8)
                }
                .padding([.horizontal, .top])
                
                Divider()
                    .padding(.top, 8)
            }
            
            if filteredNotes.isEmpty && filteredLinks.isEmpty {
                emptyInboxView
            } else {
                inboxListContent
            }
        }
        .navigationTitle("Eingang")
    }
    
    // Leerer Eingang
    private var emptyInboxView: some View {
        VStack {
            Spacer()
            
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            Text("Eingang ist leer")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Neue Elemente werden hier angezeigt")
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    // Inhalt des Eingangs
    private var inboxListContent: some View {
        List {
            // Notizen im Eingang
            if !filteredNotes.isEmpty {
                Section(header: Text("NOTIZEN")) {
                    ForEach(filteredNotes) { note in
                        Button(action: {
                            // Notiz auswählen und Link abwählen
                            selectedNote = note
                            selectedLink = nil
                        }) {
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading) {
                                    Text(note.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(note.preview)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                if selectedNote?.id == note.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .background(selectedNote?.id == note.id ? Color.blue.opacity(0.1) : Color.clear)
                        .cornerRadius(6)
                        .contextMenu {
                            Button(action: {
                                // In Ordner verschieben Aktion
                            }) {
                                Label("In Ordner verschieben", systemImage: "folder")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: {
                                notesManager.deleteNote(note.id)
                                if selectedNote?.id == note.id {
                                    selectedNote = nil
                                }
                            }) {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            
            // Links im Eingang
            if !filteredLinks.isEmpty {
                Section(header: Text("LINKS")) {
                    ForEach(filteredLinks) { link in
                        Button(action: {
                            // Link auswählen und Notiz abwählen
                            selectedLink = link
                            selectedNote = nil
                        }) {
                            HStack {
                                if let favicon = link.favicon, let nsImage = NSImage(data: favicon) {
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                } else {
                                    Image(systemName: "link")
                                        .foregroundColor(.blue)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(link.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(link.url.absoluteString)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                if selectedLink?.id == link.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .background(selectedLink?.id == link.id ? Color.blue.opacity(0.1) : Color.clear)
                        .cornerRadius(6)
                        .contextMenu {
                            Button(action: {
                                // In Ordner verschieben Aktion
                            }) {
                                Label("In Ordner verschieben", systemImage: "folder")
                            }
                            
                            Button(action: {
                                NSWorkspace.shared.open(link.url)
                            }) {
                                Label("Im Browser öffnen", systemImage: "safari")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: {
                                linkViewModel.deleteLink(link.id)
                                if selectedLink?.id == link.id {
                                    selectedLink = nil
                                }
                            }) {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
    }
    
    // Notizen im Eingang (kein folderId zugewiesen)
    private var filteredNotes: [NotesManager.Note] {
        let inboxNotes = notesManager.notes.filter { $0.folderId == nil }
        
        if searchText.isEmpty {
            return inboxNotes
        } else {
            return inboxNotes.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }
    }
    
    // Links im Eingang (kein folderId zugewiesen)
    private var filteredLinks: [LinkViewModel.Link] {
        let inboxLinks = linkViewModel.links.filter { $0.folderId == nil }
        
        if searchText.isEmpty {
            return inboxLinks
        } else {
            return inboxLinks.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.url.absoluteString.localizedCaseInsensitiveContains(searchText) ||
                ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }
    }
}

// Für die Vorschau
struct InboxListView_Previews: PreviewProvider {
    static var previews: some View {
        InboxListView(
            selectedNote: .constant(nil),
            selectedLink: .constant(nil)
        )
        .environmentObject(NotesManager())
        .environmentObject(LinkViewModel())
    }
}
