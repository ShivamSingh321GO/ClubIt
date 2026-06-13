import SwiftUI

struct FacultyHomeView: View {
    @Environment(AppSession.self) var appSession
    @State private var selectedEventId: UUID? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
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
                        
                        // Approval Request Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Approval Management")
                                NavigationLink(destination: FacultyResourceClubsView()) {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .font(.title2)
                            .bold()
                            
                            FacultyApprovalsModule(user: user)
                        }
                        
                        
                        // Upcoming Events Section
//                        VStack(alignment: .leading, spacing: 16) {
//                            HStack {
//                                Text("Upcoming Events")
//                                NavigationLink(destination: ExploreView()) {
//                                    Image(systemName: "chevron.right")
//                                }
//                            }
//                            .font(.title2)
//                            .bold()
//                            
//                            UpcomingEventsModule(user: user)
//                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                    .navigationTitle("Home")
                    .toolbarTitleDisplayMode(.inlineLarge)
                    .navigationDestination(item: $selectedEventId) { id in
                        FacultyEventApprovalsView(eventId: id, userId: user.id)
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
            .refreshable {
                await appSession.refreshData()
            }
            
            if appSession.isRefreshing {
                VStack {
                    ProgressView()
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    Text("Loading data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.1))
                .transition(.opacity)
            }
            } // Close ZStack
        }
        .task {
            await appSession.refreshData()
        }
        .sheet(item: Bindable(appSession).selectedTask) { task in
            TaskDetailView(task: task)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
        }
    }
    
}

#Preview {
    FacultyHomeView()
        .environment(MockData.session(for: .faculty))
}
