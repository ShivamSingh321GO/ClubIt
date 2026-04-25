import SwiftUI

struct StudentProfileView: View {
    @Environment(AppSession.self) private var appSession
    @Environment(\.dismiss) private var dismiss
    
    var user: User?
    
    private var displayUser: User? {
        user ?? appSession.currentUser ?? MockData.studentUser
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
                
                // Saved Events
                savedEventsSection
                
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
    }
    
    // MARK: - Sections
    
    private var profileInfoCard: some View {
        HStack(spacing: 20) {
            // Profile Image
            AsyncImage(url: URL(string: displayUser?.profileImg ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
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
    
    private var savedEventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Saved Events")
                    .font(.headline)
                Spacer()
                if !appSession.favouritedEventIds.isEmpty {
                    Text("\(appSession.favouritedEventIds.count)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.gradient)
                        .clipShape(Capsule())
                }
            }
            .padding(.leading, 4)
            
            let savedEvents = MockData.sampleEvents.filter { appSession.favouritedEventIds.contains($0.id) }
            
            if savedEvents.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary.opacity(0.3))
                        Text("No saved events yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 32)
                    Spacer()
                }
                .glassEffect(in: .rect(cornerRadius: 20))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(savedEvents) { event in
                            NavigationLink(destination: EventDetailView(event: event, isMyEvent: false)) {
                                ExploreEventCard(event: event, isMyEvent: false)
                                    .frame(width: 300) // Slightly smaller for profile
                                    .scaleEffect(0.9)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
    
    private var clubsFollowedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Clubs Followed")
                .font(.headline)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                let followed = appSession.clubStore.allClubs.filter { appSession.clubStore.followedClubIds.contains($0.id) }
                
                if followed.isEmpty {
                    HStack {
                        Spacer()
                        Text("No clubs followed")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding()
                        Spacer()
                    }
                } else {
                    ForEach(followed) { club in
                        clubRow(club: club)
                        if club.id != followed.last?.id {
                            Divider().padding(.leading, 56).opacity(0.5)
                        }
                    }
                }
            }
            .glassEffect(in: .rect(cornerRadius: 20))
        }
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
            // Club Logo
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                
                Image(club.logo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())
            }
            .frame(width: 36, height: 36)
            
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
