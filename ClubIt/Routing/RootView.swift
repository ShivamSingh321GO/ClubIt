//
//  RootView.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/19/26.
//


import SwiftUI
import ClubItShared

struct RootView: View {
    @Environment(AppSession.self) private var appSession
    @State private var showLaunchScreen: Bool = true

    var body: some View {
        Group {
            if showLaunchScreen {
                LaunchScreenView(showLaunchScreen: $showLaunchScreen)
            } else {
                if appSession.isLoggedIn {
                    DashboardRouter()
                } else {
                    SignInView()
                }
            }
        }
        .task {
            await appSession.restoreSession()
            if appSession.isLoggedIn {
                await appSession.refreshData()
            }
        }
        .onOpenURL { url in
            Task {
                _ = await appSession.handleAuthURL(url)
            }
        }
        .sheet(isPresented: Bindable(appSession).isPasswordResetMode) {
            ResetPasswordView()
        }
    }
}
