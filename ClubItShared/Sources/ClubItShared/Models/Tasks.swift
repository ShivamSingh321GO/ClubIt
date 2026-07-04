//
//  Task.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//

import Foundation




public enum TaskPriority: String, Codable, CaseIterable {
    case low
    case high
}

public enum TaskStatus: String, Codable, CaseIterable {
    case pending
    case inProgress
    case completed
}

public struct Tasks: Identifiable, Codable {
    public var id: UUID
    public var subgroupId: UUID
    public var targetSubgroupId: UUID? = nil // For cross-subgroup tasks
    public var eventId: UUID? = nil
    public var title: String
    public var description: String
    public var assignedBy: UUID
    public var assignedByRole: AppRole
    public var assignedTo: UUID
    public var assignedToRole: AppRole
    public var delegatedToId: UUID? = nil // For delegation to members
    public var deadline: Date
    public var priority: TaskPriority
    public var status: TaskStatus
    public var createdAt: Date
    public var updatedAt: Date?

    public enum CodingKeys: String, CodingKey {
        case id
        case subgroupId = "subgroup_id"
        case targetSubgroupId = "target_subgroup_id"
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

    public init(
        id: UUID,
        subgroupId: UUID,
        targetSubgroupId: UUID? = nil,
        eventId: UUID? = nil,
        title: String,
        description: String,
        assignedBy: UUID,
        assignedByRole: AppRole,
        assignedTo: UUID,
        assignedToRole: AppRole,
        delegatedToId: UUID? = nil,
        deadline: Date,
        priority: TaskPriority,
        status: TaskStatus,
        createdAt: Date,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.subgroupId = subgroupId
        self.targetSubgroupId = targetSubgroupId
        self.eventId = eventId
        self.title = title
        self.description = description
        self.assignedBy = assignedBy
        self.assignedByRole = assignedByRole
        self.assignedTo = assignedTo
        self.assignedToRole = assignedToRole
        self.delegatedToId = delegatedToId
        self.deadline = deadline
        self.priority = priority
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

}

public struct TeamMember: Identifiable, Codable {
    public var id: UUID
    public var teamId: UUID
    public var userId: UUID
    public var institutionNumber: String
    public var joinedAt: Date

    public enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case userId = "user_id"
        case institutionNumber = "institution_number"
        case joinedAt = "joined_at"
    }

    public init(id: UUID, teamId: UUID, userId: UUID, institutionNumber: String, joinedAt: Date) {
        self.id = id
        self.teamId = teamId
        self.userId = userId
        self.institutionNumber = institutionNumber
        self.joinedAt = joinedAt
    }

}
