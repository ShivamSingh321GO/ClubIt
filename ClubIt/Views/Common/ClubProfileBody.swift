import SwiftUI
import ClubItShared

struct ClubProfileBody: View {
    @Environment(AppSession.self) var appSession
    let club: Club
    let showExtraSections: Bool
    let showFollowButton: Bool
    
    @State private var isAboutExpanded: Bool
    
    init(club: Club, showExtraSections: Bool = true, showFollowButton: Bool = false, startExpanded: Bool = true) {
        self.club = club
        self.showExtraSections = showExtraSections
        self.showFollowButton = showFollowButton
        self._isAboutExpanded = State(initialValue: startExpanded)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // MARK: - About Club Card
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Button {
                    withAnimation(.spring()) {
                        isAboutExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 16) {
                    ClubLogoView(logo: club.logo, imageData: club.imageData, size: 60, iconSize: 35)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(club.name)
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                        Text(club.tagLine ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                        Image(systemName: isAboutExpanded ? "chevron.up" : "chevron.down")
                            .font(.headline)
                            .bold()
                            .padding()
                            .glassEffect(in: .circle)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                if isAboutExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 12) {
                            Divider()
                                .padding(.bottom, 4)
                                
                            Text("ABOUT THE CLUB")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            
                            Text(club.description ?? "No description available.")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                            
                            Divider()
                                .padding(.top, 4)
                        }
                        
                        HStack(spacing: 12) {
                            NavigationLink(destination: ClubMemberListView(club: club)) {
                                StatBadge(
                                    icon: "person.2.fill",
                                    count: "\(appSession.clubStore.allUsers.filter { $0.clubId == club.id }.count)",
                                    label: "Members",
                                    color: .green
                                )
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: AchievementsListView()) {
                                StatBadge(
                                    icon: "trophy.fill",
                                    count: "\(appSession.clubAchievementStore.achievements.filter { $0.clubId == club.id }.count)",
                                    label: "Achievements",
                                    color: .accentColor
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("SOCIALS")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 20) {
                                let platforms = ["whatsapp", "instagram", "facebook", "linkedin", "discord"]
                                let available = platforms.filter { (club.socials ?? [:]).keys.contains($0) }
                                
                                if available.isEmpty {
                                    Text("No social links provided")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .italic()
                                } else {
                                    ForEach(available, id: \.self) { platform in
                                        if let urlString = (club.socials ?? [:])[platform], let url = URL(string: urlString) {
                                            Link(destination: url) {
                                                SocialCircle(platform: platform)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                        
                        if showFollowButton && appSession.currentRole == .student {
                            let isFollowing = appSession.clubStore.followedClubIds.contains(club.id)
                            Button {
                                withAnimation {
                                    appSession.clubStore.toggleFollow(for: club.id)
                                }
                            } label: {
                                Label(isFollowing ? "Following" : "Follow", systemImage: isFollowing ? "checkmark" : "plus")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                            .controlSize(.large)
                            .tint(isFollowing ? .secondary : .accentColor)
                            .padding(.top, 12)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(20)
            .glassEffect(in: RoundedRectangle(cornerRadius: 20))
            
            if showExtraSections {
                // MARK: - Activities
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Activities")
                        NavigationLink(destination: ActivityListView()) {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .font(.title2)
                    .bold()
                    
                    VStack(spacing: 12) {
                        let activities = appSession.activityStore.activities.prefix(2)
                        if activities.isEmpty {
                            Text("No recent activities")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .glassEffect(in: .rect(cornerRadius: 20))
                        } else {
                            ForEach(activities) { activity in
                                ActivityCard(activity: activity) { tappedActivity in
                                    appSession.selectedActivity = tappedActivity
                                }
                                .contextMenu {
                                    if appSession.currentRole == .clubLead {
                                        Button(role: .destructive) {
                                            Task {
                                                do {
                                                    try await appSession.activityStore.deleteActivity(activity)
                                                } catch {
                                                    print("DEBUG: Failed to delete activity: \(error.localizedDescription)")
                                                }
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                                .padding(.bottom, 12)
                            }
                        }
                    }
                }
            }
            
            if showExtraSections {
                // MARK: - Media
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Media")
                        Spacer()
                    }
                    .font(.title2)
                    .bold()
                    
                    HStack(spacing: 16) {
                        NavigationLink(destination: ClubImagesView()) {
                            MediaButton(icon: "photo.fill", label: "Images", color: .accentColor)
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
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
