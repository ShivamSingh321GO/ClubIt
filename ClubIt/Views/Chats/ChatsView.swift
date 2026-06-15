import SwiftUI

struct ChatsView: View {
    @Environment(AppSession.self) private var appSession
    
    @State private var showCreateChat = false
    @State private var showCreateGroup = false
    @State private var showCreateEventChat = false
    
    @State private var showAddSubChat = false
    @State private var subChatName = ""
    @State private var subChatDescription = ""
    @State private var activeParentId: UUID? = nil
    @State private var searchText = ""
    @State private var navigateToChat: Chat? = nil
    
    var body: some View {
        @Bindable var chatStore = appSession.chatStore
        
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search", text: $searchText)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                        .padding(.horizontal, 16)
                        
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
                .refreshable {
                    await appSession.chatStore.fetchChats()
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
                        
                        if appSession.currentRole != .student {
                            Button(action: { showCreateGroup = true }) {
                                Label("Create a new group", systemImage: "person.3")
                            }
                        }
                        
                        if appSession.currentRole == .clubLead || appSession.currentRole == .president || appSession.currentRole == .admin {
                            Button(action: { showCreateEventChat = true }) {
                                Label("Create a new event chat", systemImage: "calendar")
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                            
                    }
                }
            }
            
            // Sheets
            .sheet(isPresented: $showCreateChat) {
                CreateChatView { newChat in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        navigateToChat = newChat
                    }
                }
            }
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupView { newChat in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        navigateToChat = newChat
                    }
                }
            }
            .sheet(isPresented: $showCreateEventChat) {
                CreateEventChatView { newChat in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        navigateToChat = newChat
                    }
                }
            }
            .navigationDestination(item: $navigateToChat) { chat in
                ChatBox(chat: chat)
            }
            .sheet(isPresented: $showAddSubChat) {
                NavigationStack {
                    Form {
                        Section {
                            TextField("Chat Name", text: $subChatName)
                            TextField("Description (Optional)", text: $subChatDescription)
                        }
                    }
                    .navigationTitle("New Chat")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                showAddSubChat = false
                                subChatName = ""
                                subChatDescription = ""
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                if let parentId = activeParentId {
                                    appSession.chatStore.addSubChat(name: subChatName, description: subChatDescription.isEmpty ? nil : subChatDescription, for: parentId)
                                }
                                showAddSubChat = false
                                subChatName = ""
                                subChatDescription = ""
                            } label: {
                                Text("Done")
                                    .fontWeight(.semibold)
                            }
                            .disabled(subChatName.isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
            }
        }
        .task {
            await appSession.chatStore.fetchChatsIfNeeded()
        }
    }
    
    private var filteredCategories: [ChatCategory] {
        if appSession.currentRole == .clubLead {
            return ChatCategory.allCases
        } else {
            return ChatCategory.allCases.filter { $0 != .requests }
        }
    }
    
    private func countForCategory(_ category: ChatCategory) -> Int {
        switch category {
        case .all:
            return 0
        case .unread:
            return appSession.chatStore.chats.filter { !$0.isRequest && !$0.isArchived && $0.unreadCount > 0 }.count
        case .groups:
            return appSession.chatStore.chats.filter { $0.type == .group && !$0.isRequest && !$0.isArchived }.count
        case .event:
            return appSession.chatStore.chats.filter { $0.type == .event && !$0.isRequest && !$0.isArchived }.count
        case .archived:
            return appSession.chatStore.chats.filter { $0.isArchived && !$0.isRequest }.count
        case .requests:
            return appSession.chatStore.chats.filter { $0.isRequest && !$0.isArchived }.count
        }
    }
    
    // MARK: - Filter Bar
    private func filterBar(selectedCategory: Binding<ChatCategory>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filteredCategories) { category in
                    let count = countForCategory(category)
                    Button {
                        selectedCategory.wrappedValue = category
                    } label: {
                        Text(count > 0 ? "\(category.rawValue) \(count)" : category.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                selectedCategory.wrappedValue == category
                                ? Color.orange
                                : Color(.tertiarySystemFill).opacity(0.5)
                            )
                            .foregroundStyle(
                                selectedCategory.wrappedValue == category
                                ? .white
                                : .primary
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
                                    name: chat.displayName,
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
        let chats = appSession.chatStore.filteredChats.filter {
            searchText.isEmpty ? true : ($0.displayName).localizedCaseInsensitiveContains(searchText)
        }
        
        return VStack(spacing: 0) {
            ForEach(chats) { chat in
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
                        .contextMenu {
                            Button {
                                appSession.chatStore.togglePin(for: chat.id)
                            } label: {
                                let isPinned = appSession.chatStore.pinnedChats.contains(where: { $0.id == chat.id })
                                Label(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.slash" : "pin")
                            }
                            
                            Button {
                                appSession.chatStore.toggleReadStatus(for: chat.id)
                            } label: {
                                Label(chat.unreadCount > 0 ? "Mark as Read" : "Mark as Unread", systemImage: chat.unreadCount > 0 ? "envelope.open" : "message.badge")
                            }
                            
                            Button {
                                appSession.chatStore.toggleArchive(for: chat.id)
                            } label: {
                                Label(chat.isArchived ? "Unarchive" : "Archive", systemImage: chat.isArchived ? "tray.and.arrow.up" : "tray.and.arrow.down")
                            }
                            
                            Button {
                                // Hide alerts
                            } label: {
                                Label("Hide Alerts", systemImage: "bell.slash")
                            }
                            
                            Button(role: .destructive) {
                                appSession.chatStore.deleteChat(for: chat.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
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
                        .contextMenu {
                            Button {
                                appSession.chatStore.togglePin(for: chat.id)
                            } label: {
                                let isPinned = appSession.chatStore.pinnedChats.contains(where: { $0.id == chat.id })
                                Label(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.slash" : "pin")
                            }
                            
                            Button {
                                appSession.chatStore.toggleReadStatus(for: chat.id)
                            } label: {
                                Label(chat.unreadCount > 0 ? "Mark as Read" : "Mark as Unread", systemImage: chat.unreadCount > 0 ? "envelope.open" : "message.badge")
                            }
                            
                            Button {
                                appSession.chatStore.toggleArchive(for: chat.id)
                            } label: {
                                Label(chat.isArchived ? "Unarchive" : "Archive", systemImage: chat.isArchived ? "tray.and.arrow.up" : "tray.and.arrow.down")
                            }
                            
                            Button {
                                // Hide alerts
                            } label: {
                                Label("Hide Alerts", systemImage: "bell.slash")
                            }
                            
                            Button(role: .destructive) {
                                appSession.chatStore.deleteChat(for: chat.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    
                    if chat.id != chats.last?.id {
                        Divider()
                            .padding(.leading, 80)
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
                                .padding(.leading, 80)
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                                .padding(.leading, 80)
                        }
                        
                        Button {
                            activeParentId = chat.id
                            showAddSubChat = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.subheadline)
                                Text("Add new chat")
                                    .font(.subheadline.bold())
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal, 16)
                            .padding(.leading, 64)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                            .padding(.leading, 80)
                    }
                }
            }
            
            if chats.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 40))
                        .foregroundStyle(.tertiary)
                    Text("No Messages")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text("Start a conversation")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            }
        }
    }
}

#Preview {
    ChatsView()
        .environment(AppSession())
}
