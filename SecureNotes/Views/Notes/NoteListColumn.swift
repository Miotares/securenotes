// DATEI: Views/Notes/NoteListColumn.swift
import SwiftUI

struct NoteListColumn: View {
    @EnvironmentObject var notesManager: NotesManager
    @State private var searchText = ""
    @Binding var selectedNote: NotesManager.Note?
    @State private var sortOption: SortOption = .dateModified
    @State private var showingSortMenu = false
    
    enum SortOption {
        case dateModified
        case dateCreated
        case title
        
        var label: String {
            switch self {
            case .dateModified: return "Zuletzt bearbeitet"
            case .dateCreated: return "Erstelldatum"
            case .title: return "Titel"
            }
        }
        
        var iconName: String {
            switch self {
            case .dateModified: return "calendar.badge.clock"
            case .dateCreated: return "calendar.badge.plus"
            case .title: return "textformat.abc"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header mit Suchleiste und Sortieroptionen
            VStack(spacing: 10) {
                HStack {
                    Text("Notizen")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(filteredNotes.count) \(filteredNotes.count == 1 ? "Notiz" : "Notizen")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Menu {
                        Button(action: { sortOption = .dateModified }) {
                            Label("Zuletzt bearbeitet", systemImage: "calendar.badge.clock")
                        }
                        .disabled(sortOption == .dateModified)
                        
                        Button(action: { sortOption = .dateCreated }) {
                            Label("Erstelldatum", systemImage: "calendar.badge.plus")
                        }
                        .disabled(sortOption == .dateCreated)
                        
                        Button(action: { sortOption = .title }) {
                            Label("Titel", systemImage: "textformat.abc")
                        }
                        .disabled(sortOption == .title)
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                }
                
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
            }
            .padding([.horizontal, .top], 16)
            .padding(.bottom, 8)
            
            // Sortierinfo
            HStack {
                Label(
                    title: { Text(sortOption.label).font(.caption) },
                    icon: { Image(systemName: sortOption.iconName).font(.caption) }
                )
                .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Notizenliste
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(filteredNotes) { note in
                        noteRow(for: note)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedNote = note
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
    
    // Sortieren und Filtern
    private var filteredNotes: [NotesManager.Note] {
        let filtered = searchText.isEmpty ? notesManager.notes :
            notesManager.notes.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        
        switch sortOption {
        case .dateModified:
            return filtered.sorted { $0.modificationDate > $1.modificationDate }
        case .dateCreated:
            return filtered.sorted { $0.creationDate > $1.creationDate }
        case .title:
            return filtered.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
