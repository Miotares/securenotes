//
//  NoteListColumn.swift
//  SecureNotes
//
//  Created by Merlin Kreuzkam on 17.03.25.
//


// DATEI: Views/Notes/NoteListColumn.swift
import SwiftUI

struct NoteListColumn: View {
    @EnvironmentObject var notesManager: NotesManager
    @State private var searchText = ""
    @Binding var selectedNote: NotesManager.Note?
    @State private var sortOption: SortOption = .dateModified
    
    enum SortOption {
        case dateModified
        case dateCreated
        case title
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Suchleiste und Filter-Header
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
                    
                    // Einfaches Menü für Sortierung
                    Menu {
                        Button("Nach Änderungsdatum", action: { sortOption = .dateModified })
                        Button("Nach Erstellungsdatum", action: { sortOption = .dateCreated })
                        Button("Nach Titel", action: { sortOption = .title })
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .foregroundColor(.secondary)
                    }
                }
                .padding([.horizontal, .top])
                
                Divider()
                    .padding(.top, 8)
            }
            
            // Notizenliste
            List(selection: Binding(
                get: { selectedNote?.id },
                set: { newValue in
                    if let id = newValue,
                       let note = getSortedFilteredNotes().first(where: { $0.id == id }) {
                        selectedNote = note
                    }
                }
            )) {
                ForEach(getSortedFilteredNotes()) { note in
                    noteRow(for: note)
                        .tag(note.id)
                }
            }
            .listStyle(.sidebar)
        }
        .navigationTitle("Notizen")
    }
    
    // Einzelne Notizzeile
    private func noteRow(for note: NotesManager.Note) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title)
                .font(.headline)
                .lineLimit(1)
            
            Text(note.preview)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text(formattedDate(note.modificationDate))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                tagsView(for: note)
            }
        }
        .padding(.vertical, 4)
    }
    
    // Tags-Ansicht
    private func tagsView(for note: NotesManager.Note) -> some View {
        HStack(spacing: 4) {
            if !note.tags.isEmpty {
                if note.tags.count > 0 {
                    Text(note.tags[0])
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(3)
                }
                
                if note.tags.count > 1 {
                    Text("+\(note.tags.count - 1)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // Sortieren und Filtern als separate Funktion
    private func getSortedFilteredNotes() -> [NotesManager.Note] {
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
            return filtered.sorted { $0.title < $1.title }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}