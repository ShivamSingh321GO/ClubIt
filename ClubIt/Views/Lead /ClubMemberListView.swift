import SwiftUI

struct ClubMemberListView: View {
    @Environment(AppSession.self) var appSession
    let club: Club
    
    // Filter members from mock data based on clubId
    var members: [User] {
        MockData.allMockUsers.filter { $0.clubId == club.id }
    }
    
    var body: some View {
        List {
            Section {
                ForEach(members) { member in
                    NavigationLink(destination: LeadProfileView(user: member)) {
                        HStack(spacing: 16) {
                            if !member.profileImg.isEmpty {
                                Image(member.profileImg)
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
