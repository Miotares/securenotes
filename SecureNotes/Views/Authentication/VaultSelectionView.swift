// DATEI: Views/Authentication/VaultSelectionView.swift
import SwiftUI

struct VaultSelectionView: View {
    @Binding var isPresented: Bool
    @Binding var selectedVault: Vault?
    @State private var showingNewVaultDialog = false
    @State private var vaults: [Vault] = []
    @State private var searchText = ""
    
    var body: some View {
        ZStack {
            Color("1B2838").ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                Text("Tresor auswählen")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // Suchleiste
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Suchen...", text: $searchText)
                        .foregroundColor(.white)
                        .accentColor(.blue)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                .background(Color.white.opacity(0.07))
                .cornerRadius(8)
                .padding(.horizontal)
                
                // Liste der Tresore
                if filteredVaults.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("Keine Tresore vorhanden")
                            .foregroundColor(.gray)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(filteredVaults) { vault in
                                vaultRow(vault)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 5)
                    }
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Button für neuen Tresor
                Button(action: { showingNewVaultDialog = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Neuen Tresor erstellen")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                
                // Bottom buttons
                HStack {
                    Button("Abbrechen") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    Button("Auswählen") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                    .padding(12)
                    .background(selectedVault == nil ? Color.gray.opacity(0.3) : Color.blue)
                    .cornerRadius(8)
                    .disabled(selectedVault == nil)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding()
            .frame(width: 500, height: 560)
            .background(Color("222A35"))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
        .onAppear {
            vaults = VaultManager.shared.vaults
        }
        .sheet(isPresented: $showingNewVaultDialog) {
            VaultCreationView(
                isPresented: $showingNewVaultDialog,
                onVaultCreated: { newVault in
                    vaults = VaultManager.shared.vaults
                    selectedVault = newVault
                }
            )
        }
    }
    
    private var filteredVaults: [Vault] {
        if searchText.isEmpty {
            return vaults
        } else {
            return vaults.filter { vault in
                vault.name.localizedCaseInsensitiveContains(searchText) ||
                vault.path.path.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func vaultRow(_ vault: Vault) -> some View {
        Button(action: {
            selectedVault = vault
        }) {
            HStack {
                // Icon Bereich
                ZStack {
                    Circle()
                        .fill(vault.isEncrypted ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: vault.isEncrypted ? "lock.fill" : "lock.open.fill")
                        .foregroundColor(vault.isEncrypted ? .green : .orange)
                        .font(.system(size: 18))
                }
                
                // Text Bereich
                VStack(alignment: .leading, spacing: 4) {
                    Text(vault.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(vault.path.path)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Auswahlindikator
                if selectedVault?.id == vault.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                }
            }
            .padding(12)
            .background(selectedVault?.id == vault.id ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedVault?.id == vault.id ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
