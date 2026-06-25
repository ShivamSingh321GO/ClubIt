//
//  AnnouncementView.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/20/26.
//

import SwiftUI
import ClubItShared

struct AnnouncementView: View {
    @Environment(AppSession.self) private var appSession
    
    let announcements: [Announcement]
    var onEdit: ((Announcement) -> Void)? = nil
    var onDelete: ((Announcement) -> Void)? = nil
    
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
                        AnnouncementCard(
                            announcement: announcement,
                            onEdit: { onEdit?(announcement) },
                            onDelete: { onDelete?(announcement) }
                        )
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .refreshable {
            try? await appSession.announcementStore.fetchAnnouncements()
        }
    }
}

private struct AnnouncementCard: View {
    @Environment(AppSession.self) private var appSession
    let announcement: Announcement
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    private var canManage: Bool {
        guard let currentUser = appSession.currentUser else { return false }
        let isCreator = announcement.postedBy == currentUser.id
        let role = currentUser.role
        let hasManageRole = role == .clubLead || role == .vicePresident || role == .president || role == .faculty
        return isCreator && hasManageRole
    }
    
    private var posterName: String {
        let posterRole = appSession.clubStore.allUsers.first(where: { $0.id == announcement.postedBy })?.role
        if posterRole == .president {
            return "President"
        } else if posterRole == .vicePresident {
            return "Vice President"
        } else {
            return "Event Management Team"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "megaphone.fill")
                            .foregroundStyle(.accentColor)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(announcement.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    if let clubId = announcement.clubId,
                       let club = appSession.clubStore.allClubs.first(where: { $0.id == clubId }) {
                        (Text("Posted by ")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        + Text(club.name)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary))
                    } else {
                        (Text("Posted by ")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        + Text(posterName)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary))
                    }
                    
                    Text(relativeTimeText(from: announcement.createdAt) + (announcement.isEdited == true ? " • Edited" : ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            Text(announcement.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            if !announcement.url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if let url = verifiedURL {
                    Link(destination: url) {
                        Text(announcement.url)
                            .font(.callout)
                            .foregroundStyle(.blue)
                            .lineLimit(1)
                    }
                } else {
                    Text(announcement.url)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 20))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contentShape(.rect)
        .contextMenu {
            if canManage {
                Button {
                    onEdit?()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    onDelete?()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
    
    private var verifiedURL: URL? {
        let trimmed = announcement.url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return URL(string: trimmed)
        }
        return URL(string: "https://\(trimmed)")
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
                createdAt: Date()
            )
        ]
    )
    .padding()
    .environment(MockData.session(for: .clubLead))
}
