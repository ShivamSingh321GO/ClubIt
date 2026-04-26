//
//  Achievement.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//  

import Foundation

enum AchievementType: String, Codable, CaseIterable, Identifiable {
    case award
    case milestone
    case recognition
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .award: return "Awards"
        case .milestone: return "Milestones"
        case .recognition: return "Recognition"
        }
    }
    
    var icon: String {
        switch self {
        case .award: return "trophy"
        case .milestone: return "flag"
        case .recognition: return "sparkles"
        }
    }
}

struct Achievement: Identifiable, Codable {
    var id: UUID
    var clubId: UUID
    var title: String
    var description: String
    var type: AchievementType
    var createdAt: Date
}
