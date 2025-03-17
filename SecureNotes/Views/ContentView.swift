// DATEI: Views/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab: SidebarTab = .inbox
    @StateObject private var notesManager = NotesManager()
    @StateObject private var linkViewModel = LinkViewModel()
    @State private var selectedNote: NotesManager.Note?
    @State private var selectedLink: LinkViewModel.Link?
    
    var body: some View {
        NavigationView {
            // Erste Spalte: Seitenleiste
            VStack {
                SidebarView(selectedTab: $selectedTab)
                    .environmentObject(notesManager)
                    .environmentObject(linkViewModel)
                
                Spacer()
                
                // Aktionsbuttons unten in der Seitenleiste
                Divider()
                
                HStack(spacing: 4) {
                    Button(action: createNewNote) {
                        VStack(spacing: 4) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 20))
                            Text("Neue Notiz")
                                .font(.system(size: 11))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(ButtonTileStyle(color: .green))
                    
                    Button(action: createNewLink) {
                        VStack(spacing: 4) {
                            Image(systemName: "link.badge.plus")
                                .font(.system(size: 20))
                            Text("Neuer Link")
                                .font(.system(size: 11))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(ButtonTileStyle(color: .blue))
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            
            // Zweite Spalte: Inhaltsübersicht
            Group {
                switch selectedTab {
                case .inbox:
                    InboxListView(selectedNote: $selectedNote, selectedLink: $selectedLink)
                        .environmentObject(notesManager)
                        .environmentObject(linkViewModel)
                        .onChange(of: selectedLink) { _ in
                            // Stelle sicher, dass wenn ein Link ausgewählt wird, keine Notiz ausgewählt ist
                            if selectedLink != nil {
                                selectedNote = nil
                            }
                        }
                        .onChange(of: selectedNote) { _ in
                            // Stelle sicher, dass wenn eine Notiz ausgewählt wird, kein Link ausgewählt ist
                            if selectedNote != nil {
                                selectedLink = nil
                            }
                        }
                case .notes:
                    NoteListColumn(selectedNote: $selectedNote)
                        .environmentObject(notesManager)
                        .onChange(of: selectedNote) { _ in
                            // Deselektiere Links wenn eine Notiz ausgewählt wird
                            selectedLink = nil
                        }
                case .links:
                    LinkListColumn(selectedLink: $selectedLink)
                        .environmentObject(linkViewModel)
                        .onChange(of: selectedLink) { _ in
                            // Deselektiere Notizen wenn ein Link ausgewählt wird
                            selectedNote = nil
                        }
                case .folder(let folder):
                    FolderContentView(folder: folder, selectedNote: $selectedNote, selectedLink: $selectedLink)
                        .environmentObject(notesManager)
                        .environmentObject(linkViewModel)
                        .onChange(of: selectedNote) { _ in
                            if selectedNote != nil {
                                selectedLink = nil
                            }
                        }
                        .onChange(of: selectedLink) { _ in
                            if selectedLink != nil {
                                selectedNote = nil
                            }
                        }
                }
            }
            .frame(minWidth: 250)
            
            // Dritte Spalte: Detailansicht
            Group {
                if let note = selectedNote {
                    NoteDetailView(note: note)
                        .environmentObject(notesManager)
                } else if let link = selectedLink {
                    LinkDetailView(link: link)
                        .environmentObject(linkViewModel)
                } else {
                    EmptyDetailView()
                }
            }
            .frame(minWidth: 400)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar) {
                    Image(systemName: "sidebar.left")
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
    
    private func createNewNote() {
        // Zeige den Notiz-Editor an
        let newNote = NotesManager.Note(
            id: UUID(),
            title: "Neue Notiz",
            content: "",
            tags: [],
            folderId: nil,
            creationDate: Date(),
            modificationDate: Date()
        )
        
        // Füge die neue Notiz hinzu und wähle sie aus
        notesManager.notes.append(newNote)
        selectedNote = newNote
        selectedLink = nil
        
        // Wechsle zur Notizansicht
        selectedTab = .notes
    }
    
    private func createNewLink() {
        // Zeige den Link-Editor an
        if let url = URL(string: "https://") {
            let newLink = LinkViewModel.Link(
                id: UUID(),
                title: "Neuer Link",
                url: url,
                description: nil,
                favicon: nil,
                tags: [],
                folderId: nil
            )
            
            // Füge den neuen Link hinzu und wähle ihn aus
            linkViewModel.links.append(newLink)
            selectedLink = newLink
            selectedNote = nil
            
            // Wechsle zur Linkansicht
            selectedTab = .links
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

// Leere Detailansicht, wenn nichts ausgewählt ist
struct EmptyDetailView: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "hand.tap")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            Text("Keine Auswahl")
                .font(.title)
                .foregroundColor(.secondary)
            Text("Wähle eine Notiz oder einen Link aus")
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

// Benutzerdefinierter Button-Style für die Aktionsbuttons
struct ButtonTileStyle: ButtonStyle {
    var color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? .white : color)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ? color : color.opacity(0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Für die Vorschau
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}
