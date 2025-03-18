// DATEI: App/SecureNotesApp.swift (angepasst)
import SwiftUI

@main
struct SecureNotesApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    ContentView()
                        .environmentObject(authViewModel)
                } else {
                    LoginView()
                        .environmentObject(authViewModel)
                }
            }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Neue Notiz") {
                    NotificationCenter.default.post(name: NSNotification.Name("CreateNewNote"), object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Neuer Link") {
                    NotificationCenter.default.post(name: NSNotification.Name("CreateNewLink"), object: nil)
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
                
                Button("Neuer Ordner") {
                    NotificationCenter.default.post(name: NSNotification.Name("CreateNewFolder"), object: nil)
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
            }
            
            // Menü für Tresorverwaltung
            CommandGroup(after: .newItem) {
                Divider()
                
                Button("Tresor wechseln...") {
                    NotificationCenter.default.post(name: NSNotification.Name("SwitchVault"), object: nil)
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
                
                Button("Neuen Tresor erstellen...") {
                    NotificationCenter.default.post(name: NSNotification.Name("CreateNewVault"), object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift, .option])
            }
        }
    }
}
