import Foundation
import Observation
import Supabase

@Observable
final class AnnouncementStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    
    var announcements: [Announcement] = []
    var isLoading = false
    
    init() {}
    
    @MainActor
    func fetchAnnouncements() async throws {
        isLoading = true
        defer { isLoading = false }
        
        self.announcements = try await client
            .from("announcements")
            .select()
            .order("date", ascending: false)
            .execute()
            .value
        
        print("DEBUG: Fetched \(announcements.count) announcements from Supabase")
    }
    
    @MainActor
    func addAnnouncement(title: String, content: String, url: String, postedBy: UUID, clubId: UUID?) async throws {
        let newAnnouncement = Announcement(
            id: UUID(),
            clubId: clubId,
            date: Date(),
            title: title,
            content: content,
            url: url,
            postedBy: postedBy,
            createdAt: Date()
        )
        
        // 1. Save to Supabase
        try await client
            .from("announcements")
            .insert(newAnnouncement)
            .execute()
            
        // 2. Refresh local list
        try await fetchAnnouncements()
    }

    @MainActor
    func deleteAnnouncement(_ announcement: Announcement) async throws {
        // 1. Delete from Supabase
        try await client
            .from("announcements")
            .delete()
            .eq("id", value: announcement.id)
            .execute()
            
        // 2. Refresh local list
        try await fetchAnnouncements()
    }
}
