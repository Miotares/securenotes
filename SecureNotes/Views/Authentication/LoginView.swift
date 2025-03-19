// DATEI: Views/Authentication/LoginView.swift
import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showingSetupView = false
    @State private var showingVaultSelection = false
    @State private var showingNewVaultDialog = false
    @State private var isAnimating = false
    @State private var selectedVault: Vault?
    @State private var confirmPassword = ""
    @State private var enableBiometrics = false
    @State private var vaultName = "My Vault"
    @State private var vaultLocation: URL?
    @State private var encryptVault = true
    
    var body: some View {
        ZStack {
            // Enhanced background with more depth
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.1)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Subtle pattern for added depth
            Image(systemName: "lock.shield")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 500, height: 500)
                .foregroundColor(Color.white.opacity(0.02))
                .rotationEffect(.degrees(-10))
                .offset(y: -100)
            
            VStack(spacing: 40) {
                // Logo and title
                VStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 110, height: 110)
                            .blur(radius: 5)
                        
                        Circle()
                            .fill(Color.blue)
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
                    
                    Text("Your notes. Securely encrypted.")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.7))
                }
                .padding(.top, 20)
                
                // Vault selection with improved design
                VStack(alignment: .leading, spacing: 10) {
                    Text("VAULT")
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
                                
                                Text("No vault selected")
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
                
                // Conditional view based on first launch
                if authViewModel.isFirstLaunch {
                    setupNewVaultView
                } else {
                    loginForm
                }
            }
            .frame(width: 400)
        }
        .sheet(isPresented: $showingSetupView) {
            setupPasswordView
        }
        .sheet(isPresented: $showingVaultSelection) {
            vaultSelectionView
        }
        .sheet(isPresented: $showingNewVaultDialog) {
            newVaultView
        }
        .onAppear {
            loadRecentVault()
            
            // Check if biometrics is available
            let context = LAContext()
            var error: NSError?
            enableBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        }
    }
    
    // Setup for new vault
    private var setupNewVaultView: some View {
        VStack(spacing: 20) {
            Text("Welcome to SecureNotes!")
                .font(.title2)
                .bold()
                .foregroundColor(.white)
            
            Text("To get started, please set up a password for the selected vault or create a new vault.")
                .multilineTextAlignment(.center)
                .foregroundColor(Color.white.opacity(0.7))
                .frame(maxWidth: 320)
                .fixedSize(horizontal: false, vertical: true)
            
            Button {
                showingSetupView = true
            } label: {
                HStack {
                    Image(systemName: "lock.shield")
                    Text("Set Up Password")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 320, height: 50)
                .background(
                    selectedVault == nil ?
                    Color.gray.opacity(0.3) :
                    Color.blue
                )
                .cornerRadius(10)
                .shadow(color: selectedVault == nil ? Color.clear : Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(selectedVault == nil)
            
            Button {
                showingNewVaultDialog = true
            } label: {
                HStack {
                    Image(systemName: "folder.badge.plus")
                    Text("Create New Vault")
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
    
    // Login form
    private var loginForm: some View {
        VStack(spacing: 25) {
            VStack(alignment: .leading, spacing: 10) {
                Text("MASTER PASSWORD")
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
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 320, height: 50)
                        .background(
                            password.isEmpty || selectedVault == nil ?
                            Color.gray.opacity(0.3) :
                            Color.blue
                        )
                        .cornerRadius(10)
                        .shadow(color: (password.isEmpty || selectedVault == nil) ?
                                Color.clear : Color.blue.opacity(0.3),
                                radius: 5, x: 0, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(password.isEmpty || selectedVault == nil)
                
                if authViewModel.canUseBiometrics {
                    Button {
                        authenticateWithBiometrics()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "touchid")
                            Text("Login with Touch ID")
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
    
    // Setup password view
    private var setupPasswordView: some View {
        VStack(spacing: 20) {
            Text("Set Up Master Password")
                .font(.headline)
                .padding(.top, 20)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Create a strong password to protect your vault.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 10)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
                    .padding(.bottom, 10)
                
                if enableBiometrics {
                    Toggle("Enable Touch ID for future logins", isOn: $enableBiometrics)
                        .frame(width: 300)
                }
            }
            
            Text("This password will be used to encrypt your data. If you forget it, your data cannot be recovered.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 10)
            
            HStack {
                Button("Cancel") {
                    showingSetupView = false
                }
                
                Spacer()
                
                Button("Save") {
                    setupPassword()
                }
                .buttonStyle(.borderedProminent)
                .disabled(password.isEmpty || password != confirmPassword)
            }
            .padding()
        }
        .frame(width: 350, height: 400)
        .padding()
    }
    
    // Vault selection view
    private var vaultSelectionView: some View {
        VStack(spacing: 20) {
            Text("Select Vault")
                .font(.headline)
                .padding(.top, 20)
            
            List {
                // This would be populated from VaultManager
                ForEach(mockVaults, id: \.id) { vault in
                    HStack {
                        Image(systemName: vault.isEncrypted ? "lock.fill" : "lock.open.fill")
                            .foregroundColor(vault.isEncrypted ? .green : .orange)
                        
                        VStack(alignment: .leading) {
                            Text(vault.name)
                                .font(.headline)
                            
                            Text(vault.path.absoluteString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if selectedVault?.id == vault.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedVault = vault
                    }
                }
                
                Button("Create New Vault") {
                    showingVaultSelection = false
                    showingNewVaultDialog = true
                }
                .foregroundColor(.blue)
            }
            .frame(height: 200)
            
            HStack {
                Button("Cancel") {
                    showingVaultSelection = false
                }
                
                Spacer()
                
                Button("Select") {
                    showingVaultSelection = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedVault == nil)
            }
            .padding()
        }
        .frame(width: 400, height: 350)
        .padding()
    }
    
    // New vault view
    private var newVaultView: some View {
        VStack(spacing: 20) {
            Text("Create New Vault")
                .font(.headline)
                .padding(.top, 20)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Name:")
                    .font(.subheadline)
                
                TextField("My Vault", text: $vaultName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
                
                Text("Location:")
                    .font(.subheadline)
                    .padding(.top, 10)
                
                HStack {
                    Text(vaultLocation?.path ?? "No location selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    Button("Browse...") {
                        selectVaultLocation()
                    }
                }
                .padding(8)
                .background(Color(.windowBackgroundColor).opacity(0.3))
                .cornerRadius(6)
                
                Toggle("Encrypt vault", isOn: $encryptVault)
                    .padding(.top, 10)
            }
            .padding(.horizontal)
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    showingNewVaultDialog = false
                }
                
                Spacer()
                
                Button("Create") {
                    createNewVault()
                }
                .buttonStyle(.borderedProminent)
                .disabled(vaultName.isEmpty || vaultLocation == nil)
            }
            .padding()
        }
        .frame(width: 400, height: 350)
        .padding()
    }
    
    // Authentication methods
    private func authenticate() {
        if authViewModel.authenticate(password: password) {
            if let vault = selectedVault {
                VaultManager.shared.setCurrentVault(vault)
                authViewModel.currentVault = vault
            }
            password = ""
            errorMessage = ""
        } else {
            errorMessage = "Incorrect password. Please try again."
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
    
    private func setupPassword() {
        guard !password.isEmpty && password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        
        if authViewModel.setupPassword(password, enableBiometrics: enableBiometrics) {
            showingSetupView = false
            
            if let vault = selectedVault {
                VaultManager.shared.setCurrentVault(vault)
                authViewModel.currentVault = vault
            }
        } else {
            errorMessage = "Failed to set up password. Please try again."
        }
    }
    
    private func selectVaultLocation() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.message = "Select a location for your vault"
        panel.prompt = "Select"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                self.vaultLocation = url
            }
        }
    }
    
    private func createNewVault() {
        guard !vaultName.isEmpty, let location = vaultLocation else { return }
        
        let newVault = VaultManager.shared.createVault(
            name: vaultName,
            at: location,
            encrypted: encryptVault
        )
        
        selectedVault = newVault
        showingNewVaultDialog = false
        
        // If this is the first vault, prompt for password setup
        if authViewModel.isFirstLaunch {
            showingSetupView = true
        }
    }
    
    // Load the most recently used vault
    private func loadRecentVault() {
        if let lastVault = VaultManager.shared.vaults.sorted(by: {
            ($0.lastOpened ?? Date.distantPast) > ($1.lastOpened ?? Date.distantPast)
        }).first {
            selectedVault = lastVault
        }
    }
    
    // Mock vaults for UI testing - would be replaced with actual data from VaultManager
    private let mockVaults: [Vault] = [
        Vault(id: UUID(), name: "Personal", path: URL(string: "/Users/documents/vaults/personal")!, isEncrypted: true, lastOpened: Date().addingTimeInterval(-3600)),
        Vault(id: UUID(), name: "Work", path: URL(string: "/Users/documents/vaults/work")!, isEncrypted: true, lastOpened: Date().addingTimeInterval(-86400)),
        Vault(id: UUID(), name: "Public", path: URL(string: "/Users/documents/vaults/public")!, isEncrypted: false, lastOpened: Date().addingTimeInterval(-604800))
    ]
}
