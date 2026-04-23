//
//  ClubMemberDashboardView.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/19/26.
//

import SwiftUI

struct ClubMemberDashboardView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                ClubMemberHomeView()
            }
            
            Tab("My Club", systemImage: "person.3") {
                LeadMyClubView()
            }
            
            Tab("Explore", systemImage: "calendar") {
                ExploreView()
            }
            
            
            Tab("Chats", systemImage: "message") {
                ChatsView()
            }
            
        }
    }
}

#Preview {
    ClubMemberDashboardView()
        .environment(MockData.session(for: .clubMember))
}
