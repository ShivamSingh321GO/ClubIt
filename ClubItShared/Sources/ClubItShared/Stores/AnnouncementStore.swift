import Foundation
import Observation
import Supabase

@Observable
public final class AnnouncementStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    
    public var announcements: [Announcement] = []
    public var isLoading = false
    
    private var announcementsChannel: RealtimeChannelV2?
    private var subscriptionTask: Task<Void, Never>?
    
    public init() {}
    
    @MainActor
    public func fetchAnnouncements() async throws {
        isLoading = true
        defer { isLoading = false }
        
        self.announcements = try await client
            .from("announcements")
            .select()
            .order("is_high_priority", ascending: false)
            .order("date", ascending: false)
            .execute()
            .value
        
        print("DEBUG: Fetched \(announcements.count) announcements from Supabase")
    }
    
    /// Explicit payload for inserting into the `announcements` table.
    /// Only includes columns that actually exist in the Supabase table schema.
    private struct InsertAnnouncementPayload: Encodable {
        let id: UUID
        let group_id: UUID?
        let date: String
        let title: String
        let content: String
        let url: String
        let author_id: UUID
        let created_at: String
        let is_edited: Bool
        let organization_id: UUID?
        let is_high_priority: Bool?
    }

    @MainActor
    public func addAnnouncement(title: String, content: String, url: String, postedBy: UUID, groupId: UUID?, subgroupId: UUID?, organizationId: UUID?, isHighPriority: Bool? = false) async throws {
        print("DEBUG: [AnnouncementStore] Adding announcement: title='\(title)', postedBy=\(postedBy), groupId=\(String(describing: groupId)), subgroupId=\(String(describing: subgroupId)), organizationId=\(String(describing: organizationId))")
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let now = isoFormatter.string(from: Date())
        
        let payload = InsertAnnouncementPayload(
            id: UUID(),
            group_id: groupId,
            date: now,
            title: title,
            content: content,
            url: url,
            author_id: postedBy,
            created_at: now,
            is_edited: false,
            organization_id: organizationId,
            is_high_priority: isHighPriority
        )
        
        // 1. Save to Supabase
        do {
            try await client
                .from("announcements")
                .insert(payload)
                .execute()
            print("DEBUG: [AnnouncementStore] Insert succeeded.")
        } catch {
            print("DEBUG ERROR: [AnnouncementStore] Insert failed: \(error)")
            throw error
        }
            
        // 2. Refresh local list
        try await fetchAnnouncements()
    }

    public struct UpdateAnnouncementPayload: Encodable {
        let title: String
        let content: String
        let url: String
        let is_edited: Bool
    }

    @MainActor
    public func updateAnnouncement(id: UUID, title: String, content: String, url: String) async throws {
        print("DEBUG: [AnnouncementStore] Updating announcement: id=\(id), title='\(title)'")
        let payload = UpdateAnnouncementPayload(
            title: title,
            content: content,
            url: url,
            is_edited: true
        )
        
        // 1. Update in Supabase
        do {
            try await client
                .from("announcements")
                .update(payload)
                .eq("id", value: id)
                .execute()
            print("DEBUG: [AnnouncementStore] Update succeeded.")
        } catch {
            print("DEBUG ERROR: [AnnouncementStore] Update failed: \(error)")
            throw error
        }
            
        // 2. Refresh local list
        try await fetchAnnouncements()
    }

    @MainActor
    public func deleteAnnouncement(_ announcement: Announcement) async throws {
        // 1. Delete from Supabase
        try await client
            .from("announcements")
            .delete()
            .eq("id", value: announcement.id)
            .execute()
            
        // 2. Refresh local list
        try await fetchAnnouncements()
    }
    
    @MainActor
    public func startRealtimeSubscription() {
        guard announcementsChannel == nil else { return }
        
        subscriptionTask?.cancel()
        
        let channel = client.realtimeV2.channel("public:announcements")
        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "announcements"
        )
        
        subscriptionTask = Task {
            await client.realtimeV2.connect()
            try? await channel.subscribeWithError()
            
            for await _ in changes {
                if Task.isCancelled { break }
                try? await fetchAnnouncements()
            }
        }
        
        announcementsChannel = channel
        print("DEBUG: [AnnouncementStore] Realtime subscription started")
    }
    
    @MainActor
    public func stopRealtimeSubscription() {
        subscriptionTask?.cancel()
        subscriptionTask = nil
        
        Task {
            if let channel = announcementsChannel {
                await client.realtimeV2.removeChannel(channel)
            }
        }
        announcementsChannel = nil
        print("DEBUG: [AnnouncementStore] Realtime subscription stopped")
    }
}
