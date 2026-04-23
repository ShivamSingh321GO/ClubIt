//
//  Task.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//

import Foundation

enum ClubOption: String, CaseIterable, Identifiable {
    case technoJam = "TechnoJam"
    case gdsc = "GDSC"
    case photography = "Photography Club"
    case music = "Music Society"
    
    var id: String { self.rawValue }
    
    var uuid: UUID {
        switch self {
        case .technoJam: return UUID()
        case .gdsc: return UUID()
        case .photography: return UUID()
        case .music: return UUID()
        }
    }
    
    static func from(uuid: UUID) -> ClubOption {
        return ClubOption.allCases.first(where: { $0.uuid == uuid }) ?? .technoJam
    }
}

enum AssigneeOption: String, CaseIterable, Identifiable {
    case aryan = "Aryan"
    case shivam = "Shivam"
    case ansh = "Ansh"
    case rahul = "Rahul"
    
    var id: String { self.rawValue }
    
    var uuid: UUID {
        switch self {
        case .aryan: return UUID()
        case .shivam: return UUID()
        case .ansh: return UUID()
        case .rahul: return UUID()
        }
    }
    
    static func from(uuid: UUID) -> AssigneeOption {
        return AssigneeOption.allCases.first(where: { $0.uuid == uuid }) ?? .aryan
    }
}


enum TaskPriority: String, Codable, CaseIterable {
    case low
    case high
}

enum TaskStatus: String, Codable, CaseIterable {
    case pending
    case inProgress
    case completed
}

struct Tasks: Identifiable, Codable {
    var id = UUID()
    var clubId: UUID
    var targetClubId: UUID? = nil // For cross-club tasks
    var eventId: UUID? = nil
    var title: String
    var description: String
    var assignedBy: UUID
    var assignedByRole: AppRole
    var assignedTo: UUID
    var assignedToRole: AppRole
    var delegatedToId: UUID? = nil // For delegation to members
    var delegatedToName: String? = nil // For quick UI display
    var deadline: Date
    var priority: TaskPriority
    var status: TaskStatus
    var createdAt: Date
}

struct TeamMember: Identifiable, Codable {
    var id: UUID = UUID()
    var teamId: UUID
    var userId: UUID
    var institutionNumber: String
    var joinedAt: Date
}
