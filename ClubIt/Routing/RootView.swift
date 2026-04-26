//
//  RootView.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/19/26.
//


import SwiftUI

struct RootView: View {
    @Environment(AppSession.self) private var appSession

    var body: some View {
        Group {
            if appSession.isLoggedIn {
                DashboardRouter()
            } else {
                SignInView()
            }
        }
        .task {
            if appSession.isLoggedIn {
                await appSession.refreshData()
            }
        }
    }
}
