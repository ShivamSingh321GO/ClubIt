//
//  ClubItApp.swift
//  ClubIt
//
//  Created by shivam kumar singh on 4/23/26.
//

import SwiftUI

@main
struct ClubItApp: App {
    @State private var appSession = AppSession()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appSession)
        }
    }
}
