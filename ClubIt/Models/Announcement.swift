//
//  Announcement.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/18/26.
//

import Foundation


enum AnnouncementTarget: String, Codable {
    case global
    case club
}

struct Announcement: Identifiable, Codable {
    var id: UUID
    var clubId: UUID
    var date: Date
    var title: String
    var content: String
    var url: String
    var postedBy: UUID
    var target: AnnouncementTarget
    var createdAt: Date
}
