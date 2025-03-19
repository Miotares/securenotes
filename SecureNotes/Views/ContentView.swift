// DATEI: Views/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab: String? = "notes"
    @State private var selectedNote: UUID? = nil
    @State private var selectedLink: UUID? = nil
    @State private var showingSidebar: Bool = true
    @State private var showingVaultSwitcher: Bool = false
    @State private var showingNewVaultDialog: Bool = false
    @State private var showingNewNote: Bool = false
    @State private var showingNewLink: Bool = false
    @State private var showingNewFolder: Bool = false
    @State private var searchText: String = ""
    @State private var sortOption: SortOption = .dateModified
    @State private var noteEditorMode: Bool = false
    @State private var linkEditorMode: Bool = false
    
    enum SortOption: String, CaseIterable, Identifiable {
        case dateModified = "Date Modified"
        case dateCreated = "Date Created"
        case title = "Title"
        
        var id: String { self.rawValue }
        
        var systemImage: String {
            switch self {
            case .dateModified: return "calendar.badge.clock"
            case .dateCreated: return "calendar.badge.plus"
            case .title: return "textformat.abc"
            }
        }
    }
    
    // Mock data
    let mockNotes = (1...15).map { i in
        MockNote(
            id: UUID(),
            title: "Note \(i)",
            content: "This is the content for note \(i). It contains some text that gives an idea of what the note is about.",
            tags: i % 3 == 0 ? ["work", "important"] : (i % 3 == 1 ? ["personal"] : ["ideas"]),
            date: Date().addingTimeInterval(-TimeInterval(i * 3600))
        )
    }
    
    let mockLinks = (1...8).map { i in
        MockLink(
            id: UUID(),
            title: "Link \(i)",
            url: "https://example.com/page\(i)",
            tags: i % 2 == 0 ? ["reference"] : ["bookmark"],
            date: Date().addingTimeInterval(-TimeInterval(i * 7200))
        )
    }
    
    let mockFolders = [
        MockFolder(id: "work", name: "Work", color: .blue, count: 5),
        MockFolder(id: "personal", name: "Personal", color: .green, count: 3),
        MockFolder(id: "projects", name: "Projects", color: .orange, count: 7)
    ]
    
    var body: some View {
        NavigationView {
            // First column: Sidebar
            VStack(spacing: 0) {
                // Sidebar Header
                HStack {
                    Text("SecureNotes")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let vault = authViewModel.currentVault {
                        Text("· \(vault.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding([.horizontal, .top])
                .padding(.bottom, 8)
                
                // Sidebar content
                sidebarContent
                
                Spacer()
                
                // Action buttons at bottom of sidebar
                actionButtons
            }
            .frame(minWidth: 220, maxWidth: 250)
            
            // Second column: Content overview
            Group {
                contentOverviewColumn
            }
            .frame(minWidth: 250)
            .background(Color(.windowBackgroundColor).opacity(0.6))
            
            // Third column: Detail view
            Group {
                detailColumn
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
                .help("Toggle sidebar")
            }
            
            ToolbarItem(placement: .automatic) {
                Menu {
                    // Vault management menu
                    Button(action: { showingVaultSwitcher = true }) {
                        Label("Switch Vault", systemImage: "folder.badge.person.crop")
                    }
                    
                    Button(action: { showingNewVaultDialog = true }) {
                        Label("Create New Vault", systemImage: "folder.badge.plus")
                    }
                    
                    Divider()
                    
                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        Label("Sign Out", systemImage: "lock.fill")
                    }
                } label: {
                    if let vault = authViewModel.currentVault {
                        Label(vault.name, systemImage: vault.isEncrypted ? "lock.shield" : "shield")
                    } else {
                        Label("Vault", systemImage: "lock.shield")
                    }
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    authViewModel.signOut()
                }) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.red)
                }
                .help("Sign out")
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .sheet(isPresented: $showingVaultSwitcher) {
            vaultSwitcherSheet
        }
        .sheet(isPresented: $showingNewVaultDialog) {
            newVaultSheet
        }
        .sheet(isPresented: $showingNewNote) {
            newNoteSheet
        }
        .sheet(isPresented: $showingNewLink) {
            newLinkSheet
        }
        .sheet(isPresented: $showingNewFolder) {
            newFolderSheet
        }
        .navigationTitle("")
        .onAppear {
            setupNotifications()
        }
    }
    
    // Sidebar content
    private var sidebarContent: some View {
        List(selection: Binding<String?>(
            get: { selectedTab },
            set: { if let newValue = $0 { selectedTab = newValue } }
        )) {
            Section(header: Text("LIBRARY")) {
                NavigationLink(destination: EmptyView(), tag: "inbox", selection: $selectedTab) {
                    Label("Inbox", systemImage: "tray")
                        .foregroundColor(.primary)
                }
                
                NavigationLink(destination: EmptyView(), tag: "notes", selection: $selectedTab) {
                    Label("All Notes", systemImage: "note.text")
                        .foregroundColor(.green)
                }
                
                NavigationLink(destination: EmptyView(), tag: "links", selection: $selectedTab) {
                    Label("All Links", systemImage: "link")
                        .foregroundColor(.blue)
                }
            }
            
            Section(header:
                HStack {
                    Text("FOLDERS")
                    Spacer()
                    Button(action: { showingNewFolder = true }) {
                        Image(systemName: "plus")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            ) {
                ForEach(mockFolders, id: \.id) { folder in
                    NavigationLink(destination: EmptyView(), tag: folder.id, selection: $selectedTab) {
                        Label {
                            Text(folder.name)
                        } icon: {
                            Image(systemName: "folder.fill")
                                .foregroundColor(folder.color)
                        }
                    }
                    .contextMenu {
                        Button(action: {}) {
                            Label("Rename", systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {}) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            
            Section(header: Text("TAGS")) {
                Label("work", systemImage: "tag")
                    .foregroundColor(.primary)
                Label("personal", systemImage: "tag")
                    .foregroundColor(.primary)
                Label("important", systemImage: "tag")
                    .foregroundColor(.primary)
            }
        }
        .listStyle(SidebarListStyle())
    }
    
    // Action buttons
    private var actionButtons: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 0) {
                Button(action: { showingNewNote = true }) {
                    VStack(spacing: 6) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 18))
                        Text("New Note")
                            .font(.system(size: 11))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(SidebarButtonStyle(color: .green))
                
                Divider()
                    .frame(height: 40)
                
                Button(action: { showingNewLink = true }) {
                    VStack(spacing: 6) {
                        Image(systemName: "link.badge.plus")
                            .font(.system(size: 18))
                        Text("New Link")
                            .font(.system(size: 11))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(SidebarButtonStyle(color: .blue))
            }
        }
    }
    
    // Content overview column
    private var contentOverviewColumn: some View {
        VStack {
            // Header with search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search...", text: $searchText)
                
                Spacer()
                
                Menu {
                    ForEach(SortOption.allCases) { option in
                        Button(action: { sortOption = option }) {
                            Label(option.rawValue, systemImage: option.systemImage)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(sortOption.rawValue)
                            .font(.caption)
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Divider()
            
            // Content list based on selected tab
            if selectedTab == "notes" || selectedTab == "work" || selectedTab == "personal" || selectedTab == "projects" {
                notesList
            } else if selectedTab == "links" {
                linksList
            } else if selectedTab == "inbox" {
                inboxList
            } else {
                Text("Select a category from the sidebar")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // Notes list
    private var notesList: some View {
        List(selection: Binding<UUID?>(
            get: { selectedNote },
            set: { if let newValue = $0 { selectedNote = newValue; selectedLink = nil } }
        )) {
            let filteredNotes = filterNotes()
            
            if filteredNotes.isEmpty {
                Text("No notes found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(filteredNotes) { note in
                    noteRow(note: note)
                        .tag(note.id)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // Links list
    private var linksList: some View {
        List(selection: Binding<UUID?>(
            get: { selectedLink },
            set: { if let newValue = $0 { selectedLink = newValue; selectedNote = nil } }
        )) {
            let filteredLinks = filterLinks()
            
            if filteredLinks.isEmpty {
                Text("No links found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(filteredLinks) { link in
                                    linkRow(link: link)
                                        .tag(link.id)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                    
                    // Inbox list
                    private var inboxList: some View {
                        List {
                            Section(header: Text("NOTES")) {
                                ForEach(mockNotes.prefix(3)) { note in
                                    noteRow(note: note)
                                        .tag(note.id)
                                        .onTapGesture {
                                            selectedNote = note.id
                                            selectedLink = nil
                                        }
                                }
                            }
                            
                            Section(header: Text("LINKS")) {
                                ForEach(mockLinks.prefix(2)) { link in
                                    linkRow(link: link)
                                        .tag(link.id)
                                        .onTapGesture {
                                            selectedLink = link.id
                                            selectedNote = nil
                                        }
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                    
                    // Note row
                    private func noteRow(note: MockNote) -> some View {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.title)
                                .font(.headline)
                            
                            Text(note.content)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            
                            HStack {
                                Text(formattedDate(note.date))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                // Tags
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
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button(action: {}) {
                                Label("Open in New Window", systemImage: "macwindow")
                            }
                            
                            Button(action: {}) {
                                Label("Move to Folder", systemImage: "folder")
                            }
                            
                            Button(action: {}) {
                                Label("Add Tags", systemImage: "tag")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: {}) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    
                    // Link row
                    private func linkRow(link: MockLink) -> some View {
                        HStack(spacing: 12) {
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(link.title)
                                    .font(.headline)
                                
                                Text(link.url)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text(formattedDate(link.date))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    // Tags
                                    ForEach(link.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button(action: {}) {
                                Label("Open in Browser", systemImage: "safari")
                            }
                            
                            Button(action: {}) {
                                Label("Move to Folder", systemImage: "folder")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: {}) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    
                    // Detail column
                    private var detailColumn: some View {
                        VStack {
                            if let noteId = selectedNote, let note = mockNotes.first(where: { $0.id == noteId }) {
                                noteDetailView(note: note)
                            } else if let linkId = selectedLink, let link = mockLinks.first(where: { $0.id == linkId }) {
                                linkDetailView(link: link)
                            } else {
                                emptyDetailView
                            }
                        }
                    }
                    
                    // Note detail view
                    private func noteDetailView(note: MockNote) -> some View {
                        VStack(spacing: 0) {
                            HStack {
                                if noteEditorMode {
                                    TextField("Title", text: .constant(note.title))
                                        .font(.title)
                                } else {
                                    Text(note.title)
                                        .font(.title)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    noteEditorMode.toggle()
                                }) {
                                    Image(systemName: noteEditorMode ? "checkmark.circle" : "square.and.pencil")
                                        .font(.title3)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                            
                            Divider()
                            
                            if noteEditorMode {
                                TextEditor(text: .constant(note.content))
                                    .font(.body)
                                    .padding()
                            } else {
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text(note.content)
                                            .font(.body)
                                            .padding()
                                        
                                        Divider()
                                        
                                        HStack {
                                            Text("Tags:")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                            
                                            ForEach(note.tags, id: \.self) { tag in
                                                Text(tag)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.blue.opacity(0.1))
                                                    .cornerRadius(4)
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding()
                                        
                                        Text("Created: \(formattedDate(note.date))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal)
                                        
                                        Text("Modified: \(formattedDate(note.date))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal)
                                            .padding(.bottom)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Link detail view
                    private func linkDetailView(link: MockLink) -> some View {
                        VStack(spacing: 0) {
                            HStack {
                                if linkEditorMode {
                                    TextField("Title", text: .constant(link.title))
                                        .font(.title)
                                } else {
                                    Text(link.title)
                                        .font(.title)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        guard let url = URL(string: link.url) else { return }
                                        NSWorkspace.shared.open(url)
                                    }) {
                                        Image(systemName: "safari")
                                            .font(.title3)
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Button(action: {
                                        linkEditorMode.toggle()
                                    }) {
                                        Image(systemName: linkEditorMode ? "checkmark.circle" : "square.and.pencil")
                                            .font(.title3)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                            .padding()
                            
                            Divider()
                            
                            if linkEditorMode {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("URL:")
                                        .font(.headline)
                                    
                                    TextField("URL", text: .constant(link.url))
                                        .textFieldStyle(.roundedBorder)
                                    
                                    Text("Tags:")
                                        .font(.headline)
                                        .padding(.top)
                                    
                                    TextField("Tags (comma separated)", text: .constant(link.tags.joined(separator: ", ")))
                                        .textFieldStyle(.roundedBorder)
                                    
                                    Text("Notes:")
                                        .font(.headline)
                                        .padding(.top)
                                    
                                    TextEditor(text: .constant("Add notes about this link..."))
                                        .frame(height: 120)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 16) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("URL:")
                                                .font(.headline)
                                            
                                            Text(link.url)
                                                .font(.body)
                                                .foregroundColor(.blue)
                                                .padding(.horizontal)
                                                .onTapGesture {
                                                    guard let url = URL(string: link.url) else { return }
                                                    NSWorkspace.shared.open(url)
                                                }
                                        }
                                        .padding(.horizontal)
                                        
                                        Divider()
                                            .padding(.vertical)
                                        
                                        HStack {
                                            Text("Tags:")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                            
                                            ForEach(link.tags, id: \.self) { tag in
                                                Text(tag)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.blue.opacity(0.1))
                                                    .cornerRadius(4)
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                        
                                        Spacer()
                                            .frame(height: 40)
                                        
                                        VStack(alignment: .leading) {
                                            Text("Added: \(formattedDate(link.date))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            Text("Last visited: Never")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(.top, 2)
                                        }
                                        .padding(.horizontal)
                                        .padding(.bottom)
                                    }
                                    .padding(.top)
                                }
                            }
                        }
                    }
                    
                    // Empty detail view
                    private var emptyDetailView: some View {
                        VStack {
                            Spacer()
                            
                            VStack(spacing: 20) {
                                Image(systemName: "square.text.square")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary.opacity(0.6))
                                
                                Text("No Selection")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                                
                                Text("Select a note or link to view")
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
                    
                    // Vault switcher sheet
                    private var vaultSwitcherSheet: some View {
                        VStack(spacing: 20) {
                            Text("Switch Vault")
                                .font(.title)
                                .padding(.top)
                            
                            List {
                                // Vault items would go here
                                Text("My Vault")
                                Text("Work Vault")
                            }
                            
                            HStack {
                                Button("Cancel") { showingVaultSwitcher = false }
                                Spacer()
                                Button("Switch") { showingVaultSwitcher = false }
                                    .buttonStyle(.borderedProminent)
                            }
                            .padding()
                        }
                        .frame(width: 500, height: 400)
                    }
                    
                    // New vault sheet
                    private var newVaultSheet: some View {
                        VStack(spacing: 20) {
                            Text("Create New Vault")
                                .font(.title)
                                .padding(.top)
                            
                            // Vault creation fields would go here
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Name:")
                                    .font(.headline)
                                
                                TextField("My Vault", text: .constant(""))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 300)
                                
                                Text("Location:")
                                    .font(.headline)
                                    .padding(.top, 8)
                                
                                HStack {
                                    Text("/Users/...")
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Button("Browse...") {}
                                }
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                                .frame(width: 300)
                                
                                Toggle("Encrypt vault", isOn: .constant(true))
                                    .padding(.top, 8)
                                    .frame(width: 300)
                            }
                            
                            Spacer()
                            
                            HStack {
                                Button("Cancel") { showingNewVaultDialog = false }
                                Spacer()
                                Button("Create") { showingNewVaultDialog = false }
                                    .buttonStyle(.borderedProminent)
                            }
                            .padding()
                        }
                        .frame(width: 500, height: 400)
                    }
                    
                    // New note sheet
                    private var newNoteSheet: some View {
                        VStack(spacing: 20) {
                            Text("New Note")
                                .font(.title)
                                .padding(.top)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                TextField("Title", text: .constant(""))
                                    .textFieldStyle(.roundedBorder)
                                    .padding(.horizontal)
                                
                                Text("Content:")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                TextEditor(text: .constant(""))
                                    .padding(.horizontal)
                                    .frame(height: 200)
                                    .border(Color.gray.opacity(0.2))
                                
                                Text("Tags (comma separated):")
                                    .font(.headline)
                                    .padding(.top, 4)
                                    .padding(.horizontal)
                                
                                TextField("work, important", text: .constant(""))
                                    .textFieldStyle(.roundedBorder)
                                    .padding(.horizontal)
                                
                                Text("Folder:")
                                    .font(.headline)
                                    .padding(.top, 4)
                                    .padding(.horizontal)
                                
                                Picker("", selection: .constant("")) {
                                    Text("Inbox").tag("")
                                    ForEach(mockFolders, id: \.id) { folder in
                                        Text(folder.name).tag(folder.id)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 200)
                                .padding(.horizontal)
                            }
                            
                            Spacer()
                            
                            HStack {
                                Button("Cancel") { showingNewNote = false }
                                Spacer()
                                Button("Save") { showingNewNote = false }
                                    .buttonStyle(.borderedProminent)
                            }
                            .padding()
                        }
                        .frame(width: 500, height: 500)
                    }
                    
                    // New link sheet
                    private var newLinkSheet: some View {
                        VStack(spacing: 20) {
                            Text("New Link")
                                .font(.title)
                                .padding(.top)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                TextField("Title", text: .constant(""))
                                    .textFieldStyle(.roundedBorder)
                                    .padding(.horizontal)
                                
                                Text("URL:")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                TextField("https://", text: .constant(""))
                                    .textFieldStyle(.roundedBorder)
                                    .padding(.horizontal)
                                
                                Text("Description:")
                                    .font(.headline)
                                    .padding(.top, 4)
                                    .padding(.horizontal)
                                
                                TextEditor(text: .constant(""))
                                    .padding(.horizontal)
                                    .frame(height: 100)
                                    .border(Color.gray.opacity(0.2))
                                
                                Text("Tags (comma separated):")
                                    .font(.headline)
                                    .padding(.top, 4)
                                    .padding(.horizontal)
                                
                                TextField("reference, bookmark", text: .constant(""))
                                    .textFieldStyle(.roundedBorder)
                                    .padding(.horizontal)
                                
                                Text("Folder:")
                                    .font(.headline)
                                    .padding(.top, 4)
                                    .padding(.horizontal)
                                
                                Picker("", selection: .constant("")) {
                                    Text("Inbox").tag("")
                                    ForEach(mockFolders, id: \.id) { folder in
                                        Text(folder.name).tag(folder.id)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 200)
                                .padding(.horizontal)
                            }
                            
                            Spacer()
                            
                            HStack {
                                Button("Cancel") { showingNewLink = false }
                                Spacer()
                                Button("Save") { showingNewLink = false }
                                    .buttonStyle(.borderedProminent)
                            }
                            .padding()
                        }
                        .frame(width: 500, height: 500)
                    }
                    
                    // New folder sheet
                    private var newFolderSheet: some View {
                        VStack(spacing: 20) {
                            Text("New Folder")
                                .font(.title)
                                .padding(.top)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Name:")
                                    .font(.headline)
                                
                                TextField("Folder Name", text: .constant(""))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 300)
                                
                                Text("Color:")
                                    .font(.headline)
                                    .padding(.top, 8)
                                
                                HStack(spacing: 12) {
                                    ForEach([Color.blue, Color.green, Color.red, Color.orange, Color.purple, Color.pink], id: \.self) { color in
                                        Circle()
                                            .fill(color)
                                            .frame(width: 30, height: 30)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 2)
                                                    .opacity(0.6)
                                            )
                                            .onTapGesture {}
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            HStack {
                                Button("Cancel") { showingNewFolder = false }
                                Spacer()
                                Button("Create") { showingNewFolder = false }
                                    .buttonStyle(.borderedProminent)
                            }
                            .padding()
                        }
                        .frame(width: 400, height: 300)
                    }
                    
                    // Helper methods
                    private func filterNotes() -> [MockNote] {
                        var result = mockNotes
                        
                        // Filter by category if not "All Notes"
                        if let tab = selectedTab, tab != "notes" {
                            // Here we would filter by folder or category
                        }
                        
                        // Filter by search term
                        if !searchText.isEmpty {
                            result = result.filter { note in
                                note.title.localizedCaseInsensitiveContains(searchText) ||
                                note.content.localizedCaseInsensitiveContains(searchText) ||
                                note.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
                            }
                        }
                        
                        // Apply sorting
                        switch sortOption {
                        case .dateModified:
                            result.sort { $0.date > $1.date }
                        case .dateCreated:
                            result.sort { $0.date > $1.date } // In a real app, would use creation date
                        case .title:
                            result.sort { $0.title < $1.title }
                        }
                        
                        return result
                    }
                    
                    private func filterLinks() -> [MockLink] {
                        var result = mockLinks
                        
                        // Filter by search term
                        if !searchText.isEmpty {
                            result = result.filter { link in
                                link.title.localizedCaseInsensitiveContains(searchText) ||
                                link.url.localizedCaseInsensitiveContains(searchText) ||
                                link.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
                            }
                        }
                        
                        // Apply sorting
                        switch sortOption {
                        case .dateModified:
                            result.sort { $0.date > $1.date }
                        case .dateCreated:
                            result.sort { $0.date > $1.date } // In a real app, would use creation date
                        case .title:
                            result.sort { $0.title < $1.title }
                        }
                        
                        return result
                    }
                    
                    private func formattedDate(_ date: Date) -> String {
                        // For recent dates, show relative formatting
                        let calendar = Calendar.current
                        if calendar.isDateInToday(date) {
                            return "Today"
                        } else if calendar.isDateInYesterday(date) {
                            return "Yesterday"
                        } else if let days = calendar.dateComponents([.day], from: date, to: Date()).day, days < 7 {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "EEEE" // Day of week
                            return formatter.string(from: date)
                        } else {
                            // For older dates, show the actual date
                            let formatter = DateFormatter()
                            formatter.dateStyle = .medium
                            formatter.timeStyle = .none
                            return formatter.string(from: date)
                        }
                    }
                    
                    private func toggleSidebar() {
                        showingSidebar.toggle()
                        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                    }
                    
                    private func setupNotifications() {
                        NotificationCenter.default.addObserver(forName: NSNotification.Name("CreateNewNote"), object: nil, queue: .main) { _ in
                            self.showingNewNote = true
                        }
                        
                        NotificationCenter.default.addObserver(forName: NSNotification.Name("CreateNewLink"), object: nil, queue: .main) { _ in
                            self.showingNewLink = true
                        }
                        
                        NotificationCenter.default.addObserver(forName: NSNotification.Name("CreateNewFolder"), object: nil, queue: .main) { _ in
                            self.showingNewFolder = true
                        }
                        
                        NotificationCenter.default.addObserver(forName: NSNotification.Name("SwitchVault"), object: nil, queue: .main) { _ in
                            self.showingVaultSwitcher = true
                        }
                        
                        NotificationCenter.default.addObserver(forName: NSNotification.Name("CreateNewVault"), object: nil, queue: .main) { _ in
                            self.showingNewVaultDialog = true
                        }
                    }
                }

                // Button style for the sidebar action buttons
                struct SidebarButtonStyle: ButtonStyle {
                    var color: Color
                    
                    func makeBody(configuration: Configuration) -> some View {
                        configuration.label
                            .foregroundColor(configuration.isPressed ? .white : color)
                            .background(
                                configuration.isPressed ?
                                    color.opacity(0.8) :
                                    Color.clear
                            )
                            .contentShape(Rectangle())
                    }
                }

                // Mock data structures
                struct MockNote: Identifiable {
                    let id: UUID
                    let title: String
                    let content: String
                    let tags: [String]
                    let date: Date
                }

                struct MockLink: Identifiable {
                    let id: UUID
                    let title: String
                    let url: String
                    let tags: [String]
                    let date: Date
                }

                struct MockFolder: Identifiable {
                    let id: String
                    let name: String
                    let color: Color
                    let count: Int
                }
