import Foundation
import Observation
import Supabase

@Observable
public final class AttendanceStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    public var eventAttendances: [EventAttendance] = []
    public var isFetching: Bool = false
    public var error: String? = nil

    public init() {}

    @MainActor
    public func fetchAttendance(for eventId: UUID) async {
        isFetching = true
        error = nil
        do {
            self.eventAttendances = try await client
                .from("attendance")
                .select()
                .eq("event_id", value: eventId)
                .execute()
                .value
        } catch {
            self.error = error.localizedDescription
            print("Failed to fetch attendance: \(error)")
        }
        isFetching = false
    }

    @MainActor
    public func markAttendance(eventId: UUID, userId: UUID) async throws -> Bool {
        // First check if an attendance record exists for this event and user
        let existingRecords: [EventAttendance] = try await client
            .from("attendance")
            .select()
            .eq("event_id", value: eventId)
            .eq("user_id", value: userId)
            .execute()
            .value
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let nowString = formatter.string(from: Date())

        if let existing = existingRecords.first {
            // If already entered and exited, maybe do nothing or update exit time?
            // Let's just update exit time if they scan again.
            try await client
                .from("attendance")
                .update(["exit_time": nowString])
                .eq("id", value: existing.id)
                .execute()
            
            // Update local state if it's currently loaded
            if let index = eventAttendances.firstIndex(where: { $0.id == existing.id }) {
                eventAttendances[index].exitTime = Date()
            }
            return false // Returning false indicates "Marked Exit"
        } else {
            // Create new record (Entry)
            struct InsertAttendance: Codable {
                var event_id: UUID
                var user_id: UUID
                var entry_time: String
            }
            
            let newRecord = InsertAttendance(event_id: eventId, user_id: userId, entry_time: nowString)
            
            let inserted: [EventAttendance] = try await client
                .from("attendance")
                .insert(newRecord)
                .select()
                .execute()
                .value
            
            if let first = inserted.first {
                eventAttendances.append(first)
            }
            return true // Returning true indicates "Marked Entry"
        }
    }
}
