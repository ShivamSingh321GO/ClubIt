//
//  ActivityStore.swift
//  ClubIt
//

import Foundation
import Observation
import Supabase

@Observable
final class ActivityStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    var activities: [Activity] = []
    
    init() {}
    
    @MainActor
    func fetchActivities(clubId: UUID) async throws {
        self.activities = try await client
            .from("activities")
            .select()
            .eq("club_id", value: clubId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    @MainActor
    func addActivity(_ activity: Activity) async throws {
        // 1. Insert into Supabase
        try await client
            .from("activities")
            .insert(activity)
            .execute()
        
        // 2. Refresh local list
        try await fetchActivities(clubId: activity.clubId)
    }
    
    @MainActor
    func deleteActivity(_ activity: Activity) async throws {
        // 1. Delete from Supabase
        try await client
            .from("activities")
            .delete()
            .eq("id", value: activity.id)
            .execute()
        
        // 2. Refresh local list
        try await fetchActivities(clubId: activity.clubId)
    }
}
