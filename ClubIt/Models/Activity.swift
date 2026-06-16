//
//  Activity.swift
//  ClubIt
//

import Foundation
import SwiftUI

enum ActivityType: String, Codable, CaseIterable {
    case workshop = "Workshop"
    case meeting = "Meeting"
    case announcement = "Announcement"
    case competition = "Competition"
    case seminar = "Seminar"
    
    var icon: String {
        switch self {
        case .workshop: return "laptopcomputer"
        case .meeting: return "person.2.fill"
        case .announcement: return "megaphone.fill"
        case .competition: return "trophy.fill"
        case .seminar: return "book.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .workshop: return .purple
        case .meeting: return .blue
        case .announcement: return .yellow
        case .competition: return .accentColor
        case .seminar: return .green
        }
    }
}

struct Activity: Identifiable, Codable {
    var id: UUID
    var type: ActivityType
    var title: String
    var description: String
    var date: Date
    var location: String?
    var clubId: UUID
    var postedBy: UUID
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case description
        case date
        case location
        case clubId = "club_id"
        case postedBy = "posted_by"
        case createdAt = "created_at"
    }
}
