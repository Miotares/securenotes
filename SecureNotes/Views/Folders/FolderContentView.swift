//
//  FolderContentView.swift
//  SecureNotes
//
//  Created by Merlin Kreuzkam on 17.03.25.
//


// DATEI: Views/Folders/FolderContentView.swift
import SwiftUI

struct FolderContentView: View {
    let folder: FolderViewModel.Folder
    @Binding var selectedNote: NotesManager.Note?
    @Binding var selectedLink: LinkViewModel.Link?
    @EnvironmentObject var notesManager: NotesManager
    @EnvironmentObject var linkViewModel: LinkViewModel
    @State private var searchText = ""
    @State private var showNotesTab = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Suchleiste und Tabs
            VStack(spacing: 0) {
                // Suchleiste
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
                .padding([.horizontal, .top])
                
                // Tabs
                HStack {
                    Button(action: { showNotesTab = true }) {
                        Text("Notizen")
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(showNotesTab ? Color.blue.opacity(0.1) : Color.clear)
                            .cornerRadius(8)
                            .foregroundColor(showNotesTab ? .blue : .primary)
                            .bold(showNotesTab)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { showNotesTab = false }) {
                        Text("Links")
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(!showNotesTab ? Color.blue.opacity(0.1) : Color.clear)
                            .cornerRadius(8)
                            .foregroundColor(!showNotesTab ? .blue : .primary)
                            .bold(!showNotesTab)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                Divider()
            }
            
            // Inhaltsliste
            if showNotesTab {
                folderNotesList
            } else {
                folderLinksList
            }
        }
        .navigationTitle(folder.name)
    }
    
    // Notizenliste im Ordner
    private var folderNotesList: some View {
        List(selection: Binding(
            get: { selectedNote?.id },
            set: { newValue in
                if let id = newValue,
                   let note = filteredFolderNotes.first(where: { $0.id == id }) {
                    selectedNote = note
                    selectedLink = nil
                }
            }
        )) {
            ForEach(filteredFolderNotes) { note in
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading) {
                        Text(note.title)
                            .font(.headline)
                        
                        Text(note.preview)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .tag(note.id)
            }
        }
        .listStyle(.sidebar)
    }
    
    // Linksliste im Ordner
    private var folderLinksList: some View {
        List(selection: Binding(
            get: { selectedLink?.id },
            set: { newValue in
                if let id = newValue,
                   let link = filteredFolderLinks.first(where: { $0.id == id }) {
                    selectedLink = link
                    selectedNote = nil
                }
            }
        )) {
            ForEach(filteredFolderLinks) { link in
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
                        
                        Text(link.url.absoluteString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .tag(link.id)
            }
        }
        .listStyle(.sidebar)
    }
    
    // Gefilterte Notizen im Ordner
    private var filteredFolderNotes: [NotesManager.Note] {
        let folderNotes = notesManager.notes.filter { $0.folderId == folder.id }
        
        if searchText.isEmpty {
            return folderNotes
        } else {
            return folderNotes.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }
    }
    
    // Gefilterte Links im Ordner
    private var filteredFolderLinks: [LinkViewModel.Link] {
        let folderLinks = linkViewModel.links.filter { $0.folderId == folder.id }
        
        if searchText.isEmpty {
            return folderLinks
        } else {
            return folderLinks.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.url.absoluteString.localizedCaseInsensitiveContains(searchText) ||
                ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }
    }
}
