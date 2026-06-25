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
    
    public func fetchUserProfile(userId: UUID) async throws -> User {
        let user: User = try await client
            .from("users")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        
        return user
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
