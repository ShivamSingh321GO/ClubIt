//
//  ActivityStore.swift
//  ClubIt
//

import Foundation
import Observation
import Supabase

@Observable
public final class ActivityStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    public var activities: [Activity] = []
    
    public init() {}
    
    @MainActor
    public func fetchActivities(clubId: UUID) async throws {
        self.activities = try await client
            .from("activities")
            .select()
            .eq("club_id", value: clubId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    @MainActor
    public func addActivity(_ activity: Activity) async throws {
        // 1. Insert into Supabase
        try await client
            .from("activities")
            .insert(activity)
            .execute()
        
        // 2. Refresh local list
        try await fetchActivities(clubId: activity.clubId)
    }
    
    @MainActor
    public func deleteActivity(_ activity: Activity) async throws {
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
