// DATEI: Views/Links/LinkList.swift
import SwiftUI

struct LinkList: View {
    @EnvironmentObject var linkViewModel: LinkViewModel
    @State private var searchText = ""
    @State private var showingNewLinkSheet = false
    @State private var selectedLink: LinkViewModel.Link?
    @State private var gridLayout = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Suchleiste und Ansichtsoptionen
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
                    
                    Picker("Ansicht", selection: $gridLayout) {
                        Image(systemName: "list.bullet")
                            .tag(false)
                        
                        Image(systemName: "square.grid.2x2")
                            .tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 80)
                }
                .padding([.horizontal, .top])
                
                Divider()
                    .padding(.top, 8)
            }
            
            // Links anzeigen
            Group {
                if gridLayout {
                    gridView
                } else {
                    listView
                }
            }
        }
        .navigationTitle("Links")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewLinkSheet = true }) {
                    Image(systemName: "link.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showingNewLinkSheet) {
            NewLinkView(isPresented: $showingNewLinkSheet)
                .environmentObject(linkViewModel)
        }
    }
    
    // Rasteransicht
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 16) {
                ForEach(filteredLinks) { link in
                    LinkGridCard(link: link, isSelected: selectedLink?.id == link.id)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedLink = link
                            NSWorkspace.shared.open(link.url)
                        }
                        .contextMenu {
                            Button(action: {
                                NSWorkspace.shared.open(link.url)
                            }) {
                                Label("Öffnen", systemImage: "safari")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: {
                                linkViewModel.deleteLink(link.id)
                            }) {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                }
            }
            .padding()
        }
    }
    
    // Listenansicht
    private var listView: some View {
        List(selection: Binding(
            get: { selectedLink?.id },
            set: { newValue in
                if let id = newValue, let link = filteredLinks.first(where: { $0.id == id }) {
                    selectedLink = link
                }
            }
        )) {
            ForEach(filteredLinks) { link in
                NavigationLink(
                    destination: LinkView(link: link)
                ) {
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
                                    ForEach(link.tags.prefix(2), id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                    
                                    if link.tags.count > 2 {
                                        Text("+\(link.tags.count - 2)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .tag(link.id)
            }
        }
        .listStyle(.inset)
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

struct LinkGridCard: View {
    let link: LinkViewModel.Link
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Favicon und Domain
            HStack {
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
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 44)
            
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
        .background(Color(.textBackgroundColor).opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
    }
}
