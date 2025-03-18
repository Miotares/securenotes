// DATEI: Views/Authentication/VaultSwitcherView.swift
import SwiftUI

struct VaultSwitcherView: View {
    @State private var vaults: [Vault] = []
    @State private var selectedVault: Vault?
    @State private var showingConfirmation = false
    
    var onVaultSelected: (Vault) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tresor wechseln")
                .font(.title)
                .padding(.top)
            
            // Liste der vorhandenen Tresore
            if vaults.isEmpty {
                Text("Keine Tresore vorhanden")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List(vaults, id: \.id, selection: $selectedVault) { vault in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(vault.name)
                                .font(.headline)
                            
                            Text(vault.path.path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Verschlüsselungsstatus
                        Image(systemName: vault.isEncrypted ? "lock.fill" : "lock.open.fill")
                            .foregroundColor(vault.isEncrypted ? .green : .orange)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedVault = vault
                    }
                }
                .frame(height: 200)
            }
            
            Text("Beim Wechseln des Tresors werden alle ungespeicherten Änderungen verworfen.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            HStack {
                Button("Abbrechen") {
                    NSApp.mainWindow?.endSheet(NSApp.keyWindow!)
                }
                
                Spacer()
                
                Button("Wechseln") {
                    if let vault = selectedVault {
                        showingConfirmation = true
                    }
                }
                .disabled(selectedVault == nil)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .padding()
        .frame(width: 500, height: 400)
        .onAppear {
            vaults = VaultManager.shared.vaults
        }
        .alert("Tresor wechseln", isPresented: $showingConfirmation) {
            Button("Abbrechen", role: .cancel) { }
            Button("Wechseln", role: .destructive) {
                if let vault = selectedVault {
                    onVaultSelected(vault)
                }
            }
        } message: {
            Text("Bist du sicher, dass du den Tresor wechseln möchtest? Alle ungespeicherten Änderungen gehen verloren.")
        }
    }
}
