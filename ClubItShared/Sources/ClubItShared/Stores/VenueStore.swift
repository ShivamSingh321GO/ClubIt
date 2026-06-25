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
    
    public func getBookingInfo(for venue: Venue, events: [Event], clubs: [Club]) -> [BookedSlot] {
        // Find future events at this location
        let futureEvents = events.filter { $0.location == venue.name && $0.startDate > Date() }
            .sorted { $0.startDate < $1.startDate }
        
        return futureEvents.map { event in
            BookedSlot(event: event, club: clubs.first { $0.id == event.clubId })
        }
    }
}
