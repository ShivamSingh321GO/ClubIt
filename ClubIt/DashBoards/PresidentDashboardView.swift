//
//  PresidentDashboardView.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/19/26.
//

import SwiftUI

struct PresidentDashboardView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                PresidentHomeView()
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
    PresidentDashboardView()
        .environment(MockData.session(for: .president))
}
