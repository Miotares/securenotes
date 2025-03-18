// DATEI: Views/ContentView.swift
import SwiftUI

// Importiere die zentrale Definition von SidebarTab
// In einem echten Projekt würde dies durch die richtige Module-Import-Anweisung ersetzt
// Für unser Projekt behandeln wir SidebarTabKit als Teil des Hauptmoduls

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab: SidebarTab = .notes
    @StateObject private var notesManager = NotesManager()
    @StateObject private var linkViewModel = LinkViewModel()
    @State private var selectedNote: NotesManager.Note?
    @State private var selectedLink: LinkViewModel.Link?
    @State private var showingSidebar: Bool = true
    
    var body: some View {
        NavigationView {
            // Erste Spalte: Seitenleiste
            ZStack {
                Color(.windowBackgroundColor).opacity(0.15)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Sidebar Header
                    HStack {
                        Text("SecureNotes")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding([.horizontal, .top])
                    .padding(.bottom, 8)
                    
                    // Seitenleiste Inhalt
                    SidebarView(selectedTab: $selectedTab)
                        .environmentObject(notesManager)
                        .environmentObject(linkViewModel)
                    
                    Spacer()
                    
                    // Aktionsbuttons unten in der Seitenleiste
                    VStack(spacing: 0) {
                        Divider()
                        
                        HStack(spacing: 0) {
                            Button(action: createNewNote) {
                                VStack(spacing: 6) {
                                    Image(systemName: "square.and.pencil")
                                        .font(.system(size: 18))
                                    Text("Neue Notiz")
                                        .font(.system(size: 11))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(SidebarButtonStyle(color: .green))
                            
                            Divider()
                                .frame(height: 40)
                            
                            Button(action: createNewLink) {
                                VStack(spacing: 6) {
                                    Image(systemName: "link.badge.plus")
                                        .font(.system(size: 18))
                                    Text("Neuer Link")
                                        .font(.system(size: 11))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(SidebarButtonStyle(color: .blue))
                        }
                    }
                }
            }
            .frame(minWidth: 220, maxWidth: 250)
            
            // Zweite Spalte: Inhaltsübersicht
            Group {
                // Explizite Typprüfung für den Switch
                contentForSelectedTab
            }
            .frame(minWidth: 250)
            .background(Color(.windowBackgroundColor).opacity(0.6))
            
            // Dritte Spalte: Detailansicht
            Group {
                if let note = selectedNote {
                    MinimalistNoteEditorView(note: note)
                        .environmentObject(notesManager)
                } else if let link = selectedLink {
                    LinkDetailView(link: link)
                        .environmentObject(linkViewModel)
                } else {
                    EmptyDetailView()
                }
            }
            .frame(minWidth: 400)
            .background(Color(.textBackgroundColor).opacity(0.4))
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar) {
                    Image(systemName: "sidebar.left")
                        .foregroundColor(.primary)
                }
                .help("Seitenleiste ein-/ausblenden")
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    authViewModel.signOut()
                }) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.red)
                }
                .help("Abmelden")
            }
        }
        .navigationTitle("")
        .frame(minWidth: 900, minHeight: 600)
    }
    
    // Extrahiert die View für den ausgewählten Tab, damit der Swift-Compiler besser arbeiten kann
    @ViewBuilder
    private var contentForSelectedTab: some View {
        switch selectedTab {
        case .inbox:
            NoteListColumn(selectedNote: $selectedNote)
                .environmentObject(notesManager)
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
        showingSidebar.toggle()
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

// Button-Style für die Aktionsbuttons in der Seitenleiste
struct SidebarButtonStyle: ButtonStyle {
    var color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? .white : color)
            .background(
                configuration.isPressed ?
                    color.opacity(0.8) :
                    Color(.windowBackgroundColor).opacity(0.6)
            )
            .contentShape(Rectangle())
    }
}

// Leere Detailansicht, wenn nichts ausgewählt ist
struct EmptyDetailView: View {
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "square.text.square")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary.opacity(0.6))
                
                Text("Keine Auswahl")
                    .font(.title)
                    .foregroundColor(.secondary)
                
                Text("Wähle eine Notiz oder einen Link aus")
                    .foregroundColor(.secondary)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.05))
            )
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
