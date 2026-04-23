//
//  VicePresidentDashboardView.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/19/26.
//

import SwiftUI

struct VicePresidentDashboardView: View {
   
    var body: some View {
        TabView {
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
    VicePresidentDashboardView()
        .environment(MockData.session(for: .vicePresident))
}
