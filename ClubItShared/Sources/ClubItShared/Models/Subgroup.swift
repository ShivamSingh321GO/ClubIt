//
//  Subgroup.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//


import Foundation


public enum SubgroupStatus: String, Codable {
    case active
    case inactive
}

public enum SubgroupCategory: String, Codable, CaseIterable {
    case technical = "Technical"
    case cultural = "Cultural"
    case sports = "Sports"
    case music = "Music"
    case dance = "Dance"
    case photography = "Photography"
    case literary = "Literary"
    case entrepreneurship = "Entrepreneurship"
    case ai = "AI"
    case wellness = "Wellness"
    
    public var displayName: String {
        self.rawValue.capitalized
    }
}

public struct Subgroup: Identifiable, Hashable, Codable {
    public var id: UUID
    public var name: String
    public var tagLine: String?
    public var description: String?
    public var category: SubgroupCategory
    public var logo: String
    public var subgroupLeadId: UUID
    public var facultyId: UUID
    public var vicePresidentId: UUID?
    public var instituteId: UUID
    public var groupId: UUID
    public var status: SubgroupStatus
    public var createdAt: Date
    
    // Stats and Socials
    public var memberCount: Int? = 0
    public var eventCount: Int? = 0
    public var socials: [String: String]? = [:]
    public var imageData: Data? = nil

    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case tagLine = "tag_line"
        case description
        case category
        case logo
        case subgroupLeadId = "subgroup_lead_id"
        case facultyId = "faculty_id"
        case vicePresidentId = "vice_president_id"
        case instituteId = "institute_id"
        case groupId = "group_id"
        case status
        case createdAt = "created_at"
        case memberCount = "member_count"
        case eventCount = "event_count"
        case socials
    }

    public init(
        id: UUID,
        name: String,
        tagLine: String? = nil,
        description: String? = nil,
        category: SubgroupCategory,
        logo: String,
        subgroupLeadId: UUID,
        facultyId: UUID,
        vicePresidentId: UUID? = nil,
        instituteId: UUID,
        groupId: UUID = UUID(),
        status: SubgroupStatus,
        createdAt: Date,
        memberCount: Int? = 0,
        eventCount: Int? = 0,
        socials: [String: String]? = [:],
        imageData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.tagLine = tagLine
        self.description = description
        self.category = category
        self.logo = logo
        self.subgroupLeadId = subgroupLeadId
        self.facultyId = facultyId
        self.vicePresidentId = vicePresidentId
        self.instituteId = instituteId
        self.groupId = groupId
        self.status = status
        self.createdAt = createdAt
        self.memberCount = memberCount
        self.eventCount = eventCount
        self.socials = socials
        self.imageData = imageData
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // id
        self.id = try container.decode(UUID.self, forKey: .id)
        
        // name
        self.name = try container.decode(String.self, forKey: .name)
        
        // tagLine (check both "tag_line" and "tagline")
        if let directTag = try? container.decode(String.self, forKey: .tagLine) {
            self.tagLine = directTag
        } else {
            struct TaglineDecoderKey: CodingKey {
                var stringValue: String
                init?(stringValue: String) { self.stringValue = stringValue }
                var intValue: Int? { nil }
                init?(intValue: Int) { nil }
            }
            let key = TaglineDecoderKey(stringValue: "tagline")!
            let dynamicContainer = try decoder.container(keyedBy: TaglineDecoderKey.self)
            self.tagLine = try? dynamicContainer.decode(String.self, forKey: key)
        }
        
        // description
        self.description = try? container.decode(String.self, forKey: .description)
        
        // category (flexible case-insensitive decoding)
        if let catEnum = try? container.decode(SubgroupCategory.self, forKey: .category) {
            self.category = catEnum
        } else if let catString = try? container.decode(String.self, forKey: .category) {
            switch catString.lowercased() {
            case "tech", "technical": self.category = .technical
            case "cultural": self.category = .cultural
            case "sports": self.category = .sports
            case "music": self.category = .music
            case "dance": self.category = .dance
            case "photography": self.category = .photography
            case "literary", "literature": self.category = .literary
            case "entrepreneurship": self.category = .entrepreneurship
            case "ai": self.category = .ai
            case "wellness": self.category = .wellness
            default: self.category = .technical
            }
        } else {
            self.category = .technical
        }
        
        // logo / logo_url
        if let directLogo = try? container.decode(String.self, forKey: .logo) {
            self.logo = directLogo
        } else {
            struct LogoUrlDecoderKey: CodingKey {
                var stringValue: String
                init?(stringValue: String) { self.stringValue = stringValue }
                var intValue: Int? { nil }
                init?(intValue: Int) { nil }
            }
            let key = LogoUrlDecoderKey(stringValue: "logo_url")!
            let dynamicContainer = try decoder.container(keyedBy: LogoUrlDecoderKey.self)
            self.logo = (try? dynamicContainer.decode(String.self, forKey: key)) ?? ""
        }
        
        // subgroupLeadId
        self.subgroupLeadId = (try? container.decode(UUID.self, forKey: .subgroupLeadId)) ?? UUID()
        
        // facultyId
        self.facultyId = (try? container.decode(UUID.self, forKey: .facultyId)) ?? UUID()
        
        // vicePresidentId
        self.vicePresidentId = try? container.decode(UUID.self, forKey: .vicePresidentId)
        
        // instituteId
        self.instituteId = (try? container.decode(UUID.self, forKey: .instituteId)) ?? UUID()
        
        // groupId
        if let gid = try? container.decode(UUID.self, forKey: .groupId) {
            self.groupId = gid
        } else {
            struct GroupIdDecoderKey: CodingKey {
                var stringValue: String
                init?(stringValue: String) { self.stringValue = stringValue }
                var intValue: Int? { nil }
                init?(intValue: Int) { nil }
            }
            let key = GroupIdDecoderKey(stringValue: "group_id")!
            let dynamicContainer = try decoder.container(keyedBy: GroupIdDecoderKey.self)
            self.groupId = (try? dynamicContainer.decode(UUID.self, forKey: key)) ?? UUID()
        }
        
        // status
        self.status = (try? container.decode(SubgroupStatus.self, forKey: .status)) ?? .active
        
        // createdAt
        self.createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
        
        // memberCount
        self.memberCount = (try? container.decode(Int.self, forKey: .memberCount)) ?? 0
        
        // eventCount
        self.eventCount = (try? container.decode(Int.self, forKey: .eventCount)) ?? 0
        
        // socials
        self.socials = (try? container.decode([String: String].self, forKey: .socials)) ?? [:]
        
        self.imageData = nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(tagLine, forKey: .tagLine)
        try container.encode(description, forKey: .description)
        try container.encode(category, forKey: .category)
        try container.encode(logo, forKey: .logo)
        try container.encode(subgroupLeadId, forKey: .subgroupLeadId)
        try container.encode(vicePresidentId, forKey: .vicePresidentId)
        try container.encode(instituteId, forKey: .instituteId)
        try container.encode(groupId, forKey: .groupId)
        try container.encode(status, forKey: .status)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(memberCount, forKey: .memberCount)
        try container.encode(eventCount, forKey: .eventCount)
        try container.encode(socials, forKey: .socials)
    }
}

