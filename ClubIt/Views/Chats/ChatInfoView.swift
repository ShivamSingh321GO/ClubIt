import SwiftUI

struct ChatInfoView: View {
    let chat: Chat
    @Environment(AppSession.self) private var appSession
    @Environment(\.dismiss) private var dismiss
    
    @State private var participants: [ChatParticipant] = []
    @State private var showAddMembers = false
    @State private var showAllParticipants = false
    
    private var participantUsers: [User] {
        let userIds = participants.map { $0.userId }
        return appSession.clubStore.allUsers.filter { userIds.contains($0.id) }
    }
    
    var body: some View {
        ScrollView {
            ZStack {
                VStack(spacing: 24) {
                // Header Profile
                VStack(spacing: 16) {
                    if let icon = chat.icon, icon.contains("https") {
                        AsyncImage(url: URL(string: icon)) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color(white: 0.15))
                                .frame(width: 100, height: 100)
                            
                            if let icon = chat.icon, !icon.isEmpty, icon.count > 3 {
                                Image(systemName: icon)
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: chat.icon ?? "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    VStack(spacing: 4) {
                        Text(chat.displayName)
                            .font(.title2.bold())
                        
                        if chat.type == .group || chat.type == .event {
                            Text("\(participantUsers.count) Participants")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else if let otherUser = participantUsers.first(where: { $0.id != appSession.chatStore.userId }) {
                            Text(roleName(for: otherUser))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 24)
                

                
                // Profile Information (For Individuals)
                if chat.type == .individual, let otherUser = participantUsers.first(where: { $0.id != appSession.chatStore.userId }) {
                    VStack(alignment: .leading, spacing: 20) {

                        // Contact
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Contact")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                profileRow(icon: "phone", title: otherUser.phoneNumber ?? "N/A")
                                Divider().padding(.leading, 50)
                                profileRow(icon: "building.columns", title: otherUser.course ?? "N/A")
                                Divider().padding(.leading, 50)
                                profileRow(icon: "graduationcap", title: otherUser.year ?? "N/A")
                            }
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
                            .padding(.horizontal)
                        }
                        
                        // Club
                        if let clubId = otherUser.clubId,
                           let club = appSession.clubStore.allClubs.first(where: { $0.id == clubId }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Club")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                Button(action: {}) {
                                    HStack {
                                        Text(club.name)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text(roleName(for: otherUser))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                
                // Shared Media
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Shared Media")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<4) { index in
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
                                    )
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
                
                // Participants (if Group/Event)
                if chat.type == .group || chat.type == .event {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Participants")
                                .font(.headline)
                            
                            Spacer()
                            
                            // + button to add members (rule #2 for groups, rule #3 for events)
                            Button {
                                showAddMembers = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            let displayUsers = showAllParticipants ? participantUsers : Array(participantUsers.prefix(3))
                            
                            ForEach(displayUsers) { user in
                                HStack(spacing: 16) {
                                    UserAvatarView(
                                        name: user.name,
                                        profileImg: user.profileImg,
                                        imageData: user.imageData,
                                        size: 40
                                    )
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(user.name)
                                            .font(.body)
                                        if let clubId = user.clubId,
                                           let club = appSession.clubStore.allClubs.first(where: { $0.id == clubId }) {
                                            Text(club.name)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // Show role badge
                                    if let participant = participants.first(where: { $0.userId == user.id }),
                                       participant.role == .admin {
                                        Text("Admin")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.secondary.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                            
                            if participantUsers.count > 3 {
                                Divider().padding(.leading, 56)
                                
                                Button {
                                    withAnimation {
                                        showAllParticipants.toggle()
                                    }
                                } label: {
                                    Text(showAllParticipants ? "Show Less" : "See All (\(participantUsers.count))")
                                        .font(.body.bold())
                                        .foregroundColor(.blue)
                                }
                                .padding()
                            }
                        }
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
                        .padding(.horizontal)
                    }
                }
                
                // Destructive Actions
                VStack(spacing: 0) {
                    Button(action: {}) {
                        HStack {
                            Text(chat.type == .individual ? "Block User" : "Leave Chat")
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding()
                    }
                    
                    Divider().padding(.leading)
                    
                    Button(action: {}) {
                        HStack {
                            Text("Report")
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding()
                    }
                }
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            }
        }
        .background(Color.clear)
        .task {
            participants = await appSession.chatStore.fetchParticipants(for: chat.id)
        }
        .sheet(isPresented: $showAddMembers) {
            AddMembersView(chatId: chat.id, existingParticipantIds: Set(participants.map { $0.userId }))
        }
    } 

    private func profileRow(icon: String, title: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 24)
            Text(title)
            Spacer()
        }
        .padding()
    }
    
    private func roleName(for user: User) -> String {
        switch user.role {
        case .clubLead: return "Club Lead"
        case .clubMember: return "Club Member"
        case .president: return "President"
        case .vicePresident: return "Vice President"
        case .faculty: return "Faculty"
        case .admin: return "Admin"
        case .student: return "Student"
        }
    }
}

#Preview {
    let session = AppSession()
    NavigationStack {
        ChatInfoView(chat: Chat(
            id: UUID(),
            type: .group,
            name: "Preview Group",
            createdBy: UUID(),
            createdAt: Date()
        ))
        .environment(session)
    }
}
