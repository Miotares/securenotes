//
//  FolderDetailView.swift
//  SecureNotes
//
//  Created by Merlin Kreuzkam on 17.03.25.
//


// DATEI: Views/Folders/FolderDetailView.swift
import SwiftUI

struct FolderDetailView: View {
    let folder: FolderViewModel.Folder
    @EnvironmentObject var notesManager: NotesManager
    @EnvironmentObject var linkViewModel: LinkViewModel
    
    var body: some View {
        VStack {
            Text("Ordner: \(folder.name)")
                .font(.largeTitle)
                .padding()
            
            Spacer()
            
            Text("Hier werden die Inhalte des Ordners angezeigt")
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}