public struct SubgroupFollower: Identifiable, Codable {
    public var id: UUID
    public var subgroupId: UUID
    public var userId: UUID
    public var followedAt: Date

    public enum CodingKeys: String, CodingKey {
        case id
        case subgroupId = "subgroup_id"
        case userId = "user_id"
        case followedAt = "followed_at"
    }

    public init(id: UUID, subgroupId: UUID, userId: UUID, followedAt: Date) {
        self.id = id
        self.subgroupId = subgroupId
        self.userId = userId
        self.followedAt = followedAt
    }

}


public enum SubgroupRole: String, Codable {
    case lead
    case coordinator
    case member
}

public enum SubgroupMemberStatus: String, Codable {
    case active
    case inactive
}

public struct SubgroupMember: Identifiable, Codable {
    public var id: UUID
    public var subgroupId: UUID
    public var userId: UUID
    public var role: SubgroupRole
    public var status: SubgroupMemberStatus
    public var joinedAt: Date

    public enum CodingKeys: String, CodingKey {
        case id
        case subgroupId = "subgroup_id"
        case userId = "user_id"
        case role
        case status
        case joinedAt = "joined_at"
    }

    public init(
        id: UUID,
        subgroupId: UUID,
        userId: UUID,
        role: SubgroupRole,
        status: SubgroupMemberStatus,
        joinedAt: Date
    ) {
        self.id = id
        self.subgroupId = subgroupId
        self.userId = userId
        self.role = role
        self.status = status
        self.joinedAt = joinedAt
    }

}


public enum RequestStatus: String, Codable {
    case pending
    case accepted
    case rejected
}

public struct SubgroupMembershipRequest: Identifiable, Codable {
    public var id: UUID
    public var subgroupId: UUID                     // FK → Subgroup
    public var userId: UUID                     // FK → User
    public var requestStatus: RequestStatus     // accepted / rejected / pending
    public var requestedAt: Date
    public var reviewedBy: UUID?                // FK → User (subgroup lead/admin)
    public var reviewedAt: Date?

    public enum CodingKeys: String, CodingKey {
        case id
        case subgroupId = "subgroup_id"
        case userId = "user_id"
        case requestStatus = "request_status"
        case requestedAt = "requested_at"
        case reviewedBy = "reviewed_by"
        case reviewedAt = "reviewed_at"
    }

    public init(
        id: UUID,
        subgroupId: UUID,
        userId: UUID,
        requestStatus: RequestStatus,
        requestedAt: Date,
        reviewedBy: UUID? = nil,
        reviewedAt: Date? = nil
    ) {
        self.id = id
        self.subgroupId = subgroupId
        self.userId = userId
        self.requestStatus = requestStatus
        self.requestedAt = requestedAt
        self.reviewedBy = reviewedBy
        self.reviewedAt = reviewedAt
    }

}

public enum SocialPlatform: String, Codable {
    case facebook
    case instagram
    case linkedin
    case whatsapp
    case discord
    case website
}

public struct SubgroupSocialLink: Identifiable, Codable {
    public var id: UUID
    public var subgroupId: UUID
    public var platform: SocialPlatform
    public var url: String

    public init(id: UUID, subgroupId: UUID, platform: SocialPlatform, url: String) {
        self.id = id
        self.subgroupId = subgroupId
        self.platform = platform
        self.url = url
    }

}



