// DATEI: Views/Links/LinkListColumn.swift
import SwiftUI

struct LinkListColumn: View {
    @EnvironmentObject var linkViewModel: LinkViewModel
    @State private var searchText = ""
    @Binding var selectedLink: LinkViewModel.Link?
    @State private var sortOption: SortOption = .dateModified
    @State private var viewStyle: ViewStyle = .list
    
    enum SortOption {
        case dateModified
        case dateCreated
        case title
        
        var label: String {
            switch self {
            case .dateModified: return "Zuletzt bearbeitet"
            case .dateCreated: return "Erstelldatum"
            case .title: return "Titel"
            }
        }
        
        var iconName: String {
            switch self {
            case .dateModified: return "calendar.badge.clock"
            case .dateCreated: return "calendar.badge.plus"
            case .title: return "textformat.abc"
            }
        }
    }
    
    enum ViewStyle {
        case list
        case grid
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header mit Suchleiste und Ansichtsoptionen
            VStack(spacing: 10) {
                HStack {
                    Text("Links")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(filteredLinks.count) \(filteredLinks.count == 1 ? "Link" : "Links")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Ansichts-Toggle
                    Button(action: { viewStyle = viewStyle == .list ? .grid : .list }) {
                        Image(systemName: viewStyle == .list ? "square.grid.2x2" : "list.bullet")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Sortiermenü
                    Menu {
                        Button(action: { sortOption = .dateModified }) {
                            Label("Zuletzt bearbeitet", systemImage: "calendar.badge.clock")
                        }
                        .disabled(sortOption == .dateModified)
                        
                        Button(action: { sortOption = .dateCreated }) {
                            Label("Erstelldatum", systemImage: "calendar.badge.plus")
                        }
                        .disabled(sortOption == .dateCreated)
                        
                        Button(action: { sortOption = .title }) {
                            Label("Titel", systemImage: "textformat.abc")
                        }
                        .disabled(sortOption == .title)
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                }
                
                // Suchleiste
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                    
                    TextField("Suchen...", text: $searchText)
                        .font(.system(size: 13))
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(8)
                .background(Color(.textBackgroundColor).opacity(0.4))
                .cornerRadius(8)
            }
            .padding([.horizontal, .top], 16)
            .padding(.bottom, 8)
            
            // Sortierinfo
            HStack {
                Label(
                    title: { Text(sortOption.label).font(.caption) },
                    icon: { Image(systemName: sortOption.iconName).font(.caption) }
                )
                .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Links anzeigen basierend auf ausgewähltem Stil
            if viewStyle == .list {
                listView
            } else {
                gridView
            }
        }
    }
    
    // Listenansicht
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(filteredLinks) { link in
                    linkRow(for: link)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedLink = link
                        }
                        .contextMenu {
                            Button(action: {
                                NSWorkspace.shared.open(link.url)
                            }) {
                                Label("Im Browser öffnen", systemImage: "safari")
                            }
                            
                            Button(action: {
                                // In Ordner verschieben
                            }) {
                                Label("In Ordner verschieben", systemImage: "folder")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: {
                                linkViewModel.deleteLink(link.id)
                                if selectedLink?.id == link.id {
                                    selectedLink = nil
                                }
                            }) {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // Rasteransicht
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 200))], spacing: 16) {
                ForEach(filteredLinks) { link in
                    linkCard(for: link)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedLink = link
                        }
                        .contextMenu {
                            Button(action: {
                                NSWorkspace.shared.open(link.url)
                            }) {
                                Label("Im Browser öffnen", systemImage: "safari")
                            }
                            
                            Button(action: {
                                // In Ordner verschieben
                            }) {
                                Label("In Ordner verschieben", systemImage: "folder")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: {
                                linkViewModel.deleteLink(link.id)
                                if selectedLink?.id == link.id {
                                    selectedLink = nil
                                }
                            }) {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(16)
        }
    }
    
    // Einzelne Link-Zeile
    private func linkRow(for link: LinkViewModel.Link) -> some View {
        HStack(spacing: 12) {
            // Favicon
            Group {
                if let favicon = link.favicon, let nsImage = NSImage(data: favicon) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Image(systemName: "link")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .frame(width: 20, height: 20)
                }
            }
            
            // Link Details
            VStack(alignment: .leading, spacing: 2) {
                Text(link.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(link.url.host ?? link.url.absoluteString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Letzte Änderung und Tags
                HStack {
                    Text(formattedDate(link.modificationDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Tags
                    if !link.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(link.tags.prefix(1), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            
                            if link.tags.count > 1 {
                                Text("+\(link.tags.count - 1)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(
            selectedLink?.id == link.id ?
                Color.blue.opacity(0.1) :
                Color.clear
        )
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    selectedLink?.id == link.id ?
                        Color.blue.opacity(0.3) :
                        Color.clear,
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 16)
    }
    
    // Link-Karte für die Rasteransicht
    private func linkCard(for link: LinkViewModel.Link) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header mit Favicon und Domain
            HStack {
                Group {
                    if let favicon = link.favicon, let nsImage = NSImage(data: favicon) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    } else {
                        Image(systemName: "link")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                            .frame(width: 16, height: 16)
                    }
                }
                
                Text(link.url.host ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: "arrow.up.forward.app")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Titel
            Text(link.title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 40)
            
            Spacer()
            
            // Tags
            if !link.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(link.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(height: 120)
        .background(
            selectedLink?.id == link.id ?
                Color.blue.opacity(0.1) :
                Color(.textBackgroundColor).opacity(0.5)
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    selectedLink?.id == link.id ?
                        Color.blue.opacity(0.3) :
                        Color.gray.opacity(0.2),
                    lineWidth: selectedLink?.id == link.id ? 2 : 1
                )
        )
    }
    
    // Sortieren und Filtern
    private var filteredLinks: [LinkViewModel.Link] {
        let filtered = searchText.isEmpty ? linkViewModel.links :
            linkViewModel.links.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.url.absoluteString.localizedCaseInsensitiveContains(searchText) ||
                ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        
        switch sortOption {
        case .dateModified:
            return filtered.sorted { $0.modificationDate > $1.modificationDate }
        case .dateCreated:
            return filtered.sorted { $0.creationDate > $1.creationDate }
        case .title:
            return filtered.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
