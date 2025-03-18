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
            VStack(spacing: 10) {
                // Suchleiste
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                    
                    TextField("Suchen...", text: $searchText)
                        .font(.system(size: 13))
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(8)
                .background(Color(.textBackgroundColor).opacity(0.4))
                .cornerRadius(8)
                .padding([.horizontal, .top], 16)
                
                // Header
                HStack {
                    Text(folder.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(folderItemCount) \(folderItemCount == 1 ? "Element" : "Elemente")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                
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
                .padding(.horizontal, 16)
                
                Divider()
                    .padding(.horizontal, 16)
            }
            
            // Inhaltsliste
            if showNotesTab {
                folderNotesList
            } else {
                folderLinksList
            }
        }
    }
    
    // Anzahl der Elemente im Ordner
    private var folderItemCount: Int {
        return filteredFolderNotes.count + filteredFolderLinks.count
    }
    
    // Notizenliste im Ordner
    private var folderNotesList: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(filteredFolderNotes) { note in
                    noteRow(for: note)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedNote = note
                            selectedLink = nil
                        }
                        .contextMenu {
                            Button(action: {
                                // In Ordner verschieben
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
            .padding(.vertical, 8)
        }
    }
    
    // Einzelne Notizzeile
    private func noteRow(for note: NotesManager.Note) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Text(note.preview)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text(formattedDate(note.modificationDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Tags anzeigen
                if !note.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(note.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        if note.tags.count > 2 {
                            Text("+\(note.tags.count - 2)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(
            selectedNote?.id == note.id ?
                Color.blue.opacity(0.1) :
                Color.clear
        )
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    selectedNote?.id == note.id ?
                        Color.blue.opacity(0.3) :
                        Color.clear,
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 16)
    }
    
    // Linksliste im Ordner
    private var folderLinksList: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(filteredFolderLinks) { link in
                    linkRow(for: link)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedLink = link
                            selectedNote = nil
                        }
                        .contextMenu {
                            Button(action: {
                                NSWorkspace.shared.open(link.url)
                            }) {
                                Label("Im Browser öffnen", systemImage: "safari")
                            }
                            
                            Button(action: {
                                // In Ordner verschieben
                            }) {
                                Label("In Ordner verschieben", systemImage: "folder")
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
            .padding(.vertical, 8)
        }
    }
    
    // Einzelne Link-Zeile
    private func linkRow(for link: LinkViewModel.Link) -> some View {
        HStack(spacing: 12) {
            // Favicon
            Group {
                if let favicon = link.favicon, let nsImage = NSImage(data: favicon) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Image(systemName: "link")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .frame(width: 20, height: 20)
                }
            }
            
            // Link Details
            VStack(alignment: .leading, spacing: 2) {
                Text(link.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(link.url.host ?? link.url.absoluteString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Letzte Änderung und Tags
                HStack {
                    Text(formattedDate(link.modificationDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Tags
                    if !link.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(link.tags.prefix(1), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            
                            if link.tags.count > 1 {
                                Text("+\(link.tags.count - 1)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(
            selectedLink?.id == link.id ?
                Color.blue.opacity(0.1) :
                Color.clear
        )
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    selectedLink?.id == link.id ?
                        Color.blue.opacity(0.3) :
                        Color.clear,
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 16)
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
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
