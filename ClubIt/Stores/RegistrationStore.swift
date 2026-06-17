import Foundation
import Observation
import Supabase

@Observable
final class RegistrationStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    var registrations: [IndividualRegistration] = []
    
    init() {}
    
    @MainActor
    func fetchRegistrations() async throws {
        self.registrations = try await client
            .from("registrations")
            .select()
            .execute()
            .value
    }
    
    func getRegistrations(for eventId: UUID) -> [IndividualRegistration] {
        registrations.filter { $0.eventId == eventId }
    }
    
    @MainActor
    func toggleRegistration(eventId: UUID, userId: UUID, answers: [String: String]? = nil) async throws {
        if let index = registrations.firstIndex(where: { $0.eventId == eventId && $0.userId == userId }) {
            let registrationId = registrations[index].id
            try await client
                .from("registrations")
                .delete()
                .eq("event_id", value: eventId)
                .eq("user_id", value: userId)
                .execute()
            
            registrations.remove(at: index)
        } else {
            let newRegistration = IndividualRegistration(
                id: UUID(),
                eventId: eventId,
                userId: userId,
                status: .confirmed,
                answers: answers ?? [:],
                createdAt: Date()
            )
            
            try await client
                .from("registrations")
                .insert(newRegistration)
                .execute()
            
            registrations.append(newRegistration)
        }
    }
    
    @MainActor
    func updateStatus(registrationId: UUID, status: RegistrationStatus) async throws {
        try await client
            .from("registrations")
            .update(["status": status.rawValue])
            .eq("id", value: registrationId)
            .execute()
            
        if let index = registrations.firstIndex(where: { $0.id == registrationId }) {
            registrations[index].status = status
        }
    }
}
