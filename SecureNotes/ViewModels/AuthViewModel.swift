//
//  AuthViewModel.swift
//  SecureNotes
//
//  Created by Merlin Kreuzkam on 17.03.25.
//


// DATEI: AuthViewModel.swift
import SwiftUI
import LocalAuthentication
import CryptoKit

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isFirstLaunch: Bool
    
    private let authService: AuthService
    private let encryptionService: EncryptionService
    
    var canUseBiometrics: Bool {
        authService.canUseBiometrics
    }
    
    init() {
        let authService = AuthService()
        let encryptionService = EncryptionService()
        
        self.authService = authService
        self.encryptionService = encryptionService
        self.isFirstLaunch = !authService.hasSetupPassword()
    }
    
    func authenticate(password: String) -> Bool {
        guard !password.isEmpty else { return false }
        
        if authService.verifyPassword(password) {
            // Passwort korrekt, Entschlüsselungsschlüssel ableiten und speichern
            if let key = encryptionService.deriveKey(from: password) {
                encryptionService.setCurrentKey(key)
                DispatchQueue.main.async {
                    self.isAuthenticated = true
                }
                return true
            }
        }
        return false
    }
    
    func authenticateWithBiometrics(completion: @escaping (Bool, Error?) -> Void) {
        authService.authenticateWithBiometrics { [weak self] success, error in
            guard let self = self else { return }
            
            if success, let storedKey = self.authService.retrieveKeyFromKeychain() {
                self.encryptionService.setCurrentKey(storedKey)
                DispatchQueue.main.async {
                    self.isAuthenticated = true
                }
            }
            completion(success, error)
        }
    }
    
    func setupPassword(_ password: String, enableBiometrics: Bool) -> Bool {
        guard !password.isEmpty else { return false }
        
        // Schlüssel aus Passwort ableiten
        guard let key = encryptionService.deriveKey(from: password) else {
            return false
        }
        
        // Passwort-Hash und Salt speichern
        if authService.setupPassword(password) {
            encryptionService.setCurrentKey(key)
            
            // Optional: Schlüssel in Keychain für Biometrie speichern
            if enableBiometrics {
                authService.storeKeyInKeychain(key)
            }
            
            DispatchQueue.main.async {
                self.isFirstLaunch = false
                self.isAuthenticated = true
            }
            return true
        }
        
        return false
    }
    
    func signOut() {
        encryptionService.clearCurrentKey()
        DispatchQueue.main.async {
            self.isAuthenticated = false
        }
    }
}