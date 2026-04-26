import Foundation
import Observation

@Observable
final class RegistrationStore {
    var registrations: [IndividualRegistration] = []
    
    init() {
        // Start with empty registrations for testing
    }
    
    private func allRegistrationsCount(for event: Event) -> Int {
        // Just a helper to limit mock data
        min(sampleUsersCount, 8)
    }
    
    private var sampleUsersCount: Int {
        MockData.allMockUsers.count
    }
    
    func getRegistrations(for eventId: UUID) -> [IndividualRegistration] {
        registrations.filter { $0.eventId == eventId }
    }
    
    func toggleRegistration(eventId: UUID, userId: UUID) {
        if let index = registrations.firstIndex(where: { $0.eventId == eventId && $0.userId == userId }) {
            registrations.remove(at: index)
        } else {
            registrations.append(IndividualRegistration(id: UUID(), eventId: eventId,
                userId: userId,
                status: .confirmed,
                registeredAt: Date()
            ))
        }
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
