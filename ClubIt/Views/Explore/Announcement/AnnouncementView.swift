//
//  AnnouncementView.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/20/26.
//

import SwiftUI

struct AnnouncementView: View {
    
    let announcements: [Announcement]
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                if announcements.isEmpty {
                    ContentUnavailableView(
                        "No Announcements Yet",
                        systemImage: "megaphone",
                        description: Text("Announcements you create will appear here.")
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(announcements) { announcement in
                        AnnouncementCard(announcement: announcement)
                    }
                }
            }
            .padding(.bottom, 16)
        }
    }
}

private struct AnnouncementCard: View {
    @Environment(AppSession.self) private var appSession
    let announcement: Announcement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "megaphone.fill")
                            .foregroundStyle(.goldenBrown)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(announcement.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    if let club = appSession.clubStore.allClubs.first(where: { $0.id == announcement.clubId }) {
                        Text(club.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    Text(relativeTimeText(from: announcement.createdAt))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            Text(announcement.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            if !announcement.url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(announcement.url)
                    .font(.callout)
                    .foregroundStyle(.blue)
                    .lineLimit(1)
            }
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 20))
    }
    
    private func relativeTimeText(from date: Date) -> String {
        let diff = Int(Date().timeIntervalSince(date))
        
        let minutes = diff / 60
        let hours = diff / 3600
        let days = diff / 86400
        
        if minutes < 1 {
            return "0 minutes ago"
        } else if minutes < 60 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if hours < 24 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
}

#Preview {
    AnnouncementView(
        announcements: [
            Announcement(id: UUID(), clubId: MockData.tj_id,
                date: Date(),
                title: "Sample Announcement",
                content: "This is a sample announcement.",
                url: "https://example.com",
                postedBy: UUID(),
                target: .club,
                createdAt: Date()
            )
        ]
    )
    .padding()
    .environment(MockData.session(for: .clubLead))
}
