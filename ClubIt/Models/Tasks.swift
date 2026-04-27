//
//  Task.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//

import Foundation




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
    var id: UUID
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
    var deadline: Date
    var priority: TaskPriority
    var status: TaskStatus
    var createdAt: Date
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case targetClubId = "target_club_id"
        case eventId = "event_id"
        case title
        case description
        case assignedBy = "assigned_by"
        case assignedByRole = "assigned_by_role"
        case assignedTo = "assigned_to"
        case assignedToRole = "assigned_to_role"
        case delegatedToId = "delegated_to_id"
        case deadline
        case priority
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct TeamMember: Identifiable, Codable {
    var id: UUID
    var teamId: UUID
    var userId: UUID
    var institutionNumber: String
    var joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case userId = "user_id"
        case institutionNumber = "institution_number"
        case joinedAt = "joined_at"
    }
}
