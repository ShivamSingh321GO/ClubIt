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
    var id = UUID()
    var email: String
    var password: String
    var name: String
    var instituteId: UUID
    var role: AppRole
    var clubId: UUID?
    var profileImg: String
    var phoneNumber: String
    var course: String
    var year: String
    var bio: String
    var createdAt: Date
    var status: UserStatus
}
