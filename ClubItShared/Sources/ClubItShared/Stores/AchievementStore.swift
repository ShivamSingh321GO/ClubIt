import Foundation
import Observation
import Supabase

@Observable
public final class AchievementStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    public var achievements: [Achievement] = []
    
    public init() {}
    
    @MainActor
    public func fetchAchievements(clubId: UUID) async throws {
        self.achievements = try await client
            .from("achievements")
            .select()
            .eq("club_id", value: clubId)
            .order("created_at", ascending: false)
            .execute()
            .value
        print("DEBUG: Fetched \(achievements.count) achievements from database")
    }
    
    @MainActor
    public func addAchievement(_ achievement: Achievement) async throws {
        // 1. Insert into Supabase
        try await client
            .from("achievements")
            .insert(achievement)
            .execute()
        
        // 2. Refresh local list
        try await fetchAchievements(clubId: achievement.clubId)
    }
    
    @MainActor
    public func deleteAchievement(_ achievement: Achievement) async throws {
        // 1. Delete from Supabase
        try await client
            .from("achievements")
            .delete()
            .eq("id", value: achievement.id)
            .execute()
        
        // 2. Refresh local list
        try await fetchAchievements(clubId: achievement.clubId)
    }
}
