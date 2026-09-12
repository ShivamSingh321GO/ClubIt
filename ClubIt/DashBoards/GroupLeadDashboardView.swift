//
//  GroupLeadDashboardView.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/19/26.
//

import SwiftUI
import ClubItShared

struct GroupLeadDashboardView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                PresidentHomeView()
            }
            
            if appSession.isExploreVisible {
                Tab(appSession.exploreTabTitle, systemImage: appSession.exploreTabIcon) {
                    ExploreView()
                }
            }
            
            if !(appSession.organizationFeatures?.isChatDisabled ?? false) {
                Tab("Chats", systemImage: "message") {
                    ChatsView()
                }
                .badge(appSession.chatStore.totalUnreadCount)
            }
        }
    }
}

#Preview {
    GroupLeadDashboardView()
        .environment(MockData.session(for: .groupLead))
}
