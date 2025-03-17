// DATEI: Views/Authentication/LoginView.swift
import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showingSetupView = false
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Hintergrund
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Logo und Titel
                VStack(spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                        .onAppear {
                            isAnimating = true
                        }
                    
                    Text("SecureNotes")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Deine Notizen. Sicher verschlüsselt.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
                
                // Login
                if authViewModel.isFirstLaunch {
                    VStack(spacing: 15) {
                        Text("Willkommen bei SecureNotes!")
                            .font(.title2)
                            .bold()
                        
                        Text("Um loszulegen, richte bitte dein Master-Passwort ein.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: 300)
                        
                        Button {
                            showingSetupView = true
                        } label: {
                            Text("Passwort einrichten")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 250)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } else {
                    VStack(spacing: 20) {
                        // Passwort-Feld
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Master-Passwort")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            SecureField("", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal, 8)
                                .frame(width: 300, height: 40)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                                )
                                .onSubmit {
                                    authenticate()
                                }
                        }
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .transition(.opacity)
                        }
                        
                        // Buttons
                        VStack(spacing: 12) {
                            Button {
                                authenticate()
                            } label: {
                                Text("Anmelden")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(width: 250)
                                    .background(password.isEmpty ? Color.gray : Color.blue)
                                    .cornerRadius(10)
                                    .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(password.isEmpty)
                            
                            if authViewModel.canUseBiometrics {
                                Button {
                                    authenticateWithBiometrics()
                                } label: {
                                    HStack {
                                        Image(systemName: "touchid")
                                        Text("Mit Touch ID anmelden")
                                    }
                                    .font(.footnote)
                                    .foregroundColor(.blue)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .padding(30)
            .background(Color(.windowBackgroundColor).opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        }
        .sheet(isPresented: $showingSetupView) {
            SetupPasswordView(isPresented: $showingSetupView)
                .environmentObject(authViewModel)
        }
    }
    
    private func authenticate() {
        if authViewModel.authenticate(password: password) {
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
                errorMessage = ""
            } else if let error = error {
                errorMessage = error.localizedDescription
            }
        }
    }
}
