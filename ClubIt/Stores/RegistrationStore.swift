import Foundation
import Observation

@Observable
final class RegistrationStore {
    var registrations: [IndividualRegistration] = []
    
    init() {
        // Mock registrations for Technojam's Tech Summit
        let techSummitId = MockData.technoJamBundle.events[0].id
        let sampleUsers = MockData.allMockUsers.filter { $0.role == .clubMember || $0.role == .student }.prefix(5)
        
        for user in sampleUsers {
            registrations.append(IndividualRegistration(
                eventId: techSummitId,
                userId: user.id,
                status: .confirmed,
                registeredAt: Date().addingTimeInterval(-Double.random(in: 3600...86400))
            ))
        }
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
