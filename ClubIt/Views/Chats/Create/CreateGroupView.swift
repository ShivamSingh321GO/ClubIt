import SwiftUI
import ClubItShared

struct CreateGroupView: View {
    @Environment(AppSession.self) private var appSession
    @Environment(\.dismiss) private var dismiss
    @State private var groupName = ""
    @State private var groupDescription = ""
    @State private var searchText = ""
    @State private var selectedUsers: Set<UUID> = []
    var onCreated: ((Chat) -> Void)? = nil
    
    private var suggestedUsers: [User] {
        appSession.clubStore.allUsers.filter { $0.id != appSession.chatStore.userId }
    }
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return suggestedUsers
        } else {
            return suggestedUsers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        Button(action: {}) {
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "camera.fill")
                                    .font(.title)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    
                    TextField("Name", text: $groupName)
                    TextField("Group Description (Optional)", text: $groupDescription, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search people", text: $searchText)
                    }
                    
                    if !selectedUsers.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(suggestedUsers.filter { selectedUsers.contains($0.id) }) { user in
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
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        ForEach(filteredUsers) { user in
                            UserSelectionGridItem(user: user, isSelected: selectedUsers.contains(user.id)) {
                                if selectedUsers.contains(user.id) {
                                    selectedUsers.remove(user.id)
                                } else {
                                    selectedUsers.insert(user.id)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Suggestions")
                }
            }
            .navigationTitle("Create new group")
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
                        let chat = appSession.chatStore.createGroupChat(
                            name: groupName,
                            description: groupDescription,
                            icon: nil,
                            memberIds: Array(selectedUsers)
                        )
                        onCreated?(chat)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    .disabled(groupName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    CreateGroupView()
        .environment(AppSession())
}
