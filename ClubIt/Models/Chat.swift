//
//  Chat.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//  


import Foundation


enum ChatType: String, Codable {
    case individual
    case group
    case event
}

struct Chat: Identifiable, Codable {
    var id: UUID
    var type: ChatType
    var createdBy: UUID
    var clubId: UUID?
    var createdAt: Date
    
    var name: String
    var description: String?
    var lastMessage: String
    var unreadCount: Int = 0
    var icon: String?
    var parentChatId: UUID?
    var isExpanded: Bool = false
    var isPinned: Bool = false
    var isArchived: Bool = false
    var participants: [UUID] = []
}

struct ChatParticipant: Identifiable, Codable {
    var id: UUID
    var chatId: UUID
    var userId: UUID
    var joinedAt: Date
}

struct Message: Identifiable, Codable {
    var id: UUID
    var chatId: UUID
    var senderId: UUID
    var content: String
    var attachmentUrl: String?
    var createdAt: Date
}

enum ChatCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case unread = "Unread"
    case groups = "Groups"
    case event = "Event"
    case archived = "Archived"
    
    var id: String { rawValue }
}
