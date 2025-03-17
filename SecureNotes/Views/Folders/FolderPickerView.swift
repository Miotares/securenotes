// Ordner: Views/Folders/FolderPickerView.swift
import SwiftUI

struct FolderPickerView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = FolderViewModel()
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Ziel auswählen")) {
                    Button(action: moveToInbox) {
                        Label("Eingang", systemImage: "tray")
                    }
                    
                    ForEach(viewModel.folders) { folder in
                        Button(action: { moveToFolder(folder) }) {
                            Label(folder.name, systemImage: "folder")
                                .foregroundColor(folder.color)
                        }
                    }
                }
                
                Section {
                    Button(action: { showNewFolderView() }) {
                        Label("Neuer Ordner", systemImage: "folder.badge.plus")
                    }
                }
            }
            .navigationTitle("Verschieben")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadFolders()
        }
    }
    
    private func moveToInbox() {
        // Implementierung später hinzufügen
        isPresented = false
    }
    
    private func moveToFolder(_ folder: FolderViewModel.Folder) {
        // Implementierung später hinzufügen
        isPresented = false
    }
    
    private func showNewFolderView() {
        // Implementierung später hinzufügen
    }
}
