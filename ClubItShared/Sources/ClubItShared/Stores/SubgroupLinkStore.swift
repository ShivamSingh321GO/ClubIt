import Foundation
import Observation
import Supabase

@Observable
public final class SubgroupLinkStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    public var links: [SubgroupLink] = []
    
    public init() {}
    
    @MainActor
    public func fetchLinks(subgroupId: UUID) async throws {
        self.links = try await client
            .from("subgroup_links")
            .select()
            .eq("subgroup_id", value: subgroupId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    @MainActor
    public func addLink(_ link: SubgroupLink) async throws {
        try await client
            .from("subgroup_links")
            .insert(link)
            .execute()
        
        try await fetchLinks(subgroupId: link.subgroupId)
    }
    
    @MainActor
    public func deleteLink(_ link: SubgroupLink) async throws {
        try await client
            .from("subgroup_links")
            .delete()
            .eq("id", value: link.id)
            .execute()
        
        try await fetchLinks(subgroupId: link.subgroupId)
    }
}
