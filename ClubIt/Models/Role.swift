//
//  Role.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//

import Foundation


struct Role: Identifiable, Codable {
    var id: UUID
    var name: String
    var description: String
    var createdAt: Date
}
