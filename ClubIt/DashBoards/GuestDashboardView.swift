//
//  GuestDashboardView.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/19/26.
//

import SwiftUI
import ClubItShared

struct GuestDashboardView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                StudentHomeView()
            }
            Tab("Explore", systemImage: "globe") {
                ExploreView()
            }
            
            Tab("Chats", systemImage: "message") {
                ChatsView()
            }
            .badge(appSession.chatStore.totalUnreadCount)
        }
    }
}

#Preview {
    GuestDashboardView()
        .environment(MockData.session(for: .guest))
}
