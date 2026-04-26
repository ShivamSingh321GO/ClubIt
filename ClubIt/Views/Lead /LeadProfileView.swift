import SwiftUI

struct LeadProfileView: View {
    @Environment(AppSession.self) private var appSession
    @Environment(\.dismiss) private var dismiss
    
    var user: User?
    
    private var displayUser: User? {
        user ?? appSession.currentUser
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
                        if let imageData = user.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                        } else if !(user.profileImg?.isEmpty ?? true) {
                            Image(user.profileImg ?? "")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.secondary.opacity(0.1))
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Text(String(user.name.prefix(1)))
                                        .font(.title)
                                        .foregroundColor(.primary)
                                )
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
