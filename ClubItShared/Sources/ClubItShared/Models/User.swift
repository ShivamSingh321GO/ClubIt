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
    public var groupId: UUID?
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
        case groupId = "group_id"
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
        groupId: UUID? = nil,
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
        self.groupId = groupId
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
        let userId = try container.decode(UUID.self, forKey: .id)
        id = userId
        email = try container.decode(String.self, forKey: .email)
        name = try container.decode(String.self, forKey: .name)
        instituteId = try? container.decode(UUID.self, forKey: .instituteId)
        role = (try? container.decode(AppRole.self, forKey: .role)) ?? .guest
        subgroupId = try? container.decode(UUID.self, forKey: .subgroupId)
        groupId = try? container.decode(UUID.self, forKey: .groupId)
        profileImg = try? container.decode(String.self, forKey: .profileImg)
        
        let rawPhone = try? container.decode(String.self, forKey: .phoneNumber)
        phoneNumber = UserEncryptionManager.shared.decrypt(rawPhone, for: userId)
        
        course = try? container.decode(String.self, forKey: .course)
        year = try? container.decode(String.self, forKey: .year)
        bio = try? container.decode(String.self, forKey: .bio)
        
        let rawAdmission = try? container.decode(String.self, forKey: .admissionNumber)
        admissionNumber = UserEncryptionManager.shared.decrypt(rawAdmission, for: userId)
        
        createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
        status = (try? container.decode(UserStatus.self, forKey: .status)) ?? .active
        organizationId = try? container.decode(UUID.self, forKey: .organizationId)
        imageData = nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(instituteId, forKey: .instituteId)
        try container.encode(role, forKey: .role)
        try container.encodeIfPresent(subgroupId, forKey: .subgroupId)
        try container.encodeIfPresent(groupId, forKey: .groupId)
        try container.encodeIfPresent(profileImg, forKey: .profileImg)

        let encryptedPhone = UserEncryptionManager.shared.encrypt(phoneNumber, for: id)
        try container.encodeIfPresent(encryptedPhone, forKey: .phoneNumber)

        try container.encodeIfPresent(course, forKey: .course)
        try container.encodeIfPresent(year, forKey: .year)
        try container.encodeIfPresent(bio, forKey: .bio)

        let encryptedAdmission = UserEncryptionManager.shared.encrypt(admissionNumber, for: id)
        try container.encodeIfPresent(encryptedAdmission, forKey: .admissionNumber)

        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(organizationId, forKey: .organizationId)
    }
}
