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
    
    func addActivity(_ activity: Activity) {
        activities.insert(activity, at: 0)
    }
    
    func deleteActivity(_ activity: Activity) {
        activities.removeAll { $0.id == activity.id }
    }
}
