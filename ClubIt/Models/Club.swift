//
//  Club.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//


import Foundation


enum ClubStatus: String, Codable {
    case active
    case inactive
}

enum ClubCategory: String, Codable, CaseIterable {
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
}

struct Club: Identifiable, Hashable, Codable {
    var id: UUID
    var name: String
    var tagLine: String?
    var description: String?
    var category: ClubCategory
    var logo: String
    var clubLeadId: UUID
    var facultyId: UUID
    var vicePresidentId: UUID?
    var instituteId: UUID
    var status: ClubStatus
    var createdAt: Date
    
    // Stats and Socials
    var memberCount: Int?
    var eventCount: Int?
    var socials: [String: String]?
    var imageData: Data?

    enum CodingKeys: String, CodingKey {
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
}

struct ClubFollower: Identifiable, Codable {
    var id: UUID
    var clubId: UUID
    var userId: UUID
    var followedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case userId = "user_id"
        case followedAt = "followed_at"
    }
}


enum ClubRole: String, Codable {
    case lead
    case coordinator
    case member
}

enum ClubMemberStatus: String, Codable {
    case active
    case inactive
}

struct ClubMember: Identifiable, Codable {
    var id: UUID
    var clubId: UUID
    var userId: UUID
    var role: ClubRole
    var status: ClubMemberStatus
    var joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case userId = "user_id"
        case role
        case status
        case joinedAt = "joined_at"
    }
}


enum RequestStatus: String, Codable {
    case pending
    case accepted
    case rejected
}

struct ClubMembershipRequest: Identifiable, Codable {
    var id: UUID
    var clubId: UUID                     // FK → Club
    var userId: UUID                     // FK → User
    var requestStatus: RequestStatus     // accepted / rejected / pending
    var requestedAt: Date
    var reviewedBy: UUID?                // FK → User (club lead/admin)
    var reviewedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case userId = "user_id"
        case requestStatus = "request_status"
        case requestedAt = "requested_at"
        case reviewedBy = "reviewed_by"
        case reviewedAt = "reviewed_at"
    }
}

enum SocialPlatform: String, Codable {
    case facebook
    case instagram
    case linkedin
    case whatsapp
    case discord
    case website
}

struct ClubSocialLink: Identifiable, Codable {
    var id: UUID
    var clubId: UUID
    var platform: SocialPlatform
    var url: String
}



