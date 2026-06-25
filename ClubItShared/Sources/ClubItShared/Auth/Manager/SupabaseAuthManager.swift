//
//  SupabaseAuthManager.swift
//  ClubIt
//
//  Created by shivam kumar singh on 4/26/26.
//

import Foundation


@Observable
public class SupabaseAuthManager {
    
    private let authService: SupabaseAuthService
    
    public init(authService: SupabaseAuthService = SupabaseAuthService()) { //need to see on gpt why we are initializing like this
        self.authService = authService
    }

}
