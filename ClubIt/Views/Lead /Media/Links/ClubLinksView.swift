//
//  ClubLinksView.swift
//  ClubIt
//

import SwiftUI
import ClubItShared

struct ClubLinksView: View {
    @Environment(AppSession.self) var appSession
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddSheet = false
    
    var body: some View {
        let filteredLinks = appSession.clubLinkStore.links.filter {
            $0.clubId == appSession.clubStore.club.id
        }
        
        Group {
            if filteredLinks.isEmpty {
                ContentUnavailableView(
                    "No Links Yet",
                    systemImage: "link",
                    description: Text("Only members of this club can see these links.")
                )
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        ForEach(filteredLinks) { link in
                            LinkCard(link: link)
                                .contentShape(Rectangle())
                                .contextMenu {
                                    if appSession.currentRole == .subGroupLead {
                                        Button(role: .destructive) {
                                            Task {
                                                try? await appSession.clubLinkStore.deleteLink(link)
                                            }
                                        } label: {
                                            Label("Delete Link", systemImage: "trash")
                                        }
                                    }
                                }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Links")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if appSession.currentRole == .subGroupLead {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddClubLinkView { newLink in
                var link = newLink
                link.clubId = appSession.clubStore.club.id
                link.uploadedBy = appSession.currentUser?.name ?? "Lead"
                
                Task {
                    try? await appSession.clubLinkStore.addLink(link)
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

struct LinkCard: View {
    let link: ClubLink
    @State private var justCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 70, height: 70)
                    Image(systemName: "link")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(link.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(link.uploadedBy)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(link.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            HStack {
                // URL Label (Clickable)
                if let url = verifiedURL {
                    Link(destination: url) {
                        Text(link.url)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                } else {
                    Text(link.url)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                //MARK: - copy button
                HStack(spacing: 12) {
                    Button(action: {
                        copyToClipboard()
                    }) {
                        Image(systemName: justCopied ? "checkmark" : "document.on.document")
                            .font(.headline)
                            .foregroundColor(justCopied ? .green : .primary)
                            .padding()
                            .glassEffect(in: .circle)
                    }
                }
            }
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 20))
    }
    
    private var verifiedURL: URL? {
        let trimmed = link.url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return URL(string: trimmed)
        }
        return URL(string: "https://\(trimmed)")
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = link.url
        withAnimation {
            justCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                justCopied = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        ClubLinksView()
            .environment(AppSession())
    }
}
