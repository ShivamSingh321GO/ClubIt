//
//  Approval.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//

import Foundation

public enum ApprovalType: String, Codable {
    case event
    case budget
    case resource
    case venue
}

public enum ApprovalStatus: String, Codable {
    case pending
    case approved
    case rejected
}

public struct Remark: Identifiable, Codable, Hashable {
    public var id: UUID
    public var approvalId: UUID
    public var authorId: UUID
    public var content: String
    public var createdAt: Date
    
    public enum CodingKeys: String, CodingKey {
        case id
        case approvalId = "approval_id"
        case authorId = "author_id"
        case content
        case createdAt = "created_at"
    }
    
    public init(id: UUID = UUID(), approvalId: UUID, authorId: UUID, content: String, createdAt: Date = Date()) {
        self.id = id
        self.approvalId = approvalId
        self.authorId = authorId
        self.content = content
        self.createdAt = createdAt
    }
}

// Keep RemarkMessage as an alias for now to avoid breaking other files
public typealias RemarkMessage = Remark

public struct Approval: Identifiable, Codable {
    public var id: UUID
    
    public var type: ApprovalType
    public var senderId: UUID?
    public var receiverId: UUID?
    
    public var eventId: UUID?
    public var approvalRelatedId: UUID?     
    
    public var status: ApprovalStatus
    public var remarks: [Remark]?
    
    public var createdAt: Date
    public var updatedAt: Date?

    public enum CodingKeys: String, CodingKey {
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

    public init(id: UUID, type: ApprovalType, senderId: UUID?, receiverId: UUID?, eventId: UUID?, approvalRelatedId: UUID?, status: ApprovalStatus, remarks: [Remark]? = [], createdAt: Date, updatedAt: Date? = nil) {
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

public struct Budget: Identifiable, Codable {
    public var id: UUID
    
    public var eventId: UUID?
    
    public var itemName: String
    public var unitPrice: Double
    public var quantity: Int
    
    public var totalAmount: Double {
        unitPrice * Double(quantity)
    }
    
    public var status: ApprovalStatus
    public var addedBy: UUID?
    
    public var remarks: [Remark]?
    public var createdAt: Date
    public var approvedAt: Date?

    public enum CodingKeys: String, CodingKey {
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

    public init(id: UUID, eventId: UUID?, itemName: String, unitPrice: Double, quantity: Int, status: ApprovalStatus, addedBy: UUID?, remarks: [Remark]? = [], createdAt: Date, approvedAt: Date? = nil) {
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
