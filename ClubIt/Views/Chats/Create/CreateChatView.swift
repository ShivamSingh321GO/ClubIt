import SwiftUI
import ClubItShared

struct CreateChatView: View {
    @Environment(AppSession.self) private var appSession
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedUser: User? = nil
    var onCreated: ((Chat) -> Void)? = nil
    
    private var suggestedUsers: [User] {
        appSession.subgroupStore.allUsers.filter { $0.id != appSession.chatStore.userId }
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
                    // Custom Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search people", text: $searchText)
                        Spacer()
                        Image(systemName: "mic.fill")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 24) {
                        ForEach(filteredUsers) { user in
                            UserSelectionGridItem(
                                user: user,
                                isSelected: selectedUser?.id == user.id,
                                onToggle: {
                                    withAnimation(.spring()) {
                                        selectedUser = user
                                    }
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    HStack {
                        Text(searchText.isEmpty ? "Suggestions" : "Results")
                        Image(systemName: "info.circle")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Create new chat")
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
                        if let user = selectedUser {
                            let chat = appSession.chatStore.createIndividualChat(with: user)
                            onCreated?(chat)
                        }
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            
                    }
                    .disabled(selectedUser == nil)
                }
            }

        }
    }
}

#Preview {
    CreateChatView()
        .environment(AppSession())
}
