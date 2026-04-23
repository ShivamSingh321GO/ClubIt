import SwiftUI

struct FacultyManagementView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    
                    // MARK: - Quick Actions
                    VStack(alignment: .leading, spacing: 16) {
                        
                        VStack(spacing: 0) {
                            NavigationLink(destination: FacultyResourceClubsView()) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.orange.opacity(0.1))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "archivebox")
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
                            
                            Divider().padding(.leading, 56)
                            NavigationLink {
                                FacultyVenueListView()
                            } label: {
                                QuickActionRow(icon: "building.2", title: "View Venues", color: .blue)
                            }
                            .buttonStyle(.plain)
                        }
                        .glassEffect(in: .rect(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Handled Clubs
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Assigned Clubs")
                            .font(.title2)
                            .bold()
                        
                        VStack(spacing: 16) {
                            if let user = appSession.currentUser {
                                let assignedClubs = appSession.clubStore.allClubs.filter { $0.facultyId == user.id }
                                
                                if assignedClubs.isEmpty {
                                    Text("No clubs currently assigned")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding()
                                } else {
                                    ForEach(assignedClubs) { club in
                                        HStack(spacing: 16) {
                                            Circle()
                                                .fill(Color.gray.opacity(0.1))
                                                .frame(width: 44, height: 44)
                                                .overlay(
                                                    Text(String(club.name.prefix(1)))
                                                        .font(.headline)
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(club.name)
                                                    .font(.body)
                                                    .bold()
                                                Text(club.category.rawValue)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Button(action: {}) {
                                                Image(systemName: "info.circle")
                                                    .font(.body)
                                                    .foregroundColor(.secondary)
                                                    .padding(8)
                                                    .glassEffect(in: .circle)
                                            }
                                        }
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

#Preview {
    FacultyManagementView()
        .environment(MockData.session(for: .faculty))
}
