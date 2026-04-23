import SwiftUI

struct ClubDetailView: View {
    let club: Club
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) private var appSession
    
    var isFollowing: Bool {
        appSession.clubStore.followedClubIds.contains(club.id)
    }
    
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 32) {
                
                // Club Header Section
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .frame(width: 140, height: 140)
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "circle.dotted")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundStyle(.secondary.opacity(0.3))
                    }
                    
                    VStack(spacing: 8) {
                        Text(club.name)
                            .font(.system(.title, design: .rounded))
                            .bold()
                        
                        Text(club.tagLine)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
                
                VStack(alignment: .leading, spacing: 28) {
                    // About Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About the Club")
                            .font(.title3.bold())
                        
                        Text(club.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                    
                    // Stats Section
                    HStack(spacing: 16) {
                        statBadge(value: "\(club.memberCount)", label: "Members", icon: "person.2.fill", color: .blue)
                        statBadge(value: "\(club.eventCount)", label: "Events", icon: "calendar", color: .orange)
                    }
                    
                    // Socials Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Socials")
                            .font(.title3.bold())
                        
                        HStack(spacing: 24) {
                            socialIcon(platform: "facebook", color: .blue)
                            socialIcon(platform: "instagram", color: .purple)
                            socialIcon(platform: "linkedin", color: .blue)
                            socialIcon(platform: "whatsapp", color: .green)
                            socialIcon(platform: "discord", color: .indigo)
                        }
                    }
                    
                    // Announcements Section
                    announcementsSection
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
        //.background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    appSession.clubStore.toggleFollow(for: club.id)
                } label: {
                    Text(isFollowing ? "Following" : "Follow")
                }
            }
        }
    }

    private var announcementsSection: some View {
        let clubAnnouncements = appSession.clubAnnouncementStore.announcements.filter { $0.clubId == club.id }
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Recent Announcements")
                .font(.title3)
                .bold()
            
            if clubAnnouncements.isEmpty {
                Text("No announcements yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(clubAnnouncements) { announcement in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(announcement.title)
                                .font(.headline)
                            
                            Text(announcement.content)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                            
                            HStack {
                                Text(announcement.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                if !announcement.url.isEmpty {
                                    Link(destination: URL(string: announcement.url)!) {
                                        Image(systemName: "arrow.up.right.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.3), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    }
                }
            }
        }
    }

    private func statBadge(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .bold()
                Text(label)
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func socialIcon(platform: String, color: Color) -> some View {
        let (iconName, isSystem): (String, Bool) = {
            switch platform.lowercased() {
            case "instagram": return ("camera.fill", true)
            case "facebook": return ("facebook", false)
            case "linkedin": return ("l.square.fill", true)
            case "whatsapp": return ("message.fill", true)
            case "discord": return ("bubble.left.and.bubble.right.fill", true)
            default: return ("link.circle.fill", true)
            }
        }()
        
        let urlString = club.socials[platform.lowercased()] ?? "https://google.com"
        
        return Link(destination: URL(string: urlString)!) {
            Group {
                if isSystem {
                    Image(systemName: iconName)
                        .resizable()
                        .foregroundStyle(color)
                } else {
                    Image(iconName)
                        .resizable()
                }
            }
            .aspectRatio(contentMode: .fit)
            .frame(width: 28, height: 28)
        }
    }
}

#Preview {
    NavigationStack {
        ClubDetailView(club: MockData.technoJamClub)
            .environment(AppSession())
    }
}
