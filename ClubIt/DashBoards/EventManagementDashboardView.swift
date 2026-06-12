import SwiftUI

struct EventManagementDashboardView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                EventManagementHomeView()
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
    EventManagementDashboardView()
        .environment(MockData.session(for: .faculty))
}
