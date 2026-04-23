import SwiftUI

struct ChatsView: View {
    @Environment(AppSession.self) private var appSession
    
    @State private var showCreateChat = false
    @State private var showCreateGroup = false
    @State private var showCreateEventChat = false
    
    @State private var showAddSubChat = false
    @State private var subChatName = ""
    @State private var activeParentId: UUID? = nil
    
    var body: some View {
        @Bindable var chatStore = appSession.chatStore
        
        NavigationStack {
            VStack(spacing: 0) {
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // Filter Categories
                        filterBar(selectedCategory: $chatStore.selectedCategory)
                            .padding(.horizontal, 16)
                        
                        // Pinned Chats
                        pinnedChatsSection
                        
                        // Chat List
                        chatListSection
                    }
                    .padding(.top, 8)
                }
            }
            .background(Color(.systemBackground))
            
 
            .navigationTitle("Chats")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { showCreateChat = true }) {
                            Label("Create a new chat", systemImage: "message")
                        }
                        
                        Button(action: { showCreateGroup = true }) {
                            Label("Create a new group", systemImage: "person.3")
                        }
                        
                        Button(action: { showCreateEventChat = true }) {
                            Label("Create a new event chat", systemImage: "calendar")
                        }
                    } label: {
                        Image(systemName: "plus")
                            
                    }
                }
            }
            
            // Sheets
            .sheet(isPresented: $showCreateChat) {
                CreateChatView()
            }
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupView()
            }
            .sheet(isPresented: $showCreateEventChat) {
                CreateEventChatView()
            }
            .sheet(isPresented: $showAddSubChat) {
                NavigationStack {
                    Form {
                        Section {
                            TextField("Chat Name", text: $subChatName)
                        }
                    }
                    .navigationTitle("New Chat")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                showAddSubChat = false
                                subChatName = ""
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                if let parentId = activeParentId {
                                    appSession.chatStore.addSubChat(name: subChatName, for: parentId)
                                }
                                showAddSubChat = false
                                subChatName = ""
                            } label: {
                                Image(systemName: "checkmark")
                            }
                            .disabled(subChatName.isEmpty)
                        }
                    }
                }
                .presentationDetents([.height(200)])
            }
        }
    }
    
    // MARK: - Filter Bar
    private func filterBar(selectedCategory: Binding<ChatCategory>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ChatCategory.allCases) { category in
                    Button {
                        selectedCategory.wrappedValue = category
                    } label: {
                        Text(category.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedCategory.wrappedValue == category
                                ? Color.goldenBrown.opacity(0.1)
                                : Color(.secondarySystemBackground)
                            )
                            .foregroundStyle(
                                selectedCategory.wrappedValue == category
                                ? .goldenBrown
                                : .secondary
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Pinned Chats
    private var pinnedChatsSection: some View {
        let pinnedChats = appSession.chatStore.pinnedChats
        
        return Group {
            if !pinnedChats.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(pinnedChats) { chat in
                            NavigationLink(destination: ChatBox(chat: chat)) {
                                PinnedChatItem(
                                    name: chat.name,
                                    icon: chat.icon ?? "person.circle.fill",
                                    unreadCount: chat.unreadCount,
                                    onTogglePin: {
                                        appSession.chatStore.togglePin(for: chat.id)
                                    },
                                    onDelete: {
                                        appSession.chatStore.deleteChat(for: chat.id)
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
    
    // MARK: - Chat List
    private var chatListSection: some View {
        VStack(spacing: 0) {
            ForEach(appSession.chatStore.filteredChats) { chat in
                VStack(spacing: 0) {
                    
                    if chat.type == .event {
                        ChatRow(
                            chat: chat,
                            onToggleExpansion: {
                                appSession.chatStore.toggleExpansion(for: chat.id)
                            },
                            onTogglePin: {
                                appSession.chatStore.togglePin(for: chat.id)
                            },
                            onDelete: {
                                appSession.chatStore.deleteChat(for: chat.id)
                            },
                            onAddChat: {
                                activeParentId = chat.id
                                showAddSubChat = true
                            }
                        )
                        .onTapGesture {
                            appSession.chatStore.toggleExpansion(for: chat.id)
                        }
                    } else {
                        NavigationLink(destination: ChatBox(chat: chat)) {
                            ChatRow(
                                chat: chat,
                                onToggleExpansion: {},
                                onTogglePin: {
                                    appSession.chatStore.togglePin(for: chat.id)
                                },
                                onDelete: {
                                    appSession.chatStore.deleteChat(for: chat.id)
                                }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if chat.id != appSession.chatStore.filteredChats.last?.id {
                        Divider()
                            .padding(.leading, 82)
                    }
                    
                    if chat.isExpanded {
                        let subChats = appSession.chatStore.getSubChats(for: chat.id)
                        
                        ForEach(subChats) { subChat in
                            NavigationLink(destination: ChatBox(chat: subChat)) {
                                SubChatRow(
                                    chat: subChat,
                                    onDelete: {
                                        appSession.chatStore.deleteChat(for: subChat.id)
                                    }
                                )
                                .padding(.leading, 82)
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                                .padding(.leading, 82)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ChatsView()
        .environment(AppSession())
}
