import SwiftUI

struct PresidentHomeView: View {
    @Environment(AppSession.self) var appSession
    @State private var selectedEventId: UUID? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                if let user = appSession.currentUser {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        // Today's Tasks Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Today's Task")
                                NavigationLink(destination: TasksListView(user: user)) {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .font(.title2)
                            .bold()
                            
                            HomeTasksModule(user: user)
                        }
                        
                        // Approval Request Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Approval Request")
                                NavigationLink(destination: ApprovalsListView(user: user)) {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .font(.title2)
                            .bold()
                            
                            PresidentApprovalsModule(user: user) { id in
                                selectedEventId = id
                            }
                        }
                        
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
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                    .navigationTitle("Home")
                    .toolbarTitleDisplayMode(.inlineLarge)
                    .navigationDestination(item: $selectedEventId) { id in
                        EventApprovalsDetailView(eventId: id)
                    }
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
