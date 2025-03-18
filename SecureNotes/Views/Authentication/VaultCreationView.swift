// DATEI: Views/Authentication/VaultCreationView.swift
import SwiftUI
import LocalAuthentication

struct VaultCreationView: View {
    @Binding var isPresented: Bool
    var onVaultCreated: ((Vault) -> Void)?
    
    @State private var vaultName = "Mein Tresor"
    @State private var selectedPath: URL?
    @State private var isEncrypted = true
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingPathPicker = false
    @State private var showPasswordError = false
    @State private var showPathError = false
    @State private var enableBiometrics = false
    @State private var canUseBiometrics = false
    @State private var currentStep = 1
    
    private let minimumPasswordLength = 8
    
    var body: some View {
        ZStack {
            Color.fromHex("1B2838").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                Text(currentStep == 1 ? "Tresor erstellen" : "Passwort festlegen")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.fromHex("222A35"))
                
                if currentStep == 1 {
                    createVaultView
                } else {
                    createPasswordView
                }
            }
            .background(Color.fromHex("222A35"))
            .cornerRadius(16)
            .frame(width: 500, height: 500)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
        .sheet(isPresented: $showingPathPicker) {
            PathPickerView(selectedPath: $selectedPath)
        }
        .onAppear {
            checkBiometricsAvailability()
        }
    }
    
    private var createVaultView: some View {
        VStack(spacing: 25) {
            // Name input
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("", text: $vaultName)
                    .padding(12)
                    .background(Color.white.opacity(0.07))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Speicherort
            VStack(alignment: .leading, spacing: 8) {
                Text("Speicherort")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack {
                    Text(selectedPath?.path ?? "Kein Speicherort ausgewählt")
                        .foregroundColor(selectedPath == nil ? Color.gray : .white)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(12)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(8)
                    
                    Button(action: { showingPathPicker = true }) {
                        Text("Durchsuchen...")
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                
                if showPathError {
                    Text("Bitte wähle einen Speicherort aus")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            // Verschlüsselungsoption
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $isEncrypted) {
                    HStack {
                        Image(systemName: isEncrypted ? "lock.fill" : "lock.open")
                            .foregroundColor(isEncrypted ? .green : .orange)
                        
                        Text("Tresor verschlüsseln")
                            .foregroundColor(.white)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                
                if isEncrypted {
                    Text("Der Tresor wird mit einem Passwort geschützt. Ohne das richtige Passwort können die Daten nicht entschlüsselt werden.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Der Tresor wird nicht verschlüsselt. Alle Daten werden im Klartext gespeichert.")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
            
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
                
                Button("Weiter") {
                    if validateStep1() {
                        currentStep = 2
                    }
                }
                .foregroundColor(.white)
                .padding(12)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
        .padding(25)
    }
    
    private var createPasswordView: some View {
        VStack(spacing: 25) {
            // Password fields
            VStack(alignment: .leading, spacing: 20) {
                if isEncrypted {
                    // Master password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Master-Passwort")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        SecureField("", text: $password)
                            .padding(12)
                            .background(Color.white.opacity(0.07))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        
                        // Confirm password
                        Text("Passwort bestätigen")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.top, 5)
                        
                        SecureField("", text: $confirmPassword)
                            .padding(12)
                            .background(Color.white.opacity(0.07))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        
                        if showPasswordError {
                            Text("Die Passwörter stimmen nicht überein oder sind zu kurz (mind. \(minimumPasswordLength) Zeichen)")
                                .foregroundColor(.red)
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    // Touch ID option
                    if canUseBiometrics {
                        Toggle(isOn: $enableBiometrics) {
                            HStack {
                                Image(systemName: "touchid")
                                    .foregroundColor(.blue)
                                
                                Text("Touch ID für zukünftige Anmeldungen verwenden")
                                    .foregroundColor(.white)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Warning
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        
                        Text("Wichtig: Dieses Passwort wird für die Verschlüsselung deiner Daten verwendet. Wenn du es vergisst, können deine Daten nicht wiederhergestellt werden.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Du hast die Verschlüsselung deaktiviert. Der Tresor wird ohne Passwortschutz erstellt.")
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("Möchtest du fortfahren?")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding()
                }
            }
            
            Spacer()
            
            // Bottom buttons
            HStack {
                Button("Zurück") {
                    currentStep = 1
                }
                .foregroundColor(.white)
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                
                Spacer()
                
                Button("Erstellen") {
                    if createVault() {
                        isPresented = false
                    }
                }
                .foregroundColor(.white)
                .padding(12)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
        .padding(25)
    }
    
    private func validateStep1() -> Bool {
        showPathError = selectedPath == nil
        return !showPathError && !vaultName.isEmpty
    }
    
    private func validatePasswords() -> Bool {
        if !isEncrypted {
            return true
        }
        
        let isValid = password.count >= minimumPasswordLength && password == confirmPassword
        showPasswordError = !isValid
        return isValid
    }
    
    private func checkBiometricsAvailability() {
        let context = LAContext()
        var error: NSError?
        
        canUseBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    private func createVault() -> Bool {
        // Validiere Passwörter wenn verschlüsselt
        if isEncrypted && !validatePasswords() {
            return false
        }
        
        guard let path = selectedPath else {
            return false
        }
        
        // Erstelle den Tresor
        let vault = VaultManager.shared.createVault(
            name: vaultName,
            at: path,
            encrypted: isEncrypted
        )
        
        // Wenn verschlüsselt, setze das Passwort
        if isEncrypted {
            let authService = AuthService()
            if authService.setupPassword(password) {
                if enableBiometrics {
                    let encryptionService = EncryptionService()
                    if let key = encryptionService.deriveKey(from: password) {
                        authService.storeKeyInKeychain(key)
                    }
                }
            }
        }
        
        // Benachrichtige den Caller über die Erstellung
        onVaultCreated?(vault)
        
        return true
    }
}
