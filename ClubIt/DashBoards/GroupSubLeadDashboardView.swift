//
//  GroupSubLeadDashboardView.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/19/26.
//

import SwiftUI
import ClubItShared

struct GroupSubLeadDashboardView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                VicePresidentHomeView()
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
    GroupSubLeadDashboardView()
        .environment(MockData.session(for: .groupSubLead))
}
