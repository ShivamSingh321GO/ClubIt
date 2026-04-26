import SwiftUI

struct ClubProfileBody: View {
    @Environment(AppSession.self) var appSession
    let club: Club
    let showExtraSections: Bool
    let showFollowButton: Bool
    
    init(club: Club, showExtraSections: Bool = true, showFollowButton: Bool = false) {
        self.club = club
        self.showExtraSections = showExtraSections
        self.showFollowButton = showFollowButton
    }
    
    @State private var isAboutExpanded: Bool = true
    @State private var selectedActivity: Activity? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            // MARK: - About Club Card
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.indigo.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 60, height: 60)
                        
                        if let imageData = club.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        } else if !club.logo.isEmpty && UIImage(named: club.logo) != nil {
                            Image(club.logo)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "flame.fill")
                                .font(.title.bold())
                                .foregroundColor(.white)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(club.name)
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                        Text(club.tagLine)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring()) {
                            isAboutExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isAboutExpanded ? "chevron.up" : "chevron.down")
                            .font(.headline.bold())
                            .foregroundColor(.orange)
                            .padding(12)
                            .background(Color.white.opacity(0.05))
                            .clipShape(Circle())
                    }
                }
                
                if isAboutExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About the Club")
                            .font(.headline.bold())
                            .foregroundColor(.primary)
                        
                        Text(club.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                        
                        HStack(spacing: 16) {
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
                                    color: .orange
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Socials")
                                .font(.headline.bold())
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 20) {
                                let platforms = ["whatsapp", "instagram", "facebook", "linkedin", "discord"]
                                let available = platforms.filter { club.socials.keys.contains($0) }
                                
                                if available.isEmpty {
                                    Text("No social links provided")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .italic()
                                } else {
                                    ForEach(available, id: \.self) { platform in
                                        if let urlString = club.socials[platform], let url = URL(string: urlString) {
                                            Link(destination: url) {
                                                SocialCircle(platform: platform)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                        
                        if showFollowButton {
                            let isFollowing = appSession.clubStore.followedClubIds.contains(club.id)
                            Button {
                                withAnimation {
                                    appSession.clubStore.toggleFollow(for: club.id)
                                }
                            } label: {
                                HStack {
                                    Spacer()
                                    Text(isFollowing ? "Following" : "Follow")
                                        .font(.headline.bold())
                                    Spacer()
                                }
                                .padding(.vertical, 14)
                                .background(isFollowing ? Color.white.opacity(0.1) : Color.orange)
                                .foregroundColor(isFollowing ? .primary : .white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 12)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(20)
            .background(Color(white: 0.05).opacity(0.8))
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
            .padding(.horizontal, 16)
            
            if showExtraSections {
                // MARK: - Activities
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Activities")
                            .font(.title2.bold())
                        NavigationLink(destination: ActivityListView()) {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    VStack(spacing: 12) {
                        let activities = appSession.activityStore.activities.prefix(2)
                        if activities.isEmpty {
                            Text("No recent activities")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(20)
                                .padding(.horizontal, 16)
                        } else {
                            ForEach(activities) { activity in
                                ActivityCard(activity: activity) { tappedActivity in
                                    selectedActivity = tappedActivity
                                }
                                .padding(.horizontal, 16)
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
                            .font(.title2.bold())
                        Spacer()
                    }
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
                    .padding(.horizontal, 24)
                }
            }
        }
        .sheet(item: $selectedActivity) { activity in
            ActivityDetailView(activity: activity)
                .environment(appSession)
                .presentationDetents([.large])
        }
    }
}
