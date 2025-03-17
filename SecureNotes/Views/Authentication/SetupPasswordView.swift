// Ordner: Views/Authentication/SetupPasswordView.swift
import SwiftUI
import LocalAuthentication

struct SetupPasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var isPresented: Bool
    
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var enableBiometrics = false
    @State private var showingPasswordMismatchError = false
    @State private var showingPasswordTooShortError = false
    @State private var canUseBiometrics = false
    
    private let minimumPasswordLength = 8
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Master-Passwort")
                .font(.headline)
                .padding(.top, 20)
            
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
                Text("Wichtig: Dieses Passwort wird für die Verschlüsselung deiner Daten verwendet. Wenn du es vergisst, können deine Daten nicht wiederhergestellt werden.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 300)
            }
            .padding(.vertical, 10)
            
            HStack {
                Spacer()
                
                Button("Abbrechen") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
                
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
        
        if authViewModel.setupPassword(password, enableBiometrics: enableBiometrics) {
            isPresented = false
        }
    }
}
