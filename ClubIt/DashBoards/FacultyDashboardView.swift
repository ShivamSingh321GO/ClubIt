//
//  AdminDashboardView.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/19/26.
//

import SwiftUI

struct FacultyDashboardView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                FacultyHomeView()
            }
            
            Tab("Manage", systemImage: "person.3") {
                FacultyManagementView()
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
    FacultyDashboardView()
        .environment(MockData.session(for: .faculty))
}
