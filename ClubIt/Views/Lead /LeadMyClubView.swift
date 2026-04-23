//
//  MyClubLead.swift
//  ClubIt
//


import SwiftUI

struct LeadMyClubView: View {
    @Environment(AppSession.self) var appSession
    
    var user: User? {
        appSession.currentUser
    }
    
    @State private var isAboutExpanded: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.goldenBrown, .goldenBrown.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "flame.fill")
                                    .font(.title.bold())
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(appSession.clubStore.club.name)
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.primary)
                                Text(appSession.clubStore.club.tagLine)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring()) {
                                    isAboutExpanded.toggle()
                                }
                            }) {
                                Image(systemName: isAboutExpanded ? "chevron.up" : "chevron.down")
                                    .font(.headline)
                                    .bold()
                                    .padding()
                                    .glassEffect(in: .circle)
                            }
                        }
                        
                        if isAboutExpanded {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("About the Club")
                                    .font(.headline)
                                    .bold()
                                    .foregroundColor(.primary)
                                Text(appSession.clubStore.club.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                                
                                HStack(spacing: 20) {
                                    StatBadge(icon: "person.2.fill", count: "\(appSession.clubStore.club.memberCount)", label: "Members", color: Color(red: 0.2, green: 0.8, blue: 0.5))
                                    Spacer()
                                    NavigationLink(destination: AchievementsListView()) {
                                        StatBadge(icon: "trophy.fill", count: "\(appSession.clubAchievementStore.achievements.filter { $0.clubId == appSession.clubStore.club.id }.count)", label: "Achievements", color: Color(red: 1.0, green: 0.8, blue: 0.2))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.top, 5)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Socials")
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.primary)
                                    HStack(spacing: 16) {
                                        ForEach(appSession.clubStore.club.socials.sorted(by: { $0.key < $1.key }), id: \.key) { platform, urlString in
                                            if let url = URL(string: urlString) {
                                                Link(destination: url) {
                                                    SocialCircle(platform: platform)
                                                    Spacer()
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 4)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding()
                    .glassEffect(in: .rect(cornerRadius: 20))
                    .padding(.horizontal, 16)
                    
                    
                    // MARK: - Activities
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            Text("Activities")
                            NavigationLink(destination: ActivityListView()) {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(.title2)
                        .bold()
                        .padding(.horizontal, 16)
                        
                        VStack(spacing: 0) {
                            let activities = appSession.activityStore.activities.prefix(2)
                            if activities.isEmpty {
                                Text("No recent activities")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .glassEffect(in: .rect(cornerRadius: 20))
                                    .padding(.horizontal, 16)
                            } else {
                                ForEach(activities) { activity in
                                    ActivityCard(activity: activity)
                                        .padding(.bottom, 12)
                                }
                            }
                        }
                    }
                    
                    
//                    // MARK: - Club Announcements
//                    VStack(alignment: .leading, spacing: 24) {
//                        HStack {
//                            Text("Club announcement")
//                            NavigationLink(destination: ClubAnnouncementsView()) {
//                                Image(systemName: "chevron.right")
//                            }
//                        }
//                        .font(.title2)
//                        .bold()
//                        .padding(.horizontal, 16)
//                        
//                        VStack(spacing: 8) {
//                            let recentAnnouncements = appSession.clubAnnouncementStore.announcements
//                                .filter { $0.clubId == appSession.clubStore.club.id }
//                                .sorted(by: { $0.createdAt > $1.createdAt })
//                                .prefix(2)
//                            
//                            if recentAnnouncements.isEmpty {
//                                Text("No announcements added yet.")
//                                    .font(.subheadline)
//                                    .foregroundColor(.secondary)
//                                    .frame(maxWidth: .infinity, alignment: .center)
//                                    .padding()
//                                    .glassEffect(in: .rect(cornerRadius: 20))
//                            } else {
//                                ForEach(recentAnnouncements) { ann in
//                                    LocalAnnouncementCard(announcement: ann)
//                                        .contentShape(Rectangle())
//                                        .contextMenu {
//                                            if appSession.currentRole == .clubLead {
//                                                Button(role: .destructive) {
//                                                    withAnimation {
//                                                        appSession.clubAnnouncementStore.deleteAnnouncement(ann)
//                                                    }
//                                                } label: {
//                                                    Label("Delete", systemImage: "trash")
//                                                }
//                                            }
//                                        }
//                                }
//                            }
//                        }
//                        .padding(.horizontal, 16)
//                    }
//                    
                    // MARK: - Media
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            Text("Media")
                            Spacer()
                        }
                        .font(.title2)
                        .bold()
                        .padding(.horizontal, 16)
                        
                        HStack(spacing: 16) {
                            NavigationLink(destination: ClubImagesView()) {
                                MediaButton(icon: "photo.fill", label: "Images", color: .orange)
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            NavigationLink(destination: ClubFilesView()) {
                                MediaButton(icon: "doc.text.fill", label: "Files", color: .brown)
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            NavigationLink(destination: ClubLinksView()) {
                                MediaButton(icon: "link", label: "Links", color: .green)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        .glassEffect(in: .rect(cornerRadius: 20))
                        .padding(.horizontal, 16)
                    }
                    

                    Spacer(minLength: 40)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("My Club")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if appSession.currentRole == .clubLead {
                        NavigationLink(destination: EditClubDetailView(club: appSession.clubStore.club)) {
                            Text("Edit")
                        }
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct StatBadge: View {
    let icon: String
    let count: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .center, spacing: 0) {
                Text(count)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SocialCircle: View {
    let platform: String
    
    var iconName: String {
        switch platform.lowercased() {
        case "instagram": return "camera.fill"
        case "facebook": return "f.square.fill"
        case "linkedin": return "l.square.fill"
        case "whatsapp": return "message.fill"
        case "discord": return "bubble.left.and.bubble.right.fill"
        default: return "globe"
        }
    }
    
    var color: Color {
        switch platform.lowercased() {
        case "instagram": return .pink
        case "facebook": return .blue
        case "linkedin": return .blue
        case "whatsapp": return .green
        case "discord": return .indigo
        default: return .gray
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 44, height: 44)
            Image(systemName: iconName)
                .font(.headline)
                .foregroundColor(color)
        }
    }
}

struct LocalAnnouncementCard: View {
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
                    
                    Text(relativeTimeText(from: announcement.createdAt))
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
            
            if !announcement.url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
    
    private func relativeTimeText(from date: Date) -> String {
        let diff = Int(Date().timeIntervalSince(date))
        let minutes = diff / 60
        let hours = diff / 3600
        let days = diff / 86400
        
        if minutes < 1 { return "0 minutes ago" }
        if minutes < 60 { return "\(minutes) minutes ago" }
        if hours < 24 { return "\(hours) hours ago" }
        return "\(days) days ago"
    }
}

struct MediaButton: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .frame(width: 64, height: 64)
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(5)
        .frame(width: 80)
    }
}

struct AchievementStatBox: View {
    let count: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(count)
                .font(.title3.bold())
                .foregroundColor(.primary)
            Text(label)
                .font(.caption.bold())
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.cardsBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))

    }
}

struct AchievementItem: View {
    let icon: String
    let title: String
    let date: String
    let desc: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.05))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.body)
                }
//                .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Text(desc)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let session = AppSession()
    session.currentRole = .clubLead
    session.currentUser = MockData.clubLeadUser
    return LeadMyClubView()
        .environment(session)
}
