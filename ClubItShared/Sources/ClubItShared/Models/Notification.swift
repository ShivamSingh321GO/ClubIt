//
//  Notification.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//

import Foundation


public enum NotificationType: String, Codable {
    case eventApproved
    case taskAssigned
    case newAnnouncement
    case registrationSuccess
}

public struct Notification: Identifiable, Codable {
    public var id: UUID
    public var userId: UUID
    public var title: String
    public var message: String
    public var type: NotificationType
    public var referenceId: UUID
    public var isRead: Bool
    public var createdAt: Date

    public init(
        id: UUID,
        userId: UUID,
        title: String,
        message: String,
        type: NotificationType,
        referenceId: UUID,
        isRead: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.message = message
        self.type = type
        self.referenceId = referenceId
        self.isRead = isRead
        self.createdAt = createdAt
    }

}
