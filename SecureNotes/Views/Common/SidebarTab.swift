//
//  SidebarTab.swift
//  SecureNotes
//
//  Created by Merlin Kreuzkam on 18.03.25.
//


// DATEI: Views/Common/SidebarTabKit.swift
import SwiftUI

// Zentrale Definition des SidebarTab-Enums für die gesamte Anwendung
public enum SidebarTab: Hashable, Equatable {
    case inbox
    case notes
    case links
    case folder(FolderViewModel.Folder)
    
    // Implementierung für Hashable
    public func hash(into hasher: inout Hasher) {
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
    public static func == (lhs: SidebarTab, rhs: SidebarTab) -> Bool {
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

// Stellt die SidebarTab-Enum für andere Module bereit
public struct SidebarTabKit {
    // Kann später für weitere gemeinsam genutzte Funktionen und Datenstrukturen verwendet werden
}