// DATEI: Views/Authentication/PathPickerView.swift
import SwiftUI

struct PathPickerView: View {
    @Binding var selectedPath: URL?
    @Environment(\.dismiss) var dismiss
    @State private var paths: [URL] = []
    @State private var currentDirectory: URL
    
    init(selectedPath: Binding<URL?>) {
        self._selectedPath = selectedPath
        
        // Starte im Benutzerverzeichnis
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        self._currentDirectory = State(initialValue: homeDirectory)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Speicherort auswählen")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color("222A35"))
            
            // Current path display
            HStack {
                Text(currentDirectory.lastPathComponent)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                Button(action: navigateUp) {
                    Image(systemName: "arrow.up.doc")
                        .foregroundColor(.white)
                }
                .disabled(isRootDirectory)
                .opacity(isRootDirectory ? 0.5 : 1)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            
            // Directory content
            List {
                ForEach(paths, id: \.self) { path in
                    Button(action: {
                        if isDirectory(path) {
                            navigateTo(path)
                        }
                    }) {
                        HStack {
                            Image(systemName: isDirectory(path) ? "folder" : "doc")
                                .foregroundColor(isDirectory(path) ? .blue : .gray)
                            
                            Text(path.lastPathComponent)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            if isDirectory(path) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .background(Color("1B2838"))
            
            // Bottom buttons
            HStack {
                Button("Abbrechen") {
                    dismiss()
                }
                .foregroundColor(.white)
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                
                Spacer()
                
                Button("Auswählen") {
                    selectedPath = currentDirectory
                    dismiss()
                }
                .foregroundColor(.white)
                .padding(12)
                .background(Color.blue)
                .cornerRadius(8)
            }
            .padding()
            .background(Color("222A35"))
        }
        .frame(width: 500, height: 400)
        .background(Color("1B2838"))
        .onAppear {
            loadDirectoryContents()
        }
    }
    
    private var isRootDirectory: Bool {
        return currentDirectory.path == "/"
    }
    
    private func navigateUp() {
        if !isRootDirectory {
            currentDirectory = currentDirectory.deletingLastPathComponent()
            loadDirectoryContents()
        }
    }
    
    private func navigateTo(_ path: URL) {
        currentDirectory = path
        loadDirectoryContents()
    }
    
    private func loadDirectoryContents() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: currentDirectory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            
            // Sortiere Verzeichnisse vor Dateien
            paths = contents.sorted { lhs, rhs in
                if isDirectory(lhs) && !isDirectory(rhs) {
                    return true
                } else if !isDirectory(lhs) && isDirectory(rhs) {
                    return false
                } else {
                    return lhs.lastPathComponent < rhs.lastPathComponent
                }
            }
        } catch {
            paths = []
            print("Fehler beim Laden des Verzeichnisinhalts: \(error)")
        }
    }
    
    private func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }
}
