// DATEI: Views/Notes/MarkdownSyntaxHighlightingTextEditor.swift
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
        
        textView.delegate = context.coordinator
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.font = font
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.isRichText = false
        textView.enabledTextCheckingTypes = 0
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.drawsBackground = true
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        
        if textView.string != text {
            textView.string = text
        }
        
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
            
            handleAutoBrackets(textView)
            
            parent.text = textView.string
            parent.onTextChange?(textView.string)
            
            parent.applyMarkdownSyntaxHighlighting(to: textView)
        }
        
        private func handleAutoBrackets(_ textView: NSTextView) {
            guard let selectedRange = textView.selectedRanges.first?.rangeValue,
                  selectedRange.length == 0,
                  selectedRange.location > 0 else { return }
            
            let nsString = textView.string as NSString
            let charBefore = nsString.substring(with: NSRange(location: selectedRange.location - 1, length: 1))
            
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
        
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if let selectedRange = textView.selectedRanges.first?.rangeValue,
                   selectedRange.location > 0 {
                    if isInsideLinkDefinition(textView, location: selectedRange.location) {
                        closeLinkDefinition(textView)
                        return true
                    }
                }
            }
            return false
        }
        
        private func isInsideLinkDefinition(_ textView: NSTextView, location: Int) -> Bool {
            let nsString = textView.string as NSString
            var foundOpenBracket = false
            var i = location - 1
            
            while i >= 0 {
                let char = nsString.substring(with: NSRange(location: i, length: 1))
                if char == "[" {
                    foundOpenBracket = true
                    break
                }
                if char == "]" || char == ")" {
                    break
                }
                i -= 1
            }
            
            if foundOpenBracket {
                i = location
                var foundCloseBracket = false
                
                while i < nsString.length {
                    let char = nsString.substring(with: NSRange(location: i, length: 1))
                    if char == "]" {
                        foundCloseBracket = true
                    } else if char == "(" && foundCloseBracket {
                        return false
                    }
                    i += 1
                }
                
                return foundOpenBracket && !foundCloseBracket
            }
            
            return false
        }
        
        private func closeLinkDefinition(_ textView: NSTextView) {
            textView.insertText("]()", replacementRange: NSRange(location: textView.selectedRange.location, length: 0))
            let newPosition = textView.selectedRange.location - 1
            textView.setSelectedRange(NSRange(location: newPosition, length: 0))
        }
    }
    
    private func applyMarkdownSyntaxHighlighting(to textView: NSTextView) {
        let attributedString = NSMutableAttributedString(string: textView.string)
        let range = NSRange(location: 0, length: attributedString.length)
        
        attributedString.addAttribute(.font, value: font, range: range)
        attributedString.addAttribute(.foregroundColor, value: NSColor.textColor, range: range)
        
        highlightMarkdownElements(in: attributedString)
        
        let selectedRanges = textView.selectedRanges
        textView.textStorage?.setAttributedString(attributedString)
        textView.selectedRanges = selectedRanges
    }
    
    private func highlightMarkdownElements(in attributedString: NSMutableAttributedString) {
        // Headers
        applyHighlighting(to: attributedString, withPattern: #"(^#{1,6}\s)"#, color: NSColor.systemBlue)
        
        // Lists
        applyHighlighting(to: attributedString, withPattern: #"(^[-*]\s)"#, color: NSColor.systemGreen)
        applyHighlighting(to: attributedString, withPattern: #"(^\d+\.\s)"#, color: NSColor.systemGreen)
        
        // Blockquotes
        applyHighlighting(to: attributedString, withPattern: #"(^>\s)"#, color: NSColor.systemPurple)
        
        // Horizontal rules
        applyHighlighting(to: attributedString, withPattern: #"(^-{3,}$)"#, color: NSColor.systemGray)
        
        // Links
        applyLinkHighlighting(to: attributedString, withPattern: #"(\[.+?\])(\(.+?\))"#)
    }
    
    private func applyHighlighting(to attributedString: NSMutableAttributedString, withPattern pattern: String, color: NSColor) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
        
        let nsString = attributedString.string as NSString
        let matches = regex.matches(in: attributedString.string, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            if match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                if range.location != NSNotFound {
                    attributedString.addAttribute(.foregroundColor, value: color, range: range)
                }
            }
        }
    }
    
    private func applyLinkHighlighting(to attributedString: NSMutableAttributedString, withPattern pattern: String) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
        
        let nsString = attributedString.string as NSString
        let matches = regex.matches(in: attributedString.string, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            if match.numberOfRanges > 1 {
                let linkTitleRange = match.range(at: 1)
                attributedString.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: linkTitleRange)
            }
            
            if match.numberOfRanges > 2 {
                let linkURLRange = match.range(at: 2)
                attributedString.addAttribute(.foregroundColor, value: NSColor.systemTeal, range: linkURLRange)
            }
        }
    }
}
