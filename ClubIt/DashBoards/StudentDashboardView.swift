//
//  StudentDashboardView.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/19/26.
//

import SwiftUI

struct StudentDashboardView: View {
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
        }
    }
}

#Preview {
    StudentDashboardView()
        .environment(MockData.session(for: .student))
}
