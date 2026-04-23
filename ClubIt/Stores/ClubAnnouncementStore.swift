import Foundation
import Observation

@Observable
final class ClubAnnouncementStore {
    var announcements: [Announcement] = []
    
    init() {
        let clubId = UUID()
        let userId = UUID()
        announcements = [
            Announcement(
                clubId: clubId,
                date: Date(),
                title: "Welcome to our new members!",
                content: "We're excited to have 20 new members join the club this week. Looking forward to our first meeting together.",
                url: "",
                postedBy: userId,
                target: .club,
                createdAt: Date()
            ),
            Announcement(
                clubId: clubId,
                date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                title: "Project phase 1 completed",
                content: "Great job everyone on finishing the first phase of our main project. Next sprint starts Monday.",
                url: "https://github.com/clubit",
                postedBy: userId,
                target: .club,
                createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
            )
        ]
    }
    
    func addAnnouncement(_ announcement: Announcement) {
        announcements.insert(announcement, at: 0)
    }
    
    func deleteAnnouncement(_ announcement: Announcement) {
        announcements.removeAll { $0.id == announcement.id }
    }
}
