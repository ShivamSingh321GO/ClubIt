//
//  ClubLinksView.swift
//  ClubIt
//

import SwiftUI

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
                                    if appSession.currentRole == .clubLead {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                appSession.clubLinkStore.deleteLink(link)
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
            if appSession.currentRole == .clubLead {
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
            AddClubLinkView { name, url in
                let newLink = ClubLink(
                    clubId: appSession.clubStore.club.id,
                    name: name,
                    url: url,
                    uploadedBy: appSession.currentUser?.name ?? "Lead",
                    date: Date().formatted(date: .abbreviated, time: .omitted)
                )
                appSession.clubLinkStore.addLink(newLink)
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
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 70, height: 70)
                    Image(systemName: "link")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(link.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(link.uploadedBy)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(link.date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            HStack {
                // URL Label
                Text(link.url)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .lineLimit(2)
                    .padding(.trailing, 20)
                
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
