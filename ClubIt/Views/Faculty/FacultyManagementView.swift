import SwiftUI
import ClubItShared

struct FacultyManagementView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    
                    // MARK: - Quick Actions
                    VStack(alignment: .leading, spacing: 16) {
                        
                        VStack(spacing: 0) {
                            NavigationLink(destination: FacultyResourceSubgroupsView()) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.accentColor.opacity(0.1))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "archivebox")
                                            .font(.subheadline)
                                            .foregroundColor(.accentColor)
                                    }
                                    
                                    Text("Approval Management")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                            .buttonStyle(.plain)
                            
                            if !(appSession.organizationFeatures?.isVenueDisabled ?? false) {
                                Divider().padding(.leading, 56)
                                NavigationLink {
                                    FacultyVenueListView()
                                } label: {
                                    QuickActionRow(icon: "building.2", title: "View Venues", color: .blue)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .glassEffect(in: .rect(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Handled Subgroups
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Assigned Subgroups")
                            .font(.title2)
                            .bold()
                        
                        VStack(spacing: 16) {
                            if let user = appSession.currentUser {
                                let assignedSubgroups = appSession.subgroupStore.allSubgroups.filter { $0.facultyId == user.id }
                                
                                if assignedSubgroups.isEmpty {
                                    Text("No subgroups currently assigned")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding()
                                } else {
                                    ForEach(assignedSubgroups) { subgroup in
                                        FacultyExpandableSubgroupRow(subgroup: subgroup)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Manage")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }
}



struct FacultyExpandableSubgroupRow: View {
    @Environment(AppSession.self) var appSession
    let subgroup: Subgroup
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(String(subgroup.name.prefix(1)))
                                .font(.headline)
                                .foregroundColor(.accentColor)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(subgroup.name)
                            .font(.body)
                            .bold()
                        Text(subgroup.category.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .padding(8)
                        .glassEffect(in: .circle)
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider().padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About the Subgroup")
                            .font(.headline)
                            .bold()
                        Text(subgroup.description ?? "No description available.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        FacultyStatBadge(icon: "person.2.fill", count: "\(appSession.subgroupStore.allUsers.filter { $0.subgroupId == subgroup.id }.count)", label: "Members", color: .green)
                        if !(appSession.organizationFeatures?.isAchievementsDisabled ?? false) {
                            FacultyStatBadge(icon: "trophy.fill", count: "\(appSession.subgroupAchievementStore.achievements.filter { $0.subgroupId == subgroup.id }.count)", label: "Achievements", color: .accentColor)
                        }
                    }
                    .padding(.horizontal)
                    
                    if let socials = subgroup.socials, !socials.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Socials")
                                .font(.headline)
                                .bold()
                            HStack(spacing: 12) {
                                ForEach(socials.sorted(by: { $0.key < $1.key }), id: \.key) { platform, urlString in
                                    if let url = URL(string: urlString) {
                                        Link(destination: url) {
                                            FacultySocialCircle(platform: platform)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(20)
    }
}

struct FacultyStatBadge: View {
    let icon: String
    let count: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(count)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct FacultySocialCircle: View {
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
                .frame(width: 36, height: 36)
            Image(systemName: iconName)
                .font(.caption)
                .foregroundColor(color)
        }
    }
}

#Preview {
    FacultyManagementView()
        .environment(MockData.session(for: .groupSubLead))
}
