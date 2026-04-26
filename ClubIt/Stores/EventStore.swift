//
//  EventStore.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/20/26.
//


import Foundation
import Observation
import Supabase

@Observable
final class EventStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    var events: [Event] = []
    
    init() {}
    
    @MainActor
    func fetchAllEvents() async throws {
        self.events = try await client
            .from("events")
            .select()
            .execute()
            .value
    }
    
    func addEvent(_ event: Event) {
        events.insert(event, at: 0)
    }
    
    func updateEventStatus(id: UUID, status: EventStatus) {
        if let index = events.firstIndex(where: { $0.id == id }) {
            events[index].status = status
        }
    }
    
    func updateEvent(_ event: Event) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        }
    }
}
