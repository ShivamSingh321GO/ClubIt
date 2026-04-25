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


struct Remark: Identifiable, Codable {
    var id: UUID = UUID()
    var text: String
    var authorId: UUID
    var authorName: String
    var createdAt: Date
}


struct Approval: Identifiable, Codable {
    var id: UUID
    
    var type: ApprovalType
    var senderId: UUID
    var receiverId: UUID
    
    var eventId: UUID
    var approvalRelatedId: UUID     
    
    var status: ApprovalStatus
    var remarks: [Remark]
    
    var createdAt: Date
    var updatedAt: Date?

    init(id: UUID = UUID(), type: ApprovalType, senderId: UUID, receiverId: UUID, eventId: UUID, approvalRelatedId: UUID, status: ApprovalStatus, remarks: [Remark] = [], createdAt: Date, updatedAt: Date? = nil) {
        self.id = id
        self.type = type
        self.senderId = senderId
        self.receiverId = receiverId
        self.eventId = eventId
        self.approvalRelatedId = approvalRelatedId
        self.status = status
        self.remarks = remarks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}


struct Budget: Identifiable, Codable {
    var id: UUID
    
    var eventId: UUID
    
    var itemName: String
    var unitPrice: Double
    var quantity: Int
    var totalAmount: Double
    
    var status: ApprovalStatus
    var addedBy: UUID
    
    var remarks: [Remark]
    var createdAt: Date
    var approvedAt: Date?

    init(id: UUID = UUID(), eventId: UUID, itemName: String, unitPrice: Double, quantity: Int, totalAmount: Double, status: ApprovalStatus, addedBy: UUID, remarks: [Remark] = [], createdAt: Date, approvedAt: Date? = nil) {
        self.id = id
        self.eventId = eventId
        self.itemName = itemName
        self.unitPrice = unitPrice
        self.quantity = quantity
        self.totalAmount = totalAmount
        self.status = status
        self.addedBy = addedBy
        self.remarks = remarks
        self.createdAt = createdAt
        self.approvedAt = approvedAt
    }
}
