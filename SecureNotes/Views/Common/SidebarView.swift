// DATEI: Views/Common/SidebarView.swift
import SwiftUI

struct SidebarView: View {
    @Binding var selectedTab: SidebarTab
    @StateObject private var folderViewModel = FolderViewModel()
    @State private var showingNewFolderSheet = false
    
    var body: some View {
        List(selection: $selectedTab) {
            Section(header:
                Text("BIBLIOTHEK")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            ) {
                sidebarItem(
                    icon: "tray.fill",
                    title: "Eingang",
                    tab: .inbox,
                    iconColor: .blue
                )
                
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
                    iconColor: .orange
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
                                .frame(minWidth: 200, maxWidth: 250)
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
                                HStack {
                                    Image(systemName: icon)
                                        .foregroundColor(iconColor)
                                        .frame(width: 24)
                                    
                                    Text(title)
                                        .font(.system(size: 13))
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                                .tag(tab)
                            }
                        }
