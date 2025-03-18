//
//  NewVaultView.swift
//  SecureNotes
//
//  Created by Merlin Kreuzkam on 18.03.25.
//


// DATEI: Views/Authentication/NewVaultView.swift
import SwiftUI

struct NewVaultView: View {
    @State private var vaultName = "Mein Tresor"
    @State private var selectedPath: URL?
    @State private var isEncrypted = true
    @State private var showVaultPasswordSheet = false
    
    var onVaultCreated: (Vault) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Neuen Tresor erstellen")
                .font(.title)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Name")
                    .font(.headline)
                
                TextField("Name des Tresors", text: $vaultName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: .infinity)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Speicherort")
                    .font(.headline)
                
                HStack {
                    Text(selectedPath?.path ?? "Kein Speicherort ausgewählt")
                        .foregroundColor(selectedPath == nil ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button("Durchsuchen...") {
                        selectFolder()
                    }
                }
                .padding(8)
                .background(Color(.windowBackgroundColor).opacity(0.3))
                .cornerRadius(6)
            }
            
            Toggle("Tresor verschlüsseln", isOn: $isEncrypted)
                .padding(.vertical)
            
            Spacer()
            
            HStack {
                Button("Abbrechen") {
                    NSApp.mainWindow?.endSheet(NSApp.keyWindow!)
                }
                
                Spacer()
                
                Button("Erstellen") {
                    createVault()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedPath == nil || vaultName.isEmpty)
            }
            .padding()
        }
        .padding()
        .frame(width: 500, height: 400)
        .sheet(isPresented: $showVaultPasswordSheet) {
            if let vault = createVaultWithoutPassword() {
                VaultPasswordSetupView(vault: vault) { vault in
                    onVaultCreated(vault)
                }
            }
        }
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        
        if panel.runModal() == .OK {
            selectedPath = panel.url
        }
    }
    
    private func createVault() {
        if isEncrypted {
            showVaultPasswordSheet = true
        } else if let vault = createVaultWithoutPassword() {
            onVaultCreated(vault)
        }
    }
    
    private func createVaultWithoutPassword() -> Vault? {
        guard let path = selectedPath, !vaultName.isEmpty else { return nil }
        
        let vault = VaultManager.shared.createVault(
            name: vaultName,
            at: path,
            encrypted: isEncrypted
        )
        
        return vault
    }
}