//
//  Chat.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//  


import Foundation


// MARK: - Chat Type
public enum ChatType: String, Codable {
    case individual
    case group
    case event
}

// MARK: - Chat Participant Role
public enum ChatParticipantRole: String, Codable {
    case admin
    case member
}

// MARK: - Chat Participant Status
public enum ChatParticipantStatus: String, Codable {
    case accepted
    case pending
}

// MARK: - Chat
public struct Chat: Identifiable, Codable, Equatable, Hashable {
    public static func == (lhs: Chat, rhs: Chat) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    public var id: UUID
    public var type: ChatType
    public var name: String?
    public var description: String?
    public var icon: String?
    public var subgroupId: UUID?
    public var parentChatId: UUID?
    public var createdBy: UUID
    public var createdAt: Date
    
    // Transient properties — populated after fetch, not stored in DB
    public var lastMessage: String = ""
    public var lastMessageAt: Date?
    public var unreadCount: Int = 0
    public var isExpanded: Bool = false
    
    // Per-user state from chat_participants
    public var isPinned: Bool = false
    public var isArchived: Bool = false
    public var isMuted: Bool = false
    public var isRequest: Bool = false
    public var participantIds: [UUID] = []

    public enum CodingKeys: String, CodingKey {
        case id
        case type
        case name
        case description
        case icon
        case subgroupId = "subgroup_id"
        case parentChatId = "parent_chat_id"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
    
    // Computed display name for individual chats
    public var displayName: String {
        name ?? "Chat"
    }

    public init(
        id: UUID,
        type: ChatType,
        name: String? = nil,
        description: String? = nil,
        icon: String? = nil,
        subgroupId: UUID? = nil,
        parentChatId: UUID? = nil,
        createdBy: UUID,
        createdAt: Date,
        lastMessage: String = "",
        lastMessageAt: Date? = nil,
        unreadCount: Int = 0,
        isExpanded: Bool = false,
        isPinned: Bool = false,
        isArchived: Bool = false,
        isMuted: Bool = false,
        isRequest: Bool = false,
        participantIds: [UUID] = []
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.description = description
        self.icon = icon
        self.subgroupId = subgroupId
        self.parentChatId = parentChatId
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.lastMessage = lastMessage
        self.lastMessageAt = lastMessageAt
        self.unreadCount = unreadCount
        self.isExpanded = isExpanded
        self.isPinned = isPinned
        self.isArchived = isArchived
        self.isMuted = isMuted
        self.isRequest = isRequest
        self.participantIds = participantIds
    }

}

// MARK: - Chat Participant
public struct ChatParticipant: Identifiable, Codable {
    public var id: UUID
    public var chatId: UUID
    public var userId: UUID
    public var role: ChatParticipantRole
    public var status: ChatParticipantStatus
    public var isPinned: Bool
    public var isArchived: Bool
    public var isMuted: Bool
    public var lastReadAt: Date?
    public var joinedAt: Date
    
    public enum CodingKeys: String, CodingKey {
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

    public init(
        id: UUID,
        chatId: UUID,
        userId: UUID,
        role: ChatParticipantRole,
        status: ChatParticipantStatus,
        isPinned: Bool,
        isArchived: Bool,
        isMuted: Bool,
        lastReadAt: Date? = nil,
        joinedAt: Date
    ) {
        self.id = id
        self.chatId = chatId
        self.userId = userId
        self.role = role
        self.status = status
        self.isPinned = isPinned
        self.isArchived = isArchived
        self.isMuted = isMuted
        self.lastReadAt = lastReadAt
        self.joinedAt = joinedAt
    }

}

// MARK: - Message
public struct Message: Identifiable, Codable {
    public var id: UUID
    public var chatId: UUID
    public var senderId: UUID
    public var content: String
    public var attachmentUrl: String?
    public var createdAt: Date
    
    public enum CodingKeys: String, CodingKey {
        case id
        case chatId = "chat_id"
        case senderId = "sender_id"
        case content
        case attachmentUrl = "attachment_url"
        case createdAt = "created_at"
    }

    public init(
        id: UUID,
        chatId: UUID,
        senderId: UUID,
        content: String,
        attachmentUrl: String? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.chatId = chatId
        self.senderId = senderId
        self.content = content
        self.attachmentUrl = attachmentUrl
        self.createdAt = createdAt
    }

}

// MARK: - Chat Category (Filter tabs)
public enum ChatCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case unread = "Unread"
    case groups = "Groups"
    case event = "Event"
    case archived = "Archived"
    case requests = "Requests"
    
    public var id: String { rawValue }
}

// MARK: - Encodable payloads for Supabase inserts

public struct InsertChat: Encodable {
    public let id: UUID
    public let type: String
    public let name: String?
    public let description: String?
    public let icon: String?
    public let subgroup_id: UUID?
    public let parent_chat_id: UUID?
    public let created_by: UUID
    public let created_at: String

    public init(
        id: UUID,
        type: String,
        name: String? = nil,
        description: String? = nil,
        icon: String? = nil,
        subgroup_id: UUID? = nil,
        parent_chat_id: UUID? = nil,
        created_by: UUID,
        created_at: String
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.description = description
        self.icon = icon
        self.subgroup_id = subgroup_id
        self.parent_chat_id = parent_chat_id
        self.created_by = created_by
        self.created_at = created_at
    }

}

public struct InsertChatParticipant: Encodable {
    public let chat_id: UUID
    public let user_id: UUID
    public let role: String
    public let status: String

    public init(chat_id: UUID, user_id: UUID, role: String, status: String) {
        self.chat_id = chat_id
        self.user_id = user_id
        self.role = role
        self.status = status
    }

}

public struct InsertMessage: Encodable {
    public let id: UUID
    public let chat_id: UUID
    public let sender_id: UUID
    public let content: String
    public let attachment_url: String?
    public let created_at: String

    public init(
        id: UUID,
        chat_id: UUID,
        sender_id: UUID,
        content: String,
        attachment_url: String? = nil,
        created_at: String
    ) {
        self.id = id
        self.chat_id = chat_id
        self.sender_id = sender_id
        self.content = content
        self.attachment_url = attachment_url
        self.created_at = created_at
    }

}

public struct UpdateParticipantField: Encodable {
    public var is_pinned: Bool?
    public var is_archived: Bool?
    public var is_muted: Bool?
    public var last_read_at: String?

    public enum CodingKeys: String, CodingKey {
        case is_pinned = "is_pinned"
        case is_archived = "is_archived"
        case is_muted = "is_muted"
        case last_read_at = "last_read_at"
    }

    public func encode(to encoder: Encoder) throws {
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

    public init(
        is_pinned: Bool? = nil,
        is_archived: Bool? = nil,
        is_muted: Bool? = nil,
        last_read_at: String? = nil
    ) {
        self.is_pinned = is_pinned
        self.is_archived = is_archived
        self.is_muted = is_muted
        self.last_read_at = last_read_at
    }

}

