import SwiftUI
import ClubItShared

struct EventManagementTeamView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    
                    // MARK: - Approval Management Quick Action
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(spacing: 0) {
                            NavigationLink(destination: EventManagementApprovalSubgroupsView()) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.accentColor.opacity(0.1))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "checkmark.shield")
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
                            
                            if appSession.currentRole == .groupSubLead {
                                Divider().padding(.leading, 56)
                                NavigationLink {
                                    FacultyVenueListView()
                                } label: {
                                    QuickActionRow(icon: "building.2", title: "View Venues", color: .blue)
                                }
                                .buttonStyle(.plain)
                            } else if appSession.currentRole == .groupLead {
                                Divider().padding(.leading, 56)
                                NavigationLink(destination: PresidentAssignSubgroupView()) {
                                    QuickActionRow(icon: "plus.rectangle.on.folder", title: "Assign Subgroup", color: .accentColor)
                                }
                                .buttonStyle(.plain)
                                
                                Divider().padding(.leading, 56)
                                NavigationLink(destination: PresidentRemoveVPView()) {
                                    QuickActionRow(icon: "person.badge.minus", title: "Remove Subgroup", color: .red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .glassEffect(in: .rect(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    
                    if let user = appSession.currentUser {
                        if appSession.currentRole == .groupSubLead || appSession.currentRole == .groupLead {
                            // Assigned subgroups
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Assigned Subgroups")
                                    .font(.title2)
                                    .bold()
                                
                                VStack(spacing: 16) {
                                    // For President, we show all subgroups since they oversee everything
                                    // For Faculty, we show subgroups filtered by their ID (which is now unified)
                                    let subgroupsToShow = appSession.currentRole == .groupLead ? appSession.subgroupStore.allSubgroups : appSession.subgroupStore.allSubgroups.filter { $0.facultyId == user.id }
                                    
                                    if subgroupsToShow.isEmpty {
                                        Text("No subgroups currently assigned")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .padding()
                                    } else {
                                        ForEach(subgroupsToShow) { subgroup in
                                            FacultyExpandableSubgroupRow(subgroup: subgroup)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        if appSession.currentRole == .groupLead {
                            // President core members
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Core Members")
                                    .font(.title2)
                                    .bold()
                                
                                VStack(spacing: 16) {
                                    let coreMembers = MockData.allMockUsers.filter { $0.role == .subGroupLead || $0.role == .groupSubLead }
                                    
                                    ForEach(coreMembers.prefix(5)) { member in
                                        NavigationLink(destination: MemberSubgroupsOverviewView(user: member)) {
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
        .environment(MockData.session(for: .groupSubLead))
}
