// DATEI: Views/Links/LinkView.swift
import SwiftUI
import WebKit

struct LinkView: View {
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var showingFolderPicker = false
    @State private var isLoadingWebContent = false
    @State private var webViewHeight: CGFloat = 300
    
    // Link direkt aus dem ViewModel
    let link: LinkViewModel.Link
    
    var body: some View {
        VStack {
            if isEditing {
                // Platzhalter für Editor
                Text("Link-Editor")
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            if let favicon = link.favicon, let nsImage = NSImage(data: favicon) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .frame(width: 24, height: 24)
                            } else {
                                Image(systemName: "link")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                            
                            Text(link.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Menu {
                                Button(action: { isEditing = true }) {
                                    Label("Bearbeiten", systemImage: "pencil")
                                }
                                
                                Button(action: { showingFolderPicker = true }) {
                                    Label("In Ordner verschieben", systemImage: "folder")
                                }
                                
                                Button(action: {
                                    NSWorkspace.shared.open(link.url)
                                }) {
                                    Label("Im Browser öffnen", systemImage: "safari")
                                }
                                
                                Button(role: .destructive, action: { showingDeleteAlert = true }) {
                                    Label("Löschen", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.title2)
                            }
                        }
                        .padding(.bottom, 4)
                        
                        Button(action: {
                            NSWorkspace.shared.open(link.url)
                        }) {
                            Text(link.url.absoluteString)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        
                        Text("Hinzugefügt: \(formattedDate(link.creationDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let description = link.description, !description.isEmpty {
                            Divider()
                            
                            Text("Notizen")
                                .font(.headline)
                            
                            Text(description)
                                .font(.body)
                                .lineSpacing(1.5)
                        }
                        
                        Divider()
                        
                        Text("Webseitenvorschau")
                            .font(.headline)
                        
                        WebView(url: link.url, loading: $isLoadingWebContent, height: $webViewHeight)
                            .frame(height: webViewHeight)
                            .overlay(
                                isLoadingWebContent ?
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(1.5)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color(.windowBackgroundColor).opacity(0.7))
                                : nil
                            )
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(isEditing ? "Link bearbeiten" : "Link")
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { isEditing = true }) {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
        .alert("Link löschen", isPresented: $showingDeleteAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Löschen", role: .destructive) {
                deleteLink()
            }
        } message: {
            Text("Möchtest du diesen Link wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.")
        }
        .sheet(isPresented: $showingFolderPicker) {
            // Temporärer Platzhalter für den FolderPicker
            Text("Ordnerauswahl")
                .frame(width: 300, height: 200)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func deleteLink() {
        // Hier würde in einer vollständigen App der Link gelöscht werden
        print("Link gelöscht")
    }
}
