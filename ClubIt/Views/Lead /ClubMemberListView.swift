import SwiftUI
import ClubItShared

struct ClubMemberListView: View {
    @Environment(AppSession.self) var appSession
    let club: Club
    
    // Filter members from live store data based on clubId
    var members: [User] {
        appSession.clubStore.allUsers
            .filter { $0.clubId == club.id }
            .sorted { u1, u2 in
                let priority: (AppRole) -> Int = { role in
                    if role == .subGroupLead {
                        return 0
                    } else if role.rawValue.lowercased().contains("coordinator") {
                        return 1
                    } else if role == .subGroupMember {
                        return 2
                    } else {
                        return 3
                    }
                }
                
                let p1 = priority(u1.role)
                let p2 = priority(u2.role)
                
                if p1 != p2 {
                    return p1 < p2
                }
                
                return u1.name.localizedCaseInsensitiveCompare(u2.name) == .orderedAscending
            }
    }
    
    var body: some View {
        List {
            Section {
                ForEach(members) { member in
                    NavigationLink(destination: LeadProfileView(user: member)) {
                        HStack(spacing: 16) {
                            UserAvatarView(name: member.name, profileImg: member.profileImg, imageData: member.imageData, size: 50)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(member.name)
                                    .font(.headline)
                                Text(member.role.rawValue.capitalized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if member.role == .subGroupLead {
                                Text("Lead")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.1))
                                    .foregroundColor(.accentColor)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("\(members.count) Members")
            }
        }
        .navigationTitle("Members")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            try? await appSession.clubStore.fetchAllUsers()
        }
        .task {
            try? await appSession.clubStore.fetchAllUsers()
        }
    }
}

#Preview {
    NavigationStack {
        ClubMemberListView(club: MockData.technoJamClub)
            .environment(AppSession())
    }
}
