// DATEI: ViewModels/LinkViewModel.swift
import SwiftUI
import Combine

class LinkViewModel: ObservableObject {
    @Published var links: [Link] = []
    
    struct Link: Identifiable, Equatable {
        var id: UUID
        var title: String
        var url: URL
        var description: String?
        var favicon: Data?
        var tags: [String]
        var folderId: UUID?
        var creationDate: Date
        var modificationDate: Date
        
        init(id: UUID = UUID(),
             title: String,
             url: URL,
             description: String? = nil,
             favicon: Data? = nil,
             tags: [String] = [],
             folderId: UUID? = nil,
             creationDate: Date = Date(),
             modificationDate: Date = Date()) {
            self.id = id
            self.title = title
            self.url = url
            self.description = description
            self.favicon = favicon
            self.tags = tags
            self.folderId = folderId
            self.creationDate = creationDate
            self.modificationDate = modificationDate
        }
        
        // Implementieren von Equatable
        static func == (lhs: Link, rhs: Link) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    init() {
        loadLinks()
    }
    
    func loadLinks() {
        // Beispieldaten
        links = [
            Link(title: "Apple", url: URL(string: "https://www.apple.com")!),
            Link(title: "Google", url: URL(string: "https://www.google.com")!),
            Link(title: "GitHub", url: URL(string: "https://github.com")!)
        ]
    }
    
    func addLink(_ link: Link) {
        links.append(link)
    }
    
    func updateLink(_ link: Link) {
        if let index = links.firstIndex(where: { $0.id == link.id }) {
            links[index] = link
        }
    }
    
    func deleteLink(_ id: UUID) {
        links.removeAll { $0.id == id }
    }
    
    func deleteLinks(at offsets: IndexSet) {
        links.remove(atOffsets: offsets)
    }
    
    func moveLinkToFolder(_ link: Link, folderId: UUID?) {
        var updatedLink = link
        updatedLink.folderId = folderId
        updatedLink.modificationDate = Date()
        
        updateLink(updatedLink)
    }
    
    func fetchFavicon(for link: Link, completion: @escaping (Data?) -> Void) {
        guard let faviconURL = getFaviconURL(for: link.url) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: faviconURL) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, error == nil {
                    completion(data)
                } else {
                    completion(nil)
                }
            }
        }.resume()
    }
    
    private func getFaviconURL(for url: URL) -> URL? {
        if let host = url.host {
            // Versuche zuerst Google's Favicon-Service
            return URL(string: "https://www.google.com/s2/favicons?domain=\(host)")
        }
        return nil
    }
}
