import Foundation
import Observation
import Supabase

@Observable
public final class VenueStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    public var allVenues: [Venue] = []
    
    public init() {
        self.allVenues = mockVenues()
    }
    
    @MainActor
    public func fetchVenues() async throws {
        self.allVenues = try await client
            .from("venues")
            .select()
            .execute()
            .value
        print("DEBUG: Fetched \(allVenues.count) venues from Supabase")
    }
    
    private func mockVenues() -> [Venue] {
        let instituteId = MockData.instituteId
        var venues: [Venue] = []
        
        // Auditoriums
        venues.append(Venue(id: UUID(), instituteId: instituteId, name: "New Auditorium", location: "Block A", capacity: 500, type: .auditorium, availabilityStatus: .available, createdAt: Date()))
        venues.append(Venue(id: UUID(), instituteId: instituteId, name: "Old Auditorium", location: "Block B", capacity: 300, type: .auditorium, availabilityStatus: .available, createdAt: Date()))
        
        // Classrooms
        let classrooms = ["A101", "A122", "B232", "B201", "C105", "C106", "C110"]
        for room in classrooms {
            let block = room.prefix(1)
            venues.append(Venue(id: UUID(), instituteId: instituteId, name: room, location: "Block \(block)", capacity: 60, type: .classroom, availabilityStatus: .available, createdAt: Date()))
        }
        
        // Grounds
        for i in 1...5 {
            venues.append(Venue(id: UUID(), instituteId: instituteId, name: "Ground \(i)", location: "Sports Complex", capacity: 1000, type: .ground, availabilityStatus: .available, createdAt: Date()))
        }
        
        // Cafeteria
        venues.append(Venue(id: UUID(), instituteId: instituteId, name: "Cafeteria", location: "Student Center", capacity: 200, type: .cafeteria, availabilityStatus: .available, createdAt: Date()))
        
        // Library
        venues.append(Venue(id: UUID(), instituteId: instituteId, name: "Library", location: "Central Block", capacity: 150, type: .library, availabilityStatus: .available, createdAt: Date()))
        
        // Labs
        venues.append(Venue(id: UUID(), instituteId: instituteId, name: "Computer lab C122", location: "Block C", capacity: 50, type: .lab, availabilityStatus: .available, createdAt: Date()))
        venues.append(Venue(id: UUID(), instituteId: instituteId, name: "Computer lab B322", location: "Block B", capacity: 40, type: .lab, availabilityStatus: .available, createdAt: Date()))
        
        return venues
    }
    
    public var bookedSlots: [DBBookedSlot] = []
    
    @MainActor
    public func fetchBookedSlots() async throws {
        self.bookedSlots = try await client
            .from("booked_slots")
            .select()
            .execute()
            .value
        print("DEBUG: Fetched \(bookedSlots.count) booked slots from Supabase")
    }
    
    public func getBookingInfo(for venue: Venue, events: [Event], subgroups: [Subgroup]) -> [BookedSlot] {
        let slots = bookedSlots.filter { $0.venueId == venue.id }
        var result = slots.compactMap { slot -> BookedSlot? in
            guard let event = events.first(where: { $0.id == slot.eventId }) else { return nil }
            return BookedSlot(event: event, subgroup: subgroups.first { $0.id == event.subgroupId })
        }
        
        let pendingEvents = events.filter { event in event.location == venue.name && !result.contains(where: { bs in bs.event.id == event.id }) }
        
        for pEvent in pendingEvents {
            result.append(BookedSlot(event: pEvent, subgroup: subgroups.first { $0.id == pEvent.subgroupId }))
        }
        
        result.sort { ($0.event.startTime ?? $0.event.startDate) < ($1.event.startTime ?? $1.event.startDate) }
        
        return result
    }
}

public struct DBBookedSlot: Codable, Identifiable, Sendable {
    public var id: UUID
    public var venueId: UUID
    public var eventId: UUID
    public var subgroupId: UUID?
    public var startTime: Date
    public var endTime: Date
    public var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case venueId = "venue_id"
        case eventId = "event_id"
        case subgroupId = "subgroup_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case createdAt = "created_at"
    }
}
