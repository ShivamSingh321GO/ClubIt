import SwiftUI
import ClubItShared

struct OrgAdminDashboardView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                EventManagementHomeView()
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

//#Preview {
//    OrgAdminDashboardView()
//        .environment(MockData.session(for: .groupSubLead))
//}
