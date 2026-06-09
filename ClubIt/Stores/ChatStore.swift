import Foundation
import Observation

@Observable
final class ChatStore {
    var chats: [Chat] = []
    var selectedCategory: ChatCategory = .all
    let userId = UUID()
    
    init() {
        setupMockData()
    }
    
    private func setupMockData() {
        let clubId = UUID()
        
        // Annual Tech Summit (Parent Event Chat)
        let techSummitId = UUID()
        let techSummit = Chat(
            id: techSummitId,
            type: .event,
            createdBy: userId,
            clubId: clubId,
            createdAt: Date(),
            name: "Annual Tech Summit",
            lastMessage: "",
            unreadCount: 0,
            icon: "person.3.fill",
            parentChatId: nil,
            isExpanded: false
        )
        
        let generalChat = Chat(id: UUID(), type: .event,
            createdBy: userId,
            clubId: clubId,
            createdAt: Date(),
            name: "General",
            lastMessage: "You: Everyone answer the poll for the budget",
            unreadCount: 0,
            icon: nil,
            parentChatId: techSummitId
        )
        
        let venueChat = Chat(id: UUID(), type: .event,
            createdBy: userId,
            clubId: clubId,
            createdAt: Date(),
            name: "Venue chat",
            lastMessage: "You: Everyone answer the poll for the budget",
            unreadCount: 2,
            icon: nil,
            parentChatId: techSummitId
        )
        
        let budgetChat = Chat(id: UUID(), type: .event,
            createdBy: userId,
            clubId: clubId,
            createdAt: Date(),
            name: "Budget chat",
            lastMessage: "You: Everyone answer the poll for the budget",
            unreadCount: 0,
            icon: nil,
            parentChatId: techSummitId
        )
        
        // Club Leads (Group Chat)
        let clubLeads = Chat(id: UUID(), type: .group,
            createdBy: userId,
            clubId: clubId,
            createdAt: Date(),
            name: "Club Leads (2025-26)",
            lastMessage: "i was going to do it, no need to  worry about...",
            unreadCount: 2,
            icon: "person.2.fill",   // Use system image
            isPinned: true
        )
        
        chats = [techSummit, generalChat, venueChat, budgetChat, clubLeads]
        
        // Dynamically add individual chats from MockData.allMockUsers
        for user in MockData.allMockUsers.prefix(4) {
            // Avoid creating a chat with ourselves (assuming we don't have the current user ID, we just add all for demo, or exclude placeholders)
            if user.email == "placeholder" { continue }
            
            let userChat = Chat(id: UUID(), type: .individual,
                createdBy: userId,
                clubId: nil,
                createdAt: user.createdAt,
                name: user.name,
                lastMessage: "Hey! How are you?",
                unreadCount: Int.random(in: 0...1),
                icon: user.profileImg,
                isPinned: false
            )
            chats.append(userChat)
            
            // Mock some messages
            messages[userChat.id] = [
                Message(id: UUID(), chatId: userChat.id, senderId: UUID(), content: "Hey! How are you?", createdAt: Date().addingTimeInterval(-Double.random(in: 1000...36000)))
            ]
        }
        
        messages[clubLeads.id] = [
            Message(id: UUID(), chatId: clubLeads.id, senderId: UUID(), content: "i was going to do it, no need to worry about...", createdAt: Date().addingTimeInterval(-7200)),
            Message(id: UUID(), chatId: clubLeads.id, senderId: userId, content: "Sure, let me know if you need help.", createdAt: Date().addingTimeInterval(-3600))
        ]
    }
    
    var messages: [UUID: [Message]] = [:]
    
    var pinnedChats: [Chat] {
        chats.filter { $0.isPinned }.prefix(5).map { $0 }
    }
    
    var filteredChats: [Chat] {
        let topLevelChats = chats.filter { $0.parentChatId == nil }
        
        switch selectedCategory {
        case .all:
            return topLevelChats.filter { !$0.isPinned }
        case .unread:
            return topLevelChats.filter { chat in
                if chat.unreadCount > 0 { return true }
                return chats.filter { $0.parentChatId == chat.id }.contains { $0.unreadCount > 0 }
            }
        case .groups:
            return topLevelChats.filter { $0.type == .group }
        case .event:
            return topLevelChats.filter { $0.type == .event }
        }
    }
    
    func togglePin(for chatId: UUID) {
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            var updatedChat = chats[index]
            if updatedChat.isPinned {
                updatedChat.isPinned = false
            } else {
                if chats.filter({ $0.isPinned }).count < 5 {
                    updatedChat.isPinned = true
                }
            }
            chats[index] = updatedChat
        }
    }
    
    func deleteChat(for chatId: UUID) {
        chats.removeAll { $0.id == chatId }
        chats.removeAll { $0.parentChatId == chatId }
    }
    
    func getSubChats(for parentId: UUID) -> [Chat] {
        return chats.filter { $0.parentChatId == parentId }
    }
    
    func toggleExpansion(for chatId: UUID) {
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            var updatedChat = chats[index]
            updatedChat.isExpanded.toggle()
            chats[index] = updatedChat
        }
    }
    
    func sendMessage(_ content: String, to chatId: UUID) {
        let newMessage = Message(id: UUID(), chatId: chatId,
            senderId: userId,
            content: content,
            createdAt: Date()
        )
        
        if messages[chatId] != nil {
            messages[chatId]?.append(newMessage)
        } else {
            messages[chatId] = [newMessage]
        }
        
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            chats[index].lastMessage = content
        }
    }
    
    func markAsRead(for chatId: UUID) {
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            chats[index].unreadCount = 0
        }
    }
    
    func addSubChat(name: String, for parentId: UUID) {
        guard let parentIndex = chats.firstIndex(where: { $0.id == parentId }) else { return }
        let parent = chats[parentIndex]
        
        let newChat = Chat(id: UUID(), type: .event,
            createdBy: userId,
            clubId: parent.clubId,
            createdAt: Date(),
            name: name,
            lastMessage: "New chat created",
            unreadCount: 0,
            icon: nil,
            parentChatId: parentId
        )
        
        chats.append(newChat)
        
        chats[parentIndex].isExpanded = true
    }
    
    func createIndividualChat(with user: User) {
        if chats.contains(where: { $0.type == .individual && $0.name == user.name }) { return }
        
        let newChat = Chat(id: UUID(), type: .individual,
            createdBy: userId,
            clubId: nil,
            createdAt: Date(),
            name: user.name,
            lastMessage: "Tap to start chatting",
            unreadCount: 0,
            icon: user.profileImg,
            isPinned: false
        )
        chats.insert(newChat, at: 0)
    }
    
    func createGroupChat(name: String, description: String, icon: String?, memberIds: [UUID]) {
        let newChat = Chat(id: UUID(), type: .group,
            createdBy: userId,
            clubId: nil,
            createdAt: Date(),
            name: name,
            lastMessage: "Group created",
            unreadCount: 0,
            icon: icon ?? "person.2.fill",
            isPinned: false,
            participants: memberIds
        )
        chats.insert(newChat, at: 0)
    }
    
    func createEventChat(name: String, clubId: UUID, icon: String?, memberIds: [UUID]) {
        let newChat = Chat(id: UUID(), type: .event,
            createdBy: userId,
            clubId: clubId,
            createdAt: Date(),
            name: name,
            lastMessage: "Event chat created",
            unreadCount: 0,
            icon: icon ?? "calendar",
            isPinned: false,
            participants: memberIds
        )
        chats.insert(newChat, at: 0)
    }
}
