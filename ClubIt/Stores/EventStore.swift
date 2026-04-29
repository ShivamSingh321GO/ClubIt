//
//  EventStore.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/20/26.
//


import Foundation
import Observation
import Supabase
import SwiftUI

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
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    @MainActor
    func createEvent(_ event: Event) async throws {
        // 1. Initial Local Update: Show the event immediately using local image data
        await MainActor.run {
            withAnimation {
                var localEvent = event
                // Ensure it's at the top of the list
                if let index = self.events.firstIndex(where: { $0.id == localEvent.id }) {
                    self.events[index] = localEvent
                } else {
                    self.events.insert(localEvent, at: 0)
                }
            }
        }

        // 2. Upload and Database Sync
        var eventToSave = event
        if let imageData = event.imageData {
            let fileName = "\(UUID().uuidString).jpg"
            _ = try await client.storage
                .from("event-images")
                .upload(
                    path: fileName,
                    file: imageData,
                    options: FileOptions(contentType: "image/jpeg")
                )
            
            let publicURL = try client.storage
                .from("event-images")
                .getPublicURL(path: fileName)
            
            eventToSave.bannerImage = "\(publicURL.absoluteString)?t=\(Int(Date().timeIntervalSince1970))"
            eventToSave.imageData = nil 
        }
        
        try await client
            .from("events")
            .insert(eventToSave)
            .execute()
        
        // 3. Final Local Update: Transition from local data to remote URL after propagation
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        await MainActor.run {
            withAnimation {
                if let index = self.events.firstIndex(where: { $0.id == eventToSave.id }) {
                    self.events[index] = eventToSave
                }
            }
        }
    }
    
    @MainActor
    func updateEventStatus(id: UUID, status: EventStatus) async throws {
        print("DEBUG: Attempting to update event \(id) to status: \(status.rawValue)")
        
        do {
            // 1. Update the events table and return the result to verify success
            let updatedEvents: [Event] = try await client
                .from("events")
                .update(["status": status.rawValue])
                .eq("id", value: id)
                .select() // This allows us to see if the row actually changed
                .execute()
                .value
            
            if updatedEvents.isEmpty {
                print("ERROR: No rows were updated in 'events' table. This usually means RLS is blocking you or the ID is wrong.")
                throw NSError(domain: "SupabaseError", code: 403, userInfo: [NSLocalizedDescriptionKey: "Update blocked by database security (RLS)."])
            }
            print("DEBUG: Successfully updated 'events' table. New status: \(updatedEvents.first?.status.rawValue ?? "unknown")")
            
            // 2. Sync with the approvals table
            let approvalStatus = (status == .published) ? "approved" : status.rawValue
            try await client
                .from("approvals")
                .update(["status": approvalStatus])
                .eq("approval_related_id", value: id)
                .execute()
            print("DEBUG: Successfully updated 'approvals' table with status: \(approvalStatus)")
            
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
        try await client
            .from("events")
            .update(event)
            .eq("id", value: event.id)
            .execute()
            
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        }
    }
}
