import SwiftUI
import ClubItShared

struct AddMembersView: View {
    let chatId: UUID
    let existingParticipantIds: Set<UUID>
    
    @Environment(AppSession.self) private var appSession
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedUsers: Set<UUID> = []
    @State private var isAdding = false
    
    private var availableUsers: [User] {
        appSession.clubStore.allUsers.filter { user in
            !existingParticipantIds.contains(user.id) && user.id != appSession.chatStore.userId
        }
    }
    
    private var filteredUsers: [User] {
        if searchText.isEmpty {
            return availableUsers
        } else {
            return availableUsers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search people", text: $searchText)
                    }
                    
                    if !selectedUsers.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(availableUsers.filter { selectedUsers.contains($0.id) }) { user in
                                    SelectedUserBadge(user: user) {
                                        selectedUsers.remove(user.id)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowSeparator(.hidden)
                    }
                } header: {
                    Text("Add Members")
                }
                
                Section {
                    if filteredUsers.isEmpty {
                        Text("No users available to add")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 20) {
                            ForEach(filteredUsers) { user in
                                UserSelectionGridItem(
                                    user: user,
                                    isSelected: selectedUsers.contains(user.id),
                                    onToggle: {
                                        if selectedUsers.contains(user.id) {
                                            selectedUsers.remove(user.id)
                                        } else {
                                            selectedUsers.insert(user.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text(searchText.isEmpty ? "Suggestions" : "Results")
                }
            }
            .navigationTitle("Add Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAdding = true
                        Task {
                            for userId in selectedUsers {
                                await appSession.chatStore.addParticipant(userId: userId, to: chatId)
                            }
                            isAdding = false
                            dismiss()
                        }
                    } label: {
                        if isAdding {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(selectedUsers.isEmpty || isAdding)
                }
            }
        }
    }
}

#Preview {
    AddMembersView(chatId: UUID(), existingParticipantIds: [])
        .environment(AppSession())
}
