import SwiftUI
import ClubItShared
import PhotosUI

struct ChatInfoView: View {
    let chat: Chat
    @Environment(AppSession.self) private var appSession
    @Environment(\.dismiss) private var dismiss
    
    @State private var participants: [ChatParticipant] = []
    @State private var showAddMembers = false
    @State private var showAllParticipants = false
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var uploadImageData: Data? = nil
    @State private var showPhotosPicker = false
    @State private var showPhotoActionSheet = false
    
    @State private var isEditingDescription = false
    @State private var editedDescription = ""
    
    private var currentChat: Chat {
        appSession.chatStore.chats.first(where: { $0.id == chat.id }) ?? chat
    }
    
    private var hasCustomPhoto: Bool {
        guard let icon = currentChat.icon else { return false }
        return icon != "calendar" && icon != "person.3.fill" && icon != "person.2.fill" && !icon.isEmpty
    }
    
    private var isOrganizer: Bool {
        currentChat.createdBy == appSession.chatStore.userId
    }
    
    private var canManageParticipants: Bool {
        if let parentId = currentChat.parentChatId {
            let parentChat = appSession.chatStore.chats.first(where: { $0.id == parentId })
            let isParentOrganizer = parentChat?.createdBy == appSession.chatStore.userId
            let isSubChatAdmin = participants.first(where: { $0.userId == appSession.chatStore.userId })?.role == .admin
            return isParentOrganizer || isSubChatAdmin
        } else {
            let isChatAdmin = participants.first(where: { $0.userId == appSession.chatStore.userId })?.role == .admin
            return isOrganizer || isChatAdmin
        }
    }
    
    private var participantUsers: [User] {
        let userIds = participants.map { $0.userId }
        var users = appSession.clubStore.allUsers.filter { userIds.contains($0.id) }
        users.sort { u1, u2 in
            let isU1Admin = participants.first(where: { $0.userId == u1.id })?.role == .admin
            let isU2Admin = participants.first(where: { $0.userId == u2.id })?.role == .admin
            
            if isU1Admin && !isU2Admin {
                return true
            } else if !isU1Admin && isU2Admin {
                return false
            } else {
                return u1.name < u2.name
            }
        }
        return users
    }
    
    var body: some View {
        ScrollView {
            ZStack {
                VStack(spacing: 24) {
                // Header Profile
                VStack(spacing: 16) {
                    if (currentChat.type == .group || currentChat.type == .event) && currentChat.createdBy == appSession.chatStore.userId {
                        Button {
                            if hasCustomPhoto {
                                showPhotoActionSheet = true
                            } else {
                                showPhotosPicker = true
                            }
                        } label: {
                            ZStack(alignment: .bottomTrailing) {
                                UserAvatarView(name: currentChat.displayName, profileImg: currentChat.icon, imageData: uploadImageData, size: 100)
                                
                                Image(systemName: "camera.circle.fill")
                                    .symbolRenderingMode(.multicolor)
                                    .font(.system(size: 28))
                                    .background(Circle().fill(.white))
                                    .offset(x: 2, y: 2)
                            }
                        }
                        .buttonStyle(.plain)
                    } else {
                        UserAvatarView(name: currentChat.displayName, profileImg: currentChat.icon, imageData: nil, size: 100)
                    }
                    
                    VStack(spacing: 4) {
                        Text(currentChat.displayName)
                            .font(.title2.bold())
                        
                        if currentChat.type == .group || currentChat.type == .event {
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
                
                // Description Section (For Groups and Events)
                if currentChat.type == .group || currentChat.type == .event {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            if isOrganizer {
                                if isEditingDescription {
                                    HStack {
                                        TextField("Add description...", text: $editedDescription, axis: .vertical)
                                            .textFieldStyle(.plain)
                                            .lineLimit(1...4)
                                        
                                        Button {
                                            Task {
                                                try? await appSession.chatStore.updateChatDescription(chatId: currentChat.id, description: editedDescription)
                                                isEditingDescription = false
                                            }
                                        } label: {
                                            Text("Save")
                                                .fontWeight(.semibold)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                } else {
                                    HStack {
                                        Text(currentChat.description?.isEmpty == false ? currentChat.description! : "Add description...")
                                            .foregroundColor(currentChat.description?.isEmpty == false ? .primary : .secondary)
                                            .font(.body)
                                        
                                        Spacer()
                                        
                                        Button {
                                            editedDescription = currentChat.description ?? ""
                                            isEditingDescription = true
                                        } label: {
                                            Image(systemName: "pencil")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            } else {
                                Text(currentChat.description?.isEmpty == false ? currentChat.description! : "No description")
                                    .foregroundColor(currentChat.description?.isEmpty == false ? .primary : .secondary)
                                    .font(.body)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
                        .padding(.horizontal)
                    }
                }
                

                
                // Profile Information (For Individuals)
                if currentChat.type == .individual, let otherUser = participantUsers.first(where: { $0.id != appSession.chatStore.userId }) {
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
                                
                                NavigationLink(destination: ClubDetailView(club: club)) {
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
                
                // Participants (if Group/Event)
                if currentChat.type == .group || currentChat.type == .event {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Participants")
                                .font(.headline)
                            
                            Spacer()
                            
                            // + button to add members (rule #2 for groups, rule #3 for events)
                            if canManageParticipants {
                                Button {
                                    showAddMembers = true
                                } label: {
                                    Text("Add Participants")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
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
                            Text(currentChat.type == .individual ? "Block User" : "Leave Chat")
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
            participants = await appSession.chatStore.fetchParticipants(for: currentChat.id)
        }
        .sheet(isPresented: $showAddMembers) {
            AddMembersView(chatId: currentChat.id, existingParticipantIds: Set(participants.map { $0.userId }))
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedItem, matching: .images)
        .confirmationDialog("Change Chat Photo", isPresented: $showPhotoActionSheet, titleVisibility: .visible) {
            Button("Choose Photo") {
                showPhotosPicker = true
            }
            Button("Remove Photo", role: .destructive) {
                Task {
                    do {
                        try await appSession.chatStore.removeChatIcon(chatId: currentChat.id)
                        uploadImageData = nil
                    } catch {
                        print("ERROR: Failed to remove chat icon: \(error.localizedDescription)")
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    uploadImageData = data
                    do {
                        try await appSession.chatStore.uploadChatIcon(chatId: currentChat.id, imageData: data)
                    } catch {
                        print("ERROR: Failed to upload chat icon: \(error.localizedDescription)")
                    }
                }
            }
        }
    } 

    private func profileRow(icon: String, title: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
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
