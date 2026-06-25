//
//  Announcement.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//

import Foundation


public struct Announcement: Identifiable, Codable {
    public var id: UUID
    public var clubId: UUID?
    public var date: Date
    public var title: String
    public var content: String
    public var url: String
    public var postedBy: UUID
    public var createdAt: Date
    public var isEdited: Bool? = false

    public enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case date
        case title
        case content
        case url
        case postedBy = "posted_by"
        case createdAt = "created_at"
        case isEdited = "is_edited"
    }

    public init(
        id: UUID,
        clubId: UUID? = nil,
        date: Date,
        title: String,
        content: String,
        url: String,
        postedBy: UUID,
        createdAt: Date,
        isEdited: Bool? = false
    ) {
        self.id = id
        self.clubId = clubId
        self.date = date
        self.title = title
        self.content = content
        self.url = url
        self.postedBy = postedBy
        self.createdAt = createdAt
        self.isEdited = isEdited
    }

}
