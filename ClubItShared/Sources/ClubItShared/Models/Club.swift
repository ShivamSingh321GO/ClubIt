//
//  Club.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//


import Foundation


public enum ClubStatus: String, Codable {
    case active
    case inactive
}

public enum ClubCategory: String, Codable, CaseIterable {
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

public struct Club: Identifiable, Hashable, Codable {
    public var id: UUID
    public var name: String
    public var tagLine: String?
    public var description: String?
    public var category: ClubCategory
    public var logo: String
    public var clubLeadId: UUID
    public var facultyId: UUID
    public var vicePresidentId: UUID?
    public var instituteId: UUID
    public var status: ClubStatus
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
        case clubLeadId = "club_lead_id"
        case facultyId = "faculty_id"
        case vicePresidentId = "vice_president_id"
        case instituteId = "institute_id"
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
        category: ClubCategory,
        logo: String,
        clubLeadId: UUID,
        facultyId: UUID,
        vicePresidentId: UUID? = nil,
        instituteId: UUID,
        status: ClubStatus,
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
        self.clubLeadId = clubLeadId
        self.facultyId = facultyId
        self.vicePresidentId = vicePresidentId
        self.instituteId = instituteId
        self.status = status
        self.createdAt = createdAt
        self.memberCount = memberCount
        self.eventCount = eventCount
        self.socials = socials
        self.imageData = imageData
    }

}

public struct ClubFollower: Identifiable, Codable {
    public var id: UUID
    public var clubId: UUID
    public var userId: UUID
    public var followedAt: Date

    public enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case userId = "user_id"
        case followedAt = "followed_at"
    }

    public init(id: UUID, clubId: UUID, userId: UUID, followedAt: Date) {
        self.id = id
        self.clubId = clubId
        self.userId = userId
        self.followedAt = followedAt
    }

}


public enum ClubRole: String, Codable {
    case lead
    case coordinator
    case member
}

public enum ClubMemberStatus: String, Codable {
    case active
    case inactive
}

public struct ClubMember: Identifiable, Codable {
    public var id: UUID
    public var clubId: UUID
    public var userId: UUID
    public var role: ClubRole
    public var status: ClubMemberStatus
    public var joinedAt: Date

    public enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case userId = "user_id"
        case role
        case status
        case joinedAt = "joined_at"
    }

    public init(
        id: UUID,
        clubId: UUID,
        userId: UUID,
        role: ClubRole,
        status: ClubMemberStatus,
        joinedAt: Date
    ) {
        self.id = id
        self.clubId = clubId
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

public struct ClubMembershipRequest: Identifiable, Codable {
    public var id: UUID
    public var clubId: UUID                     // FK → Club
    public var userId: UUID                     // FK → User
    public var requestStatus: RequestStatus     // accepted / rejected / pending
    public var requestedAt: Date
    public var reviewedBy: UUID?                // FK → User (club lead/admin)
    public var reviewedAt: Date?

    public enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case userId = "user_id"
        case requestStatus = "request_status"
        case requestedAt = "requested_at"
        case reviewedBy = "reviewed_by"
        case reviewedAt = "reviewed_at"
    }

    public init(
        id: UUID,
        clubId: UUID,
        userId: UUID,
        requestStatus: RequestStatus,
        requestedAt: Date,
        reviewedBy: UUID? = nil,
        reviewedAt: Date? = nil
    ) {
        self.id = id
        self.clubId = clubId
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

public struct ClubSocialLink: Identifiable, Codable {
    public var id: UUID
    public var clubId: UUID
    public var platform: SocialPlatform
    public var url: String

    public init(id: UUID, clubId: UUID, platform: SocialPlatform, url: String) {
        self.id = id
        self.clubId = clubId
        self.platform = platform
        self.url = url
    }

}



