import SwiftUI
import ClubItShared

struct LeadProfileView: View {
    @Environment(AppSession.self) private var appSession
    @Environment(\.dismiss) private var dismiss
    
    var user: User?
    
    @State private var isLoading = false
    
    private var displayUser: User? {
        if let user {
            return appSession.clubStore.allUsers.first(where: { $0.id == user.id }) ?? user
        }
        return appSession.currentUser
    }
    
    private var isCurrentUser: Bool {
        displayUser?.id == appSession.currentUser?.id
    }
    
    var body: some View {
        if let user = displayUser {
            List {
                // MARK: - Profile Header
                Section {
                    HStack(spacing: 16) {
                        UserAvatarView(name: user.name, profileImg: user.profileImg, imageData: user.imageData, size: 70)
                        
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
                    Text((user.bio?.isEmpty ?? true) ? "No bio provided" : (user.bio ?? "No bio provided"))
                        .font(.body)
                }
                
                // MARK: - Contact
                Section("Contact") {
                    Label(user.phoneNumber ?? "N/A", systemImage: "phone")
                    Label(user.course ?? "N/A", systemImage: "building.columns")
                    Label(user.year ?? "N/A", systemImage: "graduationcap")
                }
                
                // MARK: - Club
                Section("Club") {
                    if user.role == .vicePresident {
                        let assignedClubs = appSession.clubStore.allClubs.filter { $0.vicePresidentId == user.id }
                        if !assignedClubs.isEmpty {
                            ForEach(assignedClubs) { club in
                                HStack {
                                    Text(club.name)
                                    
                                    Spacer()
                                    
                                    Text(user.role.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else {
                            Text("No clubs assigned")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        if let clubId = user.clubId,
                           let club = appSession.clubStore.allClubs.first(where: { $0.id == clubId }) {
                            
                            HStack {
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
                }
                
                // MARK: - Settings (Only for current user)
                if isCurrentUser {
                    Section("Settings") {
//                        NavigationLink {
//                            Text("Notifications Screen")
//                        } label: {
//                            Label("Notifications", systemImage: "bell")
//                        }
                        
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
            }
            .listStyle(.insetGrouped)
            .navigationTitle(isCurrentUser ? "My Profile" : user.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isCurrentUser {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            EditProfileView(user: user)
                        } label: {
                            Text("Edit")
                        }
                    }
                }
            }
            .refreshable {
                try? await appSession.clubStore.fetchAllUsers()
            }
            .task {
                isLoading = true
                try? await appSession.clubStore.fetchAllUsers()
                isLoading = false
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
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
