//
//  Media.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//

import Foundation

public enum MediaType: String, Codable {
    case image
    case file
    case link
}

public struct ClubImage: Identifiable, Codable, Hashable {
    public var id = UUID()
    public var clubId: UUID
    public var eventId: UUID?
    public var type: MediaType
    public var title: String
    public var fileUrl: String
    public var imageData: Data? = nil
    public var uploadedBy: UUID
    public var createdAt: Date

    public enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case eventId = "event_id"
        case type
        case title
        case fileUrl = "file_url"
        case uploadedBy = "uploaded_by"
        case createdAt = "created_at"
    }

    public init(
        id: UUID = UUID(),
        clubId: UUID,
        eventId: UUID? = nil,
        type: MediaType,
        title: String,
        fileUrl: String,
        imageData: Data? = nil,
        uploadedBy: UUID,
        createdAt: Date
    ) {
        self.id = id
        self.clubId = clubId
        self.eventId = eventId
        self.type = type
        self.title = title
        self.fileUrl = fileUrl
        self.imageData = imageData
        self.uploadedBy = uploadedBy
        self.createdAt = createdAt
    }

}


// for media part
public struct ClubFile: Identifiable, Codable {
    public var id: UUID = UUID()
    public var clubId: UUID
    public var name: String
    public var size: String
    public var uploadedBy: String
    public var fileURL: String?
    public var createdAt: Date = Date()
    
    public enum CodingKeys: String, CodingKey {
        case id, name, size
        case clubId = "club_id"
        case uploadedBy = "uploaded_by"
        case fileURL = "file_url"
        case createdAt = "created_at"
    }

    public init(
        id: UUID = UUID(),
        clubId: UUID,
        name: String,
        size: String,
        uploadedBy: String,
        fileURL: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.clubId = clubId
        self.name = name
        self.size = size
        self.uploadedBy = uploadedBy
        self.fileURL = fileURL
        self.createdAt = createdAt
    }

}

public struct ClubLink: Identifiable, Codable {
    public var id: UUID = UUID()
    public var clubId: UUID
    public var name: String
    public var url: String
    public var uploadedBy: String
    public var createdAt: Date = Date()
    
    public enum CodingKeys: String, CodingKey {
        case id, name, url
        case clubId = "club_id"
        case uploadedBy = "uploaded_by"
        case createdAt = "created_at"
    }

    public init(
        id: UUID = UUID(),
        clubId: UUID,
        name: String,
        url: String,
        uploadedBy: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.clubId = clubId
        self.name = name
        self.url = url
        self.uploadedBy = uploadedBy
        self.createdAt = createdAt
    }

}
