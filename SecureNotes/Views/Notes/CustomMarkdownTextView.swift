// DATEI: Views/Notes/CustomMarkdownTextView.swift
import SwiftUI
import AppKit

struct CustomMarkdownTextView: View {
    let content: String
    var font: Font = .body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(processedLines, id: \.id) { line in
                line.view
                    .padding(.bottom, 8)
            }
        }
    }
    
    // Struktur, die eine verarbeitete Zeile repräsentiert
    private struct ProcessedLine: Identifiable {
        let id = UUID()
        let view: AnyView
    }
    
    // Verarbeitet den Text und gibt eine Liste von verarbeiteten Zeilen zurück
    private var processedLines: [ProcessedLine] {
        // Text in Zeilen aufteilen
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        var result: [ProcessedLine] = []
        
        for line in lines {
            let processedLine = processLine(String(line))
            result.append(processedLine)
        }
        
        return result
    }
    
    // Verarbeitet eine einzelne Zeile
    private func processLine(_ line: String) -> ProcessedLine {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        
        // Leere Zeile
        if trimmedLine.isEmpty {
            return ProcessedLine(view: AnyView(
                Spacer()
                    .frame(height: 4)
            ))
        }
        
        // Überschriften
        if trimmedLine.starts(with: "# ") {
            return ProcessedLine(view: AnyView(
                Text(String(trimmedLine.dropFirst(2)))
                    .font(.largeTitle)
                    .fontWeight(.bold)
            ))
        }
        
        if trimmedLine.starts(with: "## ") {
            return ProcessedLine(view: AnyView(
                Text(String(trimmedLine.dropFirst(3)))
                    .font(.title)
                    .fontWeight(.bold)
            ))
        }
        
        if trimmedLine.starts(with: "### ") {
            return ProcessedLine(view: AnyView(
                Text(String(trimmedLine.dropFirst(4)))
                    .font(.title2)
                    .fontWeight(.bold)
            ))
        }
        
        // Horizontale Trennlinie
        if trimmedLine.matches(pattern: "^-{3,}$") {
            return ProcessedLine(view: AnyView(
                Divider()
                    .frame(height: 1)
                    .background(Color.gray)
                    .padding(.vertical, 8)
            ))
        }
        
        // Aufzählungspunkte
        if trimmedLine.starts(with: "- ") {
            return ProcessedLine(view: AnyView(
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(font)
                    Text(String(trimmedLine.dropFirst(2)))
                        .font(font)
                }
            ))
        }
        
        // Links
        if let linkMatch = extractLink(from: trimmedLine) {
            return ProcessedLine(view: AnyView(
                Button(action: {
                    if let url = URL(string: linkMatch.url), NSWorkspace.shared.open(url) {
                        print("URL geöffnet: \(url)")
                    }
                }) {
                    Text(linkMatch.title)
                        .foregroundColor(.blue)
                        .underline()
                }
                .buttonStyle(.plain)
            ))
        }
        
        // Zitate
        if trimmedLine.starts(with: "> ") {
            return ProcessedLine(view: AnyView(
                Text(String(trimmedLine.dropFirst(2)))
                    .font(font)
                    .italic()
                    .padding(.leading, 12)
                    .overlay(
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 4)
                            .padding(.vertical, -4),
                        alignment: .leading
                    )
            ))
        }
        
        // Normaler Text
        return ProcessedLine(view: AnyView(
            Text(trimmedLine)
                .font(font)
        ))
    }
    
    // Extrahiert Links aus dem Format [title](url)
    private func extractLink(from text: String) -> (title: String, url: String)? {
        // Vereinfachter Regex-Ansatz
        let pattern = "\\[([^\\]]+)\\]\\(([^\\)]+)\\)"
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
            
            if let titleRange = Range(match.range(at: 1), in: text),
               let urlRange = Range(match.range(at: 2), in: text) {
                
                let title = String(text[titleRange])
                let url = String(text[urlRange])
                
                // Wenn der ganze Text ein Link ist, gib Link-Informationen zurück
                if match.range.length == text.count {
                    return (title: title, url: url)
                }
            }
        }
        
        return nil
    }
}

// String-Erweiterung für Regex-Matching
extension String {
    func matches(pattern: String) -> Bool {
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex?.firstMatch(in: self, options: [], range: range) != nil
    }
}
