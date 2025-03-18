// DATEI: Models/Item.swift
import SwiftUI

protocol Item: Identifiable, Codable {
    var id: UUID { get }
    var title: String { get set }
    var creationDate: Date { get }
    var modificationDate: Date { get set }
    var folderId: UUID? { get set }
    var tags: [String] { get set }
}

struct Note: Item {
    var id: UUID
    var title: String
    var content: String
    var creationDate: Date
    var modificationDate: Date
    var folderId: UUID?
    var tags: [String]
    
    init(id: UUID = UUID(), title: String, content: String, folderId: UUID? = nil, tags: [String] = []) {
        self.id = id
        self.title = title
        self.content = content
        self.creationDate = Date()
        self.modificationDate = Date()
        self.folderId = folderId
        self.tags = tags
    }
}

struct Link: Item {
    var id: UUID
    var title: String
    var url: URL
    var description: String?
    var creationDate: Date
    var modificationDate: Date
    var folderId: UUID?
    var tags: [String]
    var favicon: Data?
    
    init(id: UUID = UUID(), title: String, url: URL, description: String? = nil, folderId: UUID? = nil, tags: [String] = [], favicon: Data? = nil) {
        self.id = id
        self.title = title
        self.url = url
        self.description = description
        self.creationDate = Date()
        self.modificationDate = Date()
        self.folderId = folderId
        self.tags = tags
        self.favicon = favicon
    }
}

struct Folder: Identifiable, Codable {
    var id: UUID
    var name: String
    var creationDate: Date
    var modificationDate: Date
    var parentFolderId: UUID?
    var color: Color?
    
    init(id: UUID = UUID(), name: String, creationDate: Date = Date(), modificationDate: Date = Date(), parentFolderId: UUID? = nil, color: Color? = nil) {
        self.id = id
        self.name = name
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.parentFolderId = parentFolderId
        self.color = color
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, creationDate, modificationDate, parentFolderId
        case colorR, colorG, colorB, colorA
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        creationDate = try container.decode(Date.self, forKey: .creationDate)
        modificationDate = try container.decode(Date.self, forKey: .modificationDate)
        parentFolderId = try container.decodeIfPresent(UUID.self, forKey: .parentFolderId)
        
        if container.contains(.colorR),
           container.contains(.colorG),
           container.contains(.colorB),
           container.contains(.colorA) {
            let r = try container.decode(Double.self, forKey: .colorR)
            let g = try container.decode(Double.self, forKey: .colorG)
            let b = try container.decode(Double.self, forKey: .colorB)
            let a = try container.decode(Double.self, forKey: .colorA)
            
            #if os(macOS)
            self.color = Color(NSColor(calibratedRed: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a)))
            #else
            self.color = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
            #endif
        } else {
            self.color = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(creationDate, forKey: .creationDate)
        try container.encode(modificationDate, forKey: .modificationDate)
        try container.encodeIfPresent(parentFolderId, forKey: .parentFolderId)
        
        if let color = color {
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            
            #if os(macOS)
            if let nsColor = NSColor(color) {
                nsColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            }
            #else
            if let components = UIColor(color).cgColor.components, components.count >= 4 {
                r = components[0]
                g = components[1]
                b = components[2]
                a = components[3]
            }
            #endif
            
            try container.encode(Double(r), forKey: .colorR)
            try container.encode(Double(g), forKey: .colorG)
            try container.encode(Double(b), forKey: .colorB)
            try container.encode(Double(a), forKey: .colorA)
        }
    }
}

// Um polymorphe Listen mit Items zu ermöglichen
enum AnyItem: Identifiable {
    case note(Note)
    case link(Link)
    
    var id: UUID {
        switch self {
        case .note(let note): return note.id
        case .link(let link): return link.id
        }
    }
}
