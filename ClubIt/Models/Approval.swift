//
//  Approval.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//

import Foundation

enum ApprovalType: String, Codable {
    case event
    case budget
    case resource
    case venue
}

enum ApprovalStatus: String, Codable {
    case pending
    case approved
    case rejected
}

struct Remark: Identifiable, Codable, Hashable {
    var id: UUID
    var approvalId: UUID
    var authorId: UUID
    var content: String
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case approvalId = "approval_id"
        case authorId = "author_id"
        case content
        case createdAt = "created_at"
    }
    
    init(id: UUID = UUID(), approvalId: UUID, authorId: UUID, content: String, createdAt: Date = Date()) {
        self.id = id
        self.approvalId = approvalId
        self.authorId = authorId
        self.content = content
        self.createdAt = createdAt
    }
}

// Keep RemarkMessage as an alias for now to avoid breaking other files
typealias RemarkMessage = Remark

struct Approval: Identifiable, Codable {
    var id: UUID
    
    var type: ApprovalType
    var senderId: UUID?
    var receiverId: UUID?
    
    var eventId: UUID?
    var approvalRelatedId: UUID?     
    
    var status: ApprovalStatus
    var remarks: [Remark]?
    
    var createdAt: Date
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case eventId = "event_id"
        case approvalRelatedId = "approval_related_id"
        case status
        case remarks
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(id: UUID, type: ApprovalType, senderId: UUID?, receiverId: UUID?, eventId: UUID?, approvalRelatedId: UUID?, status: ApprovalStatus, remarks: [Remark]? = [], createdAt: Date, updatedAt: Date? = nil) {
        self.id = id
        self.type = type
        self.senderId = senderId
        self.receiverId = receiverId
        self.eventId = eventId
        self.approvalRelatedId = approvalRelatedId
        self.status = status
        self.remarks = remarks ?? []
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct Budget: Identifiable, Codable {
    var id: UUID
    
    var eventId: UUID?
    
    var itemName: String
    var unitPrice: Double
    var quantity: Int
    
    var totalAmount: Double {
        unitPrice * Double(quantity)
    }
    
    var status: ApprovalStatus
    var addedBy: UUID?
    
    var remarks: [Remark]?
    var createdAt: Date
    var approvedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case itemName = "item_name"
        case unitPrice = "unit_price"
        case quantity
        case status
        case addedBy = "added_by"
        case remarks
        case createdAt = "created_at"
        case approvedAt = "approved_at"
    }

    init(id: UUID, eventId: UUID?, itemName: String, unitPrice: Double, quantity: Int, status: ApprovalStatus, addedBy: UUID?, remarks: [Remark]? = [], createdAt: Date, approvedAt: Date? = nil) {
        self.id = id
        self.eventId = eventId
        self.itemName = itemName
        self.unitPrice = unitPrice
        self.quantity = quantity
        self.status = status
        self.addedBy = addedBy
        self.remarks = remarks ?? []
        self.createdAt = createdAt
        self.approvedAt = approvedAt
    }
}
