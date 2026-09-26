//
//  SupabaseAuthService.swift
//  ClubIt
//
//  Created by shivam kumar singh on 4/26/26.
//

import Foundation
import Supabase




public struct SupabaseAuthService {
    
    public var client: SupabaseClient { SupabaseManager.shared.client }
    
    public init() {}
    
    public func signIn(email: String, password: String) async throws -> User {
        // 1. Sign in with Supabase Auth
        try await client.auth.signIn(email: email, password: password)
        
        // 2. Clear user session if login fails or token is invalid (handled by throws)
        guard let currentUser = client.auth.currentUser else {
            throw AuthError.userNotFound
        }
        
        // 3. Fetch public profile from 'users' table
        return try await fetchUserProfile(userId: currentUser.id)
    }
    
    public func signOut() async throws {
        try await client.auth.signOut()
    }
    
    public func verifyCurrentPassword(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }
    
    public func updatePassword(newPassword: String) async throws {
        try await client.auth.update(user: UserAttributes(password: newPassword))
    }
    
    public func resetPasswordForEmail(_ email: String, redirectTo: URL? = nil) async throws {
        try await client.auth.resetPasswordForEmail(email, redirectTo: redirectTo)
    }
    
    public func handleAuthURL(_ url: URL) async throws {
        try await client.auth.session(from: url)
    }
    
    public func fetchUserProfile(userId: UUID) async throws -> User {
        var user: User = try await client
            .from("users")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        
        func rolePriority(_ role: AppRole) -> Int {
            switch role {
            case .superAdmin: return 7
            case .admin: return 6
            case .groupLead: return 5
            case .groupSubLead: return 4
            case .subGroupLead: return 3
            case .subGroupMember: return 2
            case .guest: return 1
            }
        }
        
        struct RoleRow: Decodable {
            let role_name: String
            let subgroup_id: UUID?
            let group_id: UUID?
        }
        
        if let roleRows: [RoleRow] = try? await client
            .from("user_roles")
            .select("role_name, subgroup_id, group_id")
            .eq("user_id", value: userId)
            .execute()
            .value, !roleRows.isEmpty {
            
            var bestRole: AppRole = user.role
            var bestSubgroupId: UUID? = user.subgroupId
            var bestGroupId: UUID? = user.groupId
            
            for row in roleRows {
                if let mappedRole = mapRoleName(row.role_name) {
                    if rolePriority(mappedRole) > rolePriority(bestRole) {
                        bestRole = mappedRole
                        if let subId = row.subgroup_id { bestSubgroupId = subId }
                        if let grpId = row.group_id { bestGroupId = grpId }
                    } else if bestSubgroupId == nil, let subId = row.subgroup_id {
                        bestSubgroupId = subId
                    }
                }
            }
            
            user.role = bestRole
            if let subId = bestSubgroupId { user.subgroupId = subId }
            if let grpId = bestGroupId { user.groupId = grpId }
        }
        
        // Smart fallback: If user role resolves to guest but email or name indicates a leadership title
        if user.role == .guest {
            let lowerEmail = user.email.lowercased()
            let lowerName = user.name.lowercased()
            
            if lowerEmail.contains("groupsublead") || lowerEmail.contains("tcgsublead") || lowerName.contains("group sublead") || lowerName.contains("vice president") || lowerName.contains("vp") {
                user.role = .groupSubLead
            } else if lowerEmail.contains("grouplead") || lowerName.contains("group lead") || lowerName.contains("president") {
                user.role = .groupLead
            } else if lowerEmail.contains("subgrouplead") || lowerName.contains("subgroup lead") || lowerName.contains("club lead") {
                user.role = .subGroupLead
            } else if lowerEmail.contains("admin") || lowerName.contains("admin") {
                user.role = .admin
            }
        }
        
        // If the user is a Subgroup Lead and subgroupId is still nil,
        // resolve it by looking up lead_email in subgroups table
        if user.role == .subGroupLead && user.subgroupId == nil {
            struct SubgroupLookup: Decodable {
                let id: UUID
            }
            if let subgroups: [SubgroupLookup] = try? await client
                .from("subgroups")
                .select("id")
                .eq("lead_email", value: user.email)
                .execute()
                .value,
               let firstSubgroup = subgroups.first {
                user.subgroupId = firstSubgroup.id
            }
        }
        
        return user
    }
    
    private func mapRoleName(_ roleName: String) -> AppRole? {
        return AppRole.from(dbRole: roleName)
    }
    
    public enum AuthError: LocalizedError {
        case userNotFound
        case profileNotFound
        
        public var errorDescription: String? {
            switch self {
            case .userNotFound: return "User account not found."
            case .profileNotFound: return "User profile not found in database."
            }
        }
    }
}
