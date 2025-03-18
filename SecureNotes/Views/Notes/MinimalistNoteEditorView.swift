// DATEI: Views/Notes/MinimalistNoteEditorView.swift
import SwiftUI
import Combine
import AppKit

struct MinimalistNoteEditorView: View {
    @EnvironmentObject var notesManager: NotesManager
    let note: NotesManager.Note
    
    // Editor-Zustand
    @State private var isEditMode: Bool = true
    @State private var editableTitle: String
    @State private var editableContent: String
    @State private var editableTags: String
    @State private var contentHasChanged: Bool = false
    @State private var formattedContent: AttributedString = AttributedString("")
    
    // Auto-Save Timer
    @State private var saveTimer: AnyCancellable?
    
    // Focus-Management
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool
    
    // UI-Zustände
    @State private var showToolbar: Bool = true
    @State private var isFullScreenMode: Bool = false
    @State private var fontSize: CGFloat = 16
    @State private var showMarkdownHelp: Bool = false
    
    // Konstanten
    private let autosaveInterval: TimeInterval = 3.0
    private let minFontSize: CGFloat = 12
    private let maxFontSize: CGFloat = 24
    
    // Font-Einstellungen
    private var editorFont: Font {
        Font.system(size: fontSize)
    }
    private let readerTitleFont = Font.system(.largeTitle, design: .serif).weight(.bold)
    private let readerBodyFont = Font.system(.body, design: .serif)
    
    init(note: NotesManager.Note) {
        self.note = note
        _editableTitle = State(initialValue: note.title)
        _editableContent = State(initialValue: note.content)
        _editableTags = State(initialValue: note.tags.joined(separator: ", "))
        
        // Starte im Bearbeitungsmodus für neue Notizen
        _isEditMode = State(initialValue: note.content.isEmpty || note.modificationDate.timeIntervalSinceNow > -5)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Minimalistische Toolbar
                if showToolbar {
                    toolbar
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(
                            Color(.windowBackgroundColor)
                                .opacity(0.9)
                                .blur(radius: 3)
                        )
                }
                
                // Inhalt
                if isEditMode {
                    editingView
                } else {
                    readingView
                }
            }
            
