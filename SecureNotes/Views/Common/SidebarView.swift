// DATEI: Views/Common/SidebarView.swift
import SwiftUI
import Combine

struct SidebarView: View {
    @Binding var selectedTab: SidebarTab
    @StateObject private var folderViewModel = FolderViewModel()
    @State private var showingNewFolderSheet = false
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
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
            .background(Color(.textBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            .padding([.horizontal, .bottom], 8)
            
            // Listenansicht
            List(selection: Binding<SidebarTab?>(
                get: { selectedTab },
                set: { if let newValue = $0 { selectedTab = newValue } }
            )) {
                Section(header:
                    Text("BIBLIOTHEK")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                ) {
                    sidebarItem(
                        icon: "note.text",
                        title: "Alle Notizen",
                        tab: .notes,
                        iconColor: .green
                    )
                    
                    sidebarItem(
                        icon: "link",
                        title: "Alle Links",
                        tab: .links,
                        iconColor: .blue
                    )
                }
                
                Section(header:
                    HStack {
                        Text("ORDNER")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: { showingNewFolderSheet = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                ) {
                    ForEach(folderViewModel.folders) { folder in
                        sidebarItem(
                            icon: "folder.fill",
                            title: folder.name,
                            tab: .folder(folder),
                            iconColor: folder.color
                        )
                        .contextMenu {
                            Button(action: {
                                // Ordner umbenennen
                            }) {
                                Label("Umbenennen", systemImage: "pencil")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: {
                                folderViewModel.deleteFolder(folder.id)
                            }) {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(SidebarListStyle())
        }
        .sheet(isPresented: $showingNewFolderSheet) {
            FolderEditorView(isPresented: $showingNewFolderSheet)
                .environmentObject(folderViewModel)
        }
        .onAppear {
            folderViewModel.loadFolders()
        }
    }
    
    @ViewBuilder
    private func sidebarItem(icon: String, title: String, tab: SidebarTab, iconColor: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 20, height: 20)
                .font(.system(size: 13))
            
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .tag(tab)
    }
}
