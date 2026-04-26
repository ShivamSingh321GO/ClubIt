//
//  Notification.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//

import Foundation


enum NotificationType: String, Codable {
    case eventApproved
    case taskAssigned
    case newAnnouncement
    case registrationSuccess
}

struct Notification: Identifiable, Codable {
    var id: UUID
    var userId: UUID
    var title: String
    var message: String
    var type: NotificationType
    var referenceId: UUID
    var isRead: Bool
    var createdAt: Date
}
