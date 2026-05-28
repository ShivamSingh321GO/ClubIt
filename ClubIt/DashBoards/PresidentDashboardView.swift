//
//  PresidentDashboardView.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/19/26.
//

import SwiftUI

struct PresidentDashboardView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                PresidentHomeView()
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
    PresidentDashboardView()
        .environment(MockData.session(for: .president))
}
