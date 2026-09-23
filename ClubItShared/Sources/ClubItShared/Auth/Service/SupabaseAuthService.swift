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
    
    public func fetchUserProfile(userId: UUID) async throws -> User {
        var user: User = try await client
            .from("users")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        
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
            .value {
            
            for row in roleRows {
                if let mappedRole = mapRoleName(row.role_name) {
                    user.role = mappedRole
                    if let subId = row.subgroup_id {
                        user.subgroupId = subId
                    }
                    if let grpId = row.group_id {
                        user.groupId = grpId
                    }
                    break
                }
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
        let name = roleName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Exact / Case-insensitive match to AppRole raw values
        for role in AppRole.allCases {
            if role.rawValue.lowercased() == name {
                return role
            }
        }
        
        // 2. Custom case-insensitive mapping fallbacks
        if name == "group lead" || name == "grouplead" {
            return .groupLead
        }
        if name == "group sublead" || name == "groupsublead" {
            return .groupSubLead
        }
        if name == "subgroup lead" || name == "subgrouplead" {
            return .subGroupLead
        }
        if name == "subgroup member" || name == "subgroupmember" {
            return .subGroupMember
        }
        if name == "superadmin" {
            return .superAdmin
        }
        if name == "admin" {
            return .admin
        }
        
        // 3. Hierarchical custom levels mapping
        // Level 1 represents Group
        if name.contains("level_1_lead") || name == "level_1_lead" {
            return .groupLead
        }
        if name.contains("level_1_sublead") || name == "level_1_sublead" {
            return .groupSubLead
        }
        
        // Level 2 represents SubGroup
        if name.contains("level_2_lead") || name == "level_2_lead" {
            return .subGroupLead
        }
        if name.contains("level_2_sublead") || name.contains("level_2_member") {
            return .subGroupMember
        }
        
        return nil
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
