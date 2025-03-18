// DATEI: Views/Notes/ImprovedNoteDetailView.swift
import SwiftUI
import Combine

struct ImprovedNoteDetailView: View {
    @EnvironmentObject var notesManager: NotesManager
    let note: NotesManager.Note
    
    @State private var isEditMode: Bool = true
    @State private var editableTitle: String
    @State private var editableContent: String
    @State private var lastSavedContent: String
    @State private var contentHasChanged: Bool = false
    @State private var formattedContent: AttributedString = AttributedString("")
    
    // Auto-Save Timer
    @State private var saveTimer: AnyCancellable?
    
    // Focus-Management
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool
    
    // Font settings
    private let editorFont = Font.system(.body)
    private let readerTitleFont = Font.system(.largeTitle, design: .serif).weight(.bold)
    private let readerBodyFont = Font.system(.body, design: .serif)
    
    init(note: NotesManager.Note) {
        self.note = note
        _editableTitle = State(initialValue: note.title)
        _editableContent = State(initialValue: note.content)
        _lastSavedContent = State(initialValue: note.content)
        
        // Start in edit mode for new notes
        _isEditMode = State(initialValue: note.content.isEmpty || note.modificationDate.timeIntervalSinceNow > -5)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar
                .padding()
                .background(Color(.windowBackgroundColor))
            
            Divider()
            
            // Content
            if isEditMode {
                editingView
            } else {
                readingView
            }
        }
        .onAppear {
            setupAutoSaveTimer()
            updateFormattedContent()
        }
        .onDisappear {
            saveTimer?.cancel()
            
            // Auto-save when leaving the view
            if contentHasChanged {
                saveNote()
            }
        }
    }
    
    // Toolbar for both modes
    private var toolbar: some View {
        HStack(spacing: 16) {
            // Left side: Mode toggle
            Button(action: {
                if isEditMode {
                    saveNote()
                }
                isEditMode.toggle()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: isEditMode ? "eye" : "pencil")
                    Text(isEditMode ? "Vorschau" : "Bearbeiten")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.windowBackgroundColor).opacity(0.5))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .help(isEditMode ? "Vorschaumodus anzeigen" : "Bearbeitungsmodus")
            
            // Middle: Shows current mode
            Text(isEditMode ? "Bearbeitungsmodus" : "Lesemodus")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Info about last edit
            Text("Bearbeitet: \(formatDate(note.modificationDate))")
                .font(.caption)
                .foregroundColor(.secondary)
                
            if contentHasChanged {
                Button(action: saveNote) {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.blue)
                }
                .keyboardShortcut("s", modifiers: .command)
                .help("Speichern (⌘S)")
            }
            
            if isEditMode {
                Button("Speichern") {
                    saveNote()
                }
                .keyboardShortcut("s", modifiers: .command)
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    // Reading view with markdown rendering
    private var readingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title
                Text(note.title)
                    .font(readerTitleFont)
                    .padding(.bottom, 4)
                
                // Metadata: tags and date
                if !note.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(note.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Rendered markdown content
                Text(formattedContent)
                    .font(readerBodyFont)
                    .textSelection(.enabled)
                    .lineSpacing(1.4)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.textBackgroundColor).opacity(0.4))
    }
    
    // Editing view with markdown support
    private var editingView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Editable title
                    TextField("Titel", text: $editableTitle, axis: .vertical)
                        .font(.system(size: 24, weight: .bold))
                        .focused($isTitleFocused)
                        .padding([.horizontal, .top])
                        .background(Color.clear)
                        .onChange(of: editableTitle) { _ in
                            contentHasChanged = true
                            resetAutoSaveTimer()
                        }
                    
                    // Tags input
                    HStack {
                        Text("Tags:")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        
                        let tagsString = note.tags.joined(separator: ", ")
                        Text(tagsString.isEmpty ? "Keine Tags" : tagsString)
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Markdown editor
                    TextEditor(text: $editableContent)
                        .font(editorFont)
                        .lineSpacing(1.2)
                        .focused($isContentFocused)
                        .padding([.horizontal])
                        .frame(minHeight: 300)
                        .onChange(of: editableContent) { _ in
                            contentHasChanged = true
                            resetAutoSaveTimer()
                            updateFormattedContent()
                        }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 40)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Menu {
                    markdownHelpMenu
                } label: {
                    Label("Markdown", systemImage: "text.badge.checkmark")
                }
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: insertHeading) {
                    Image(systemName: "textformat.size")
                }
                .help("Überschrift einfügen")
                
                Button(action: insertBulletList) {
                    Image(systemName: "list.bullet")
                }
                .help("Liste einfügen")
                
                Button(action: insertBlockquote) {
                    Image(systemName: "text.quote")
                }
                .help("Zitat einfügen")
                
                Menu {
                    Button(action: { formatSelectedText(prefix: "**", suffix: "**") }) {
                        Label("Fett", systemImage: "bold")
                    }
                    
                    Button(action: { formatSelectedText(prefix: "*", suffix: "*") }) {
                        Label("Kursiv", systemImage: "italic")
                    }
                    
                    Button(action: { formatSelectedText(prefix: "~~", suffix: "~~") }) {
                        Label("Durchgestrichen", systemImage: "strikethrough")
                    }
                    
                    Button(action: { formatSelectedText(prefix: "`", suffix: "`") }) {
                        Label("Code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    
                    Divider()
                    
                    Button(action: insertLink) {
                        Label("Link", systemImage: "link")
                    }
                } label: {
                    Image(systemName: "textformat")
                }
            }
        }
    }
    
    // MARK: - Markdown Help Menu
    private var markdownHelpMenu: some View {
        Group {
            Section {
                Label("Markdown Formatierung", systemImage: "info.circle")
                    .font(.headline)
            }
            
            Divider()
            
            Section {
                Text("# Überschrift 1")
                Text("## Überschrift 2")
                Text("### Überschrift 3")
            }
            
            Divider()
            
            Section {
                Text("**Fett**")
                Text("*Kursiv*")
                Text("~~Durchgestrichen~~")
                Text("`Code`")
            }
            
            Divider()
            
            Section {
                Text("- Aufzählungspunkt")
                Text("1. Nummerierte Liste")
                Text("> Zitat")
                Text("---  (Horizontale Linie)")
            }
            
            Divider()
            
            Section {
                Text("[Link Text](URL)")
            }
        }
    }
    
    // MARK: - Auto-Save Functions
    private func setupAutoSaveTimer() {
        saveTimer = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if contentHasChanged {
                    saveNote()
                }
            }
    }
    
    private func resetAutoSaveTimer() {
        saveTimer?.cancel()
        setupAutoSaveTimer()
    }
    
    // MARK: - Update Formatted Content
    private func updateFormattedContent() {
        do {
            // Convert markdown to AttributedString
            if #available(macOS 12.0, *) {
                formattedContent = try AttributedString(markdown: editableContent)
            } else {
                // Fallback for older versions
                formattedContent = AttributedString(editableContent)
            }
        } catch {
            print("Error formatting markdown: \(error)")
            formattedContent = AttributedString(editableContent)
        }
    }
    
    // MARK: - Text Formatting Helpers
    private func insertHeading() {
        let newText = "## Überschrift\n"
        if editableContent.isEmpty {
            editableContent = newText
        } else {
            // Insert at cursor position (simplified implementation)
            editableContent += "\n\(newText)"
        }
        contentHasChanged = true
        resetAutoSaveTimer()
    }
    
    private func insertBulletList() {
        let newText = "- Listenpunkt\n"
        if editableContent.isEmpty {
            editableContent = newText
        } else {
            editableContent += "\n\(newText)"
        }
        contentHasChanged = true
        resetAutoSaveTimer()
    }
    
    private func insertBlockquote() {
        let newText = "> Zitat\n"
        if editableContent.isEmpty {
            editableContent = newText
        } else {
            editableContent += "\n\(newText)"
        }
        contentHasChanged = true
        resetAutoSaveTimer()
    }
    
    private func insertLink() {
        let newText = "[Link-Text](https://example.com)"
        if editableContent.isEmpty {
            editableContent = newText
        } else {
            editableContent += " \(newText)"
        }
        contentHasChanged = true
        resetAutoSaveTimer()
    }
    
    private func formatSelectedText(prefix: String, suffix: String) {
        // Note: In a complete implementation, this would format the currently selected text
        // Here just a simple demonstration
        
        let newText = "\(prefix)Text\(suffix)"
        if editableContent.isEmpty {
            editableContent = newText
        } else {
            editableContent += " \(newText)"
        }
        contentHasChanged = true
        resetAutoSaveTimer()
    }
    
    // MARK: - Save Function
    private func saveNote() {
        var updatedNote = note
        updatedNote.title = editableTitle
        updatedNote.content = editableContent
        updatedNote.modificationDate = Date()
        
        // Save the updated note in NotesManager
        if let index = notesManager.notes.firstIndex(where: { $0.id == note.id }) {
            notesManager.notes[index] = updatedNote
            lastSavedContent = editableContent
            contentHasChanged = false
        }
    }
    
    // MARK: - Helper Functions
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Placeholder for the SimpleWorkingEditor component
// You'll need to implement this separately or replace with TextEditor
struct SimpleWorkingEditor: View {
    @Binding var text: String
    
    var body: some View {
        TextEditor(text: $text)
            .font(.body)
            .padding(.horizontal)
            .frame(minHeight: 300)
    }
}
