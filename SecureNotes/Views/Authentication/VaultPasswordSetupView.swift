// DATEI: Views/Authentication/VaultPasswordSetupView.swift
import SwiftUI
import LocalAuthentication

struct VaultPasswordSetupView: View {
    let vault: Vault
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var enableBiometrics = false
    @State private var showingPasswordMismatchError = false
    @State private var showingPasswordTooShortError = false
    @State private var canUseBiometrics = false
    
    var onSetupComplete: (Vault) -> Void
    
    private let minimumPasswordLength = 8
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tresor-Passwort einrichten")
                .font(.headline)
                .padding(.top, 20)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Tresor: \(vault.name)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if vault.isEncrypted {
                    Text("Dieser Tresor ist verschlüsselt und benötigt ein Master-Passwort.")
                        .foregroundColor(.secondary)
                } else {
                    Text("Dieser Tresor ist nicht verschlüsselt, aber du kannst trotzdem ein Passwort für den Zugriff festlegen.")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 16)
            
            VStack(alignment: .leading, spacing: 15) {
                SecureField("Passwort eingeben", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
                
                SecureField("Passwort bestätigen", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
                
                if showingPasswordMismatchError {
                    Text("Die Passwörter stimmen nicht überein")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                if showingPasswordTooShortError {
                    Text("Das Passwort muss mindestens \(minimumPasswordLength) Zeichen lang sein")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding(.vertical, 10)
            
            if canUseBiometrics {
                VStack(alignment: .leading) {
                    Text("Biometrischer Zugriff")
                        .font(.headline)
                    
                    Toggle("Touch ID für zukünftige Anmeldungen verwenden", isOn: $enableBiometrics)
                        .padding(.top, 5)
                }
                .frame(width: 300)
            }
            
            VStack(alignment: .leading) {
                if vault.isEncrypted {
                    Text("Wichtig: Dieses Passwort wird für die Verschlüsselung deiner Daten verwendet. Wenn du es vergisst, können deine Daten nicht wiederhergestellt werden.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: 300)
                }
            }
            .padding(.vertical, 10)
            
            HStack {
                Button("Abbrechen") {
                    NSApp.mainWindow?.endSheet(NSApp.keyWindow!)
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Fertig") {
                    setupPassword()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(password.isEmpty || confirmPassword.isEmpty)
            }
            .padding()
        }
        .padding()
        .frame(width: 350, height: 400)
        .onAppear {
            checkBiometricsAvailability()
        }
    }
    
    private func checkBiometricsAvailability() {
        let context = LAContext()
        var error: NSError?
        
        canUseBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    private func setupPassword() {
        showingPasswordMismatchError = false
        showingPasswordTooShortError = false
        
        if password != confirmPassword {
            showingPasswordMismatchError = true
            return
        }
        
        if password.count < minimumPasswordLength {
            showingPasswordTooShortError = true
            return
        }
        
        // Hier würde normalerweise authViewModel.setupPassword aufgerufen werden
        // Da wir in einem Blattknoten sind, müssen wir das direkt machen:
        
        let authService = AuthService()
        if authService.setupPassword(password) {
            // Wenn Biometrie aktiviert wurde, speichere den Schlüssel
            if enableBiometrics {
                let encryptionService = EncryptionService()
                if let key = encryptionService.deriveKey(from: password) {
                    authService.storeKeyInKeychain(key)
                }
            }
            
            onSetupComplete(vault)
            NSApp.mainWindow?.endSheet(NSApp.keyWindow!)
        }
    }
}
