func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // Abfangen von Tastatureingaben für spezielle Funktionen
            
            // Speziell für die Behandlung der Eingabetaste nach "["
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                let selectedRange = textView.selectedRange
                if selectedRange.location > 0 {
                    let nsString = textView.string as NSString
                    let charBeforeCursor = nsString.substring(with: NSRange(location: selectedRange.location - 1, length: 1))
                    
                    // Wenn wir uns innerhalb eines Links befinden, spezielle Behandlung
                    if isInsideLinkDefinition(textView: textView, at: selectedRange.location) {
                        // Schließe den Link automatisch und positioniere den Cursor
                        closeLinkDefinition(textView: textView)
                        return true
                    }
                }
            }
            
            // Überlasse den Befehl der Standardbehandlung
            return false
        }
        
        // Hilfsmethode, um zu prüfen, ob der Cursor innerhalb einer Link-Definition ist
        private func isInsideLinkDefinition(textView: NSTextView, at location: Int) -> Bool {
            let nsString = textView.string as NSString
            
            // Prüfe, ob wir nach einem "[" und vor einem "](" sind
            var foundOpenBracket = false
            var i = location - 1
            
            // Rückwärts nach "[" suchen
            while i >= 0 {
                let char = nsString.substring(with: NSRange(location: i, length: 1))
                if char == "[" {
                    foundOpenBracket = true
                    break
                }
                if char == "]" || char == ")" {
                    break // Wir haben eine schließende Klammer gefunden, kein offener Link
                }
                i -= 1
            }
            
            // Vorwärts nach "](" suchen
            if foundOpenBracket {
                i = location
                var foundCloseBracket = false
                
                while i < nsString.length {
                    let char = nsString.substring(with: NSRange(location: i, length: 1))
                    if char == "]" {
                        foundCloseBracket = true
                    } else if char == "(" && foundCloseBracket {
                        return false // Vollständiger Link bereits vorhanden
                    }
                    i += 1
                }
                
                return foundOpenBracket && !foundCloseBracket
            }
            
            return false
        }
        
        // Schließt eine Link-Definition automatisch
        private func closeLinkDefinition(textView: NSTextView) {
            // Füge "](" ein und positioniere den Cursor
            textView.insertText("]()", replacementRange: NSRange(location: textView.selectedRange.location, length: 0))
            
            // Setze Cursor zwischen die runden Klammern
            let newPosition = textView.selectedRange.location - 1
            textView.setSelectedRange(NSRange(location: newPosition, length: 0))
        }// DATEI: Views/Notes/MarkdownSyntaxHighlightingTextEditor.swift
import SwiftUI
import AppKit

