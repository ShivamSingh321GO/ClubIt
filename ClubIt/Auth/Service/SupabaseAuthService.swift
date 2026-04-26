//
//  SupabaseAuthService.swift
//  ClubIt
//
//  Created by shivam kumar singh on 4/26/26.
//

import Foundation
import Supabase




struct SupabaseAuthService {
    
    let client: SupabaseClient
    
    init() {
        self.client = SupabaseClient.init(
            supabaseURL: URL(
                
                string: Constants.projectURLString
            )!,
            supabaseKey: Constants.projectAPIKey
        )
    }
}
