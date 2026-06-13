//
//  Media.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//

import Foundation

enum MediaType: String, Codable {
    case image
    case file
    case link
}

struct ClubImage: Identifiable, Codable, Hashable {
    var id = UUID()
    var clubId: UUID
    var eventId: UUID?
    var type: MediaType
    var title: String
    var fileUrl: String
    var imageData: Data? = nil
    var uploadedBy: UUID
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case eventId = "event_id"
        case type
        case title
        case fileUrl = "file_url"
        case uploadedBy = "uploaded_by"
        case createdAt = "created_at"
    }
}


// for media part
struct ClubFile: Identifiable, Codable {
    var id: UUID = UUID()
    var clubId: UUID
    var name: String
    var size: String
    var uploadedBy: String
    var fileURL: String?
    var createdAt: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case id, name, size
        case clubId = "club_id"
        case uploadedBy = "uploaded_by"
        case fileURL = "file_url"
        case createdAt = "created_at"
    }
}

struct ClubLink: Identifiable, Codable {
    var id: UUID = UUID()
    var clubId: UUID
    var name: String
    var url: String
    var uploadedBy: String
    var createdAt: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case id, name, url
        case clubId = "club_id"
        case uploadedBy = "uploaded_by"
        case createdAt = "created_at"
    }
}
