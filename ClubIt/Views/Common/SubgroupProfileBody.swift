import SwiftUI
import ClubItShared

struct SubgroupProfileBody: View {
    @Environment(AppSession.self) var appSession
    let subgroup: Subgroup
    let showExtraSections: Bool
    let showFollowButton: Bool
    
    @State private var isAboutExpanded: Bool
    
    init(subgroup: Subgroup, showExtraSections: Bool = true, showFollowButton: Bool = false, startExpanded: Bool = true) {
        self.subgroup = subgroup
        self.showExtraSections = showExtraSections
        self.showFollowButton = showFollowButton
        self._isAboutExpanded = State(initialValue: startExpanded)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // MARK: - About Subgroup Card
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Button {
                    withAnimation(.spring()) {
                        isAboutExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 16) {
                    SubgroupLogoView(logo: subgroup.logo, imageData: subgroup.imageData, size: 60, iconSize: 35)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(subgroup.name)
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                        Text(subgroup.tagLine ?? "")
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
                                
                            Text("ABOUT THE SUBGROUP")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            
                            Text(subgroup.description ?? "No description available.")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                            
                            Divider()
                                .padding(.top, 4)
                        }
                        
                        HStack(spacing: 12) {
                            NavigationLink(destination: SubgroupMemberListView(subgroup: subgroup)) {
                                StatBadge(
                                    icon: "person.2.fill",
                                    count: "\(appSession.subgroupStore.allUsers.filter { $0.subgroupId == subgroup.id }.count)",
                                    label: "Members",
                                    color: .green
                                )
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: AchievementsListView()) {
                                StatBadge(
                                    icon: "trophy.fill",
                                    count: "\(appSession.subgroupAchievementStore.achievements.filter { $0.subgroupId == subgroup.id }.count)",
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
                                let available = platforms.filter { (subgroup.socials ?? [:]).keys.contains($0) }
                                
                                if available.isEmpty {
                                    Text("No social links provided")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .italic()
                                } else {
                                    ForEach(available, id: \.self) { platform in
                                        if let urlString = (subgroup.socials ?? [:])[platform], let url = URL(string: urlString) {
                                            Link(destination: url) {
                                                SocialCircle(platform: platform)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                        
                        if showFollowButton && appSession.currentRole == .guest {
                            let isFollowing = appSession.subgroupStore.followedSubgroupIds.contains(subgroup.id)
                            Button {
                                withAnimation {
                                    appSession.subgroupStore.toggleFollow(for: subgroup.id)
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
                                    if appSession.currentRole == .subGroupLead {
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
                        NavigationLink(destination: SubgroupImagesView()) {
                            MediaButton(icon: "photo.fill", label: "Images", color: .accentColor)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        NavigationLink(destination: SubgroupFilesView()) {
                            MediaButton(icon: "doc.text.fill", label: "Files", color: .brown)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        NavigationLink(destination: SubgroupLinksView()) {
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
