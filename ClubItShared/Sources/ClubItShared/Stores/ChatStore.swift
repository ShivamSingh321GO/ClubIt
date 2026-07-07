import Foundation
import Observation
import Supabase
#if canImport(UIKit)
import UIKit
#endif

@Observable
public final class ChatStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    
    public var chats: [Chat] = []
    public var messages: [UUID: [Message]] = [:]
    public var chatParticipants: [UUID: [ChatParticipant]] = [:]
    public var selectedCategory: ChatCategory = .all
    public var isLoading = false
    public var activeChatId: UUID? = nil
    
    // Online Status and Typing Indicators
    public var onlineUserIds: Set<UUID> = []
    public var typingUsers: [UUID: Set<UUID>] = [:]
    private var onlinePresences: [UUID: Set<String>] = [:]
    private var typingClearTasks: [UUID: Task<Void, Never>] = [:]
    
    // Set from AppSession on sign-in
    public var userId: UUID = UUID()
    
    weak var eventStore: EventStore?
    
    // ── Fetch lifecycle guards ──
    // Tracks whether the very first fetch has completed, so views
    // know whether the empty state is "loading" vs "truly empty".
    private(set) var hasFetchedInitialData = false
    // Serialises network fetches so only one can be in-flight at a time.
    private var isFetching = false
    // Timestamp of the last completed fetch, used for debouncing.
    private var lastFetchDate: Date = .distantPast
    // Debounce timer for realtime participant-change events.
    private var participantDebounceTask: Task<Void, Never>?
    
    // Realtime channels
    private var messagesChannel: RealtimeChannelV2?
    private var participantsChannel: RealtimeChannelV2?
    private var presenceChannel: RealtimeChannelV2?
    private var messageSubscriptionTask: Task<Void, Never>?
    private var participantSubscriptionTask: Task<Void, Never>?
    private var presenceSubscriptionTask: Task<Void, Never>?
    
    // MARK: - Computed Properties
    
    public var totalUnreadCount: Int {
        chats.filter { !$0.isArchived && !$0.isRequest && $0.parentChatId == nil }
            .reduce(0) { total, chat in
                if chat.type == .event {
                    // Sum unread from sub-chats
                    let subUnread = getSubChats(for: chat.id).reduce(0) { $0 + $1.unreadCount }
                    return total + chat.unreadCount + subUnread
                }
                return total + chat.unreadCount
            }
    }
    
    public var pinnedChats: [Chat] {
        let sorted = sortedChats(chats.filter { $0.isPinned && !$0.isArchived && !$0.isRequest && $0.parentChatId == nil })
        return Array(sorted.prefix(5))
    }
    
    public var filteredChats: [Chat] {
        let topLevelChats = chats.filter { $0.parentChatId == nil }
        
        let filtered: [Chat]
        switch selectedCategory {
        case .all:
            filtered = topLevelChats.filter { !$0.isPinned && !$0.isArchived && !$0.isRequest }
        case .unread:
            filtered = topLevelChats.filter { chat in
                if chat.isArchived || chat.isRequest { return false }
                if chat.unreadCount > 0 { return true }
                return getSubChats(for: chat.id).contains { $0.unreadCount > 0 }
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
        
        return sortedChats(filtered)
    }
    
    /// Sorts chats by most-recent-activity first. Captures `Date()` once
    /// so every pairwise comparison within a single sort uses the same
    /// reference point — prevents mid-sort drift that caused list shuffling.
    private func sortedChats(_ input: [Chat]) -> [Chat] {
        var processed = input
        for idx in processed.indices {
            let chat = processed[idx]
            if chat.type == .event && chat.parentChatId == nil {
                // Find all visible sub-chats for this parent
                let subChats = chats.filter { sub in
                    sub.parentChatId == chat.id &&
                    (sub.name?.lowercased() == "general" || sub.participantIds.contains(userId))
                }
                
                // Find the latest message among the parent and its sub-chats
                let allChats = [chat] + subChats
                let latestChatWithMsg = allChats
                    .filter { !$0.lastMessage.isEmpty }
                    .max(by: { ($0.lastMessageAt ?? .distantPast) < ($1.lastMessageAt ?? .distantPast) })
                
                if let latest = latestChatWithMsg {
                    processed[idx].lastMessageAt = latest.lastMessageAt
                    if latest.id == chat.id {
                        processed[idx].lastMessage = latest.lastMessage
                    } else {
                        // Display: [Sub-chat Name] ▸ [Message]
                        processed[idx].lastMessage = "\(latest.displayName) ▸ \(latest.lastMessage)"
                    }
                }
            }
        }
        
        let now = Date()
        return processed.sorted { c1, c2 in
            var t1 = c1.lastMessageAt ?? c1.createdAt
            var t2 = c2.lastMessageAt ?? c2.createdAt
            
            // Cap future timestamps so they don't get stuck at the top
            if t1 > now { t1 = now }
            if t2 > now { t2 = now }
            
            if t1 != t2 {
                return t1 > t2
            }
            // Stable tiebreaker — prevents order flickering between fetches
            return c1.id.uuidString < c2.id.uuidString
        }
    }
    
    public func getSubChats(for parentId: UUID) -> [Chat] {
        return chats.filter { subChat in
            subChat.parentChatId == parentId &&
            (subChat.name?.lowercased() == "general" || subChat.participantIds.contains(userId))
        }
    }
    
    // MARK: - Fetch Chats
    
    /// Called by views on appear — skips the network call entirely if data
    /// was fetched recently (within 30s) and the initial load already completed.
    @MainActor
    public func fetchChatsIfNeeded() async {
        if hasFetchedInitialData && Date().timeIntervalSince(lastFetchDate) < 30 {
            return
        }
        await fetchChats()
    }
    
    /// Full fetch from Supabase.  Uses in-place merging so the SwiftUI list
    /// never sees an empty intermediate state.
    @MainActor
    public func fetchChats() async {
        // ── Serialisation: only one fetch can run at a time ──
        guard !isFetching else {
            print("DEBUG: [ChatStore] Skipping fetchChats — already in progress")
            return
        }
        isFetching = true
        defer {
            isFetching = false
            lastFetchDate = Date()
            hasFetchedInitialData = true
        }
        
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
                // User genuinely has no chats — clear the list.
                if !self.chats.isEmpty { self.chats = [] }
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
            
            // 3. Also fetch sub-chats for event chats
            let eventChatIds = fetchedChats.filter { $0.type == .event }.map { $0.id }
            if !eventChatIds.isEmpty {
                let subChats: [Chat] = try await client
                    .from("chats")
                    .select()
                    .in("parent_chat_id", values: eventChatIds)
                    .execute()
                    .value
                
                let existingIds = Set(fetchedChats.map { $0.id })
                for sub in subChats where !existingIds.contains(sub.id) {
                    fetchedChats.append(sub)
                }
            }
            
            // 3.5 Fetch all participant records for resolving display names
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
            
            // Fetch user info for individual chat partners
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
            
            // Snapshot of current transient UI state to preserve across merge
            let existingChatState: [UUID: Chat] = Dictionary(
                uniqueKeysWithValues: self.chats.map { ($0.id, $0) }
            )
            
            // Fetch unread counts and last message in parallel
            await withTaskGroup(of: (UUID, String, Date?, Int).self) { group in
                for i in fetchedChats.indices {
                    let chatId = fetchedChats[i].id
                    let p = participantMap[chatId]
                    
                    group.addTask {
                        // Fetch last message for this chat (ignoring system messages for preview)
                        let lastMessages: [Message] = (try? await self.client
                            .from("messages")
                            .select()
                            .eq("chat_id", value: chatId)
                            .order("created_at", ascending: false)
                            .limit(10)
                            .execute()
                            .value) ?? []
                        
                        let firstNonSystem = lastMessages.first(where: { !$0.content.hasPrefix("[System]: ") })
                        let lastMsgText = firstNonSystem?.content ?? ""
                        let lastMsgAt = firstNonSystem?.createdAt
                        
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
            
            // Enrich fetched chats with participant & transient UI state
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
                
                // Preserve transient UI-only state from the previous array
                if let existing = existingChatState[chatId] {
                    fetchedChats[i].isExpanded = existing.isExpanded
                }
            }
            
            // ── In-place merge ──
            // Instead of `self.chats = fetchedChats` (which swaps the entire
            // array and causes SwiftUI to flash), we merge surgically:
            //   • Update existing chats in-place
            //   • Append genuinely new chats
            //   • Remove chats that no longer exist on the server
            let newChatMap = Dictionary(uniqueKeysWithValues: fetchedChats.map { ($0.id, $0) })
            let newIds = Set(newChatMap.keys)
            let oldIds = Set(self.chats.map { $0.id })
            
            // Update existing chats in-place (preserves array identity for SwiftUI)
            for i in self.chats.indices {
                if let updated = newChatMap[self.chats[i].id] {
                    self.chats[i] = updated
                }
            }
            
            // Remove chats that were deleted server-side
            let removedIds = oldIds.subtracting(newIds)
            if !removedIds.isEmpty {
                self.chats.removeAll { removedIds.contains($0.id) }
            }
            
            // Append genuinely new chats
            let addedIds = newIds.subtracting(oldIds)
            for id in addedIds {
                if let chat = newChatMap[id] {
                    self.chats.append(chat)
                }
            }
            
            print("DEBUG: [ChatStore] Merged \(fetchedChats.count) chats (updated \(oldIds.intersection(newIds).count), added \(addedIds.count), removed \(removedIds.count))")
            
            if let eventStore = self.eventStore {
                await self.autoArchiveExpiredEventChats(events: eventStore.events)
            }
        } catch {
            print("DEBUG ERROR: [ChatStore] fetchChats failed: \(error)")
            // On failure, keep existing chats — never wipe the list
        }
    }
    
    // MARK: - Fetch Messages
    
    @MainActor
    public func fetchMessages(for chatId: UUID) async {
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
    public func sendMessage(_ content: String, to chatId: UUID) {
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
            attachment_url: nil,
            created_at: istDateString(from: newMessage.createdAt)
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
    
    public func sendSystemMessage(_ content: String, to chatId: UUID, senderId: UUID? = nil) {
        let systemContent = "[System]: " + content
        let actualSenderId = senderId ?? userId
        let payload = InsertMessage(
            id: UUID(),
            chat_id: chatId,
            sender_id: actualSenderId,
            content: systemContent,
            attachment_url: nil,
            created_at: istDateString(from: Date())
        )
        Task {
            do {
                try await client.from("messages").insert(payload).execute()
                print("DEBUG: [ChatStore] System message sent successfully: \(content)")
            } catch {
                print("DEBUG ERROR: [ChatStore] Failed to send system message: \(error)")
            }
        }
    }
    
    // MARK: - Delete Message
    
    @MainActor
    public func deleteMessage(messageId: UUID, chatId: UUID) {
        messages[chatId]?.removeAll { $0.id == messageId }
        
        Task {
            do {
                try await client
                    .from("messages")
                    .delete()
                    .eq("id", value: messageId)
                    .execute()
                print("DEBUG: [ChatStore] Deleted message \(messageId)")
            } catch {
                print("DEBUG ERROR: [ChatStore] deleteMessage failed: \(error)")
            }
        }
    }
    
    // MARK: - Mark As Read
    
    @MainActor
    public func markAsRead(for chatId: UUID) async {
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
    
    public func togglePin(for chatId: UUID) {
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
    
    public func toggleArchive(for chatId: UUID) {
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
    
    public func toggleReadStatus(for chatId: UUID) {
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
    
    @MainActor
    public func autoArchiveExpiredEventChats(events: [Event]) async {
        let now = Date()
        let thirtyDaysAgo = now.addingTimeInterval(-30 * 24 * 60 * 60)
        
        // Create a set of expired event IDs
        let expiredEventIds = Set(events.filter { $0.endDate < thirtyDaysAgo }.map { $0.id })
        
        guard !expiredEventIds.isEmpty else { return }
        
        var chatsToArchive: [Chat] = []
        
        for chat in chats {
            guard chat.type == .event && !chat.isArchived else { continue }
            
            // For parent event chat, targetId is chat.id. For sub-chats, targetId is parentChatId.
            let targetEventId = chat.parentChatId ?? chat.id
            if expiredEventIds.contains(targetEventId) {
                chatsToArchive.append(chat)
            }
        }
        
        guard !chatsToArchive.isEmpty else { return }
        
        print("DEBUG: [ChatStore] Auto-archiving \(chatsToArchive.count) expired event chats")
        
        // Update local state first
        for chat in chatsToArchive {
            if let index = chats.firstIndex(where: { $0.id == chat.id }) {
                chats[index].isArchived = true
                chats[index].isPinned = false
            }
        }
        
        // Update database in parallel
        await withTaskGroup(of: Void.self) { group in
            for chat in chatsToArchive {
                group.addTask {
                    do {
                        let payload = UpdateParticipantField(is_pinned: false, is_archived: true)
                        try await self.client
                            .from("chat_participants")
                            .update(payload)
                            .eq("chat_id", value: chat.id)
                            .eq("user_id", value: self.userId)
                            .execute()
                        print("DEBUG: [ChatStore] Successfully auto-archived chat \(chat.id) in DB")
                    } catch {
                        print("DEBUG ERROR: [ChatStore] Failed to auto-archive chat \(chat.id) in DB: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Delete Chat
    
    @MainActor
    public func deleteChat(for chatId: UUID) {
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
    
    public func toggleExpansion(for chatId: UUID) {
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            chats[index].isExpanded.toggle()
        }
    }
    
    // MARK: - Create Individual Chat
    
    @discardableResult
    @MainActor
    public func createIndividualChat(with user: User) -> Chat {
        // Prevent duplicate individual chats
        if let existing = chats.first(where: { chat in
            chat.type == .individual && chat.participantIds.contains(user.id)
        }) { return existing }
        
        let chatId = UUID()
        let newChat = Chat(
            id: chatId,
            type: .individual,
            name: user.name,
            icon: user.profileImg,
            createdBy: userId,
            createdAt: Date(),
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
                    subgroup_id: nil,
                    parent_chat_id: nil,
                    created_by: userId,
                    created_at: istDateString(from: newChat.createdAt)
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
        
        return newChat
    }
    
    // MARK: - Create Group Chat
    
    @discardableResult
    @MainActor
    public func createGroupChat(name: String, description: String, icon: String?, memberIds: [UUID]) -> Chat {
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
                    subgroup_id: nil,
                    parent_chat_id: nil,
                    created_by: userId,
                    created_at: istDateString(from: newChat.createdAt)
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
        
        return newChat
    }
    // MARK: - Auto-Create Event Chats
    
    @MainActor
    public func createEventChatsForPublishedEvent(event: Event) async {
        // 1. Check local memory
        if chats.contains(where: { $0.id == event.id }) {
            print("DEBUG: [ChatStore] Event chat for event ID '\(event.id)' already exists in memory. Skipping.")
            return
        }
        
        // 2. Check Supabase database
        do {
            let existingChats: [Chat] = try await client
                .from("chats")
                .select()
                .eq("id", value: event.id)
                .execute()
                .value
            if !existingChats.isEmpty {
                print("DEBUG: [ChatStore] Event chat for event ID '\(event.id)' already exists in Supabase. Skipping.")
                return
            }
        } catch {
            print("DEBUG ERROR: [ChatStore] Failed to check for existing event chat: \(error)")
        }
        
        let parentChatId = event.id
        let generalChatId = UUID()
        let leadId = event.createdBy
        
        // Fetch members to populate initial participant list
        var memberIdsToAdd: [UUID] = []
        if let subgroupId = event.subgroupId {
            // Regular subgroup event
            do {
                let subgroupMembers: [User] = try await client
                    .from("users")
                    .select()
                    .eq("subgroup_id", value: subgroupId)
                    .execute()
                    .value
                memberIdsToAdd = subgroupMembers.map { $0.id }.filter { $0 != leadId }
            } catch {
                print("DEBUG ERROR: [ChatStore] Failed to fetch subgroup members: \(error)")
            }
        } else if let subgroupIds = event.subgroupIds, !subgroupIds.isEmpty {
            // Group/Council event targeting multiple subgroups
            do {
                let subgroupMembers: [User] = try await client
                    .from("users")
                    .select()
                    .in("subgroup_id", values: subgroupIds)
                    .execute()
                    .value
                memberIdsToAdd = subgroupMembers.map { $0.id }.filter { $0 != leadId }
            } catch {
                print("DEBUG ERROR: [ChatStore] Failed to fetch members for subgroups: \(error)")
            }
        } else {
            // Group/Council event with no specific subgroups (fallback: fetch everyone in lead's organization)
            do {
                let leadUsers: [User] = try await client
                    .from("users")
                    .select()
                    .eq("id", value: leadId)
                    .execute()
                    .value
                if let leadUser = leadUsers.first,
                   let orgId = leadUser.organizationId {
                    let orgUsers: [User] = try await client
                        .from("users")
                        .select()
                        .eq("organization_id", value: orgId)
                        .execute()
                        .value
                    memberIdsToAdd = orgUsers.map { $0.id }.filter { $0 != leadId }
                }
            } catch {
                print("DEBUG ERROR: [ChatStore] Failed to fetch organization members: \(error)")
            }
        }
        
        let allParticipantIds = [leadId] + memberIdsToAdd
        
        let parentChat = Chat(
            id: parentChatId,
            type: .event,
            name: event.title,
            icon: "calendar",
            subgroupId: event.subgroupId,
            createdBy: leadId,
            createdAt: Date(),
            participantIds: allParticipantIds
        )
        
        var generalChat = Chat(
            id: generalChatId,
            type: .event,
            name: "General",
            icon: nil,
            subgroupId: event.subgroupId,
            parentChatId: parentChatId,
            createdBy: leadId,
            createdAt: Date(),
            participantIds: allParticipantIds
        )
        generalChat.parentChatId = parentChatId
        
        chats.insert(parentChat, at: 0)
        chats.append(generalChat)
        if let index = chats.firstIndex(where: { $0.id == parentChatId }) {
            chats[index].isExpanded = true
        }
        
        do {
            let parentPayload = InsertChat(
                id: parentChatId,
                type: "event",
                name: event.title,
                description: nil,
                icon: "calendar",
                subgroup_id: event.subgroupId,
                parent_chat_id: nil,
                created_by: leadId,
                created_at: istDateString(from: parentChat.createdAt)
            )
            try await client.from("chats").insert(parentPayload).execute()
            
            let parentParticipant = InsertChatParticipant(
                chat_id: parentChatId,
                user_id: leadId,
                role: "admin",
                status: "accepted"
            )
            try await client.from("chat_participants").insert(parentParticipant).execute()
            
            let generalPayload = InsertChat(
                id: generalChatId,
                type: "event",
                name: "General",
                description: nil,
                icon: nil,
                subgroup_id: event.subgroupId,
                parent_chat_id: parentChatId,
                created_by: leadId,
                created_at: istDateString(from: generalChat.createdAt)
            )
            try await client.from("chats").insert(generalPayload).execute()
            
            let generalParticipant = InsertChatParticipant(
                chat_id: generalChatId,
                user_id: leadId,
                role: "admin",
                status: "accepted"
            )
            try await client.from("chat_participants").insert(generalParticipant).execute()
            
            // Add all subgroup members as participants to both parent & general chats in Supabase
            let parentParticipants = memberIdsToAdd.map { userId in
                InsertChatParticipant(
                    chat_id: parentChatId,
                    user_id: userId,
                    role: "member",
                    status: "accepted"
                )
            }
            let generalParticipants = memberIdsToAdd.map { userId in
                InsertChatParticipant(
                    chat_id: generalChatId,
                    user_id: userId,
                    role: "member",
                    status: "accepted"
                )
            }
            
            if !parentParticipants.isEmpty {
                _ = try? await client.from("chat_participants").insert(parentParticipants).execute()
            }
            if !generalParticipants.isEmpty {
                _ = try? await client.from("chat_participants").insert(generalParticipants).execute()
            }
            
            sendSystemMessage("All subgroup members were added by the organizer", to: parentChatId, senderId: leadId)
            sendSystemMessage("All subgroup members were added by the organizer", to: generalChatId, senderId: leadId)
            
            // Retroactively add any already-registered users (in case they registered before the chat was created)
            let existingRegistrations: [IndividualRegistration] = try await client
                .from("registrations")
                .select()
                .eq("event_id", value: event.id)
                .execute()
                .value
            
            for reg in existingRegistrations {
                guard let rUserId = reg.userId, rUserId != leadId && !memberIdsToAdd.contains(rUserId) else { continue }
                let pParticipant = InsertChatParticipant(chat_id: parentChatId, user_id: rUserId, role: "member", status: "accepted")
                let gParticipant = InsertChatParticipant(chat_id: generalChatId, user_id: rUserId, role: "member", status: "accepted")
                _ = try? await client.from("chat_participants").insert(pParticipant).execute()
                _ = try? await client.from("chat_participants").insert(gParticipant).execute()
            }
            
            print("DEBUG: [ChatStore] Auto-created Event Chat for '\(event.title)' and 'General' sub-chat. Added \(memberIdsToAdd.count) subgroup members and \(existingRegistrations.count) existing participants.")
        } catch {
            print("DEBUG ERROR: [ChatStore] createEventChatsForPublishedEvent failed: \(error)")
            self.chats.removeAll { $0.id == parentChatId || $0.id == generalChatId }
        }
    }
    
    // MARK: - Create Event Chat
    
    @discardableResult
    @MainActor
    public func createEventChat(name: String, subgroupId: UUID, icon: String?, memberIds: [UUID]) -> Chat {
        let chatId = UUID()
        let allParticipantIds = [userId] + memberIds
        
        let newChat = Chat(
            id: chatId,
            type: .event,
            name: name,
            icon: icon ?? "calendar",
            subgroupId: subgroupId,
            createdBy: userId,
            createdAt: Date(),
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
                    subgroup_id: subgroupId,
                    parent_chat_id: nil,
                    created_by: userId,
                    created_at: istDateString(from: newChat.createdAt)
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
        
        return newChat
    }
    
    // MARK: - Add Sub-Chat (under Event)
    
    @MainActor
    public func addSubChat(name: String, description: String? = nil, memberIds: [UUID] = [], for parentId: UUID) {
        guard let parentIndex = chats.firstIndex(where: { $0.id == parentId }) else { return }
        let parent = chats[parentIndex]
        let subChatId = UUID()
        
        var newChat = Chat(
            id: subChatId,
            type: .event,
            name: name,
            description: description,
            subgroupId: parent.subgroupId,
            parentChatId: parentId,
            createdBy: userId,
            createdAt: Date(),
            lastMessage: ""
        )
        newChat.parentChatId = parentId
        newChat.participantIds = [userId] + memberIds
        
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
                    subgroup_id: parent.subgroupId,
                    parent_chat_id: parentId,
                    created_by: userId,
                    created_at: istDateString(from: newChat.createdAt)
                )
                try await client.from("chats").insert(chatPayload).execute()
                
                // Add participants (creator as admin, others as members)
                var participants = [
                    InsertChatParticipant(chat_id: subChatId, user_id: userId, role: "admin", status: "accepted")
                ]
                for memberId in memberIds {
                    participants.append(
                        InsertChatParticipant(chat_id: subChatId, user_id: memberId, role: "member", status: "accepted")
                    )
                }
                try await client.from("chat_participants").insert(participants).execute()
                
                print("DEBUG: [ChatStore] Created sub-chat '\(name)' under parent \(parentId) with \(memberIds.count) extra participants")
                
                // Send system message for each member added
                for memberId in memberIds {
                    do {
                        let addedUser: User = try await client
                            .from("users")
                            .select()
                            .eq("id", value: memberId)
                            .single()
                            .execute()
                            .value
                        sendSystemMessage("\(addedUser.name) was added by the organizer", to: subChatId, senderId: userId)
                    } catch {
                        print("DEBUG ERROR: [ChatStore] Failed to send participant add system message in addSubChat: \(error)")
                    }
                }
            } catch {
                print("DEBUG ERROR: [ChatStore] addSubChat failed: \(error)")
                self.chats.removeAll { $0.id == subChatId }
            }
        }
    }
    
    // MARK: - Add Participant
    
    @MainActor
    public func addParticipant(userId participantUserId: UUID, to chatId: UUID) async {
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
            
            // If this is a sub-chat, also add the user to the parent chat so it shows up in their list
            var addedToParent = false
            if let index = chats.firstIndex(where: { $0.id == chatId }),
               let parentId = chats[index].parentChatId {
                 
                // Add to parent chat participants in Supabase (ignore error if already participant)
                let parentPayload = InsertChatParticipant(
                    chat_id: parentId,
                    user_id: participantUserId,
                    role: "member",
                    status: "accepted"
                )
                
                if let parentIndex = chats.firstIndex(where: { $0.id == parentId }) {
                    if !chats[parentIndex].participantIds.contains(participantUserId) {
                        _ = try? await client.from("chat_participants").insert(parentPayload).execute()
                        chats[parentIndex].participantIds.append(participantUserId)
                        addedToParent = true
                    }
                } else {
                    _ = try? await client.from("chat_participants").insert(parentPayload).execute()
                    addedToParent = true
                }
            }
            
            // Send system message: "[Name] was added by the organizer"
            Task {
                do {
                    let addedUser: User = try await client
                        .from("users")
                        .select()
                        .eq("id", value: participantUserId)
                        .single()
                        .execute()
                        .value
                    sendSystemMessage("\(addedUser.name) was added by the organizer", to: chatId, senderId: userId)
                    
                    if let index = chats.firstIndex(where: { $0.id == chatId }),
                       let parentId = chats[index].parentChatId,
                       addedToParent {
                        sendSystemMessage("\(addedUser.name) was added by the organizer", to: parentId, senderId: userId)
                    }
                } catch {
                    print("DEBUG ERROR: [ChatStore] Failed to send participant add system message: \(error)")
                }
            }
            
            print("DEBUG: [ChatStore] Added participant \(participantUserId) to chat \(chatId)")
        } catch {
            print("DEBUG ERROR: [ChatStore] addParticipant failed: \(error)")
        }
    }
    
    // MARK: - Remove Participant
    
    @MainActor
    public func removeParticipant(userId participantUserId: UUID, from chatId: UUID) async {
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
    
    // MARK: - Global Event Chat Registration
    
    @MainActor
    public func addUserToEventChatsGlobally(userId: UUID, eventId: UUID, eventTitle: String, subgroupId: UUID) async {
        do {
            var parentChat: Chat? = nil
            let chatsById: [Chat] = try await client
                .from("chats")
                .select()
                .eq("id", value: eventId)
                .execute()
                .value
            
            parentChat = chatsById.first
            
            if parentChat == nil {
                let allChats: [Chat] = try await client
                    .from("chats")
                    .select()
                    .eq("type", value: "event")
                    .eq("name", value: eventTitle)
                    .eq("subgroup_id", value: subgroupId)
                    .execute()
                    .value
                parentChat = allChats.first(where: { $0.parentChatId == nil })
            }
            
            guard let resolvedParent = parentChat else {
                print("DEBUG: [ChatStore] Parent event chat not found for event ID \(eventId) or '\(eventTitle)'. Cannot auto-add participant.")
                return
            }
            
            let generalChats: [Chat] = try await client
                .from("chats")
                .select()
                .eq("type", value: "event")
                .eq("name", value: "General")
                .eq("parent_chat_id", value: resolvedParent.id)
                .execute()
                .value
                
            guard let generalChat = generalChats.first else { return }
            
            let parentParticipant = InsertChatParticipant(chat_id: resolvedParent.id, user_id: userId, role: "member", status: "accepted")
            let generalParticipant = InsertChatParticipant(chat_id: generalChat.id, user_id: userId, role: "member", status: "accepted")
            
            do {
                try await client.from("chat_participants").insert(parentParticipant).execute()
            } catch {
                print("DEBUG: [ChatStore] User already in parent chat or error: \(error)")
            }
            
            do {
                try await client.from("chat_participants").insert(generalParticipant).execute()
            } catch {
                print("DEBUG: [ChatStore] User already in general chat or error: \(error)")
            }
            
            print("DEBUG: [ChatStore] Globally added user to Event Chat and General sub-chat for event ID \(eventId)")
            
            // Send system message
            Task {
                do {
                    let registeringUser: User = try await client
                        .from("users")
                        .select()
                        .eq("id", value: userId)
                        .single()
                        .execute()
                        .value
                    sendSystemMessage("\(registeringUser.name) was added", to: resolvedParent.id, senderId: userId)
                    sendSystemMessage("\(registeringUser.name) was added", to: generalChat.id, senderId: userId)
                } catch {
                    print("DEBUG ERROR: [ChatStore] Failed to send register system message: \(error)")
                }
            }
            
            if userId == self.userId {
                await fetchChats()
            }
        } catch {
            print("DEBUG ERROR: [ChatStore] addUserToEventChatsGlobally failed: \(error)")
        }
    }
    
    @MainActor
    public func removeUserFromEventChatsGlobally(userId: UUID, eventId: UUID, eventTitle: String, subgroupId: UUID) async {
        do {
            var parentChat: Chat? = nil
            let chatsById: [Chat] = try await client
                .from("chats")
                .select()
                .eq("id", value: eventId)
                .execute()
                .value
            
            parentChat = chatsById.first
            
            if parentChat == nil {
                let allChats: [Chat] = try await client
                    .from("chats")
                    .select()
                    .eq("type", value: "event")
                    .eq("name", value: eventTitle)
                    .eq("subgroup_id", value: subgroupId)
                    .execute()
                    .value
                parentChat = allChats.first(where: { $0.parentChatId == nil })
            }
            
            guard let resolvedParent = parentChat else { return }
            
            let generalChats: [Chat] = try await client
                .from("chats")
                .select()
                .eq("type", value: "event")
                .eq("name", value: "General")
                .eq("parent_chat_id", value: resolvedParent.id)
                .execute()
                .value
                
            guard let generalChat = generalChats.first else { return }
            
            try await client
                .from("chat_participants")
                .delete()
                .in("chat_id", value: [resolvedParent.id, generalChat.id])
                .eq("user_id", value: userId)
                .execute()
                
            print("DEBUG: [ChatStore] Globally removed user from Event Chat and General sub-chat for event ID \(eventId)")
            
            if userId == self.userId {
                await fetchChats()
            }
        } catch {
            print("DEBUG ERROR: [ChatStore] removeUserFromEventChatsGlobally failed: \(error)")
        }
    }
    
    // MARK: - Fetch Participants
    
    @MainActor
    public func fetchParticipants(for chatId: UUID) async -> [ChatParticipant] {
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
    public func acceptRequest(for chatId: UUID) {
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
    public func startRealtimeSubscription() {
        guard messagesChannel == nil && participantsChannel == nil else {
            print("DEBUG: [ChatStore] Realtime subscriptions already active. Skipping setup.")
            return
        }

        // Clean up any stale subscription tasks first
        messageSubscriptionTask?.cancel()
        participantSubscriptionTask?.cancel()
        presenceSubscriptionTask?.cancel()

        // Subscribe to new messages across all user's chats
        let msgChannel = client.realtimeV2.channel("chat-messages-\(userId.uuidString)")
        
        let messageInsertions = msgChannel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages"
        )
        
        messageSubscriptionTask = Task {
            // Connect the realtime socket first, then subscribe to the channel
            await client.realtimeV2.connect()
            print("DEBUG: [ChatStore] Realtime client connected")
            
            _ = try? await msgChannel.subscribeWithError()
            print("DEBUG: [ChatStore] Messages channel subscribed")
            
            for await insertion in messageInsertions {
                if Task.isCancelled { break }
                print("DEBUG: [ChatStore] Received realtime message insertion")
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
            _ = try? await partChannel.subscribeWithError()
            
            for await _ in participantInsertions {
                if Task.isCancelled { break }
                // Debounce: wait 2 seconds before refreshing to batch rapid changes
                // (e.g. when creating a group adds multiple participants at once)
                self.participantDebounceTask?.cancel()
                self.participantDebounceTask = Task {
                    _ = try? await Task.sleep(for: .seconds(2))
                    guard !Task.isCancelled else { return }
                    await self.fetchChats()
                }
            }
        }
        
        self.participantsChannel = partChannel
        
        // --- ONLINE STATUS & TYPING INDICATORS ---
        let presChannel = client.realtimeV2.channel("online-users")
        let presenceStream = presChannel.presenceChange()
        let typingStream = presChannel.broadcastStream(event: "typing")
        
        presenceSubscriptionTask = Task {
            _ = try? await presChannel.subscribeWithError()
            
            // Track our own presence
            _ = try? await presChannel.track(state: ["userId": .string(self.userId.uuidString)])
            
            // Handle incoming presence events
            Task {
                for await action in presenceStream {
                    if Task.isCancelled { break }
                    await MainActor.run {
                        for (_, presence) in action.joins {
                            if let userIdStr = presence.state["userId"]?.stringValue,
                               let id = UUID(uuidString: userIdStr) {
                                if self.onlinePresences[id] == nil { self.onlinePresences[id] = [] }
                                self.onlinePresences[id]?.insert(presence.ref)
                            }
                        }
                        for (_, presence) in action.leaves {
                            if let userIdStr = presence.state["userId"]?.stringValue,
                               let id = UUID(uuidString: userIdStr) {
                                self.onlinePresences[id]?.remove(presence.ref)
                            }
                        }
                        self.onlineUserIds = Set(self.onlinePresences.filter { !$0.value.isEmpty }.keys)
                    }
                }
            }
            
            // Handle incoming typing events
            Task {
                for await payload in typingStream {
                    if Task.isCancelled { break }
                    if let chatIdStr = payload["chatId"]?.stringValue,
                       let typingUserIdStr = payload["userId"]?.stringValue,
                       let chatId = UUID(uuidString: chatIdStr),
                       let typingUserId = UUID(uuidString: typingUserIdStr),
                       typingUserId != self.userId {
                       
                       await MainActor.run {
                           if self.typingUsers[chatId] == nil {
                               self.typingUsers[chatId] = []
                           }
                           self.typingUsers[chatId]?.insert(typingUserId)
                           
                           // Clear typing status after 3 seconds
                           self.typingClearTasks[typingUserId]?.cancel()
                           self.typingClearTasks[typingUserId] = Task {
                               _ = try? await Task.sleep(for: .seconds(3))
                               guard !Task.isCancelled else { return }
                               await MainActor.run {
                                   self.typingUsers[chatId]?.remove(typingUserId)
                               }
                           }
                       }
                    }
                }
            }
        }
        self.presenceChannel = presChannel
        
        print("DEBUG: [ChatStore] Realtime subscriptions started")
    }
    
    @MainActor
    public func sendTypingEvent(chatId: UUID) {
        guard let channel = presenceChannel else { return }
        Task {
            _ = try? await channel.broadcast(
                event: "typing",
                message: [
                    "chatId": .string(chatId.uuidString),
                    "userId": .string(userId.uuidString)
                ]
            )
        }
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
            
            // Skip if it's our own message that we already added optimistically on this device
            if messages[newMessage.chatId]?.contains(where: { $0.id == newMessage.id }) == true {
                print("DEBUG: [ChatStore] Skipping message \(newMessage.id) (already in state)")
                return
            }
            
            print("DEBUG: [ChatStore] Processing incoming message from \(newMessage.senderId) in chat \(newMessage.chatId)")
            
            // Add to messages — initialize array if not yet loaded
            if messages[newMessage.chatId] == nil {
                messages[newMessage.chatId] = []
            }
            
            // Avoid duplicates
            if !(messages[newMessage.chatId]?.contains(where: { $0.id == newMessage.id }) ?? false) {
                messages[newMessage.chatId]?.append(newMessage)
                print("DEBUG: [ChatStore] Appended message \(newMessage.id) to chat \(newMessage.chatId), total messages: \(messages[newMessage.chatId]?.count ?? 0)")
            }
            
            // Update last message and unread count on the chat (ignoring system messages for preview & badge count)
            if let index = chats.firstIndex(where: { $0.id == newMessage.chatId }) {
                let isSystem = newMessage.content.hasPrefix("[System]: ")
                if !isSystem {
                    chats[index].lastMessage = newMessage.content
                    chats[index].lastMessageAt = newMessage.createdAt
                }
                
                let isAppActive: Bool = {
                    #if canImport(UIKit)
                    return UIApplication.shared.applicationState == .active
                    #else
                    return true
                    #endif
                }()
                
                if newMessage.chatId == activeChatId && isAppActive {
                    await markAsRead(for: newMessage.chatId)
                } else if !isSystem {
                    chats[index].unreadCount += 1
                }
            }
        } catch {
            print("DEBUG ERROR: [ChatStore] handleNewMessage decode failed: \(error)")
        }
    }
    
    @MainActor
    public func stopRealtimeSubscription() {
        messageSubscriptionTask?.cancel()
        messageSubscriptionTask = nil
        participantSubscriptionTask?.cancel()
        participantSubscriptionTask = nil
        presenceSubscriptionTask?.cancel()
        presenceSubscriptionTask = nil

        Task {
            if let channel = messagesChannel {
                await client.realtimeV2.removeChannel(channel)
            }
            if let channel = participantsChannel {
                await client.realtimeV2.removeChannel(channel)
            }
            if let channel = presenceChannel {
                await client.realtimeV2.removeChannel(channel)
            }
        }
        messagesChannel = nil
        participantsChannel = nil
        presenceChannel = nil
        print("DEBUG: [ChatStore] Realtime subscriptions stopped")
    }
    
    // MARK: - Cleanup
    
    public func clearData() {
        chats = []
        messages = [:]
        chatParticipants = [:]
        onlineUserIds = []
        typingUsers = [:]
        onlinePresences = [:]
        selectedCategory = .all
        hasFetchedInitialData = false
        isFetching = false
        lastFetchDate = .distantPast
        participantDebounceTask?.cancel()
        participantDebounceTask = nil
    }

    // MARK: - Update Chat Icon
    
    @MainActor
    public func uploadChatIcon(chatId: UUID, imageData: Data) async throws {
        let storagePath = "chats/\(chatId.uuidString)/avatar_\(Int(Date().timeIntervalSince1970)).jpg"
        
        // Remove older chat avatar files in this chat's folder if any
        if let files = try? await client.storage.from("userProfile-images").list(path: "chats/\(chatId.uuidString)") {
            let pathsToDelete = files.map { "chats/\(chatId.uuidString)/\($0.name)" }
            if !pathsToDelete.isEmpty {
                _ = try? await client.storage.from("userProfile-images").remove(paths: pathsToDelete)
            }
        }
        
        // Upload new image data
        try await client.storage
            .from("userProfile-images")
            .upload(
                storagePath,
                data: imageData,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: true
                )
            )
        
        let publicURL = try client.storage
            .from("userProfile-images")
            .getPublicURL(path: storagePath)
        
        // Update database and local state
        try await updateChatIcon(chatId: chatId, iconURL: publicURL.absoluteString)
    }

    @MainActor
    public func updateChatIcon(chatId: UUID, iconURL: String) async throws {
        try await client
            .from("chats")
            .update(["icon": AnyJSON.string(iconURL)])
            .eq("id", value: chatId)
            .execute()
        
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            chats[index].icon = iconURL
        }
    }

    @MainActor
    public func removeChatIcon(chatId: UUID) async throws {
        try await client
            .from("chats")
            .update(["icon": AnyJSON.null])
            .eq("id", value: chatId)
            .execute()
        
        if let files = try? await client.storage.from("userProfile-images").list(path: "chats/\(chatId.uuidString)") {
            let pathsToDelete = files.map { "chats/\(chatId.uuidString)/\($0.name)" }
            if !pathsToDelete.isEmpty {
                _ = try? await client.storage.from("userProfile-images").remove(paths: pathsToDelete)
            }
        }
        
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            chats[index].icon = nil
        }
    }

    @MainActor
    public func updateChatDescription(chatId: UUID, description: String?) async throws {
        let cleanDescription = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        let dbValue: AnyJSON = (cleanDescription == nil || cleanDescription!.isEmpty) ? .null : .string(cleanDescription!)
        
        try await client
            .from("chats")
            .update(["description": dbValue])
            .eq("id", value: chatId)
            .execute()
        
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            chats[index].description = (cleanDescription == nil || cleanDescription!.isEmpty) ? nil : cleanDescription
        }
    }

    private func istDateString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
