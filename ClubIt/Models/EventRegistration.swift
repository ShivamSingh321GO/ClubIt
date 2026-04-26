//
//  EventRegistration.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/19/26.
//

import Foundation



enum RegistrationStatus: String, Codable {
    case pending
    case confirmed
    case cancelled
}

struct IndividualRegistration: Identifiable, Codable {
    var id: UUID
    var eventId: UUID
    var userId: UUID
    var status: RegistrationStatus
    var registeredAt: Date
}


enum EventRole: String, Codable {
    case organizer
    case coordinator
    case volunteer
    case judge
    case host
}

enum AssignmentStatus: String, Codable {
    case assigned
    case inProgress
    case completed
    case cancelled
}

struct EventRoleAssignment: Identifiable, Codable {
    var id: UUID
    
    var eventId: UUID
    var role: EventRole
    
    var assignedTo: UUID      // ClubMember ID
    var assignedBy: UUID      // User ID
    
    var assignedAt: Date
    var status: AssignmentStatus
    
    var createdAt: Date
}



struct RegistrationAnswer: Identifiable, Codable {
    var id: UUID
    var questionId: UUID
    var userId: UUID
    var answer: String
    var createdAt: Date
}

