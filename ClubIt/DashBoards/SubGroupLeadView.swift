//
//  SubGroupLeadView.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/19/26.
//

import SwiftUI
import ClubItShared

struct SubGroupLeadView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                LeadHomeView()
                    //.padding(.horizontal)
            }
            
            Tab("My Club", systemImage: "person.3") {
                LeadMyClubView()
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
    SubGroupLeadView()
        .environment(MockData.session(for: .subGroupLead))
}
