// DATEI: Views/Common/SidebarTab.swift
import SwiftUI

// Define SidebarTab as internal (not public) to avoid conflicts
enum SidebarTab: Hashable, Equatable {
    case inbox
    case notes
    case links
    case folder(FolderViewModel.Folder)
    
    // Implementation for Hashable
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
    
    // Implementation for Equatable
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

// Remove the SidebarTabKit struct which is causing the ambiguity
