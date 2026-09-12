//
//  SubGroupMemberView.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/19/26.
//

import SwiftUI
import ClubItShared

struct SubGroupMemberView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                SubgroupMemberHomeView()
            }
            
            Tab("My \(appSession.subgroupStore.levelName(for: 2, defaultName: "Subgroup"))", systemImage: "person.3") {
                LeadMySubgroupView()
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
    SubGroupMemberView()
        .environment(MockData.session(for: .subGroupMember))
}
