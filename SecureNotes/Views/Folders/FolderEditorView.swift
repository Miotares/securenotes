// DATEI: Views/Folders/FolderEditorView.swift
import SwiftUI

struct FolderEditorView: View {
    @EnvironmentObject var folderViewModel: FolderViewModel
    @Binding var isPresented: Bool
    var folder: FolderViewModel.Folder?
    @State private var folderName: String
    @State private var selectedColor: Color
    
    private let colorOptions: [Color] = [
        .blue, .green, .orange, .red, .purple, .pink, .yellow, .gray
    ]
    
    init(folder: FolderViewModel.Folder? = nil, isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        self.folder = folder
        _folderName = State(initialValue: folder?.name ?? "")
        _selectedColor = State(initialValue: folder?.color ?? .blue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header mit abgerundeten Ecken oben
            Text(folder == nil ? "Neuer Ordner" : "Ordner bearbeiten")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .background(Color(.windowBackgroundColor))
            
            Divider()
            
            // Content mit abgerundetem Design
            VStack(alignment: .leading, spacing: 24) {
                // Ordnername
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ordnername")
                        .font(.headline)
                    
                    TextField("Name eingeben", text: $folderName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: .infinity)
                }
                
                // Farbauswahl
                VStack(alignment: .leading, spacing: 12) {
                    Text("Farbe")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                        ForEach(colorOptions, id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 40, height: 40)
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    
                                    if color == selectedColor {
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: 2)
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.bottom, 12)
                }
                
                Spacer()
            }
            .padding(20)
            
            Divider()
            
            // Footer mit Aktionsbuttons
            HStack {
                Button("Abbrechen") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button(folder == nil ? "Erstellen" : "Speichern") {
                    saveFolder()
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(folderName.isEmpty)
            }
            .padding()
            .background(Color(.windowBackgroundColor))
        }
        .frame(width: 400, height: 350)
        .background(Color(.textBackgroundColor).opacity(0.5))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 2)
    }
    
    private func saveFolder() {
        if let existingFolder = folder {
            // Bearbeiten eines bestehenden Ordners
            var updatedFolder = existingFolder
            updatedFolder.name = folderName
            updatedFolder.color = selectedColor
            
            // Direkt im Array aktualisieren
            folderViewModel.folders = folderViewModel.folders.map { folder in
                if folder.id == updatedFolder.id {
                    return updatedFolder
                } else {
                    return folder
                }
            }
        } else {
            // Erstellen eines neuen Ordners
            let newFolder = FolderViewModel.Folder(
                id: UUID(),
                name: folderName,
                color: selectedColor
            )
            
            // Direktes Hinzufügen zum Array
            folderViewModel.folders.append(newFolder)
        }
    }
}
