import Foundation
import Observation
import Supabase

@Observable
final class ClubLinkStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    var links: [ClubLink] = []
    
    init() {}
    
    @MainActor
    func fetchLinks(clubId: UUID) async throws {
        self.links = try await client
            .from("club_links")
            .select()
            .eq("club_id", value: clubId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    @MainActor
    func addLink(_ link: ClubLink) async throws {
        try await client
            .from("club_links")
            .insert(link)
            .execute()
        
        try await fetchLinks(clubId: link.clubId)
    }
    
    @MainActor
    func deleteLink(_ link: ClubLink) async throws {
        try await client
            .from("club_links")
            .delete()
            .eq("id", value: link.id)
            .execute()
        
        try await fetchLinks(clubId: link.clubId)
    }
}
