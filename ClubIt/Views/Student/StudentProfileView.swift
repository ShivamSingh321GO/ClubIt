import SwiftUI

struct StudentProfileView: View {
    @Environment(AppSession.self) private var appSession
    @Environment(\.dismiss) private var dismiss
    
    var user: User?
    
    @State private var isLoading = false
    
    private var displayUser: User? {
        if let user {
            return appSession.clubStore.allUsers.first(where: { $0.id == user.id }) ?? user
        }
        return appSession.currentUser ?? MockData.studentUser
    }
    
    private var isCurrentUser: Bool {
        displayUser?.id == appSession.currentUser?.id
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Profile Info Card
                profileInfoCard
                
                // Contact Section
                contactSection
                
                // Requested Clubs
                requestedClubsSection
                
                // Clubs Followed
                clubsFollowedSection
                
                // Settings Section (Only for current user)
                if isCurrentUser {
                    settingsSection
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .navigationTitle(isCurrentUser ? "Profile" : (displayUser?.name ?? "Profile"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isCurrentUser, let user = displayUser {
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
    }
    
    // MARK: - Sections
    
    private var profileInfoCard: some View {
        HStack(spacing: 20) {
            // Profile Image
            UserAvatarView(name: displayUser?.name ?? "", profileImg: displayUser?.profileImg, imageData: displayUser?.imageData, size: 80)
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(displayUser?.name ?? "Kamakshi")
                    .font(.title3)
                    .bold()
                
                Text(appSession.currentRole?.rawValue ?? "Role - Student")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("Admission no : \("23SCSE0000000")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 20))
    }
    
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact")
                .font(.headline)
                .padding(.leading, 4)
            
            VStack(spacing: 1) {
                infoRow(icon: "phone.fill", text: displayUser?.phoneNumber ?? "+91 12345 67890")
                Divider().padding(.leading, 44).opacity(0.5)
                infoRow(icon: "envelope.fill", text: displayUser?.email ?? "kamakshi@gmail.com")
                Divider().padding(.leading, 44).opacity(0.5)
                infoRow(icon: "graduationcap.fill", text: displayUser?.course ?? "B Tech CSE")
            }
            .glassEffect(in: .rect(cornerRadius: 20))
        }
    }
    
    private var requestedClubsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Requested Clubs")
                .font(.headline)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                let requested = appSession.clubStore.allClubs.filter { appSession.clubStore.requestedClubIds.contains($0.id) }
                
                if requested.isEmpty {
                    HStack {
                        Spacer()
                        Text("No requested clubs")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding()
                        Spacer()
                    }
                } else {
                    ForEach(requested) { club in
                        clubRow(club: club)
                        if club.id != requested.last?.id {
                            Divider().padding(.leading, 56).opacity(0.5)
                        }
                    }
                }
            }
            .glassEffect(in: .rect(cornerRadius: 20))
        }
    }
    

    
    private var clubsFollowedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Clubs Followed")
                .font(.headline)
                .padding(.leading, 4)
            
            let followed = appSession.clubStore.allClubs.filter { appSession.clubStore.followedClubIds.contains($0.id) }
            
            if followed.isEmpty {
                VStack {
                    HStack {
                        Spacer()
                        Text("No clubs followed")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding()
                        Spacer()
                    }
                }
                .glassEffect(in: .rect(cornerRadius: 20))
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(followed) { club in
                        NavigationLink(destination: ClubDetailView(club: club)) {
                            clubGridItem(club: club)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private func clubGridItem(club: Club) -> some View {
        HStack(spacing: 10) {
            ClubLogoView(logo: club.logo, imageData: club.imageData, size: 32, iconSize: 20)
            
            Text(club.name)
                .font(.caption.bold())
                .lineLimit(1)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassEffect(in: .rect(cornerRadius: 16))
    }

    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .padding(.leading, 4)
            
            VStack(spacing: 1) {
                settingRow(icon: "bell.badge.fill", title: "Notification", color: .goldenBrown)
                Divider().padding(.leading, 44).opacity(0.5)
                settingRow(icon: "lock.rotation", title: "Change Password", color: .goldenBrown)
                Divider().padding(.leading, 44).opacity(0.5)
                
                Button {
                    appSession.signOut()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.title3)
                            .foregroundStyle(.red)
                            .frame(width: 32)
                        
                        Text("Log Out")
                            .font(.body)
                            .foregroundStyle(.red)
                        
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                }
            }
            .glassEffect(in: .rect(cornerRadius: 20))
        }
    }
    
    // MARK: - Row Helpers
    
    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.secondary.opacity(0.1)))
            
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
    
    private func clubRow(club: Club) -> some View {
        HStack(spacing: 12) {
            ClubLogoView(logo: club.logo, imageData: club.imageData, size: 36, iconSize: 22)
            
            Text(club.name)
                .font(.body)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
    
    private func settingRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
}

#Preview {
    NavigationStack {
        StudentProfileView()
            .environment(AppSession())
    }
}
