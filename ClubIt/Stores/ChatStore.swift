import Foundation
import Observation
import Supabase
#if canImport(UIKit)
import UIKit
#endif

@Observable
final class ChatStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    
    var chats: [Chat] = []
    var messages: [UUID: [Message]] = [:]
    var chatParticipants: [UUID: [ChatParticipant]] = [:]
    var selectedCategory: ChatCategory = .all
    var isLoading = false
    var activeChatId: UUID? = nil
    
    // Set from AppSession on sign-in
    var userId: UUID = UUID()
    
    // Realtime channels
    private var messagesChannel: RealtimeChannelV2?
    private var participantsChannel: RealtimeChannelV2?
    private var messageSubscriptionTask: Task<Void, Never>?
    private var participantSubscriptionTask: Task<Void, Never>?
    
    // MARK: - Computed Properties
    
    var totalUnreadCount: Int {
        chats.filter { !$0.isArchived && !$0.isRequest && $0.parentChatId == nil }
            .reduce(0) { total, chat in
                if chat.type == .event {
                    // Sum unread from sub-chats
                    let subUnread = chats.filter { $0.parentChatId == chat.id }.reduce(0) { $0 + $1.unreadCount }
                    return total + chat.unreadCount + subUnread
                }
                return total + chat.unreadCount
            }
    }
    
    var pinnedChats: [Chat] {
        chats.filter { $0.isPinned && !$0.isArchived && !$0.isRequest && $0.parentChatId == nil }
            .sorted { (c1, c2) -> Bool in
                let hasMsg1 = !c1.lastMessage.isEmpty
                let hasMsg2 = !c2.lastMessage.isEmpty
                if hasMsg1 != hasMsg2 {
                    return hasMsg1
                }
                let t1 = c1.lastMessageAt ?? c1.createdAt
                let t2 = c2.lastMessageAt ?? c2.createdAt
                return t1 > t2
            }
            .prefix(5).map { $0 }
    }
    
    var filteredChats: [Chat] {
        let topLevelChats = chats.filter { $0.parentChatId == nil }
        
        let filtered: [Chat]
        switch selectedCategory {
        case .all:
            filtered = topLevelChats.filter { !$0.isPinned && !$0.isArchived && !$0.isRequest }
        case .unread:
            filtered = topLevelChats.filter { chat in
                if chat.isArchived || chat.isRequest { return false }
                if chat.unreadCount > 0 { return true }
                return chats.filter { $0.parentChatId == chat.id }.contains { $0.unreadCount > 0 }
            }
        case .groups:
            filtered = topLevelChats.filter { $0.type == .group && !$0.isArchived && !$0.isRequest }
        case .event:
            filtered = topLevelChats.filter { $0.type == .event && !$0.isArchived && !$0.isRequest }
        case .archived:
            filtered = topLevelChats.filter { $0.isArchived && !$0.isRequest }
        case .requests:
            filtered = topLevelChats.filter { $0.isRequest && !$0.isArchived }
        }
        
        return filtered.sorted { (c1, c2) -> Bool in
            let hasMsg1 = !c1.lastMessage.isEmpty
            let hasMsg2 = !c2.lastMessage.isEmpty
            if hasMsg1 != hasMsg2 {
                return hasMsg1
            }
            let t1 = c1.lastMessageAt ?? c1.createdAt
            let t2 = c2.lastMessageAt ?? c2.createdAt
            return t1 > t2
        }
    }
    
    func getSubChats(for parentId: UUID) -> [Chat] {
        return chats.filter { $0.parentChatId == parentId }
    }
    
    // MARK: - Fetch Chats
    
    @MainActor
    func fetchChats() async {
        do {
            // 1. Fetch all chat_participants for current user
            let participants: [ChatParticipant] = try await client
                .from("chat_participants")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            let chatIds = participants.map { $0.chatId }
            guard !chatIds.isEmpty else {
                self.chats = []
                return
            }
            
            // 2. Fetch all chats the user participates in
            var fetchedChats: [Chat] = try await client
                .from("chats")
                .select()
                .in("id", values: chatIds)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            // 3. Also fetch sub-chats (parent_chat_id in chatIds) that the user might not directly participate in
            // but should see because they're in the parent event chat
            let eventChatIds = fetchedChats.filter { $0.type == .event }.map { $0.id }
            if !eventChatIds.isEmpty {
                let subChats: [Chat] = try await client
                    .from("chats")
                    .select()
                    .in("parent_chat_id", values: eventChatIds)
                    .execute()
                    .value
                
                // Merge sub-chats that aren't already in fetchedChats
                let existingIds = Set(fetchedChats.map { $0.id })
                for sub in subChats where !existingIds.contains(sub.id) {
                    fetchedChats.append(sub)
                }
            }
            
            // 3.5 Fetch all participant records for these chats to resolve individual chat display names and participantIds
            let allParticipants: [ChatParticipant] = try await client
                .from("chat_participants")
                .select()
                .in("chat_id", values: chatIds)
                .execute()
                .value
            
            let participantsByChat = Dictionary(grouping: allParticipants, by: { $0.chatId })
            
            // Collect other user IDs for individual chats
            var otherUserIds: [UUID] = []
            for (chatId, chatParticipants) in participantsByChat {
                if let chat = fetchedChats.first(where: { $0.id == chatId }), chat.type == .individual {
                    if let otherParticipant = chatParticipants.first(where: { $0.userId != userId }) {
                        otherUserIds.append(otherParticipant.userId)
                    }
                }
            }
            
            // Fetch user info for those other users
            var usersMap: [UUID: User] = [:]
            if !otherUserIds.isEmpty {
                do {
                    let otherUsers: [User] = try await client
                        .from("users")
                        .select()
                        .in("id", values: otherUserIds)
                        .execute()
                        .value
                    usersMap = Dictionary(uniqueKeysWithValues: otherUsers.map { ($0.id, $0) })
                } catch {
                    print("DEBUG ERROR: [ChatStore] Failed to fetch other users: \(error)")
                }
            }
            
            // 4. Apply per-user state from participants
            let participantMap = Dictionary(uniqueKeysWithValues: participants.map { ($0.chatId, $0) })
            
            // We'll prepare to fetch unread counts and last message in parallel
            await withTaskGroup(of: (UUID, String, Date?, Int).self) { group in
                for i in fetchedChats.indices {
                    let chatId = fetchedChats[i].id
                    let p = participantMap[chatId]
                    
                    group.addTask {
                        // Fetch last message for this chat
                        let lastMessages: [Message] = (try? await self.client
                            .from("messages")
                            .select()
                            .eq("chat_id", value: chatId)
                            .order("created_at", ascending: false)
                            .limit(1)
                            .execute()
                            .value) ?? []
                        
                        let lastMsgText = lastMessages.first?.content ?? ""
                        let lastMsgAt = lastMessages.first?.createdAt
                        
                        // Calculate unread count
                        var unreadCount = 0
                        if let p = p {
                            let lastRead = p.lastReadAt ?? p.joinedAt
                            let formatter = ISO8601DateFormatter()
                            formatter.timeZone = TimeZone(secondsFromGMT: 0)
                            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                            let lastReadStr = formatter.string(from: lastRead)
                            
                            do {
                                struct MessageId: Decodable { let id: UUID }
                                let unreadMessages: [MessageId] = try await self.client
                                    .from("messages")
                                    .select("id")
                                    .eq("chat_id", value: chatId)
                                    .gt("created_at", value: lastReadStr)
                                    .not("sender_id", operator: .eq, value: self.userId)
                                    .execute()
                                    .value
                                unreadCount = unreadMessages.count
                            } catch {
                                print("DEBUG ERROR: [ChatStore] Failed to fetch unread count for \(chatId): \(error)")
                            }
                        }
                        
                        return (chatId, lastMsgText, lastMsgAt, unreadCount)
                    }
                }
                
                for await (chatId, lastMsgText, lastMsgAt, unreadCount) in group {
                    if let idx = fetchedChats.firstIndex(where: { $0.id == chatId }) {
                        fetchedChats[idx].lastMessage = lastMsgText
                        fetchedChats[idx].lastMessageAt = lastMsgAt
                        fetchedChats[idx].unreadCount = unreadCount
                    }
                }
            }
            
            // Set fields from participant mapping
            for i in fetchedChats.indices {
                let chatId = fetchedChats[i].id
                if let chatParts = participantsByChat[chatId] {
                    fetchedChats[i].participantIds = chatParts.map { $0.userId }
                }
                
                if fetchedChats[i].type == .individual {
                    if let otherUserId = fetchedChats[i].participantIds.first(where: { $0 != userId }),
                       let otherUser = usersMap[otherUserId] {
                        fetchedChats[i].name = otherUser.name
                        fetchedChats[i].icon = otherUser.profileImg
                    }
                }
                
                if let p = participantMap[chatId] {
                    fetchedChats[i].isPinned = p.isPinned
                    fetchedChats[i].isArchived = p.isArchived
                    fetchedChats[i].isMuted = p.isMuted
                    fetchedChats[i].isRequest = (p.status == .pending)
                }
            }
            
            self.chats = fetchedChats
            print("DEBUG: [ChatStore] Fetched \(fetchedChats.count) chats")
        } catch {
            print("DEBUG ERROR: [ChatStore] fetchChats failed: \(error)")
        }
    }
    
    // MARK: - Fetch Messages
    
    @MainActor
    func fetchMessages(for chatId: UUID) async {
        do {
            let fetchedMessages: [Message] = try await client
                .from("messages")
                .select()
                .eq("chat_id", value: chatId)
                .order("created_at", ascending: true)
                .execute()
                .value
            
            // Merge: use fetched messages as base, then append any local-only optimistic messages
            let fetchedIds = Set(fetchedMessages.map { $0.id })
            let existingLocal = (self.messages[chatId] ?? []).filter { !fetchedIds.contains($0.id) }
            
            self.messages[chatId] = fetchedMessages + existingLocal
            print("DEBUG: [ChatStore] fetchMessages for \(chatId): \(fetchedMessages.count) from DB, \(existingLocal.count) local-only")
        } catch {
            print("DEBUG ERROR: [ChatStore] fetchMessages failed: \(error)")
            // Don't clear existing messages on fetch failure
        }
    }
    
    // MARK: - Send Message
    
    @MainActor
    func sendMessage(_ content: String, to chatId: UUID) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let newMessage = Message(
            id: UUID(),
            chatId: chatId,
            senderId: userId,
            content: trimmed,
            attachmentUrl: nil,
            createdAt: Date()
        )
        
        // Optimistic update
        if messages[chatId] != nil {
            messages[chatId]?.append(newMessage)
        } else {
            messages[chatId] = [newMessage]
        }
        
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            chats[index].lastMessage = trimmed
            chats[index].lastMessageAt = Date()
        }
        
        // Persist to Supabase
        let payload = InsertMessage(
            id: newMessage.id,
            chat_id: chatId,
            sender_id: userId,
            content: trimmed,
            attachment_url: nil
        )
        
        Task {
            do {
                let insertedMessage: Message = try await client
                    .from("messages")
                    .insert(payload)
                    .select()
                    .single()
                    .execute()
                    .value
                
                await MainActor.run {
                    if let index = self.messages[chatId]?.firstIndex(where: { $0.id == newMessage.id }) {
                        self.messages[chatId]?[index] = insertedMessage
                    }
                    if let index = self.chats.firstIndex(where: { $0.id == chatId }) {
                        self.chats[index].lastMessageAt = insertedMessage.createdAt
                    }
                }
                print("DEBUG: [ChatStore] Message sent successfully to chat \(chatId)")
            } catch {
                print("DEBUG ERROR: [ChatStore] sendMessage failed: \(error)")
                print("DEBUG ERROR: [ChatStore] payload: chat_id=\(chatId), sender_id=\(userId), content=\(trimmed)")
                // Keep the optimistic message visible — it will sync on next fetch if RLS is fixed
            }
        }
    }
    
    // MARK: - Mark As Read
    
    @MainActor
    func markAsRead(for chatId: UUID) async {
        // Optimistic local update
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            chats[index].unreadCount = 0
        }
        
        let lastMessageDate = (messages[chatId]?.last?.createdAt ?? Date()).addingTimeInterval(0.001)
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let nowStr = formatter.string(from: lastMessageDate)
        
        do {
            let payload = UpdateParticipantField(last_read_at: nowStr)
            try await client
                .from("chat_participants")
                .update(payload)
                .eq("chat_id", value: chatId)
                .eq("user_id", value: userId)
                .execute()
        } catch {
            print("DEBUG ERROR: [ChatStore] markAsRead failed: \(error)")
        }
    }
    
    // MARK: - Toggle Pin
    
    func togglePin(for chatId: UUID) {
        guard let index = chats.firstIndex(where: { $0.id == chatId }) else { return }
        
        let newPinned: Bool
        if chats[index].isPinned {
            newPinned = false
        } else {
            guard chats.filter({ $0.isPinned }).count < 5 else { return }
            newPinned = true
        }
        
        chats[index].isPinned = newPinned
        
        Task {
            do {
                let payload = UpdateParticipantField(is_pinned: newPinned)
                try await client
                    .from("chat_participants")
                    .update(payload)
                    .eq("chat_id", value: chatId)
                    .eq("user_id", value: userId)
                    .execute()
            } catch {
                print("DEBUG ERROR: [ChatStore] togglePin failed: \(error)")
            }
        }
    }
    
    // MARK: - Toggle Archive
    
    func toggleArchive(for chatId: UUID) {
        guard let index = chats.firstIndex(where: { $0.id == chatId }) else { return }
        
        chats[index].isArchived.toggle()
        if chats[index].isArchived {
            chats[index].isPinned = false
        }
        let newArchived = chats[index].isArchived
        
        Task {
            do {
                let payload = UpdateParticipantField(is_pinned: newArchived ? false : nil, is_archived: newArchived)
                try await client
                    .from("chat_participants")
                    .update(payload)
                    .eq("chat_id", value: chatId)
                    .eq("user_id", value: userId)
                    .execute()
            } catch {
                print("DEBUG ERROR: [ChatStore] toggleArchive failed: \(error)")
            }
        }
    }
    
    func toggleReadStatus(for chatId: UUID) {
        guard let index = chats.firstIndex(where: { $0.id == chatId }) else { return }
        if chats[index].unreadCount > 0 {
            chats[index].unreadCount = 0
            Task {
                await markAsRead(for: chatId)
            }
        } else {
            chats[index].unreadCount = 1
        }
    }
    
    // MARK: - Delete Chat
    
    @MainActor
    func deleteChat(for chatId: UUID) {
        chats.removeAll { $0.id == chatId }
        chats.removeAll { $0.parentChatId == chatId }
        messages.removeValue(forKey: chatId)
        
        Task {
            do {
                try await client
                    .from("chats")
                    .delete()
                    .eq("id", value: chatId)
                    .execute()
            } catch {
                print("DEBUG ERROR: [ChatStore] deleteChat failed: \(error)")
            }
        }
    }
    
    // MARK: - Toggle Expansion (UI only)
    
    func toggleExpansion(for chatId: UUID) {
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            chats[index].isExpanded.toggle()
        }
    }
    
    // MARK: - Create Individual Chat
    
    @MainActor
    func createIndividualChat(with user: User) {
        // Prevent duplicate individual chats
        if chats.contains(where: { chat in
            chat.type == .individual && chat.participantIds.contains(user.id)
        }) { return }
        
        let chatId = UUID()
        let newChat = Chat(
            id: chatId,
            type: .individual,
            name: user.name,
            icon: user.profileImg,
            createdBy: userId,
            createdAt: Date(),
            lastMessage: "Tap to start chatting",
            participantIds: [userId, user.id]
        )
        
        chats.insert(newChat, at: 0)
        
        Task {
            do {
                // Insert chat
                let chatPayload = InsertChat(
                    id: chatId,
                    type: "individual",
                    name: user.name,
                    description: nil,
                    icon: user.profileImg,
                    club_id: nil,
                    parent_chat_id: nil,
                    created_by: userId
                )
                try await client.from("chats").insert(chatPayload).execute()
                
                // Insert participants
                let participants = [
                    InsertChatParticipant(chat_id: chatId, user_id: userId, role: "admin", status: "accepted"),
                    InsertChatParticipant(chat_id: chatId, user_id: user.id, role: "member", status: "accepted")
                ]
                try await client.from("chat_participants").insert(participants).execute()
                
                print("DEBUG: [ChatStore] Created individual chat with \(user.name)")
            } catch {
                print("DEBUG ERROR: [ChatStore] createIndividualChat failed: \(error)")
                self.chats.removeAll { $0.id == chatId }
            }
        }
    }
    
    // MARK: - Create Group Chat
    
    @MainActor
    func createGroupChat(name: String, description: String, icon: String?, memberIds: [UUID]) {
        let chatId = UUID()
        let allParticipantIds = [userId] + memberIds
        
        let newChat = Chat(
            id: chatId,
            type: .group,
            name: name,
            description: description.isEmpty ? nil : description,
            icon: icon ?? "person.2.fill",
            createdBy: userId,
            createdAt: Date(),
            lastMessage: "Group created",
            participantIds: allParticipantIds
        )
        
        chats.insert(newChat, at: 0)
        
        Task {
            do {
                let chatPayload = InsertChat(
                    id: chatId,
                    type: "group",
                    name: name,
                    description: description.isEmpty ? nil : description,
                    icon: icon ?? "person.2.fill",
                    club_id: nil,
                    parent_chat_id: nil,
                    created_by: userId
                )
                try await client.from("chats").insert(chatPayload).execute()
                
                var participants = [
                    InsertChatParticipant(chat_id: chatId, user_id: userId, role: "admin", status: "accepted")
                ]
                for memberId in memberIds {
                    participants.append(
                        InsertChatParticipant(chat_id: chatId, user_id: memberId, role: "member", status: "accepted")
                    )
                }
                try await client.from("chat_participants").insert(participants).execute()
                
                print("DEBUG: [ChatStore] Created group chat '\(name)' with \(allParticipantIds.count) members")
            } catch {
                print("DEBUG ERROR: [ChatStore] createGroupChat failed: \(error)")
                self.chats.removeAll { $0.id == chatId }
            }
        }
    }
    
    // MARK: - Create Event Chat
    
    @MainActor
    func createEventChat(name: String, clubId: UUID, icon: String?, memberIds: [UUID]) {
        let chatId = UUID()
        let allParticipantIds = [userId] + memberIds
        
        let newChat = Chat(
            id: chatId,
            type: .event,
            name: name,
            icon: icon ?? "calendar",
            clubId: clubId,
            createdBy: userId,
            createdAt: Date(),
            lastMessage: "Event chat created",
            participantIds: allParticipantIds
        )
        
        chats.insert(newChat, at: 0)
        
        Task {
            do {
                let chatPayload = InsertChat(
                    id: chatId,
                    type: "event",
                    name: name,
                    description: nil,
                    icon: icon ?? "calendar",
                    club_id: clubId,
                    parent_chat_id: nil,
                    created_by: userId
                )
                try await client.from("chats").insert(chatPayload).execute()
                
                var participants = [
                    InsertChatParticipant(chat_id: chatId, user_id: userId, role: "admin", status: "accepted")
                ]
                for memberId in memberIds {
                    participants.append(
                        InsertChatParticipant(chat_id: chatId, user_id: memberId, role: "member", status: "accepted")
                    )
                }
                try await client.from("chat_participants").insert(participants).execute()
                
                print("DEBUG: [ChatStore] Created event chat '\(name)'")
            } catch {
                print("DEBUG ERROR: [ChatStore] createEventChat failed: \(error)")
                self.chats.removeAll { $0.id == chatId }
            }
        }
    }
    
    // MARK: - Add Sub-Chat (under Event)
    
    @MainActor
    func addSubChat(name: String, description: String? = nil, for parentId: UUID) {
        guard let parentIndex = chats.firstIndex(where: { $0.id == parentId }) else { return }
        let parent = chats[parentIndex]
        let subChatId = UUID()
        
        var newChat = Chat(
            id: subChatId,
            type: .event,
            name: name,
            description: description,
            clubId: parent.clubId,
            parentChatId: parentId,
            createdBy: userId,
            createdAt: Date(),
            lastMessage: "Sub-chat created"
        )
        newChat.parentChatId = parentId
        
        chats.append(newChat)
        chats[parentIndex].isExpanded = true
        
        Task {
            do {
                let chatPayload = InsertChat(
                    id: subChatId,
                    type: "event",
                    name: name,
                    description: description,
                    icon: nil,
                    club_id: parent.clubId,
                    parent_chat_id: parentId,
                    created_by: userId
                )
                try await client.from("chats").insert(chatPayload).execute()
                
                // Add creator as participant
                let participant = InsertChatParticipant(
                    chat_id: subChatId,
                    user_id: userId,
                    role: "admin",
                    status: "accepted"
                )
                try await client.from("chat_participants").insert(participant).execute()
                
                print("DEBUG: [ChatStore] Created sub-chat '\(name)' under parent \(parentId)")
            } catch {
                print("DEBUG ERROR: [ChatStore] addSubChat failed: \(error)")
                self.chats.removeAll { $0.id == subChatId }
            }
        }
    }
    
    // MARK: - Add Participant
    
    @MainActor
    func addParticipant(userId participantUserId: UUID, to chatId: UUID) async {
        do {
            let payload = InsertChatParticipant(
                chat_id: chatId,
                user_id: participantUserId,
                role: "member",
                status: "accepted"
            )
            try await client.from("chat_participants").insert(payload).execute()
            
            // Update local participants list
            if let index = chats.firstIndex(where: { $0.id == chatId }) {
                chats[index].participantIds.append(participantUserId)
            }
            
            print("DEBUG: [ChatStore] Added participant \(participantUserId) to chat \(chatId)")
        } catch {
            print("DEBUG ERROR: [ChatStore] addParticipant failed: \(error)")
        }
    }
    
    // MARK: - Remove Participant
    
    @MainActor
    func removeParticipant(userId participantUserId: UUID, from chatId: UUID) async {
        do {
            try await client
                .from("chat_participants")
                .delete()
                .eq("chat_id", value: chatId)
                .eq("user_id", value: participantUserId)
                .execute()
            
            if let index = chats.firstIndex(where: { $0.id == chatId }) {
                chats[index].participantIds.removeAll { $0 == participantUserId }
            }
            
            print("DEBUG: [ChatStore] Removed participant \(participantUserId) from chat \(chatId)")
        } catch {
            print("DEBUG ERROR: [ChatStore] removeParticipant failed: \(error)")
        }
    }
    
    // MARK: - Fetch Participants
    
    @MainActor
    func fetchParticipants(for chatId: UUID) async -> [ChatParticipant] {
        do {
            let participants: [ChatParticipant] = try await client
                .from("chat_participants")
                .select()
                .eq("chat_id", value: chatId)
                .execute()
                .value
            
            self.chatParticipants[chatId] = participants
            
            // Also update participantIds on the chat
            if let index = chats.firstIndex(where: { $0.id == chatId }) {
                chats[index].participantIds = participants.map { $0.userId }
            }
            
            return participants
        } catch {
            print("DEBUG ERROR: [ChatStore] fetchParticipants failed: \(error)")
            return []
        }
    }
    
    // MARK: - Accept Chat Request
    
    @MainActor
    func acceptRequest(for chatId: UUID) {
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            chats[index].isRequest = false
        }
        
        Task {
            do {
                struct StatusUpdate: Encodable { let status: String }
                try await client
                    .from("chat_participants")
                    .update(StatusUpdate(status: "accepted"))
                    .eq("chat_id", value: chatId)
                    .eq("user_id", value: userId)
                    .execute()
            } catch {
                print("DEBUG ERROR: [ChatStore] acceptRequest failed: \(error)")
            }
        }
    }
    
    // MARK: - Realtime Subscriptions
    
    @MainActor
    func startRealtimeSubscription() {
        guard messagesChannel == nil && participantsChannel == nil else {
            print("DEBUG: [ChatStore] Realtime subscriptions already active. Skipping setup.")
            return
        }

        // Clean up any stale subscription tasks first
        messageSubscriptionTask?.cancel()
        participantSubscriptionTask?.cancel()

        // Connect realtime socket
        Task {
            await client.realtimeV2.connect()
            print("DEBUG: [ChatStore] Realtime client connected")
        }

        // Subscribe to new messages across all user's chats
        let msgChannel = client.realtimeV2.channel("chat-messages-\(userId.uuidString)")
        
        let messageInsertions = msgChannel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages"
        )
        
        messageSubscriptionTask = Task {
            await msgChannel.subscribe()
            
            for await insertion in messageInsertions {
                if Task.isCancelled { break }
                await handleNewMessage(insertion)
            }
        }
        
        self.messagesChannel = msgChannel
        
        // Subscribe to participant changes (new chats added for this user)
        let partChannel = client.realtimeV2.channel("chat-participants-\(userId.uuidString)")
        
        let participantInsertions = partChannel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "chat_participants"
        )
        
        participantSubscriptionTask = Task {
            await partChannel.subscribe()
            
            for await _ in participantInsertions {
                if Task.isCancelled { break }
                // Refresh chat list when participant changes happen
                await fetchChats()
            }
        }
        
        self.participantsChannel = partChannel
        
        print("DEBUG: [ChatStore] Realtime subscriptions started")
    }
    
    @MainActor
    private func handleNewMessage(_ insertion: InsertAction) async {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateStr = try container.decode(String.self)
                
                // Clean up string
                let cleaned = dateStr.replacingOccurrences(of: " ", with: "T")
                
                // Try formatters
                let formats = [
                    "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ",
                    "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ",
                    "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
                    "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                    "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
                    "yyyy-MM-dd'T'HH:mm:ssZ",
                    "yyyy-MM-dd HH:mm:ss.SSSSSSZZZZZ",
                    "yyyy-MM-dd HH:mm:ss.SSSSSSZ",
                    "yyyy-MM-dd HH:mm:ss.SSSZZZZZ",
                    "yyyy-MM-dd HH:mm:ss.SSSZ",
                    "yyyy-MM-dd HH:mm:ssZZZZZ",
                    "yyyy-MM-dd HH:mm:ssZ",
                    "yyyy-MM-dd HH:mm:ss.SSSSSS",
                    "yyyy-MM-dd HH:mm:ss.SSS",
                    "yyyy-MM-dd HH:mm:ss",
                    "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
                    "yyyy-MM-dd'T'HH:mm:ss.SSS",
                    "yyyy-MM-dd'T'HH:mm:ss"
                ]
                
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                for format in formats {
                    formatter.dateFormat = format
                    if let date = formatter.date(from: dateStr) {
                        return date
                    }
                    if let date = formatter.date(from: cleaned) {
                        return date
                    }
                }
                
                // Fallback to ISO8601
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = isoFormatter.date(from: dateStr) {
                    return date
                }
                if let date = isoFormatter.date(from: cleaned) {
                    return date
                }
                
                let isoFormatterNoFrac = ISO8601DateFormatter()
                isoFormatterNoFrac.formatOptions = [.withInternetDateTime]
                if let date = isoFormatterNoFrac.date(from: dateStr) {
                    return date
                }
                if let date = isoFormatterNoFrac.date(from: cleaned) {
                    return date
                }
                
                print("WARNING: Failed to decode date string: \(dateStr). Falling back to current date.")
                return Date()
            }
            let newMessage = try insertion.decodeRecord(as: Message.self, decoder: decoder)
            
            // Skip if it's our own message (already added optimistically)
            guard newMessage.senderId != userId else { return }
            
            // Add to messages if we have them loaded
            if var chatMessages = messages[newMessage.chatId] {
                // Avoid duplicates
                if !chatMessages.contains(where: { $0.id == newMessage.id }) {
                    chatMessages.append(newMessage)
                    messages[newMessage.chatId] = chatMessages
                }
            }
            
            // Update last message and unread count on the chat
            if let index = chats.firstIndex(where: { $0.id == newMessage.chatId }) {
                chats[index].lastMessage = newMessage.content
                chats[index].lastMessageAt = newMessage.createdAt
                
                let isAppActive: Bool = {
                    #if canImport(UIKit)
                    return UIApplication.shared.applicationState == .active
                    #else
                    return true
                    #endif
                }()
                
                if newMessage.chatId == activeChatId && isAppActive {
                    await markAsRead(for: newMessage.chatId)
                } else {
                    chats[index].unreadCount += 1
                }
            }
        } catch {
            print("DEBUG ERROR: [ChatStore] handleNewMessage decode failed: \(error)")
        }
    }
    
    @MainActor
    func stopRealtimeSubscription() {
        messageSubscriptionTask?.cancel()
        messageSubscriptionTask = nil
        participantSubscriptionTask?.cancel()
        participantSubscriptionTask = nil

        Task {
            if let channel = messagesChannel {
                await client.realtimeV2.removeChannel(channel)
            }
            if let channel = participantsChannel {
                await client.realtimeV2.removeChannel(channel)
            }
        }
        messagesChannel = nil
        participantsChannel = nil
        print("DEBUG: [ChatStore] Realtime subscriptions stopped")
    }
    
    // MARK: - Cleanup
    
    func clearData() {
        chats = []
        messages = [:]
        chatParticipants = [:]
        selectedCategory = .all
    }
}
