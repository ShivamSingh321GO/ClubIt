import Foundation
import Observation
import Supabase

@Observable
final class ClubStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    
    var club: Club
    var allClubs: [Club] = []
    var allUsers: [User] = []
    
    var followedClubIds: Set<UUID> = []
    var requestedClubIds: Set<UUID> = []
    
    init() {
        // Provide a temporary placeholder until data is loaded
        self.club = Club(
            id: UUID(),
            name: "Loading...",
            tagLine: "",
            description: "",
            category: .technical,
            logo: "",
            clubLeadId: UUID(),
            facultyId: UUID(),
            instituteId: UUID(),
            status: .active,
            createdAt: Date(),
            socials: [:]
        )
    }

    @MainActor
    func fetchAllClubs() async throws {
        self.allClubs = try await client
            .from("clubs")
            .select()
            .execute()
            .value
        print("DEBUG: Fetched \(allClubs.count) clubs from Supabase")
    }

    @MainActor
    func fetchClubDetails(id: UUID) async throws {
        self.club = try await client
            .from("clubs")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }
    
    @MainActor
    func fetchAllUsers() async throws {
        self.allUsers = try await client
            .from("users")
            .select()
            .execute()
            .value
    }
    
    func updateClub(name: String, tagLine: String, description: String, category: ClubCategory, memberCount: Int, eventCount: Int, socials: [String: String], logo: String, imageData: Data?) {
        club.name = name
        club.tagLine = tagLine
        club.description = description
        club.category = category
        club.memberCount = memberCount
        club.eventCount = eventCount
        club.socials = socials
        club.logo = logo
        club.imageData = imageData
    }
    
    func toggleFollow(for clubId: UUID) {
        if followedClubIds.contains(clubId) {
            followedClubIds.remove(clubId)
        } else {
            followedClubIds.insert(clubId)
        }
    }
    
    func updateMember(updatedUser: User) {
        if let index = allUsers.firstIndex(where: { $0.id == updatedUser.id }) {
            allUsers[index] = updatedUser
        }
    }
}
