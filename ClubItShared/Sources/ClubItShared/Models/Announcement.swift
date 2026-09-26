//
//  Announcement.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//

import Foundation


public struct Announcement: Identifiable, Codable {
    public var id: UUID
    public var groupId: UUID?
    public var subgroupId: UUID?
    public var date: Date
    public var title: String
    public var content: String
    public var url: String
    public var postedBy: UUID
    public var createdAt: Date
    public var isEdited: Bool? = false
    public var organizationId: UUID?
    public var isHighPriority: Bool?

    public enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case subgroupId = "subgroup_id"
        case date
        case title
        case content
        case url
        case postedBy = "author_id"
        case createdAt = "created_at"
        case isEdited = "is_edited"
        case organizationId = "organization_id"
        case isHighPriority = "is_high_priority"
    }

    public init(
        id: UUID,
        groupId: UUID? = nil,
        subgroupId: UUID? = nil,
        date: Date,
        title: String,
        content: String,
        url: String,
        postedBy: UUID,
        createdAt: Date,
        isEdited: Bool? = false,
        organizationId: UUID? = nil,
        isHighPriority: Bool? = nil
    ) {
        self.id = id
        self.groupId = groupId
        self.subgroupId = subgroupId
        self.date = date
        self.title = title
        self.content = content
        self.url = url
        self.postedBy = postedBy
        self.createdAt = createdAt
        self.isEdited = isEdited
        self.organizationId = organizationId
        self.isHighPriority = isHighPriority
    }

}
