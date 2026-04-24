import SwiftUI

struct PresidentHomeView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                if let user = appSession.currentUser {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        // Today's Tasks Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("All Tasks")
                                NavigationLink(destination: TasksListView(user: user)) {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .font(.title2)
                            .bold()
                            
                            HomeTasksModule(user: user)
                        }
                        
                        // Approval Management Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Approval Management")
                                NavigationLink(destination: PresidentBudgetClubsView()) {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .font(.title2)
                            .bold()
                            
                            PresidentApprovalsModule(user: user)
                        }
                        
                        /*
                        // Upcoming Events Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Upcoming Events")
                                NavigationLink(destination: ExploreView()) {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .font(.title2)
                            .bold()
                            
                            UpcomingEventsModule(user: user)
                        }
                        */
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                    .navigationTitle("Home")
                    .toolbarTitleDisplayMode(.inlineLarge)
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            NavigationLink {
                                LeadNotificationView()
                            } label: {
                                Image(systemName: "bell")
                            }
                            
                            NavigationLink {
                                LeadProfileView()
                            } label: {
                                Image(systemName: "person.circle")
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let session = MockData.session(for: .president)
    return PresidentHomeView()
        .environment(session)
}
