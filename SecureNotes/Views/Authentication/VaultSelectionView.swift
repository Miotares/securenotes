//
//  VaultSelectionView.swift
//  SecureNotes
//
//  Created by Merlin Kreuzkam on 17.03.25.
//


// Ordner: Views/Authentication/VaultSelectionView.swift
import SwiftUI

struct VaultSelectionView: View {
    @State private var selectedPath: String?
    @State private var showingFileChooser = false
    @State private var vaultName = "Mein Tresor"
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tresor erstellen")
                .font(.title)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Name")
                    .font(.headline)
                
                TextField("Name des Tresors", text: $vaultName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Speicherort")
                    .font(.headline)
                
                HStack {
                    Text(selectedPath ?? "Kein Speicherort ausgewählt")
                        .foregroundColor(selectedPath == nil ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(width: 240, alignment: .leading)
                    
                    Button("Durchsuchen...") {
                        showingFileChooser = true
                    }
                }
                .padding(8)
                .background(Color(.windowBackgroundColor).opacity(0.3))
                .cornerRadius(6)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Abbrechen") {
                    dismiss()
                }
                
                Button("Erstellen") {
                    createVault()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedPath == nil || vaultName.isEmpty)
            }
            .padding()
        }
        .padding()
        .frame(width: 400, height: 300)
        .fileImporter(
            isPresented: $showingFileChooser,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let selectedURL = urls.first {
                    selectedPath = selectedURL.path
                }
            case .failure(let error):
                print("Fehler bei der Auswahl des Speicherorts: \(error.localizedDescription)")
            }
        }
    }
    
    private func createVault() {
        guard let path = selectedPath, !vaultName.isEmpty else { return }
        
        // Hier würde die eigentliche Implementierung erfolgen, um den Tresor zu erstellen
        print("Erstelle Tresor '\(vaultName)' unter: \(path)")
        
        dismiss()
    }
}