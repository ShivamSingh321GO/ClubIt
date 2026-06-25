//
//  EventRegistration.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/19/26.
//

import Foundation



public enum RegistrationStatus: String, Codable {
    case pending
    case confirmed
    case cancelled
}

public struct IndividualRegistration: Identifiable, Codable {
    public var id: UUID
    public var eventId: UUID?
    public var userId: UUID?
    public var status: RegistrationStatus?
    public var answers: [String: String]?
    public var createdAt: Date

    public enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case userId = "user_id"
        case status
        case answers
        case createdAt = "created_at"
    }

    public init(
        id: UUID,
        eventId: UUID? = nil,
        userId: UUID? = nil,
        status: RegistrationStatus? = nil,
        answers: [String: String]? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.eventId = eventId
        self.userId = userId
        self.status = status
        self.answers = answers
        self.createdAt = createdAt
    }

}


public enum EventRole: String, Codable {
    case organizer
    case coordinator
    case volunteer
    case judge
    case host
}

public enum AssignmentStatus: String, Codable {
    case assigned
    case inProgress
    case completed
    case cancelled
}

public struct EventRoleAssignment: Identifiable, Codable {
    public var id: UUID
    
    public var eventId: UUID
    public var role: EventRole
    
    public var assignedTo: UUID      // ClubMember ID
    public var assignedBy: UUID      // User ID
    
    public var assignedAt: Date
    public var status: AssignmentStatus
    
    public var createdAt: Date

    public init(
        id: UUID,
        eventId: UUID,
        role: EventRole,
        assignedTo: UUID,
        assignedBy: UUID,
        assignedAt: Date,
        status: AssignmentStatus,
        createdAt: Date
    ) {
        self.id = id
        self.eventId = eventId
        self.role = role
        self.assignedTo = assignedTo
        self.assignedBy = assignedBy
        self.assignedAt = assignedAt
        self.status = status
        self.createdAt = createdAt
    }

}



public struct RegistrationAnswer: Identifiable, Codable {
    public var id: UUID
    public var questionId: UUID
    public var userId: UUID
    public var answer: String
    public var createdAt: Date

    public init(id: UUID, questionId: UUID, userId: UUID, answer: String, createdAt: Date) {
        self.id = id
        self.questionId = questionId
        self.userId = userId
        self.answer = answer
        self.createdAt = createdAt
    }

}

