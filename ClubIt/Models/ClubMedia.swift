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

struct ClubImage: Identifiable, Codable {
    var id = UUID()
    var clubId: UUID
    var eventId: UUID?
    var type: MediaType
    var title: String
    var fileUrl: String
    var imageData: Data? = nil
    var uploadedBy: UUID
    var createdAt: Date
}


// for media part
struct ClubFile: Identifiable, Codable {
    var id: UUID
    var clubId: UUID
    var name: String
    var size: String
    var uploadedBy: String
    var date: String
    var fileURL: URL?
}

struct ClubLink: Identifiable, Codable {
    var id: UUID
    var clubId: UUID
    var name: String
    var url: String
    var uploadedBy: String
    var date: String
}
