//
//  Institution.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//

import Foundation

public enum InstitutionStatus: String, Codable {
    case active
    case inactive
    case suspended
}

public struct Institution: Identifiable, Codable {
    public var id = UUID()
    public var name: String
    public var email: String
    public var domain: String?
    public var logo: String?
    public var subscriptionPlanId: UUID
    public var status: InstitutionStatus
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        email: String,
        domain: String? = nil,
        logo: String? = nil,
        subscriptionPlanId: UUID,
        status: InstitutionStatus,
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.domain = domain
        self.logo = logo
        self.subscriptionPlanId = subscriptionPlanId
        self.status = status
        self.createdAt = createdAt
    }

}
