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


struct Approval: Identifiable, Codable {
    var id: UUID = UUID()
    
    var type: ApprovalType
    var senderId: UUID
    var receiverId: UUID
    
    var eventId: UUID
    var approvalRelatedId: UUID     
    
    var status: ApprovalStatus
    var remark: String?
    
    var createdAt: Date
    var updatedAt: Date?
}


struct Budget: Identifiable, Codable {
    var id: UUID = UUID()
    
    var eventId: UUID
    
    var itemName: String
    var unitPrice: Double
    var quantity: Int
    var totalAmount: Double
    
    var status: ApprovalStatus
    var addedBy: UUID
    
    var remark: String?
    var createdAt: Date
    var approvedAt: Date?
}
