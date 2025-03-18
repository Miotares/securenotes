// DATEI: Views/Notes/NoteDetailView.swift
import SwiftUI

struct NoteDetailView: View {
    @EnvironmentObject var notesManager: NotesManager
    let note: NotesManager.Note
    @State private var isEditing: Bool
    @State private var editedTitle: String
    @State private var editedContent: String
    @State private var editedTags: String
    @State private var formattedContent: AttributedString = AttributedString("")
    
    // Font settings
    private let editorFont = Font.system(.body)
    private let readerTitleFont = Font.system(.largeTitle, design: .serif).weight(.bold)
    private let readerBodyFont = Font.system(.body, design: .serif)
    
    init(note: NotesManager.Note) {
        self.note = note
        _editedTitle = State(initialValue: note.title)
        _editedContent = State(initialValue: note.content)
        _editedTags = State(initialValue: note.tags.joined(separator: ", "))
        
        // Startet im Bearbeitungsmodus, wenn es eine neue Notiz ist (oder der Inhalt leer ist)
        let isNewNote = note.content.isEmpty && note.modificationDate.timeIntervalSinceNow > -5 // Weniger als 5 Sekunden alt
        _isEditing = State(initialValue: isNewNote)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar oben
            toolbar
                .padding()
                .background(Color(.windowBackgroundColor))
            
            Divider()
            
            // Inhalt
            if isEditing {
                editingView
            } else {
                readingView
            }
        }
        .onAppear {
            updateFormattedContent()
        }
    }
    
    // Toolbar für beide Modi
    private var toolbar: some View {
        HStack(spacing: 16) {
            // Linke Seite: Modus-Umschaltung
            Button(action: {
                if isEditing {
                    saveNote()
                } else {
                    startEditing()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: isEditing ? "eye" : "pencil")
                    Text(isEditing ? "Vorschau" : "Bearbeiten")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.windowBackgroundColor).opacity(0.5))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .help(isEditing ? "Vorschaumodus anzeigen" : "Bearbeitungsmodus")
            
            // Middle: Zeigt Modi an
            Text(isEditing ? "Bearbeitungsmodus" : "Lesemodus")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
            
            if isEditing {
                // Markdown Hilfe
                Button(action: {
                    // Zeige Markdown Hilfe
                    NSWorkspace.shared.open(URL(string: "https://www.markdownguide.org/cheat-sheet/")!)
                }) {
                    Image(systemName: "questionmark.circle")
                }
                .buttonStyle(.plain)
                .help("Markdown Hilfe öffnen")
                
                // Schnellformatierung für Markdown wenn im Bearbeitungsmodus
                ForEach(MarkdownFormatOption.allCases, id: \.self) { option in
                    Button(action: {
                        applyMarkdownFormat(option)
                    }) {
                        Image(systemName: option.iconName)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .help(option.tooltip)
                }
                
                Spacer()
                
                Button("Abbrechen") {
                    cancelEditing()
                }
                .buttonStyle(.plain)
                
                Button("Speichern") {
                    saveNote()
                }
                .keyboardShortcut("s", modifiers: .command)
                .buttonStyle(.borderedProminent)
            } else {
                Spacer()
                
                Button(action: {
                    // Drucken-Funktion hier einfügen
                }) {
                    Image(systemName: "printer")
                }
                .buttonStyle(.plain)
                .help("Drucken")
                
                Button(action: {
                    // Text in die Zwischenablage kopieren
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(note.content, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.plain)
                .help("Kopieren")
                
                Button(action: {
                    startEditing()
                }) {
                    Image(systemName: "square.and.pencil")
                }
                .buttonStyle(.plain)
                .help("Bearbeiten")
            }
        }
    }
    
    // Ansicht zum Lesen mit Markdown-Darstellung
    private var readingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Titel
                Text(note.title)
                    .font(readerTitleFont)
                    .padding(.bottom, 4)
                
                // Metadaten: Tags und Datum
                HStack {
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
                    
                    Spacer()
                    
                    // Datum
                    Text("Bearbeitet: \(formattedDate(note.modificationDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Gerenderte Markdown-Inhalte
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
    
    // Ansicht zum Bearbeiten mit Markdown-Unterstützung
    private var editingView: some View {
        VStack(spacing: 0) {
            // Titel
            TextField("Titel", text: $editedTitle)
                .font(.title)
                .padding()
                .background(Color(.windowBackgroundColor).opacity(0.5))
                .overlay(Divider(), alignment: .bottom)
            
            // Hauptbearbeitungsbereich mit Zwei-Spalten-Layout
            HStack(spacing: 0) {
                // Linke Spalte: Editor
                VStack(spacing: 8) {
                    // Tags
                    HStack {
                        Text("Tags:")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        
                        TextField("Durch Komma getrennt", text: $editedTags)
                            .font(.callout)
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    Divider()
                    
                    // Markdown Editor
                    TextEditor(text: $editedContent)
                        .font(editorFont)
                        .lineSpacing(1.2)
                        .padding([.horizontal, .bottom])
                        .background(Color(.textBackgroundColor).opacity(0.3))
                        .cornerRadius(4)
                        .onChange(of: editedContent) { _ in
                            updateFormattedContent()
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Divider()
                
                // Rechte Spalte: Live-Vorschau
                VStack {
                    HStack {
                        Text("Vorschau")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding([.horizontal, .top])
                    
                    Divider()
                    
                    ScrollView {
                        Text(formattedContent)
                            .font(readerBodyFont)
                            .textSelection(.disabled)
                            .lineSpacing(1.4)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color(.textBackgroundColor).opacity(0.2))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func startEditing() {
        editedTitle = note.title
        editedContent = note.content
        editedTags = note.tags.joined(separator: ", ")
        isEditing = true
    }
    
    private func cancelEditing() {
        isEditing = false
        updateFormattedContent()
    }
    
    private func saveNote() {
        let processedTags = editedTags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var updatedNote = note
        updatedNote.title = editedTitle
        updatedNote.content = editedContent
        updatedNote.tags = processedTags
        updatedNote.modificationDate = Date()
        
        // Speichern der aktualisierten Notiz im NotesManager
        if let index = notesManager.notes.firstIndex(where: { $0.id == note.id }) {
            notesManager.notes[index] = updatedNote
        }
        
        isEditing = false
        updateFormattedContent()
    }
    
    private func updateFormattedContent() {
        do {
            // Konvertiere Markdown zu AttributedString
            let contentToFormat = isEditing ? editedContent : note.content
            if #available(macOS 12.0, *) {
                formattedContent = try AttributedString(markdown: contentToFormat)
            } else {
                // Fallback für ältere Versionen
                formattedContent = AttributedString(contentToFormat)
            }
        } catch {
            print("Fehler beim Formatieren des Markdown: \(error)")
            if isEditing {
                formattedContent = AttributedString(editedContent)
            } else {
                formattedContent = AttributedString(note.content)
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Markdown-Formatierung anwenden
    private func applyMarkdownFormat(_ option: MarkdownFormatOption) {
        let selectedText = NSTextView.currentTextView()?.selectedText ?? ""
        let replacement: String
        
        switch option {
        case .bold:
            replacement = "**\(selectedText)**"
        case .italic:
            replacement = "*\(selectedText)*"
        case .heading:
            replacement = "# \(selectedText)"
        case .subheading:
            replacement = "## \(selectedText)"
        case .bulletList:
            let lines = selectedText.split(separator: "\n")
            replacement = lines.map { "- \($0)" }.joined(separator: "\n")
        case .numberList:
            let lines = selectedText.split(separator: "\n")
            replacement = lines.enumerated().map { "1. \($1)" }.joined(separator: "\n")
        case .code:
            replacement = "`\(selectedText)`"
        case .codeBlock:
            replacement = "```\n\(selectedText)\n```"
        case .link:
            replacement = "[\(selectedText)](https://)"
        case .image:
            replacement = "![\(selectedText)](https://)"
        case .quote:
            let lines = selectedText.split(separator: "\n")
            replacement = lines.map { "> \($0)" }.joined(separator: "\n")
        case .horizontalRule:
            replacement = selectedText.isEmpty ? "---" : "\(selectedText)\n\n---"
        }
        
        if let textView = NSTextView.currentTextView() {
            if let selectedRange = textView.selectedRanges.first?.rangeValue {
                let nsString = NSString(string: editedContent)
                let beforeText = nsString.substring(to: selectedRange.location)
                let afterText = nsString.substring(from: selectedRange.location + selectedRange.length)
                
                editedContent = beforeText + replacement + afterText
                
                // Setze den Cursor neu
                DispatchQueue.main.async {
                    let newLocation = selectedRange.location + replacement.count
                    textView.setSelectedRange(NSRange(location: newLocation, length: 0))
                }
            }
        } else {
            // Fallback, wenn kein TextEditor aktiv ist
            editedContent = editedContent + replacement
        }
        
        updateFormattedContent()
    }
}

// Erweiterung für NSTextView, um den aktuell fokussierten TextEditor zu erhalten
extension NSTextView {
    static func currentTextView() -> NSTextView? {
        if let mainWindow = NSApplication.shared.mainWindow,
           let firstResponder = mainWindow.firstResponder as? NSTextView {
            return firstResponder
        }
        return nil
    }
    
    var selectedText: String {
        let range = self.selectedRange()
        guard range.length > 0 else { return "" }
        return (self.string as NSString).substring(with: range)
    }
}

// Markdown Formatierungsoptionen
enum MarkdownFormatOption: CaseIterable {
    case bold
    case italic
    case heading
    case subheading
    case bulletList
    case numberList
    case code
    case codeBlock
    case link
    case image
    case quote
    case horizontalRule
    
    var iconName: String {
        switch self {
        case .bold: return "bold"
        case .italic: return "italic"
        case .heading: return "textformat.size.larger"
        case .subheading: return "textformat.size"
        case .bulletList: return "list.bullet"
        case .numberList: return "list.number"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .codeBlock: return "curlybraces"
        case .link: return "link"
        case .image: return "photo"
        case .quote: return "text.quote"
        case .horizontalRule: return "minus"
        }
    }
    
    var tooltip: String {
        switch self {
        case .bold: return "Fett (⌘B)"
        case .italic: return "Kursiv (⌘I)"
        case .heading: return "Überschrift"
        case .subheading: return "Unterüberschrift"
        case .bulletList: return "Aufzählungsliste"
        case .numberList: return "Nummerierte Liste"
        case .code: return "Inline-Code"
        case .codeBlock: return "Codeblock"
        case .link: return "Link"
        case .image: return "Bild"
        case .quote: return "Zitat"
        case .horizontalRule: return "Horizontale Linie"
        }
    }
}