struct MarkdownSyntaxHighlightingTextEditor: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont
    var isEditable: Bool = true
    var onTextChange: ((String) -> Void)?
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        // Setze den Delegaten für Änderungsereignisse
        textView.delegate = context.coordinator
        
        // Konfiguriere TextKit-Stack
        let layoutManager = textView.layoutManager!
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.font = font
        textView.textContainerInset = NSSize(width: 16, height: 16) // Padding
        textView.isRichText = false
        textView.enabledTextCheckingTypes = 0 // Deaktiviere automatische Textkorrektur
        
        // Aktiviere automatische Paaren von Klammern unabhängig von Systemeinstellungen
        // (Da isAutomaticBracketInsertionEnabled nicht verfügbar ist, verwenden wir unsere eigene Implementierung im Delegate)
        
        // Konfiguriere Aussehen
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.drawsBackground = true
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        
        // Update nur, wenn sich der Text extern geändert hat
        if textView.string != text {
            textView.string = text
        }
        
        // Hervorhebung der Markdown-Syntax anwenden
        applyMarkdownSyntaxHighlighting(to: textView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownSyntaxHighlightingTextEditor
        
        init(_ parent: MarkdownSyntaxHighlightingTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Auto-Close Brackets
            if let selectedRange = textView.selectedRanges.first?.rangeValue,
               selectedRange.length == 0, // Keine Textauswahl
               selectedRange.location > 0 {
                
                let nsString = textView.string as NSString
                let charBefore = nsString.substring(with: NSRange(location: selectedRange.location - 1, length: 1))
                
                // Füge die schließende Klammer hinzu und setze den Cursor zwischen die Klammern
                switch charBefore {
                case "[":
                    textView.insertText("]", replacementRange: NSRange(location: NSNotFound, length: 0))
                    textView.setSelectedRange(NSRange(location: selectedRange.location, length: 0))
                case "(":
                    textView.insertText(")", replacementRange: NSRange(location: NSNotFound, length: 0))
                    textView.setSelectedRange(NSRange(location: selectedRange.location, length: 0))
                default:
                    break
                }
            }
            
            // Text aktualisieren und an Parent zurückgeben
            parent.text = textView.string
            parent.onTextChange?(textView.string)
            
            // Hervorhebung der Markdown-Syntax anwenden
            parent.applyMarkdownSyntaxHighlighting(to: textView)
        }
    }
    
    // Hervorhebung der Markdown-Syntax
    private func applyMarkdownSyntaxHighlighting(to textView: NSTextView) {
        let attributedString = NSMutableAttributedString(string: textView.string)
        let range = NSRange(location: 0, length: attributedString.length)
        
        // Standard-Textattribute festlegen
        attributedString.addAttribute(.font, value: font, range: range)
        attributedString.addAttribute(.foregroundColor, value: NSColor.textColor, range: range)
        
        // Reguläre Ausdrücke für verschiedene Markdown-Elemente
        let headerPattern = #"(^#{1,6}\s)"#
        let bulletPointPattern = #"(^[-*]\s)"#
        let numberedListPattern = #"(^\d+\.\s)"#
        let blockquotePattern = #"(^>\s)"#
        let linkPattern = #"(\[.+?\])(\(.+?\))"#
        let horizontalRulePattern = #"(^-{3,}$)"#
        
        // Markdown-Operatoren hervorheben
        applyHighlighting(to: attributedString, withPattern: headerPattern, color: NSColor.systemBlue)
        applyHighlighting(to: attributedString, withPattern: bulletPointPattern, color: NSColor.systemGreen)
        applyHighlighting(to: attributedString, withPattern: numberedListPattern, color: NSColor.systemGreen)
        applyHighlighting(to: attributedString, withPattern: blockquotePattern, color: NSColor.systemPurple)
        applyHighlighting(to: attributedString, withPattern: horizontalRulePattern, color: NSColor.systemGray)
        
        // Links besonders hervorheben
        applyLinkHighlighting(to: attributedString, withPattern: linkPattern)
        
        // Stille Aktualisierung ohne Cursor-Bewegung
        let selectedRanges = textView.selectedRanges
        textView.textStorage?.setAttributedString(attributedString)
        textView.selectedRanges = selectedRanges
    }
    
    private func applyHighlighting(to attributedString: NSMutableAttributedString, withPattern pattern: String, color: NSColor) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
        
        let nsString = attributedString.string as NSString
        let matches = regex.matches(in: attributedString.string, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            // Hervorhebe nur den Markdown-Operator (nicht den gesamten Text)
            let headerRange = match.range(at: 1)
            if headerRange.location != NSNotFound {
                attributedString.addAttribute(.foregroundColor, value: color, range: headerRange)
            }
        }
    }
    
    private func applyLinkHighlighting(to attributedString: NSMutableAttributedString, withPattern pattern: String) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
        
        let nsString = attributedString.string as NSString
        let matches = regex.matches(in: attributedString.string, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            // Hervorhebe den Linktitel-Teil [text]
            if match.numberOfRanges > 1 {
                let linkTitleRange = match.range(at: 1)
                attributedString.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: linkTitleRange)
            }
            
            // Hervorhebe den URL-Teil (url)
            if match.numberOfRanges > 2 {
                let linkURLRange = match.range(at: 2)
                attributedString.addAttribute(.foregroundColor, value: NSColor.systemTeal, range: linkURLRange)
            }
        }
    }
}
