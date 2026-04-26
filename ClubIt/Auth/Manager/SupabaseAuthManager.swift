//
//  SupabaseAuthManager.swift
//  ClubIt
//
//  Created by shivam kumar singh on 4/26/26.
//

import Foundation


@Observable
class SupabaseAuthManager {
    
    private let authService: SupabaseAuthService
    
    init(authService: SupabaseAuthService = SupabaseAuthService()) { //need to see on gpt why we are initializing like this
        self.authService = authService
    }

}
