//
//  SidebarTab.swift
//  SecureNotes
//
//  Created by Merlin Kreuzkam on 17.03.25.
//


// Am besten in einer eigenen Datei: SidebarTab.swift
import SwiftUI

enum SidebarTab: Hashable, Equatable {
    case inbox
    case notes
    case links
    case folder(FolderViewModel.Folder)
    
    // Implementierung für Hashable
    func hash(into hasher: inout Hasher) {
        switch self {
        case .inbox:
            hasher.combine(0)
        case .notes:
            hasher.combine(1)
        case .links:
            hasher.combine(2)
        case .folder(let folder):
            hasher.combine(3)
            hasher.combine(folder.id)
        }
    }
    
    // Implementierung für Equatable
    static func == (lhs: SidebarTab, rhs: SidebarTab) -> Bool {
        switch (lhs, rhs) {
        case (.inbox, .inbox), (.notes, .notes), (.links, .links):
            return true
        case (.folder(let lhsFolder), .folder(let rhsFolder)):
            return lhsFolder.id == rhsFolder.id
        default:
            return false
        }
    }
}