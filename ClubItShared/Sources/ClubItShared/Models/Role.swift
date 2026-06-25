//
//  Role.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//

import Foundation


public struct Role: Identifiable, Codable {
    public var id: UUID
    public var name: String
    public var description: String
    public var createdAt: Date

    public init(id: UUID, name: String, description: String, createdAt: Date) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
    }

}
