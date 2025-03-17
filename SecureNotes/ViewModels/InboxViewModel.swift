//
//  InboxViewModel.swift
//  SecureNotes
//
//  Created by Merlin Kreuzkam on 17.03.25.
//


// DATEI: InboxViewModel.swift
import SwiftUI
import Combine

class InboxViewModel: ObservableObject {
    @Published var inboxItems: [AnyItem] = []
    
    private let storageService = StorageService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadInboxItems()
        
        // Beobachte Änderungen am Speicher
        storageService.itemsPublisher
            .sink { [weak self] items in
                self?.updateInboxItems(items)
            }
            .store(in: &cancellables)
    }
    
    func loadInboxItems() {
        // Lade nur Items ohne Ordner (Eingangsitems)
        let notes = storageService.loadNotes().filter { $0.folderId == nil }
        let links = storageService.loadLinks().filter { $0.folderId == nil }
        
        let noteItems = notes.map { AnyItem.note($0) }
        let linkItems = links.map { AnyItem.link($0) }
        
        inboxItems = (noteItems + linkItems).sorted {
            switch ($0, $1) {
            case (.note(let note1), .note(let note2)):
                return note1.modificationDate > note2.modificationDate
            case (.link(let link1), .link(let link2)):
                return link1.modificationDate > link2.modificationDate
            case (.note(let note), .link(let link)):
                return note.modificationDate > link.modificationDate
            case (.link(let link), .note(let note)):
                return link.modificationDate > note.modificationDate
            }
        }
    }
    
    private func updateInboxItems(_ items: [AnyItem]) {
        // Aktualisiere nur Eingangsitems (ohne Ordner)
        inboxItems = items.filter {
            switch $0 {
            case .note(let note): return note.folderId == nil
            case .link(let link): return link.folderId == nil
            }
        }
    }
    
    func addNote(_ note: Note) {
        storageService.saveNote(note)
        loadInboxItems()
    }
    
    func addLink(_ link: Link) {
        storageService.saveLink(link)
        loadInboxItems()
    }
    
    func moveToFolder(_ item: AnyItem, folderId: UUID) {
        switch item {
        case .note(var note):
            note.folderId = folderId
            note.modificationDate = Date()
            storageService.saveNote(note)
        case .link(var link):
            link.folderId = folderId
            link.modificationDate = Date()
            storageService.saveLink(link)
        }
        loadInboxItems()
    }
    
    func removeItems(at offsets: IndexSet) {
        for index in offsets {
            if index < inboxItems.count {
                let item = inboxItems[index]
                switch item {
                case .note(let note):
                    storageService.deleteNote(note.id)
                case .link(let link):
                    storageService.deleteLink(link.id)
                }
            }
        }
        loadInboxItems()
    }
}