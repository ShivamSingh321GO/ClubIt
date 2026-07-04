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
    public func fetchActivities(subgroupId: UUID) async throws {
        self.activities = try await client
            .from("activities")
            .select()
            .eq("subgroup_id", value: subgroupId)
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
        try await fetchActivities(subgroupId: activity.subgroupId)
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
        try await fetchActivities(subgroupId: activity.subgroupId)
    }
}
