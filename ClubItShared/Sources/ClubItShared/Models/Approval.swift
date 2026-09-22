//
//  Approval.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//

import Foundation

public enum ApprovalType: String, Codable, Equatable, Hashable {
    case event
    case budget
    case resource
    case venue
}

public enum ApprovalStatus: String, Codable, Equatable, Hashable {
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

public struct Approval: Identifiable, Codable, Equatable {
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

    public static func == (lhs: Approval, rhs: Approval) -> Bool {
        lhs.id == rhs.id && lhs.status == rhs.status && lhs.updatedAt == rhs.updatedAt && lhs.remarks == rhs.remarks
    }

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
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(ApprovalType.self, forKey: .type)
        senderId = try? container.decode(UUID.self, forKey: .senderId)
        receiverId = try? container.decode(UUID.self, forKey: .receiverId)
        eventId = try? container.decode(UUID.self, forKey: .eventId)
        approvalRelatedId = try? container.decode(UUID.self, forKey: .approvalRelatedId)
        status = (try? container.decode(ApprovalStatus.self, forKey: .status)) ?? .pending
        // Gracefully handle remarks — if it can't decode as [Remark], use empty array
        remarks = (try? container.decode([Remark].self, forKey: .remarks)) ?? []
        createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
        updatedAt = try? container.decode(Date.self, forKey: .updatedAt)
    }
}

public struct Budget: Identifiable, Codable, Equatable {
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

    public static func == (lhs: Budget, rhs: Budget) -> Bool {
        lhs.id == rhs.id && lhs.status == rhs.status && lhs.remarks == rhs.remarks && lhs.unitPrice == rhs.unitPrice && lhs.quantity == rhs.quantity
    }

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
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        eventId = try? container.decode(UUID.self, forKey: .eventId)
        itemName = (try? container.decode(String.self, forKey: .itemName)) ?? ""
        // Handle unit_price as either Double or String
        if let price = try? container.decode(Double.self, forKey: .unitPrice) {
            unitPrice = price
        } else if let priceStr = try? container.decode(String.self, forKey: .unitPrice),
                  let price = Double(priceStr) {
            unitPrice = price
        } else {
            unitPrice = 0
        }
        quantity = (try? container.decode(Int.self, forKey: .quantity)) ?? 1
        status = (try? container.decode(ApprovalStatus.self, forKey: .status)) ?? .pending
        addedBy = try? container.decode(UUID.self, forKey: .addedBy)
        remarks = (try? container.decode([Remark].self, forKey: .remarks)) ?? []
        createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
        approvedAt = try? container.decode(Date.self, forKey: .approvedAt)
    }
}
