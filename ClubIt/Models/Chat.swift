//
//  Chat.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//  


import Foundation


// MARK: - Chat Type
enum ChatType: String, Codable {
    case individual
    case group
    case event
}

// MARK: - Chat Participant Role
enum ChatParticipantRole: String, Codable {
    case admin
    case member
}

// MARK: - Chat Participant Status
enum ChatParticipantStatus: String, Codable {
    case accepted
    case pending
}

// MARK: - Chat
struct Chat: Identifiable, Codable {
    var id: UUID
    var type: ChatType
    var name: String?
    var description: String?
    var icon: String?
    var clubId: UUID?
    var parentChatId: UUID?
    var createdBy: UUID
    var createdAt: Date
    
    // Transient properties — populated after fetch, not stored in DB
    var lastMessage: String = ""
    var lastMessageAt: Date?
    var unreadCount: Int = 0
    var isExpanded: Bool = false
    
    // Per-user state from chat_participants
    var isPinned: Bool = false
    var isArchived: Bool = false
    var isMuted: Bool = false
    var isRequest: Bool = false
    var participantIds: [UUID] = []

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case name
        case description
        case icon
        case clubId = "club_id"
        case parentChatId = "parent_chat_id"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
    
    // Computed display name for individual chats
    var displayName: String {
        name ?? "Chat"
    }
}

// MARK: - Chat Participant
struct ChatParticipant: Identifiable, Codable {
    var id: UUID
    var chatId: UUID
    var userId: UUID
    var role: ChatParticipantRole
    var status: ChatParticipantStatus
    var isPinned: Bool
    var isArchived: Bool
    var isMuted: Bool
    var lastReadAt: Date?
    var joinedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case chatId = "chat_id"
        case userId = "user_id"
        case role
        case status
        case isPinned = "is_pinned"
        case isArchived = "is_archived"
        case isMuted = "is_muted"
        case lastReadAt = "last_read_at"
        case joinedAt = "joined_at"
    }
}

// MARK: - Message
struct Message: Identifiable, Codable {
    var id: UUID
    var chatId: UUID
    var senderId: UUID
    var content: String
    var attachmentUrl: String?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case chatId = "chat_id"
        case senderId = "sender_id"
        case content
        case attachmentUrl = "attachment_url"
        case createdAt = "created_at"
    }
}

// MARK: - Chat Category (Filter tabs)
enum ChatCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case unread = "Unread"
    case groups = "Groups"
    case event = "Event"
    case archived = "Archived"
    case requests = "Requests"
    
    var id: String { rawValue }
}

// MARK: - Encodable payloads for Supabase inserts

struct InsertChat: Encodable {
    let id: UUID
    let type: String
    let name: String?
    let description: String?
    let icon: String?
    let club_id: UUID?
    let parent_chat_id: UUID?
    let created_by: UUID
}

struct InsertChatParticipant: Encodable {
    let chat_id: UUID
    let user_id: UUID
    let role: String
    let status: String
}

struct InsertMessage: Encodable {
    let id: UUID
    let chat_id: UUID
    let sender_id: UUID
    let content: String
    let attachment_url: String?
}

struct UpdateParticipantField: Encodable {
    var is_pinned: Bool?
    var is_archived: Bool?
    var is_muted: Bool?
    var last_read_at: String?

    enum CodingKeys: String, CodingKey {
        case is_pinned = "is_pinned"
        case is_archived = "is_archived"
        case is_muted = "is_muted"
        case last_read_at = "last_read_at"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let is_pinned = is_pinned {
            try container.encode(is_pinned, forKey: .is_pinned)
        }
        if let is_archived = is_archived {
            try container.encode(is_archived, forKey: .is_archived)
        }
        if let is_muted = is_muted {
            try container.encode(is_muted, forKey: .is_muted)
        }
        if let last_read_at = last_read_at {
            try container.encode(last_read_at, forKey: .last_read_at)
        }
    }
}

