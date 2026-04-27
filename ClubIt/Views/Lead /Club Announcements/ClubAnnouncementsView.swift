//
//  ClubAnnouncementsView.swift
//  ClubIt
//

import SwiftUI

struct ClubAnnouncementsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) var appSession
    
    @State private var showCreateSheet = false
    
    var body: some View {
        let clubAnnouncements = appSession.announcementStore.announcements
            .filter { $0.clubId == appSession.clubStore.club.id }
        
        Group {
            if clubAnnouncements.isEmpty {
                ContentUnavailableView(
                    "No announcements yet",
                    systemImage: "megaphone",
                    description: Text("Stay tuned for updates from your club.")
                )
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(clubAnnouncements) { announcement in
                            ClubAnnouncementCard(announcement: announcement)
                                .contentShape(Rectangle())
                                .contextMenu {
                                    if appSession.currentRole == .clubLead {
                                        Button(role: .destructive) {
                                            Task {
                                                try? await appSession.announcementStore.deleteAnnouncement(announcement)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(Color.f2Background.ignoresSafeArea())
        .navigationTitle("Club Announcements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if appSession.currentRole == .clubLead {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateClubAnnouncementView { title, content, url in
                Task {
                    try? await appSession.announcementStore.addAnnouncement(
                        title: title,
                        content: content,
                        url: url,
                        postedBy: appSession.currentUser?.id ?? UUID(),
                        clubId: appSession.clubStore.club.id
                    )
                }
            }
        }
    }
}

struct ClubAnnouncementCard: View {
    let announcement: Announcement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "megaphone.fill")
                            .foregroundStyle(.goldenBrown)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(announcement.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(announcement.date, format: .dateTime.month().day().year().hour().minute())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(announcement.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)
            
            if !announcement.url.isEmpty {
                Text(announcement.url)
                    .font(.callout)
                    .foregroundColor(.blue)
                    .lineLimit(1)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(in: .rect(cornerRadius: 20))
    }
}

#Preview {
    NavigationStack {
        ClubAnnouncementsView()
            .environment(MockData.session(for: .clubLead))
    }
}
