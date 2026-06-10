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
        let regularEvents: [Event] = try await client
            .from("events")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
            
        var councilEvents: [Event] = []
        do {
            councilEvents = try await client
                .from("council_events")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
        } catch {
            print("WARNING: Could not fetch from 'council_events' table. Error: \(error.localizedDescription)")
        }
        
        var mappedCouncilEvents = councilEvents
        for i in 0..<mappedCouncilEvents.count {
            mappedCouncilEvents[i].status = .published
        }
        
        self.events = (regularEvents + mappedCouncilEvents).sorted(by: { $0.createdAt > $1.createdAt })
    }
    
    @MainActor
    func createEvent(_ event: Event, isCouncil: Bool = false) async throws {
        let table = isCouncil ? "council_events" : "events"
        try await client
            .from(table)
            .insert(event)
            .execute()
        
        // Preserve imageData locally since it's not stored in Supabase
        let localImageData = event.imageData
        
        // Add locally to avoid full refresh if preferred, but refresh is safer
        try? await fetchAllEvents()
        
        // Re-attach imageData to the local event after fetch (Supabase won't return it)
        if let localImageData, let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index].imageData = localImageData
        }
    }
    
    @MainActor
    func updateEventStatus(id: UUID, status: EventStatus) async throws {
        print("DEBUG: Attempting to update event \(id) to status: \(status.rawValue)")
        
        do {
            // 1. Update the events table and return the result to verify success
            var updatedEvents: [Event] = try await client
                .from("events")
                .update(["status": status.rawValue])
                .eq("id", value: id)
                .select() // This allows us to see if the row actually changed
                .execute()
                .value
            
            if updatedEvents.isEmpty {
                // Try updating council_events instead
                updatedEvents = try await client
                    .from("council_events")
                    .update(["status": status.rawValue])
                    .eq("id", value: id)
                    .select()
                    .execute()
                    .value
                
                if updatedEvents.isEmpty {
                    print("ERROR: No rows were updated in 'events' or 'council_events' table. This usually means RLS is blocking you or the ID is wrong.")
                    throw NSError(domain: "SupabaseError", code: 403, userInfo: [NSLocalizedDescriptionKey: "Update blocked by database security (RLS)."])
                }
                print("DEBUG: Successfully updated 'council_events' table. New status: \(updatedEvents.first?.status.rawValue ?? "unknown")")
            } else {
                print("DEBUG: Successfully updated 'events' table. New status: \(updatedEvents.first?.status.rawValue ?? "unknown")")
                
                // 2. Sync with the approvals table
                let approvalStatus = (status == .published) ? "approved" : status.rawValue
                try await client
                    .from("approvals")
                    .update(["status": approvalStatus])
                    .eq("approval_related_id", value: id)
                    .execute()
                print("DEBUG: Successfully updated 'approvals' table with status: \(approvalStatus)")
            }
            
            // 3. Update local state
            if let index = events.firstIndex(where: { $0.id == id }) {
                events[index].status = status
            }
        } catch {
            print("CRITICAL ERROR in updateEventStatus: \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func updateEvent(_ event: Event) async throws {
        do {
            try await client
                .from("events")
                .update(event)
                .eq("id", value: event.id)
                .execute()
        } catch {
            try await client
                .from("council_events")
                .update(event)
                .eq("id", value: event.id)
                .execute()
        }
            
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        }
    }
}
