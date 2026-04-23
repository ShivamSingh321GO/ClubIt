//
//  Event.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//

import Foundation

enum RegistrationType: String, Codable {
    case individual = "Individual Registration"
    case team = "Team Registration"
}

enum EventStatus: String, Codable {
    case upcoming
    case ongoing
    case completed
    case cancelled
    case pending
    case pastEvent
}

enum EventCategory: String, CaseIterable, Codable {
    case workshop = "Workshop"
    case technical = "Technical"
    case entertainment = "Entertainment"
    case sports = "Sports"
    case ai = "AI"
    case wellness = "Wellness"
    case literary = "Literary"
    case entrepreneurship = "Entrepreneurship"
}



struct Event: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    
    var name: String
    var title: String
    var description: String
    
    var startDate: Date
    var endDate: Date
    
    var startTime: Date
    var endTime: Date
    
    var numberOfVolunteers: Int
    var numberOfRegistrations: Int
    var maxParticipants: Int
    
    var registrationType: RegistrationType
    var location: String
    
    var clubId: UUID
    var createdBy: UUID
    
    var category: EventCategory
    var status: EventStatus
    
    var registrationDeadline: Date
    var bannerImage: String?
    var imageData: Data?
    var agenda: String?
    
    var createdAt: Date
}



struct EventApproval: Identifiable, Codable {
    var id: UUID = UUID()
    
    var eventId: UUID
    var approvedBy: UUID
    var requestedBy: UUID
    
    var approvalType: ApprovalType
    var status: ApprovalStatus
    
    var remark: String?
    
    var createdAt: Date
    var approvedAt: Date?
}


enum ResourceType: String, Codable {
    case university
    case external
}

enum ResourceStatus: String, Codable {
    case pending
    case approved
    case rejected
    case issued
    case returned
}


struct Resource: Identifiable, Codable {
    var id: UUID = UUID()
    
    var eventId: UUID
    
    var name: String
    var quantity: Int
    
    var type: ResourceType
    var status: ResourceStatus
    
    var cost: Double?          // external only
    var vendorName: String?    // external only
    
    var issuedAt: Date?        // university
    var returnedAt: Date?      // university
    
    var addedBy: UUID
    
    var remark: String?
    var createdAt: Date
    var approvedAt: Date?
}


enum VenueType: String, Codable {
    case classroom
    case auditorium
    case library
    case ground
    case lab
    case cafeteria
}

enum VenueAvailabilityStatus: String, Codable {
    case available
    case booked
    case underMaintenance
}



struct Venue: Identifiable, Codable {
    var id: UUID = UUID()
    
    var instituteId: UUID
    var name: String
    var location: String
    var capacity: Int
    
    var type: VenueType
    var availabilityStatus: VenueAvailabilityStatus
    
    var createdAt: Date
}

struct BookedSlot: Identifiable {
    var id: UUID { event.id }
    let event: Event
    let club: Club?
}
