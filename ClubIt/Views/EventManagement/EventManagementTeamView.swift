import SwiftUI

struct EventManagementTeamView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    
                    // MARK: - Approval Management Quick Action
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(spacing: 0) {
                            NavigationLink(destination: EventManagementApprovalClubsView()) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.orange.opacity(0.1))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "checkmark.shield")
                                            .font(.subheadline)
                                            .foregroundColor(.orange)
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
                            
                            if appSession.currentUser?.role == .faculty {
                                Divider().padding(.leading, 56)
                                NavigationLink {
                                    FacultyVenueListView()
                                } label: {
                                    QuickActionRow(icon: "building.2", title: "View Venues", color: .blue)
                                }
                                .buttonStyle(.plain)
                            } else if appSession.currentUser?.role == .president {
                                Divider().padding(.leading, 56)
                                NavigationLink(destination: PresidentAssignClubView()) {
                                    QuickActionRow(icon: "plus.rectangle.on.folder", title: "Assign Club", color: .orange)
                                }
                                .buttonStyle(.plain)
                                
                                Divider().padding(.leading, 56)
                                NavigationLink(destination: PresidentRemoveVPView()) {
                                    QuickActionRow(icon: "person.badge.minus", title: "Remove Club", color: .red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .glassEffect(in: .rect(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Conditional Sections
                    if let user = appSession.currentUser {
                        if user.role == .faculty || user.role == .president {
                            // Assigned clubs
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Assigned Clubs")
                                    .font(.title2)
                                    .bold()
                                
                                VStack(spacing: 16) {
                                    // For President, we show all clubs since they oversee everything
                                    // For Faculty, we show clubs filtered by their ID (which is now unified)
                                    let clubsToShow = user.role == .president ? appSession.clubStore.allClubs : appSession.clubStore.allClubs.filter { $0.facultyId == user.id }
                                    
                                    if clubsToShow.isEmpty {
                                        Text("No clubs currently assigned")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .padding()
                                    } else {
                                        ForEach(clubsToShow) { club in
                                            FacultyExpandableClubRow(club: club)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        if user.role == .president {
                            // President core members
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Core Members")
                                    .font(.title2)
                                    .bold()
                                
                                VStack(spacing: 16) {
                                    let coreMembers = MockData.allMockUsers.filter { $0.role == .clubLead || $0.role == .vicePresident }
                                    
                                    ForEach(coreMembers.prefix(5)) { member in
                                        NavigationLink(destination: MemberClubsOverviewView(user: member)) {
                                            CoreMemberRow(user: member)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Manage")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }
}

#Preview {
    EventManagementTeamView()
        .environment(MockData.session(for: .faculty))
}
