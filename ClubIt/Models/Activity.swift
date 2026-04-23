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
        case .announcement: return .orange
        case .competition: return .goldenBrown
        case .seminar: return .green
        }
    }
}

struct Activity: Identifiable, Codable {
    var id: UUID = UUID()
    var type: ActivityType
    var title: String
    var description: String
    var date: Date
    var location: String?
    var clubId: UUID
    var postedBy: UUID
    var postedByName: String?
    var createdAt: Date
}
