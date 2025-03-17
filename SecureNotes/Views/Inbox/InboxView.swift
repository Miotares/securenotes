// Ordner: Views/Inbox/InboxView.swift
import SwiftUI

struct InboxView: View {
    @State private var searchText = ""
    @State private var showingNewNoteSheet = false
    @State private var showingNewLinkSheet = false
    
    var body: some View {
        VStack {
            // Temporär einfache Suchleiste bis SearchBar implementiert ist
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Suchen...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            
            List {
                Text("Eingangsbereich - Elemente werden hier angezeigt")
            }
            .listStyle(PlainListStyle())
            
            HStack {
                Spacer()
                
                Button(action: { showingNewNoteSheet = true }) {
                    Label("Neue Notiz", systemImage: "note.text.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: { showingNewLinkSheet = true }) {
                    Label("Neuer Link", systemImage: "link.badge.plus")
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Eingang")
        .sheet(isPresented: $showingNewNoteSheet) {
            NewNoteView(isPresented: $showingNewNoteSheet)
        }
        .sheet(isPresented: $showingNewLinkSheet) {
            NewLinkView(isPresented: $showingNewLinkSheet)
        }
    }
}

// Einfache Hilfssicht für Einträge
struct InboxItemRowView: View {
    var title: String
    var subtitle: String
    var icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
