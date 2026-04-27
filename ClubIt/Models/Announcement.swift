//
//  Announcement.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//

import Foundation


struct Announcement: Identifiable, Codable {
    var id: UUID
    var clubId: UUID?
    var date: Date
    var title: String
    var content: String
    var url: String
    var postedBy: UUID
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case date
        case title
        case content
        case url
        case postedBy = "posted_by"
        case createdAt = "created_at"
    }
}
