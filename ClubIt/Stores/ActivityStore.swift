//
//  ActivityStore.swift
//  ClubIt
//

import Foundation
import Observation

@Observable
final class ActivityStore {
    var activities: [Activity] = []
    
    init() {
        // Mock data for initial view
        let clubId = MockData.tj_id
        let leadId = MockData.clubLeadUser.id
        
        self.activities = [
            Activity(
                type: .workshop,
                title: "Deep Dive into SwiftUI 5.0",
                description: "Explaining the new observation framework and animation systems with practical examples.",
                date: Date().addingTimeInterval(3600 * 24),
                location: "Lab 3, Ramanujan Block",
                clubId: clubId,
                postedBy: leadId,
                postedByName: "Aryan",
                createdAt: Date()
            ),
            Activity(
                type: .meeting,
                title: "Core Committee Sync",
                description: "Weekly sync to discuss upcoming event logistics and budget approvals.",
                date: Date().addingTimeInterval(3600 * 2),
                location: "Conference Room A",
                clubId: clubId,
                postedBy: leadId,
                postedByName: "Aryan",
                createdAt: Date()
            ),
            Activity(
                type: .competition,
                title: "Hack-O-Relay 2025",
                description: "Internal club hackathon to prep for national level competitions.",
                date: Date().addingTimeInterval(3600 * 24 * 7),
                location: "Main Auditorium",
                clubId: clubId,
                postedBy: leadId,
                postedByName: "Aryan",
                createdAt: Date()
            )
        ]
    }
    
    func addActivity(_ activity: Activity) {
        activities.insert(activity, at: 0)
    }
    
    func deleteActivity(_ activity: Activity) {
        activities.removeAll { $0.id == activity.id }
    }
}
