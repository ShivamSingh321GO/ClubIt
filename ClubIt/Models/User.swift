//
//  User.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/16/26.
//

import Foundation

enum UserStatus: String, Codable {
    case active
    case blocked
    case inactive
}

struct User: Identifiable, Codable {
    var id: UUID
    var email: String
    var name: String
    var instituteId: UUID?
    var role: AppRole
    var clubId: UUID?
    var profileImg: String?
    var phoneNumber: String?
    var course: String?
    var year: String?
    var bio: String?
    var createdAt: Date
    var status: UserStatus
    var imageData: Data? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case instituteId = "institute_id"
        case role
        case clubId = "club_id"
        case profileImg = "profile_img"
        case phoneNumber = "phone_number"
        case course
        case year
        case bio
        case createdAt = "created_at"
        case status
    }
}
