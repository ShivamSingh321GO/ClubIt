//
//  AnnouncementStore.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/20/26.
//


import Foundation
import Observation

@Observable
final class AnnouncementStore {
    
    var announcements: [Announcement] = MockData.sampleAnnouncements
    
    init() {}
    
    
    func addAnnouncement(title: String, content: String, url: String, postedBy: UUID, clubId: UUID, target: AnnouncementTarget = .club) {
        let newAnnouncement = Announcement(id: UUID(), clubId: clubId,
            date: Date(),
            title: title,
            content: content,
            url: url,
            postedBy: postedBy,
            target: target,
            createdAt: Date()
        )
        
        announcements.insert(newAnnouncement, at: 0)
    }
}
