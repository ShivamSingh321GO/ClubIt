import Foundation
import Observation
import Supabase

@Observable
public final class ClubStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    
    public var club: Club
    public var allClubs: [Club] = []
    public var allUsers: [User] = []
    
    public var followedClubIds: Set<UUID> = []
    public var requestedClubIds: Set<UUID> = []
    
    public init() {
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
    public func fetchAllClubs() async throws {
        self.allClubs = try await client
            .from("clubs")
            .select()
            .execute()
            .value
        print("DEBUG: Fetched \(allClubs.count) clubs from Supabase")
    }

    @MainActor
    public func fetchClubDetails(id: UUID) async throws {
        self.club = try await client
            .from("clubs")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }
    
    @MainActor
    public func fetchAllUsers() async throws {
        self.allUsers = try await client
            .from("users")
            .select()
            .execute()
            .value
    }
    
    @MainActor
    public func updateClub(name: String, tagLine: String, description: String, category: ClubCategory, memberCount: Int, eventCount: Int, socials: [String: String], logo: String, imageData: Data?) async throws {
        var logoUrl = logo
        
        // 1. Upload logo image to Supabase Storage bucket 'clubProfile-images' if new imageData is provided
        if let imageData {
            do {
                // Remove older logo files in this club's folder to avoid storage bloat
                if let files = try? await client.storage.from("clubProfile-images").list(path: club.id.uuidString) {
                    let pathsToDelete = files.map { "\(club.id.uuidString)/\($0.name)" }
                    if !pathsToDelete.isEmpty {
                        try? await client.storage.from("clubProfile-images").remove(paths: pathsToDelete)
                    }
                }
                
                // Use a unique filename incorporating a timestamp to bypass cached URL/image lookups
                let storagePath = "\(club.id.uuidString)/logo_\(Int(Date().timeIntervalSince1970)).jpg"
                try await client.storage
                    .from("clubProfile-images")
                    .upload(
                        storagePath,
                        data: imageData,
                        options: FileOptions(
                            contentType: "image/jpeg",
                            upsert: true
                        )
                    )
                
                let publicURL = try client.storage
                    .from("clubProfile-images")
                    .getPublicURL(path: storagePath)
                
                logoUrl = publicURL.absoluteString
                print("DEBUG: Uploaded club logo to clubProfile-images Storage. Public URL: \(logoUrl)")
            } catch {
                print("DEBUG ERROR: Failed to upload logo image: \(error.localizedDescription)")
                throw error
            }
        }
        
        // 2. Update Supabase table
        let updateData: [String: AnyJSON] = [
            "name": .string(name),
            "tag_line": .string(tagLine),
            "description": .string(description),
            "category": .string(category.rawValue),
            "socials": .object(socials.mapValues { .string($0) }),
            "logo": .string(logoUrl)
        ]
        
        try await client
            .from("clubs")
            .update(updateData)
            .eq("id", value: club.id)
            .execute()
            
        // 3. Update local state
        club.name = name
        club.tagLine = tagLine
        club.description = description
        club.category = category
        club.memberCount = memberCount
        club.eventCount = eventCount
        club.socials = socials
        club.logo = logoUrl
        club.imageData = imageData
        
        // 4. Refresh global list
        try? await fetchAllClubs()
    }
    
    public func toggleFollow(for clubId: UUID) {
        if followedClubIds.contains(clubId) {
            followedClubIds.remove(clubId)
        } else {
            followedClubIds.insert(clubId)
        }
    }
    
    public func updateMember(updatedUser: User) {
        if let index = allUsers.firstIndex(where: { $0.id == updatedUser.id }) {
            allUsers[index] = updatedUser
        }
    }
}
