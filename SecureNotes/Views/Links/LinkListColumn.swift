//
//  LinkListColumn.swift
//  SecureNotes
//
//  Created by Merlin Kreuzkam on 17.03.25.
//


// DATEI: Views/Links/LinkListColumn.swift
import SwiftUI

struct LinkListColumn: View {
    @EnvironmentObject var linkViewModel: LinkViewModel
    @State private var searchText = ""
    @Binding var selectedLink: LinkViewModel.Link?
    
    var body: some View {
        VStack(spacing: 0) {
            // Suchleiste
            VStack(spacing: 0) {
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Suchen...", text: $searchText)
                            .textFieldStyle(.plain)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(8)
                }
                .padding([.horizontal, .top])
                
                Divider()
                    .padding(.top, 8)
            }
            
            // Links-Liste
            List(selection: Binding(
                get: { selectedLink?.id },
                set: { newValue in
                    if let id = newValue,
                       let link = filteredLinks.first(where: { $0.id == id }) {
                        selectedLink = link
                    }
                }
            )) {
                ForEach(filteredLinks) { link in
                    linkRow(for: link)
                        .tag(link.id)
                }
            }
            .listStyle(.sidebar)
        }
        .navigationTitle("Links")
    }
    
    // Link-Zeile
    private func linkRow(for link: LinkViewModel.Link) -> some View {
        HStack {
            // Favicon
            if let favicon = link.favicon, let nsImage = NSImage(data: favicon) {
                Image(nsImage: nsImage)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .cornerRadius(2)
            } else {
                Image(systemName: "link")
                    .foregroundColor(.blue)
                    .frame(width: 16, height: 16)
            }
            
            // Link Details
            VStack(alignment: .leading, spacing: 4) {
                Text(link.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(link.url.host ?? link.url.absoluteString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Tags
                if !link.tags.isEmpty {
                    HStack {
                        Text(link.tags.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var filteredLinks: [LinkViewModel.Link] {
        if searchText.isEmpty {
            return linkViewModel.links
        } else {
            return linkViewModel.links.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.url.absoluteString.localizedCaseInsensitiveContains(searchText) ||
                ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }
    }
}