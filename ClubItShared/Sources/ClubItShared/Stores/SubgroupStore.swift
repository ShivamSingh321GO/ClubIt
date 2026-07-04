import Foundation
import Observation
import Supabase

@Observable
public final class SubgroupStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    
    public var subgroup: Subgroup
    public var allSubgroups: [Subgroup] = []
    public var allUsers: [User] = []
    
    public var followedSubgroupIds: Set<UUID> = []
    public var requestedSubgroupIds: Set<UUID> = []
    
    public init() {
        // Provide a temporary placeholder until data is loaded
        self.subgroup = Subgroup(
            id: UUID(),
            name: "Loading...",
            tagLine: "",
            description: "",
            category: .technical,
            logo: "",
            subgroupLeadId: UUID(),
            facultyId: UUID(),
            instituteId: UUID(),
            status: .active,
            createdAt: Date(),
            socials: [:]
        )
    }

    @MainActor
    public func fetchAllSubgroups() async throws {
        self.allSubgroups = try await client
            .from("subgroups")
            .select()
            .execute()
            .value
        print("DEBUG: Fetched \(allSubgroups.count) subgroups from Supabase")
    }

    @MainActor
    public func fetchSubgroupDetails(id: UUID) async throws {
        self.subgroup = try await client
            .from("subgroups")
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
    public func updateSubgroup(name: String, tagLine: String, description: String, category: SubgroupCategory, memberCount: Int, eventCount: Int, socials: [String: String], logo: String, imageData: Data?) async throws {
        var logoUrl = logo
        
        // 1. Upload logo image to Supabase Storage bucket 'subgroupProfile-images' if new imageData is provided
        if let imageData {
            do {
                // Remove older logo files in this subgroup's folder to avoid storage bloat
                if let files = try? await client.storage.from("subgroupProfile-images").list(path: subgroup.id.uuidString) {
                    let pathsToDelete = files.map { "\(subgroup.id.uuidString)/\($0.name)" }
                    if !pathsToDelete.isEmpty {
                        try? await client.storage.from("subgroupProfile-images").remove(paths: pathsToDelete)
                    }
                }
                
                // Use a unique filename incorporating a timestamp to bypass cached URL/image lookups
                let storagePath = "\(subgroup.id.uuidString)/logo_\(Int(Date().timeIntervalSince1970)).jpg"
                try await client.storage
                    .from("subgroupProfile-images")
                    .upload(
                        storagePath,
                        data: imageData,
                        options: FileOptions(
                            contentType: "image/jpeg",
                            upsert: true
                        )
                    )
                
                let publicURL = try client.storage
                    .from("subgroupProfile-images")
                    .getPublicURL(path: storagePath)
                
                logoUrl = publicURL.absoluteString
                print("DEBUG: Uploaded subgroup logo to subgroupProfile-images Storage. Public URL: \(logoUrl)")
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
            .from("subgroups")
            .update(updateData)
            .eq("id", value: subgroup.id)
            .execute()
            
        // 3. Update local state
        subgroup.name = name
        subgroup.tagLine = tagLine
        subgroup.description = description
        subgroup.category = category
        subgroup.memberCount = memberCount
        subgroup.eventCount = eventCount
        subgroup.socials = socials
        subgroup.logo = logoUrl
        subgroup.imageData = imageData
        
        // 4. Refresh global list
        try? await fetchAllSubgroups()
    }
    
    public func toggleFollow(for subgroupId: UUID) {
        if followedSubgroupIds.contains(subgroupId) {
            followedSubgroupIds.remove(subgroupId)
        } else {
            followedSubgroupIds.insert(subgroupId)
        }
    }
    
    public func updateMember(updatedUser: User) {
        if let index = allUsers.firstIndex(where: { $0.id == updatedUser.id }) {
            allUsers[index] = updatedUser
        }
    }
}
