//
//  Institution.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//

import Foundation

enum InstitutionStatus: String, Codable {
    case active
    case inactive
    case suspended
}

struct Institution: Identifiable, Codable {
    var id = UUID()
    var name: String
    var email: String
    var domain: String?
    var logo: String?
    var subscriptionPlanId: UUID
    var status: InstitutionStatus
    var createdAt: Date
}
