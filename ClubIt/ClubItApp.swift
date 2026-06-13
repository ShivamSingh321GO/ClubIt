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
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appSession)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && appSession.isLoggedIn {
                Task {
                    await appSession.refreshData()
                }
            }
        }
    }
}