            // Schwebendes Toolbar-Toggle für Vollbild-Modus
            if isFullScreenMode {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { showToolbar.toggle() }) {
                            Image(systemName: showToolbar ? "chevron.up" : "chevron.down")
                                .padding(10)
                                .background(Color(.windowBackgroundColor).opacity(0.8))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut("t", modifiers: .command)
                        .padding()
                    }
                    Spacer()
                }
            }
            
            // Markdown-Hilfe-Overlay
            if showMarkdownHelp {
                markdownHelpOverlay
            }
        }
        .onAppear {
            setupAutoSaveTimer()
            updateFormattedContent()
        }
        .onDisappear {
            saveTimer?.cancel()
            // Auto-Save beim Verlassen der Ansicht
            if contentHasChanged {
                saveNote()
            }
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
        HStack(spacing: 16) {
            // Linke Seite
            HStack(spacing: 8) {
                // Modus wechseln
                Button(action: {
                    if isEditMode {
                        saveNote()
                    }
                    withAnimation {
                        isEditMode.toggle()
                    }
                }) {
                    Image(systemName: isEditMode ? "eye" : "pencil")
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .help(isEditMode ? "Vorschaumodus" : "Bearbeitungsmodus")
                
                // Vollbild-Modus
                Button(action: {
                    withAnimation {
                        isFullScreenMode.toggle()
                    }
                }) {
                    Image(systemName: isFullScreenMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .help(isFullScreenMode ? "Vollbild beenden" : "Vollbild")
            }
            
            Spacer()
            
            // Rechte Seite
            HStack(spacing: 12) {
                if isEditMode {
                    // Schriftgröße
                    Button(action: { decreaseFontSize() }) {
                        Image(systemName: "textformat.size.smaller")
                    }
                    .buttonStyle(.plain)
                    .help("Schrift verkleinern")
                    
                    Button(action: { increaseFontSize() }) {
                        Image(systemName: "textformat.size.larger")
                    }
                    .buttonStyle(.plain)
                    .help("Schrift vergrößern")
                    
                    // Markdown-Hilfe
                    Button(action: { showMarkdownHelp.toggle() }) {
                        Image(systemName: "questionmark.circle")
                    }
                    .buttonStyle(.plain)
                    .help("Markdown-Hilfe")
                    
                    Divider()
                        .frame(height: 20)
                }
                
                // Letzte Änderung
                Text("Bearbeitet: \(formatDate(note.modificationDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if contentHasChanged {
                    // Speichern
                    Button(action: saveNote) {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("s", modifiers: .command)
                    .help("Speichern (⌘S)")
                }
            }
        }
    }
    
    // MARK: - Leseansicht
    
    private var readingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Titel
                Text(note.title)
                    .font(readerTitleFont)
                    .padding(.bottom, 4)
                
                // Tags
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
                
                // Gerenderter Markdown-Inhalt mit benutzerdefiniertem Renderer
                CustomMarkdownTextView(content: editableContent)
                    .font(readerBodyFont)
                    .textSelection(.enabled)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.textBackgroundColor).opacity(0.4))
    }
    
    // MARK: - Bearbeitungsansicht
    
    private var editingView: some View {
        VStack(spacing: 0) {
            // Titel und Tags
            VStack(spacing: 8) {
                TextField("Titel", text: $editableTitle, axis: .vertical)
                    .font(.system(size: 24, weight: .bold))
                    .focused($isTitleFocused)
                    .padding([.horizontal, .top])
                    .padding(16) // Mehr Padding hinzufügen
                    .background(Color.clear)
                    .onChange(of: editableTitle) { _ in
                        contentHasChanged = true
                        resetAutoSaveTimer()
                    }
                
                TextField("Tags (durch Komma getrennt)", text: $editableTags)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(16) // Mehr Padding hinzufügen
                    .onChange(of: editableTags) { _ in
                        contentHasChanged = true
                        resetAutoSaveTimer()
                    }
            }
            .padding(.bottom, 8)
            
            // Split Editor mit Live-Vorschau
            HStack(spacing: 0) {
                // Editor
                VStack {
                    MarkdownSyntaxHighlightingTextEditor(
                        text: $editableContent,
                        font: NSFont.systemFont(ofSize: fontSize),
                        onTextChange: { _ in
                            contentHasChanged = true
                            resetAutoSaveTimer()
                            updateFormattedContent()
                        }
                    )
                }
                .frame(maxWidth: .infinity)
                
                // Live-Vorschau
                Divider()
                
                ScrollView {
                    VStack(alignment: .leading) {
                        Text("Vorschau")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding([.top, .horizontal])
                        
                        Divider()
                        
                        CustomMarkdownTextView(content: editableContent)
                            .font(readerBodyFont)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color(.textBackgroundColor).opacity(0.1))
            }
        }
    }
    
    // MARK: - Markdown-Tastatur-Toolbar
    
    private var markdownKeyboardToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Button(action: { insertMarkdown("# ", replacement: "Überschrift") }) {
                    Image(systemName: "textformat.size.larger")
                }
                Button(action: { insertMarkdown("## ", replacement: "Unterüberschrift") }) {
                    Image(systemName: "textformat.size")
                }
                Button(action: { formatSelectedText(prefix: "**", suffix: "**", defaultText: "Fett") }) {
                    Image(systemName: "bold")
                }
                Button(action: { formatSelectedText(prefix: "*", suffix: "*", defaultText: "Kursiv") }) {
                    Image(systemName: "italic")
                }
                Button(action: { insertMarkdown("- ", replacement: "Listenpunkt") }) {
                    Image(systemName: "list.bullet")
                }
                Button(action: { insertMarkdown("1. ", replacement: "Nummerierter Punkt") }) {
                    Image(systemName: "list.number")
                }
                Button(action: { formatSelectedText(prefix: "`", suffix: "`", defaultText: "Code") }) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                }
                Button(action: { insertMarkdown("> ", replacement: "Zitat") }) {
                    Image(systemName: "text.quote")
                }
                Button(action: { formatSelectedText(prefix: "[", suffix: "](https://example.com)", defaultText: "Link") }) {
                    Image(systemName: "link")
                }
                Button(action: { insertMarkdown("\n---\n", replacement: "") }) {
                    Image(systemName: "minus")
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Markdown-Hilfe-Overlay
    
    private var markdownHelpOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    showMarkdownHelp = false
                }
            
            VStack {
                HStack {
                    Text("Markdown-Kurzreferenz")
                        .font(.headline)
                    Spacer()
                    Button(action: { showMarkdownHelp = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                
                Divider()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        markdownHelpSection(title: "Überschriften", examples: [
                            ("# Überschrift 1", "Größte Überschrift"),
                            ("## Überschrift 2", "Unterüberschrift"),
                            ("### Überschrift 3", "Kleinere Überschrift")
                        ])
                        
                        markdownHelpSection(title: "Formatierung", examples: [
                            ("**Fett**", "Fetter Text"),
                            ("*Kursiv*", "Kursiver Text"),
                            ("~~Durchgestrichen~~", "Durchgestrichener Text"),
                            ("`Code`", "Inline-Code")
                        ])
                        
                        markdownHelpSection(title: "Listen", examples: [
                            ("- Element", "Aufzählungsliste"),
                            ("1. Element", "Nummerierte Liste"),
                            ("   - Element", "Verschachtelte Liste (mit Einrückung)")
                        ])
                        
                        markdownHelpSection(title: "Andere Elemente", examples: [
                            ("> Zitat", "Blockzitat"),
                            ("---", "Horizontale Linie"),
                            ("[Link-Text](URL)", "Hyperlink"),
                            ("![Alt-Text](URL)", "Bild (falls unterstützt)")
                        ])
                        
                        markdownHelpSection(title: "Codeblöcke", examples: [
                            ("```\nCode hier\n```", "Codeblock mit Syntax-Highlighting")
                        ])
                    }
                    .padding()
                }
                
                Divider()
                
                Button("Schließen") {
                    showMarkdownHelp = false
                }
                .keyboardShortcut(.escape)
                .padding()
            }
            .frame(width: 500, height: 500)
            .background(Color(.windowBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 10)
        }
    }
    
    private func markdownHelpSection(title: String, examples: [(syntax: String, description: String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            ForEach(examples, id: \.syntax) { example in
                HStack(alignment: .top) {
                    Text(example.syntax)
                        .font(.system(.body, design: .monospaced))
                        .padding(6)
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(4)
                    
                    Text(example.description)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
                .padding(.vertical, 4)
        }
    }
    
    // MARK: - Formatierungs-Helfer
    
    private func formatSelectedText(prefix: String, suffix: String, defaultText: String) {
        // Vereinfachte Version ohne NSTextView-Zugriff
        let replacement = "\(prefix)\(defaultText)\(suffix)"
        
        // Einfach am Ende hinzufügen
        editableContent += replacement
        
        // Markiere, dass Änderungen vorgenommen wurden
        contentHasChanged = true
        resetAutoSaveTimer()
        updateFormattedContent()
    }
    
    private func insertMarkdown(_ prefix: String, replacement: String) {
        // Vereinfachte Implementierung, die am Ende des Textes einfügt
        let textToInsert = replacement.isEmpty ? prefix : prefix + replacement
        
        // Füge einen Zeilenumbruch ein, wenn wir nicht am Anfang des Texts sind und
        // der aktuelle Text nicht mit einem Zeilenumbruch endet
        if !editableContent.isEmpty && !editableContent.hasSuffix("\n") {
            editableContent += "\n"
        }
        
        // Füge den Markdown-Text ein
        editableContent += textToInsert
        
        // Markiere, dass Änderungen vorgenommen wurden
        contentHasChanged = true
        resetAutoSaveTimer()
        updateFormattedContent()
    }
    
    // MARK: - Auto-Save Funktionen
    
    private func setupAutoSaveTimer() {
        saveTimer = Timer.publish(every: autosaveInterval, on: .main, in: .common)
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
    
    // MARK: - Markdown-Aktualisierung
    
    private func updateFormattedContent() {
        do {
            // Konvertiere Markdown zu AttributedString
            if #available(macOS 12.0, *) {
                // Stelle sicher, dass Zeilenumbrüche korrekt berücksichtigt werden
                // Verwende MarkdownParsingOptions um Absätze richtig zu formatieren
                var options = AttributedString.MarkdownParsingOptions()
                options.interpretedSyntax = .inlineOnlyPreservingWhitespace
                
                // Bereite den Text vor, um doppelte Zeilenumbrüche als Absätze zu erhalten
                let processedContent = editableContent
                    .replacingOccurrences(of: "\n\n", with: "  \n\n") // Zwei Leerzeichen am Ende für harte Umbrüche
                
                formattedContent = try AttributedString(markdown: processedContent, options: options)
            } else {
                // Fallback für ältere Versionen
                let processedContent = editableContent
                    .replacingOccurrences(of: "\n", with: "  \n") // Zwei Leerzeichen am Ende für Zeilenumbrüche
                
                formattedContent = AttributedString(processedContent)
            }
        } catch {
            print("Fehler beim Formatieren des Markdown: \(error)")
            formattedContent = AttributedString(editableContent)
        }
    }
    
    // MARK: - Font-Größe
    
    private func increaseFontSize() {
        if fontSize < maxFontSize {
            fontSize += 1
        }
    }
    
    private func decreaseFontSize() {
        if fontSize > minFontSize {
            fontSize -= 1
        }
    }
    
    // MARK: - Speichern
    
    private func saveNote() {
        let processedTags = editableTags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var updatedNote = note
        updatedNote.title = editableTitle
        updatedNote.content = editableContent
        updatedNote.tags = processedTags
        updatedNote.modificationDate = Date()
        
        // Speichere aktualisierte Notiz im NotesManager
        if let index = notesManager.notes.firstIndex(where: { $0.id == note.id }) {
            notesManager.notes[index] = updatedNote
            contentHasChanged = false
        }
    }
    
    // MARK: - Helfer
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
