//
//  User.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/16/26.
//

import Foundation

public enum UserStatus: String, Codable {
    case active
    case blocked
    case inactive
}

public struct User: Identifiable, Codable {
    public var id: UUID
    public var email: String
    public var name: String
    public var instituteId: UUID?
    public var role: AppRole
    public var clubId: UUID?
    public var profileImg: String?
    public var phoneNumber: String?
    public var course: String?
    public var year: String?
    public var bio: String?
    public var admissionNumber: String?
    public var createdAt: Date
    public var status: UserStatus
    public var imageData: Data? = nil

    public enum CodingKeys: String, CodingKey {
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
        case admissionNumber = "admission_number"
        case createdAt = "created_at"
        case status
    }

    public init(
        id: UUID,
        email: String,
        name: String,
        instituteId: UUID? = nil,
        role: AppRole,
        clubId: UUID? = nil,
        profileImg: String? = nil,
        phoneNumber: String? = nil,
        course: String? = nil,
        year: String? = nil,
        bio: String? = nil,
        admissionNumber: String? = nil,
        createdAt: Date,
        status: UserStatus,
        imageData: Data? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.instituteId = instituteId
        self.role = role
        self.clubId = clubId
        self.profileImg = profileImg
        self.phoneNumber = phoneNumber
        self.course = course
        self.year = year
        self.bio = bio
        self.admissionNumber = admissionNumber
        self.createdAt = createdAt
        self.status = status
        self.imageData = imageData
    }

}
