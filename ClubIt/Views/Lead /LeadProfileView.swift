import SwiftUI

struct LeadProfileView: View {
    @Environment(AppSession.self) private var appSession
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        if let user = appSession.currentUser {
            NavigationStack {
                List {
                    // MARK: - Profile Header
                    Section {
                        HStack(spacing: 16) {
                            if !user.profileImg.isEmpty {
                                AsyncImage(url: URL(string: user.profileImg)) { image in
                                    image.resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Color.gray.opacity(0.2)
                                }
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 70, height: 70)
                                    .foregroundStyle(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.headline)
                                
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Text(user.role.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // MARK: - About
                    Section("About") {
                        Text(user.bio.isEmpty ? "No bio provided" : user.bio)
                            .font(.body)
                    }
                    
                    // MARK: - Contact
                    Section("Contact") {
                        Label(user.phoneNumber, systemImage: "phone")
                        Label(user.course, systemImage: "building.columns")
                        Label(user.year, systemImage: "graduationcap")
                    }
                    
                    // MARK: - Club
                    Section("Club") {
                        if let clubId = user.clubId,
                           let club = appSession.clubStore.allClubs.first(where: { $0.id == clubId }) {
                            
                            HStack {
//                                Image(club.logo)
//                                    .resizable()
//                                    .frame(width: 32, height: 32)
//                                    .clipShape(Circle())
                                
                                Text(club.name)
                                
                                Spacer()
                                
                                Text(user.role.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Not part of any club")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // MARK: - Settings
                    Section("Settings") {
                        
                        NavigationLink {
                            Text("Notifications Screen")
                        } label: {
                            Label("Notifications", systemImage: "bell")
                        }
                        
                        NavigationLink {
                            Text("Change Password Screen")
                        } label: {
                            Label("Change Password", systemImage: "arrow.triangle.2.circlepath")
                        }
                        
                        Button(role: .destructive) {
                            appSession.signOut()
                        } label: {
                            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                                .foregroundStyle(.red)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.inline)
//                .toolbar {
//                    ToolbarItem(placement: .topBarTrailing) {
//                        Button("Edit") {
//                            // Edit Action
//                        }
//                    }
//                }
            }
        } else {
            ContentUnavailableView(
                "Please login to view profile",
                systemImage: "person.crop.circle.badge.exclamationmark"
            )
        }
    }
}

// MARK: - Supporting Views
struct SettingsRow: View {
    let icon: String
    let title: String
    var hasChevron: Bool = false
    var color: Color = .primary
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.primary)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .foregroundStyle(color)
            
            Spacer()
            
            if hasChevron {
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        LeadProfileView()
            .environment(MockData.session(for: .clubLead))
    }
}
