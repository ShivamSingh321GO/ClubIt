//
//  Event.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//

import Foundation

enum RegistrationType: String, Codable {
    case individual
    case team
    
    var displayName: String {
        switch self {
        case .individual: return "Individual Registration"
        case .team: return "Team Registration"
        }
    }
}

enum EventStatus: String, Codable {
    case pending
    case approved
    case published
}

enum EventCategory: String, CaseIterable, Codable {
    case workshop
    case technical
    case entertainment
    case sports
    case ai
    case wellness
    case literary
    case entrepreneurship
    
    var displayName: String {
        self.rawValue.capitalized
    }
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
    var id: UUID
    var label: String = ""
    var type: FormFieldType = .text
    var options: [String]? // For multiple choice, checkbox, dropdown
    var isRequired: Bool? = true
    var placeholder: String? = ""
    
    enum CodingKeys: String, CodingKey {
        case id, label, type, options
        case isRequired = "is_required"
        case placeholder
    }
}

struct Event: Identifiable, Hashable, Codable {
    var id: UUID
    
    var name: String
    var title: String
    var description: String
    
    var startDate: Date
    var endDate: Date
    
    var startTime: Date? = nil
    var endTime: Date? = nil
    
    var numberOfVolunteers: Int
    var numberOfRegistrations: Int?
    var maxParticipants: Int
    
    var registrationType: RegistrationType?
    var location: String
    
    var clubId: UUID
    var createdBy: UUID
    
    var category: EventCategory
    var status: EventStatus
    
    var registrationDeadline: Date?
    var bannerImage: String?
    var imageData: Data? = nil
    var agenda: String?
    
    var registrationForm: [RegistrationFormField]? = nil
    
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case title
        case description
        case startDate = "start_date"
        case endDate = "end_date"
        case startTime = "start_time"
        case endTime = "end_time"
        case numberOfVolunteers = "number_of_volunteers"
        case numberOfRegistrations = "number_of_registrations"
        case maxParticipants = "max_participants"
        case registrationType = "registration_type"
        case location
        case clubId = "club_id"
        case createdBy = "created_by"
        case category
        case status
        case registrationDeadline = "registration_deadline"
        case bannerImage = "banner_image"
        case imageData = "image_data"
        case agenda
        case registrationForm = "registration_form"
        case createdAt = "created_at"
    }

    init(id: UUID, name: String, title: String, description: String, startDate: Date, endDate: Date, startTime: Date? = nil, endTime: Date? = nil, numberOfVolunteers: Int, numberOfRegistrations: Int? = nil, maxParticipants: Int, registrationType: RegistrationType? = nil, location: String, clubId: UUID, createdBy: UUID, category: EventCategory, status: EventStatus, registrationDeadline: Date? = nil, bannerImage: String? = nil, imageData: Data? = nil, agenda: String? = nil, registrationForm: [RegistrationFormField]? = nil, createdAt: Date) {
        self.id = id
        self.name = name
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.startTime = startTime
        self.endTime = endTime
        self.numberOfVolunteers = numberOfVolunteers
        self.numberOfRegistrations = numberOfRegistrations
        self.maxParticipants = maxParticipants
        self.registrationType = registrationType
        self.location = location
        self.clubId = clubId
        self.createdBy = createdBy
        self.category = category
        self.status = status
        self.registrationDeadline = registrationDeadline
        self.bannerImage = bannerImage
        self.imageData = imageData
        self.agenda = agenda
        self.registrationForm = registrationForm
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        title = (try? container.decode(String.self, forKey: .title)) ?? ""
        description = (try? container.decode(String.self, forKey: .description)) ?? ""
        
        // Flexible Date Decoding
        let dateStringDecoder = { (key: CodingKeys) -> Date? in
            guard let str = try? container.decode(String.self, forKey: key) else { return nil }
            return Event.parseDate(str)
        }
        
        startDate = dateStringDecoder(.startDate) ?? Date()
        endDate = dateStringDecoder(.endDate) ?? Date()
        startTime = dateStringDecoder(.startTime)
        endTime = dateStringDecoder(.endTime)
        
        numberOfVolunteers = (try? container.decode(Int.self, forKey: .numberOfVolunteers)) ?? 0
        numberOfRegistrations = try? container.decode(Int.self, forKey: .numberOfRegistrations)
        maxParticipants = (try? container.decode(Int.self, forKey: .maxParticipants)) ?? 0
        registrationType = try? container.decode(RegistrationType.self, forKey: .registrationType)
        location = (try? container.decode(String.self, forKey: .location)) ?? ""
        clubId = try container.decode(UUID.self, forKey: .clubId)
        createdBy = try container.decode(UUID.self, forKey: .createdBy)
        
        // Robust Enum Decoding
        category = (try? container.decode(EventCategory.self, forKey: .category)) ?? .technical
        status = (try? container.decode(EventStatus.self, forKey: .status)) ?? .pending
        
        registrationDeadline = dateStringDecoder(.registrationDeadline)
        bannerImage = try? container.decode(String.self, forKey: .bannerImage)
        imageData = try? container.decode(Data.self, forKey: .imageData)
        agenda = try? container.decode(String.self, forKey: .agenda)
        registrationForm = try? container.decode([RegistrationFormField].self, forKey: .registrationForm)
        createdAt = dateStringDecoder(.createdAt) ?? Date()
    }

    static func parseDate(_ string: String) -> Date? {
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
            "yyyy-MM-dd",
            "HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss"
        ]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }
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

    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case approvedBy = "approved_by"
        case requestedBy = "requested_by"
        case approvalType = "approval_type"
        case status
        case remarks
        case createdAt = "created_at"
        case approvedAt = "approved_at"
    }

    init(id: UUID, eventId: UUID, approvedBy: UUID, requestedBy: UUID, approvalType: ApprovalType, status: ApprovalStatus, remarks: [Remark] = [], createdAt: Date, approvedAt: Date? = nil) {
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
    var eventId: UUID?
    
    var name: String
    var quantity: Int
    
    var type: ResourceType
    var status: ResourceStatus
    
    var cost: Double?          // external only
    var vendorName: String?    // external only
    
    var issuedAt: Date?        // university
    var returnedAt: Date?      // university
    
    var addedBy: UUID?
    
    var remarks: [Remark]
    var createdAt: Date
    var approvedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case name
        case quantity
        case type
        case status
        case cost
        case vendorName = "vendor_name"
        case issuedAt = "issued_at"
        case returnedAt = "returned_at"
        case addedBy = "added_by"
        case remarks
        case createdAt = "created_at"
        case approvedAt = "approved_at"
    }

    init(id: UUID, eventId: UUID?, name: String, quantity: Int, type: ResourceType, status: ResourceStatus, cost: Double? = nil, vendorName: String? = nil, issuedAt: Date? = nil, returnedAt: Date? = nil, addedBy: UUID?, remarks: [Remark] = [], createdAt: Date, approvedAt: Date? = nil) {
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
    var id: UUID
    
    var instituteId: UUID
    var name: String
    var location: String
    var capacity: Int
    
    var type: VenueType
    var availabilityStatus: VenueAvailabilityStatus
    
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case instituteId = "institute_id"
        case name
        case location
        case capacity
        case type
        case availabilityStatus = "availability_status"
        case createdAt = "created_at"
    }
}

struct BookedSlot: Identifiable {
    var id: UUID { event.id }
    let event: Event
    let club: Club?
}
