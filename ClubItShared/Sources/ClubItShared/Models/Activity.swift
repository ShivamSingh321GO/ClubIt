//
//  Activity.swift
//  ClubIt
//

import Foundation
import SwiftUI

public enum ActivityType: String, Codable, CaseIterable {
    case workshop = "Workshop"
    case meeting = "Meeting"
    case announcement = "Announcement"
    case competition = "Competition"
    case seminar = "Seminar"
    
    public var icon: String {
        switch self {
        case .workshop: return "laptopcomputer"
        case .meeting: return "person.2.fill"
        case .announcement: return "megaphone.fill"
        case .competition: return "trophy.fill"
        case .seminar: return "book.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .workshop: return .purple
        case .meeting: return .blue
        case .announcement: return .yellow
        case .competition: return .accentColor
        case .seminar: return .green
        }
    }
}

public struct Activity: Identifiable, Codable {
    public var id: UUID
    public var type: ActivityType
    public var title: String
    public var description: String
    public var date: Date
    public var location: String?
    public var subgroupId: UUID
    public var postedBy: UUID
    public var createdAt: Date

    public enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case description
        case date
        case location
        case subgroupId = "subgroup_id"
        case postedBy = "posted_by"
        case createdAt = "created_at"
    }

    public init(
        id: UUID,
        type: ActivityType,
        title: String,
        description: String,
        date: Date,
        location: String? = nil,
        subgroupId: UUID,
        postedBy: UUID,
        createdAt: Date
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.date = date
        self.location = location
        self.subgroupId = subgroupId
        self.postedBy = postedBy
        self.createdAt = createdAt
    }

}
