import SwiftUI

struct ClubMemberListView: View {
    @Environment(AppSession.self) var appSession
    let club: Club
    
    // Filter members from live store data based on clubId
    var members: [User] {
        appSession.clubStore.allUsers
            .filter { $0.clubId == club.id }
            .sorted { u1, u2 in
                let priority: (AppRole) -> Int = { role in
                    if role == .clubLead {
                        return 0
                    } else if role.rawValue.lowercased().contains("coordinator") {
                        return 1
                    } else if role == .clubMember {
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
                            if let imageData = member.imageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            } else if !(member.profileImg?.isEmpty ?? true) {
                                Image(member.profileImg ?? "")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.secondary.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(String(member.name.prefix(1)))
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(member.name)
                                    .font(.headline)
                                Text(member.role.rawValue.capitalized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if member.role == .clubLead {
                                Text("Lead")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.goldenBrown.opacity(0.1))
                                    .foregroundColor(.goldenBrown)
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
    }
}

#Preview {
    NavigationStack {
        ClubMemberListView(club: MockData.technoJamClub)
            .environment(AppSession())
    }
}
