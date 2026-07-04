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
    public var subgroupId: UUID?
    public var profileImg: String?
    public var phoneNumber: String?
    public var course: String?
    public var year: String?
    public var bio: String?
    public var admissionNumber: String?
    public var createdAt: Date
    public var status: UserStatus
    public var organizationId: UUID?
    public var imageData: Data? = nil

    public enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case instituteId = "institute_id"
        case role
        case subgroupId = "subgroup_id"
        case profileImg = "profile_img"
        case phoneNumber = "phone_number"
        case course
        case year
        case bio
        case admissionNumber = "admission_number"
        case createdAt = "created_at"
        case status
        case organizationId = "organization_id"
    }

    public init(
        id: UUID,
        email: String,
        name: String,
        instituteId: UUID? = nil,
        role: AppRole,
        subgroupId: UUID? = nil,
        profileImg: String? = nil,
        phoneNumber: String? = nil,
        course: String? = nil,
        year: String? = nil,
        bio: String? = nil,
        admissionNumber: String? = nil,
        createdAt: Date,
        status: UserStatus,
        organizationId: UUID? = nil,
        imageData: Data? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.instituteId = instituteId
        self.role = role
        self.subgroupId = subgroupId
        self.profileImg = profileImg
        self.phoneNumber = phoneNumber
        self.course = course
        self.year = year
        self.bio = bio
        self.admissionNumber = admissionNumber
        self.createdAt = createdAt
        self.status = status
        self.organizationId = organizationId
        self.imageData = imageData
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decode(String.self, forKey: .name)
        instituteId = try? container.decode(UUID.self, forKey: .instituteId)
        role = (try? container.decode(AppRole.self, forKey: .role)) ?? .guest
        subgroupId = try? container.decode(UUID.self, forKey: .subgroupId)
        profileImg = try? container.decode(String.self, forKey: .profileImg)
        phoneNumber = try? container.decode(String.self, forKey: .phoneNumber)
        course = try? container.decode(String.self, forKey: .course)
        year = try? container.decode(String.self, forKey: .year)
        bio = try? container.decode(String.self, forKey: .bio)
        admissionNumber = try? container.decode(String.self, forKey: .admissionNumber)
        createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
        status = (try? container.decode(UserStatus.self, forKey: .status)) ?? .active
        organizationId = try? container.decode(UUID.self, forKey: .organizationId)
        imageData = nil
    }
}
