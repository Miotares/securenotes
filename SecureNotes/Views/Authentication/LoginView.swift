// DATEI: Views/Authentication/LoginView.swift
import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showingSetupView = false
    @State private var showingVaultSelection = false
    @State private var isAnimating = false
    @State private var selectedVault: Vault?
    @State private var setupNewVault: some View = EmptyView()
    
    var body: some View {
        ZStack {
            // Verbesserter Hintergrund mit mehr Tiefe
            LinearGradient(
                gradient: Gradient(colors: [Color("152642"), Color("27374D")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Subtiles Muster für mehr Tiefe
            Image(systemName: "lock.shield")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 500, height: 500)
                .foregroundColor(Color.white.opacity(0.02))
                .rotationEffect(.degrees(-10))
                .offset(y: -100)
            
            VStack(spacing: 40) {
                // Logo und Titel
                VStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 110, height: 110)
                            .blur(radius: 5)
                        
                        Circle()
                            .fill(Color("0984e3"))
                            .frame(width: 100, height: 100)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "lock.shield.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                            .scaleEffect(isAnimating ? 1.05 : 1.0)
                            .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                            .onAppear {
                                isAnimating = true
                            }
                    }
                    
                    Text("SecureNotes")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Deine Notizen. Sicher verschlüsselt.")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.7))
                }
                .padding(.top, 20)
                
                // Tresor-Auswahl mit verbessertem Design
                VStack(alignment: .leading, spacing: 10) {
                    Text("TRESOR")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(.leading, 5)
                    
                    HStack {
                        HStack {
                            if let vault = selectedVault {
                                Image(systemName: vault.isEncrypted ? "lock.fill" : "lock.open.fill")
                                    .foregroundColor(vault.isEncrypted ? .green : .orange)
                                    .font(.system(size: 16))
                                
                                Text(vault.name)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            } else {
                                Image(systemName: "folder.badge.questionmark")
                                    .foregroundColor(.gray)
                                
                                Text("Kein Tresor ausgewählt")
                                    .foregroundColor(Color.white.opacity(0.5))
                            }
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(8)
                        
                        Button(action: {
                            showingVaultSelection = true
                        }) {
                            Image(systemName: "folder.badge.gear")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 360)
                
                // Login mit verbesserten Eingabefeldern
                if authViewModel.isFirstLaunch {
                    setupNewVaultView
                } else {
                    loginForm
                }
            }
            .frame(width: 400)
        }
        .sheet(isPresented: $showingSetupView) {
            SetupPasswordView(isPresented: $showingSetupView)
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showingVaultSelection) {
            VaultSelectionView(isPresented: $showingVaultSelection, selectedVault: $selectedVault)
        }
        .onAppear {
            // Versuche, den zuletzt verwendeten Tresor zu laden
            if let mostRecentVault = VaultManager.shared.vaults.sorted(by: {
                ($0.lastOpened ?? Date.distantPast) > ($1.lastOpened ?? Date.distantPast)
            }).first {
                selectedVault = mostRecentVault
            }
        }
    }
    
    // Setup für neuen Tresor
    private var setupNewVaultView: some View {
        VStack(spacing: 20) {
            Text("Willkommen bei SecureNotes!")
                .font(.title2)
                .bold()
                .foregroundColor(.white)
            
            Text("Um loszulegen, richte bitte ein Passwort für den ausgewählten Tresor ein oder erstelle einen neuen Tresor.")
                .multilineTextAlignment(.center)
                .foregroundColor(Color.white.opacity(0.7))
                .frame(maxWidth: 320)
                .fixedSize(horizontal: false, vertical: true)
            
            Button {
                showingSetupView = true
            } label: {
                HStack {
                    Image(systemName: "lock.shield")
                    Text("Passwort einrichten")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 320, height: 50)
                .background(
                    Group {
                        if selectedVault == nil {
                            Color.gray.opacity(0.3)
                        } else {
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                )
                .cornerRadius(10)
                .shadow(color: selectedVault == nil ? Color.clear : Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(selectedVault == nil)
            
            Button {
                showingVaultSelection = true
            } label: {
                HStack {
                    Image(systemName: "folder.badge.plus")
                    Text("Neuen Tresor erstellen")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 320, height: 50)
                .background(Color.white.opacity(0.07))
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // Verbesserte Login-Form
    private var loginForm: some View {
        VStack(spacing: 25) {
            VStack(alignment: .leading, spacing: 10) {
                Text("MASTER-PASSWORT")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.6))
                    .padding(.leading, 5)
                
                SecureField("", text: $password)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(16)
                    .background(Color.white.opacity(0.07))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                    .frame(width: 320)
                    .onSubmit {
                        authenticate()
                    }
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.callout)
                    .padding(.horizontal)
                    .transition(.opacity)
            }
            
            VStack(spacing: 15) {
                Button {
                    authenticate()
                } label: {
                    Text("Anmelden")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 320, height: 50)
                        .background(
                            Group {
                                if password.isEmpty || selectedVault == nil {
                                    Color.gray.opacity(0.3)
                                } else {
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                }
                            }
                        )
                        .cornerRadius(10)
                        .shadow(color: (password.isEmpty || selectedVault == nil) ? Color.clear : Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(password.isEmpty || selectedVault == nil)
                
                if authViewModel.canUseBiometrics {
                    Button {
                        authenticateWithBiometrics()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "touchid")
                            Text("Mit Touch ID anmelden")
                        }
                        .font(.callout)
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(selectedVault == nil)
                    .padding(.top, 5)
                }
            }
        }
    }
    
    private func authenticate() {
        if authViewModel.authenticate(password: password) {
            if let vault = selectedVault {
                VaultManager.shared.setCurrentVault(vault)
                authViewModel.currentVault = vault
            }
            password = ""
            errorMessage = ""
        } else {
            errorMessage = "Falsches Passwort. Bitte versuche es erneut."
            password = ""
        }
    }
    
    private func authenticateWithBiometrics() {
        authViewModel.authenticateWithBiometrics { success, error in
            if success {
                if let vault = self.selectedVault {
                    VaultManager.shared.setCurrentVault(vault)
                    self.authViewModel.currentVault = vault
                }
                errorMessage = ""
            } else if let error = error {
                errorMessage = error.localizedDescription
            }
        }
    }
}
