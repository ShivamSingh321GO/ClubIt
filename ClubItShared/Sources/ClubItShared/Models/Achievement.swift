//
//  Achievement.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//  

import Foundation

public enum AchievementType: String, Codable, CaseIterable, Identifiable {
    case award
    case milestone
    case recognition
    
    public var id: String { self.rawValue }
    
    public var title: String {
        switch self {
        case .award: return "Awards"
        case .milestone: return "Milestones"
        case .recognition: return "Recognition"
        }
    }
    
    public var icon: String {
        switch self {
        case .award: return "trophy"
        case .milestone: return "flag"
        case .recognition: return "sparkles"
        }
    }
}

public struct Achievement: Identifiable, Codable {
    public var id: UUID
    public var subgroupId: UUID
    public var title: String
    public var description: String
    public var type: AchievementType
    public var createdAt: Date

    public enum CodingKeys: String, CodingKey {
        case id
        case subgroupId = "subgroup_id"
        case title
        case description
        case type
        case createdAt = "created_at"
    }

    public init(
        id: UUID,
        subgroupId: UUID,
        title: String,
        description: String,
        type: AchievementType,
        createdAt: Date
    ) {
        self.id = id
        self.subgroupId = subgroupId
        self.title = title
        self.description = description
        self.type = type
        self.createdAt = createdAt
    }

}
