import Foundation
import Observation

@Observable
final class RegistrationStore {
    var registrations: [IndividualRegistration] = []
    
    init() {
        // Create mock registrations for all sample events
        let allEvents = MockData.sampleEvents
        let sampleUsers = MockData.allMockUsers.filter { $0.role == .clubMember || $0.role == .student || $0.role == .clubLead }
        
        for event in allEvents {
            // Pick a random subset of users for each event
            let participants = sampleUsers.shuffled().prefix(Int.random(in: 3...allRegistrationsCount(for: event)))
            
            for user in participants {
                registrations.append(IndividualRegistration(
                    eventId: event.id,
                    userId: user.id,
                    status: .confirmed,
                    registeredAt: Date().addingTimeInterval(-Double.random(in: 3600...172800))
                ))
            }
        }
    }
    
    private func allRegistrationsCount(for event: Event) -> Int {
        // Just a helper to limit mock data
        return min(sampleUsersCount, 8)
    }
    
    private var sampleUsersCount: Int {
        MockData.allMockUsers.count
    }
    
    func getRegistrations(for eventId: UUID) -> [IndividualRegistration] {
        registrations.filter { $0.eventId == eventId }
    }
    
    func updateStatus(registrationId: UUID, status: RegistrationStatus) {
        if let index = registrations.firstIndex(where: { $0.id == registrationId }) {
            registrations[index].status = status
        }
    }
    
    func confirmAll(for eventId: UUID) {
        for index in registrations.indices {
            if registrations[index].eventId == eventId {
                registrations[index].status = .confirmed
            }
        }
    }
}
