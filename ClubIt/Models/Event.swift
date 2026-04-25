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
    case published
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



enum FormFieldType: String, Codable, CaseIterable {
    case text = "Short Answer"
    case paragraph = "Paragraph"
    case multipleChoice = "Multiple Choice"
    case checkbox = "Checkbox"
    case dropdown = "Dropdown"
    
    var icon: String {
        switch self {
        case .text: return "text.alignleft"
        case .paragraph: return "text.justify.left"
        case .multipleChoice: return "list.bullet.circle"
        case .checkbox: return "checkmark.square"
        case .dropdown: return "chevron.down.circle"
        }
    }
}

struct RegistrationFormField: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var label: String = ""
    var type: FormFieldType = .text
    var options: [String]? // For multiple choice, checkbox, dropdown
    var isRequired: Bool = true
    var placeholder: String = ""
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
    
    var registrationForm: [RegistrationFormField]? = nil
    
    var createdAt: Date
}



struct EventApproval: Identifiable, Codable {
    var id: UUID
    
    var eventId: UUID
    var approvedBy: UUID
    var requestedBy: UUID
    
    var approvalType: ApprovalType
    var status: ApprovalStatus
    
    var remarks: [Remark]
    
    var createdAt: Date
    var approvedAt: Date?

    init(id: UUID = UUID(), eventId: UUID, approvedBy: UUID, requestedBy: UUID, approvalType: ApprovalType, status: ApprovalStatus, remarks: [Remark] = [], createdAt: Date, approvedAt: Date? = nil) {
        self.id = id
        self.eventId = eventId
        self.approvedBy = approvedBy
        self.requestedBy = requestedBy
        self.approvalType = approvalType
        self.status = status
        self.remarks = remarks
        self.createdAt = createdAt
        self.approvedAt = approvedAt
    }
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
    var id: UUID
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
    
    var remarks: [Remark]
    var createdAt: Date
    var approvedAt: Date?

    init(id: UUID = UUID(), eventId: UUID, name: String, quantity: Int, type: ResourceType, status: ResourceStatus, cost: Double? = nil, vendorName: String? = nil, issuedAt: Date? = nil, returnedAt: Date? = nil, addedBy: UUID, remarks: [Remark] = [], createdAt: Date, approvedAt: Date? = nil) {
        self.id = id
        self.eventId = eventId
        self.name = name
        self.quantity = quantity
        self.type = type
        self.status = status
        self.cost = cost
        self.vendorName = vendorName
        self.issuedAt = issuedAt
        self.returnedAt = returnedAt
        self.addedBy = addedBy
        self.remarks = remarks
        self.createdAt = createdAt
        self.approvedAt = approvedAt
    }
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
