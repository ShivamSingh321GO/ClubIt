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
    case technical
    case cultural
    case sports
    case music
    case dance
    case photography
    case literary
    case entrepreneurship
    case ai
    case wellness
}

struct Club: Identifiable, Hashable ,Codable {
    var id = UUID()
    var name: String
    var tagLine: String
    var description: String
    var category: ClubCategory
    var logo: String
    var clubLeadId: UUID
    var facultyId: UUID
    var vicePresidentId: UUID
    var instituteId: UUID
    var status: ClubStatus
    var createdAt: Date
    
    // Stats and Socials
    var memberCount: Int
    var eventCount: Int
    var socials: [String: String]
}

struct ClubFollower: Identifiable, Codable {
    var id = UUID()
    var clubId: UUID
    var userId: UUID
    var followedAt: Date
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
    var id = UUID()
    var clubId: UUID
    var userId: UUID
    var role: ClubRole
    var status: ClubMemberStatus
    var joinedAt: Date
    
}


enum RequestStatus: String, Codable {
    case pending
    case accepted
    case rejected
}

struct ClubMembershipRequest: Identifiable, Codable {
    
    var id = UUID()
    
    var clubId: UUID                     // FK → Club
    var userId: UUID                     // FK → User
    
    var requestStatus: RequestStatus     // accepted / rejected / pending
    
    var requestedAt: Date
    
    var reviewedBy: UUID?                // FK → User (club lead/admin)
    var reviewedAt: Date?
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
    var id = UUID()
    
    var clubId: UUID
    var platform: SocialPlatform
    var url: String
}



