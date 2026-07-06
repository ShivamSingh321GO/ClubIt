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
    public var hierarchyLevels: [HierarchyLevelModel] = []
    
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
        var fetchedUsers: [User] = try await client
            .from("users")
            .select()
            .execute()
            .value
        
        struct UserRoleRow: Decodable {
            let user_id: UUID
            let role_name: String
            let subgroup_id: UUID?
            let group_id: UUID?
        }
        
        let roles: [UserRoleRow] = (try? await client
            .from("admin_user_roles_view")
            .select("user_id, role_name, subgroup_id, group_id")
            .execute()
            .value) ?? []
            
        for i in 0..<fetchedUsers.count {
            let userRoles = roles.filter { $0.user_id == fetchedUsers[i].id }
            
            // Prioritize roles with subgroup_id, then group_id, then "level_" prefix
            let bestRole = userRoles.sorted { r1, r2 in
                if r1.subgroup_id != nil && r2.subgroup_id == nil { return true }
                if r1.subgroup_id == nil && r2.subgroup_id != nil { return false }
                if r1.group_id != nil && r2.group_id == nil { return true }
                if r1.group_id == nil && r2.group_id != nil { return false }
                if r1.role_name.starts(with: "level_") && !r2.role_name.starts(with: "level_") { return true }
                return false
            }.first
            
            if let userRole = bestRole {
                fetchedUsers[i].role = AppRole.from(dbRole: userRole.role_name)
                fetchedUsers[i].subgroupId = userRole.subgroup_id
                fetchedUsers[i].groupId = userRole.group_id
            }
        }
        
        self.allUsers = fetchedUsers
    }
    
    @MainActor
    public func fetchHierarchyLevels() async throws {
        do {
            self.hierarchyLevels = try await client
                .from("hierarchy_levels")
                .select()
                .order("level_number", ascending: true)
                .execute()
                .value
            print("DEBUG: Fetched \(hierarchyLevels.count) hierarchy levels from Supabase")
        } catch {
            print("DEBUG ERROR: Failed to fetch hierarchy levels: \(error)")
        }
        
        if self.hierarchyLevels.isEmpty {
            let dummyOrgId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
            self.hierarchyLevels = [
                HierarchyLevelModel(organizationId: dummyOrgId, levelNumber: 1, levelName: "Groups", isEnabled: true),
                HierarchyLevelModel(organizationId: dummyOrgId, levelNumber: 2, levelName: "Subgroups", isEnabled: true),
                HierarchyLevelModel(organizationId: dummyOrgId, levelNumber: 3, levelName: "Nested Subgroups", isEnabled: true),
                HierarchyLevelModel(organizationId: dummyOrgId, levelNumber: 4, levelName: "Teams", isEnabled: false),
                HierarchyLevelModel(organizationId: dummyOrgId, levelNumber: 5, levelName: "Level 5", isEnabled: false)
            ]
        }
    }
    
    public func levelName(for levelNumber: Int, defaultName: String) -> String {
        return hierarchyLevels.first(where: { $0.levelNumber == levelNumber })?.levelName ?? defaultName
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
