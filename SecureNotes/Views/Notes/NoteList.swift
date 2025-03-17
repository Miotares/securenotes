// DATEI: Views/Notes/NoteList.swift
import SwiftUI

struct NoteList: View {
    @EnvironmentObject var notesManager: NotesManager
    @State private var searchText = ""
    @State private var showingNewNoteSheet = false
    @State private var selectedNote: NotesManager.Note?
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
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(getSortedFilteredNotes()) { note in
                        noteCard(for: note)
                            .padding(.horizontal)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .navigationTitle("Notizen")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewNoteSheet = true }) {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showingNewNoteSheet) {
            NewNoteView(isPresented: $showingNewNoteSheet)
                .environmentObject(notesManager)
        }
    }
    
    // Einzelne Notizenkarte
    private func noteCard(for note: NotesManager.Note) -> some View {
        VStack(alignment: .leading, spacing: 8) {
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
        .padding(12)
        .background(selectedNote?.id == note.id ? Color.blue.opacity(0.05) : Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(selectedNote?.id == note.id ? Color.blue.opacity(0.5) : Color.gray.opacity(0.1),
                       lineWidth: selectedNote?.id == note.id ? 2 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selectedNote = note
        }
    }
    
    // Tags-Ansicht
    private func tagsView(for note: NotesManager.Note) -> some View {
        HStack(spacing: 4) {
            if !note.tags.isEmpty {
                if note.tags.count > 0 {
                    Text(note.tags[0])
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
                
                if note.tags.count > 1 {
                    Text(note.tags[1])
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
